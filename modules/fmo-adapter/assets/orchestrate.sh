#!/usr/bin/env bash

set -euo pipefail

CWD=${PWD}

if [ -f ${CWD}/.orchestrate_running ]; then
    exit 0
fi

touch ${CWD}/.orchestrate_running

RET=2
WORKDIR=""
PROVISIONING_PID=""
PCSCD_PID=""

do_exit() {
    rm -f ${CWD}/.orchestrate_running

    if (( ${RET} == 2 )); then
        local reply=""
        read -p "Failed to orchestate adapter drones; remove generated configuration [Y/n]: " reply
        if [ ! "${reply^^}" == "N" ]; then
            sudo rm -rf ${WORKDIR}/devices
        fi
    fi

    if [ "${PROVISIONING_PID}x" != "x" ]; then
        echo "Stopping provisioning-server..."
        kill ${PROVISIONING_PID}
    fi

    if [ "${PCSCD_PID}x" != "x" ]; then
        echo "Stopping pcscd..."
        kill ${PCSCD_PID}
    fi

    exit ${RET}
}

trap do_exit INT

# Yubikey
PIN=""

# Adapter files
TAG=""
COMPOSE_IMAGE=""
DEFAULT_IMAGE="ghcr.io/tiiuae/tii-fmo-adapter-files"

# Components
COMPONENT_FILE=""
MANIFEST_FILE=""
REGISTRATION_IMAGE=""
PROVISIONING_IMAGE=""

DRONES=()

start_pcscd() {
    local count=$(ps aux | grep -w "pcscd" | grep -v "grep" | wc -l)
    if (( ${count} != 0 )); then
        return
    fi

    pcscd &
    PCSCD_PID=$!
}

read_pin() {
    for i in {1..3}; do
        read -p "Enter secure store PIN: " PIN
        yubico-piv-tool --action verify-pin --pin ${PIN}

        if (( $? == 0 )); then
            return
        fi
    done

    do_exit
}

get_compose_image() {
    for i in {1..3}; do
        COMPOSE_IMAGE=""
        read -p "Enter adapter image [${DEFAULT_IMAGE}]: " COMPOSE_IMAGE
        COMPOSE_IMAGE=${COMPOSE_IMAGE:-${DEFAULT_IMAGE}}
        if (( $(awk -F: '{print length($1)}' <<< "${COMPOSE_IMAGE}") == $(awk '{print length($1)}' <<< "${COMPOSE_IMAGE}") )); then
            read -p "Enter tag for \"${COMPOSE_IMAGE}\": " TAG
            COMPOSE_IMAGE=${COMPOSE_IMAGE}:${TAG}
        fi

        docker pull ${COMPOSE_IMAGE}

        if (( $? == 0 )); then
            local container_id=$(docker create ${COMPOSE_IMAGE})
            docker cp $container_id:/data/ ${WORKDIR}
            docker cp $container_id:/templates/ ${WORKDIR}
            docker cp $container_id:/scripts/ ${WORKDIR}
            docker rm $container_id

            return
        fi

        echo "Fetching adapter image \"${COMPOSE_IMAGE}\" failed."
    done

    do_exit
}

prepare_components() {
    # extract required components' images into ${COMPONENT_FILE}
    jq '[ .Components[] |
        select(.Name == "registration-agent" or .Name == "pkcs11-proxy" or
        .Name == "certificate-setup" or .Name == "fog-navigation-lite" or
        .Name == "telem-nats" or .Name == "path-worker" or
        .Name == "swarm-agent" or .Name == "sec-udp-rev-proxy" or
        .Name == "nats-server-swarm" or .Name == "mocap-pose" or
        .Name == "ntrip-client" or .Name == "trajectory-multicast" or
        .Name == "provisioning-server") |
        {(.Name|tostring): .Artifacts[].ImageRef}] | add' ${MANIFEST_FILE} >${COMPONENT_FILE}

    REGISTRATION_IMAGE=$(grep "registration-agent" ${COMPONENT_FILE} | awk '{print $2}' | tr -d '",')
    PROVISIONING_IMAGE=$(grep "provisioning-server" ${COMPONENT_FILE} | awk '{print $2}' | tr -d '",')
}

