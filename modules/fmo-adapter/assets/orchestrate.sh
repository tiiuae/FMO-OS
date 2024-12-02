#!/usr/bin/env bash

set -euo pipefail

CWD=${PWD}
RUNNING=${CWD}/.orchestrate_running
PROVISIONED=${CWD}/.provisioned_drones
STARTED=${CWD}/.started_drones

if [ -f ${RUNNING} ]; then
    exit 0
fi

touch ${RUNNING}
rm -f ${PROVISIONED}

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
DEFAULT_IMAGE="ghcr.io/tiiuae/tii-fmo-adapter-files"
TAG=""
COMPOSE_IMAGE=""

# Components
COMPONENT_FILE=""
MANIFEST_FILE=""
PROVISIONING_IMAGE=""
REGISTRATION_IMAGE=""

docker_login() {
    docker-login.sh
    if (( $? != 0 )); then
        echo "Docker login failed, exiting."
        do_exit
    fi
}

start_pcscd() {
    local count=$(ps aux | grep -w "pcscd" | grep -v "grep" | wc -l)
    if (( ${count} != 0 )); then
        return
    fi

    sudo bash -c 'pcscd &'
    PCSCD_PID=$!
}

read_pin() {
    read -p "Please plug in Yubikey before continuing, press <Enter> to continue"

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
    compose-image.sh
    if (( $? != 0 )); then
        echo "Compose image retrieval failed, exiting."
        do_exit
    fi
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

# Using local provisioning server instance for convenience because
# 1. using an official provisioning server requires waking up internal wifi adapter
#    and some forwarding rules in place
# 2. official provisioning server is not always in your reach
start_provisioning_server() {
    local container_id=$(docker create ${PROVISIONING_IMAGE})
    docker cp $container_id:/app/provisioning-server ${WORKDIR}
    docker rm $container_id

    local cfg_file=$(find ./data -name "*_cfg.json" | head -1)

    echo "Using ${cfg_file} for provisioning server configuration"

    mustache --override ${COMPONENT_FILE} ${cfg_file} ${WORKDIR}/templates/provisioning-server-env.template >${WORKDIR}/.env

    local PKCS11_MODULE=/run/current-system/sw/lib/libykcs11.so
    if [ ! -f ${PKCS11_MODULE} ]; then
        echo 'Could not locate "libykcs11.so", exiting'
        do_exit
    fi

    local ENGINE=$(find /run/current-system/sw/lib/ -name "libpkcs11.so" | grep "engine" | head -1)
    if [ ! -f ${ENGINE} ]; then
        echo 'Could not locate PKCS#11 engine, exiting'
        do_exit
    fi

    sed -i "s|xyzPATHxyz|${WORKDIR}|g" ${WORKDIR}/.env
    sed -i "s|xyzPKCS11xyz|${PKCS11_MODULE}|g" ${WORKDIR}/.env
    sed -i "s|xyzPINxyz|${PIN}|g" ${WORKDIR}/.env
    sed -i "s|xyzENGINExyz|${ENGINE}|g" ${WORKDIR}/.env

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

        mkdir -p ${device_dir}
        mkdir -p ${device_dir}/cfg
        mkdir -p ${device_dir}/cert
        mkdir -p ${device_dir}/mount
        mkdir -p ${device_dir}/enclave/nats
        mkdir -p ${device_dir}/softhsm/pins
        mkdir -p ${device_dir}/softhsm/so-pins
        mkdir -p ${device_dir}/softhsm/swarm
        mkdir -p ${device_dir}/softhsm/tokens

        cp ${WORKDIR}/data/DEFAULT_FASTRTPS_PROFILES_1.xml ${device_dir}/mount

        grep "provisioning_nats_url" ${cfg_file} | awk '{print $2}' | tr -d '",' >${device_dir}/cfg/service_nats_url.txt

        mustache --override ${COMPONENT_FILE} ${cfg_file} ${WORKDIR}/templates/register-env.template >${device_dir}/register-env.list
        mustache --override ${COMPONENT_FILE} ${cfg_file} ${WORKDIR}/templates/compose.template >${device_dir}/docker-compose.yaml
        mustache --override ${COMPONENT_FILE} ${cfg_file} ${WORKDIR}/templates/certificate-setup.template >${device_dir}/certificate-setup.json
        mustache --override ${COMPONENT_FILE} ${cfg_file} ${WORKDIR}/templates/proxy.template >${device_dir}/proxy-compose.yaml
        mustache ${cfg_file} ${WORKDIR}/templates/nats-server-conf.template >${device_dir}/cfg/nats-server.conf
        mustache ${cfg_file} ${WORKDIR}/templates/config-fmo-mavlink.template >${device_dir}/cfg/sec-udp/config-fmo-mavlink.yaml

        # Start device's pkcs11-proxy instance
        # docker compose -f ${device_dir}/proxy-compose.yaml up -d

        local ret=$(docker run --network host --rm --name registration-agent \
            --env-file ${device_dir}/register-env.list --volume ${device_dir}:/data \
            --user $(id -u ${USER}):$(id -g ${USER}) ${REGISTRATION_IMAGE} provision)
        if (( ${ret} != 0 )); then
            echo "Provisioning device \"${device_alias}\" failed."
            do_exit
        fi

        # Registering to be implemented in a later phase
        # docker run --network host --rm --name registration-agent \
        #     --env-file ${device_dir}/register-env.list --volume ${device_dir}:/data \
        #     --user $(id -u ${USER}):$(id -g ${USER}) ${REGISTRATION_IMAGE} register

        if [ ! -f ${device_dir}/device-registered.txt ]; then
            echo "Provisioning device \"${device_alias}\" failed."
            do_exit
        fi

        local drone_device_id=$(grep "\"id\":" ${device_dir}/device-registered.txt | awk '{print $2}' | tr -d '",')

        sed -i "s/xyzXYZxyz/${drone_device_id}/g" ${device_dir}/docker-compose.yaml

        echo "${device_alias}" >>${PROVISIONED}
    done

    read -p "Drones provisioned, Yubikey may be removed, press <Enter> to continue"
}

start_drones() {
    local provisioned=$(cat ${PROVISIONED} | sort -u)
    local started=$(cat ${STARTED})

    for drone in ${provisioned[@]}; do
        local is_started="n"
        for already in ${started[@]}; do
            if [ "${drone}x" == "${already}x"]; then
                is_started="y"
                break
            fi
        done

        if [ "${is_started}" == "n" ]; then
            local reply=""
            read -p "Do you want to start adapter drone ${drone} [Y/n]: " reply
            if [ "${reply^^}" == "N" ]; then
                continue
            fi

            docker compose -f devices/${drone}/docker-compose.yaml up -d

            echo "${drone}" >>${STARTED}
        fi
    done
}

stop_drones() {
    local started=$(cat ${STARTED})
    local stopped=()

    for drone in ${started[@]}; do
        local reply=""
        read -p "Do you want to stop adapter drone ${drone} [Y/n]: " reply
        if [ "${reply^^}" == "N" ]; then
            continue
        fi

        docker compose -f devices/${drone}/docker-compose.yaml down

        stopped+=("${drone}")
    done

    rm -f ${STARTED}

    for started_drone in ${started[@]}; do
        local found="n"
        for stopped_drone in ${stopped[@]}; do
            if [ "${started_drone}x" == "${stopped_drone}x" ]; then
                found="y"
                break
            fi
        done

        if [ "${found}" == "n" ]; then
            echo "${started_drone}" >>${STARTED}
        fi
    done
}

choices() {
    for (( ; ; )); do
        local reply=""
        echo "Choose:"
        echo "  1 - Prepare and provision drones"
        echo "  2 - Start drones"
        echo "  3 - Stop drones"
        echo "  0 - Exit (any started drone will remain started)"
        read -p "Your choice: " reply

        case ${reply} in
            1)
                prepare_drones
                ;;
            2)
                start_drones
                ;;
            3)
                stop_drones
                ;;
            0)
                RET=0
                do_exit
                ;;
            *)
                echo "Not a valid option"
                ;;
        esac
    done
}

read -p "Enter working folder [${PWD}]: " WORKDIR
WORKDIR=${WORKDIR:-${PWD}}
COMPONENT_FILE="${WORKDIR}/data/components.json"
MANIFEST_FILE="${WORKDIR}/data/manifest.json"

if [ ! -d ${WORKDIR} ]; then
    mkdir -p ${WORKDIR}
fi

mkdir -p ${WORKDIR}/data
mkdir -p ${WORKDIR}/scripts
mkdir -p ${WORKDIR}/templates
mkdir -p ${WORKDIR}/devices
mkdir -p ${WORKDIR}/devices/common

docker_login
start_pcscd
read_pin
get_compose_image
prepare_components
start_provisioning_server

choices