start_provisioning_server() {
    local container_id=$(docker create ${PROVISIONING_IMAGE})
    docker cp $container_id:/provisioning-server ${WORKDIR}
    docker rm $container_id

    mustache --override ${COMPONENT_FILE} ${cfg_file} ${WORKDIR}/templates/provisioning-server-env.template >${WORKDIR}/.env

    local PKCS11_MODULE=$(find /nix/store/ -name "libykcs11.so" | grep "system-path/lib" | head -n 1)
    if [ "${PKCS11_MODULE}x" == "x" ]; then
        echo 'Could not locate "libykcs11.so", exiting'
        do_exit
    fi

    sed -i "s/xyzPATHxyz/${WORKDIR}/g" ${WORKDIR}/.env
    sed -i "s/xyzPKCS11xyz/${PKCS11_MODULE}/g" ${WORKDIR}/.env
    sed -i "s/xyzPINxyz/${PIN}/g" ${WORKDIR}/.env

    ${WORKDIR}/provisioning-server &
    PROVISIONING_PID=$!

    echo "Provisioning server started..."
}

prepare_drones() {
    for cfg_file in $WORKDIR/data/*_cfg.json; do
        local reply=""
        read -p "Do you want to add device configuration $(basename ${cfg_file}) to adapter [Y/n]: " reply
        if [ "${reply^^}" == "N" ]; then
            continue
        fi

        local device_alias=$(grep "device_alias" ${cfg_file} | awk '{print $2}' | tr -d '",')
        local device_dir="${WORKDIR}/devices/${device_alias}"

        DRONES+=("${device_alias}")

        mkdir ${device_dir}
        mkdir ${device_dir}/cfg
        mkdir ${device_dir}/cert
        mkdir ${device_dir}/mount
        mkdir -p ${device_dir}/enclave/nats
        mkdir -p ${device_dir}/softhsm/pins
        mkdir ${device_dir}/softhsm/so-pins
        mkdir ${device_dir}/softhsm/swarm
        mkdir ${device_dir}/softhsm/tokens

        cp ${WORKDIR}/data/DEFAULT_FASTRTPS_PROFILES_1.xml ${device_dir}/mount

        grep "provisioning_nats_url" ${cfg_file} | awk '{print $2}' | tr -d '",' >${device_dir}/cfg/service_nats_url.txt

        mustache --override ${COMPONENT_FILE} ${cfg_file} ${WORKDIR}/templates/register-env.template >${device_dir}/register-env.list
        mustache --override ${COMPONENT_FILE} ${cfg_file} ${WORKDIR}/templates/compose.template >${device_dir}/docker-compose.yaml
        mustache --override ${COMPONENT_FILE} ${cfg_file} ${WORKDIR}/templates/certificate-setup.template >${device_dir}/certificate-setup.json
        mustache --override ${COMPONENT_FILE} ${cfg_file} ${WORKDIR}/templates/proxy.template >${device_dir}/proxy-compose.yaml

        # Start device's pkcs11-proxy instance
        docker compose -f ${device_dir}/proxy-compose.yaml up -d

        # Each drone requires own drone-nats-server but the configuration is same to all
        if [ ! -f ${WORKDIR}/devices/common/nats-server.conf ]; then
            mustache ${cfg_file} ${WORKDIR}/templates/nats-server-conf.template >${WORKDIR}/devices/common/nats-server.conf
        fi

        docker run --network host --rm --name registration-agent \
            --env-file ${device_dir}/register-env.list --volume ${device_dir}:/data \
            --user $(id -u ${USER}):$(id -g ${USER}) ${REGISTRATION_IMAGE} provision

        docker run --network host --rm --name registration-agent \
            --env-file ${device_dir}/register-env.list --volume ${device_dir}:/data \
            --user $(id -u ${USER}):$(id -g ${USER}) ${REGISTRATION_IMAGE} register

        if [ ! -f ${device_dir}/device-registered.txt ]; then
            echo "Provisioning device \"${device_alias}\" failed."
            do_exit
        fi

        local drone_device_id=$(grep "\"id\":" ${device_dir}/device-registered.txt | awk '{print $2}' | tr -d '",')

        sed -i "s/xyzXYZxyz/${drone_device_id}/g" ${device_dir}/docker-compose.yaml
    done
}

read -p "Enter working folder [${PWD}]: " WORKDIR
WORKDIR=${WORKDIR:-${PWD}}
COMPONENT_FILE="${WORKDIR}/data/components.json"
MANIFEST_FILE="${WORKDIR}/data/foghyper/fog_system/manifest.json"

if [ ! -d ${WORKDIR} ]; then
    mkdir -p ${WORKDIR}
fi

mkdir ${WORKDIR}/data
mkdir ${WORKDIR}/scripts
mkdir ${WORKDIR}/templates
mkdir ${WORKDIR}/devices
mkdir ${WORKDIR}/devices/common

docker-login.sh
start_pcscd
read_pin
get_compose_image
prepare_components
start_provisioning_server
prepare_drones

echo ${PIN}
echo ${COMPOSE_IMAGE}

RET=0
do_exit
