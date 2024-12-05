#!/usr/bin/env bash

set -euo pipefail

CWD=${PWD}
RUNNING=/tmp/orchestrate_running
PROVISIONED=/tmp/provisioned_drones
STARTED=/tmp/started_drones

if [ -f ${RUNNING} ]; then
    echo "File ${RUNNING} already exists for some reason, please remove it first."
    exit 0
fi

touch ${RUNNING}
rm -f ${PROVISIONED}

RET=2
DEFAULT_DIR="/var/lib/fogdata/adapter"
WORK_DIR=""
PCSCD_PID=""

do_exit() {
    rm -f ${RUNNING}

    if (( ${RET} == 2 )); then
        local reply=""
        read -p "Failed to orchestate adapter drones; remove generated configuration [Y/n]: " reply
        if [ ! "${reply^^}" == "N" ]; then
            sudo rm -rf ${WORK_DIR}/devices
        fi
    fi

    local prov_pid=$(ps f -u ${USER} | grep "provisioning-server" | grep -v grep | awk '{print $1}')
    if [ "${prov_pid}x" != "x" ]; then
        echo "Stopping provisioning-server..."
        kill ${prov_pid}
    fi

    if [ "${PCSCD_PID}x" != "x" ]; then
        echo "Stopping pcscd..."
        kill ${PCSCD_PID}
    fi

    cd ${CWD}

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

get_compose_data() {
    local reply=""
    read -p "Do you want to use a Docker image for compose data [Y/n]: " reply
    if [ "${reply^^}" != "N" ]; then
        compose-image.sh
        if (( $? != 0 )); then
            echo "Compose image retrieval failed, exiting."
            do_exit
        fi
    else
        echo "Make sure, you have ${WORK_DIR}/data and ${WORK_DIR}/templates in place."
        read -p "Press <Enter> when done copying compose data."
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
    docker cp $container_id:/app/provisioning-server ${WORK_DIR}
    docker rm $container_id

    local cfg_file=$(find ./data -name "*_cfg.json" | head -1)

    echo "Using ${cfg_file} for provisioning server configuration"

    mustache --override ${COMPONENT_FILE} ${cfg_file} ${WORK_DIR}/templates/provisioning-server-env.template >${WORK_DIR}/.env

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

    sed -i "s|xyzPATHxyz|${WORK_DIR}|g" ${WORK_DIR}/.env
    sed -i "s|xyzPKCS11xyz|${PKCS11_MODULE}|g" ${WORK_DIR}/.env
    sed -i "s|xyzPINxyz|${PIN}|g" ${WORK_DIR}/.env
    sed -i "s|xyzENGINExyz|${ENGINE}|g" ${WORK_DIR}/.env

    ${WORK_DIR}/provisioning-server &
    sleep 1
    echo "Provisioning server started..."
}

prepare_drones() {
    for cfg_file in ${WORK_DIR}/data/*_cfg.json; do
        local reply=""
        read -p "Do you want to add device configuration $(basename ${cfg_file}) to adapter [Y/n]: " reply
        if [ "${reply^^}" == "N" ]; then
            continue
        fi

        local device_alias=$(grep "device_alias" ${cfg_file} | awk '{print $2}' | tr -d '",')
        local device_dir="${WORK_DIR}/devices/${device_alias}"

        mkdir -p ${device_dir}
        mkdir -p ${device_dir}/cfg
        mkdir -p ${device_dir}/cfg/sec-udp
        mkdir -p ${device_dir}/cert
        mkdir -p ${device_dir}/mount
        mkdir -p ${device_dir}/enclave/nats
        mkdir -p ${device_dir}/softhsm/pins
        mkdir -p ${device_dir}/softhsm/so-pins
        mkdir -p ${device_dir}/softhsm/swarm
        mkdir -p ${device_dir}/softhsm/tokens

        cp ${WORK_DIR}/data/DEFAULT_FASTRTPS_PROFILES_1.xml ${device_dir}/mount

        grep "provisioning_nats_url" ${cfg_file} | awk '{print $2}' | tr -d '",' >${device_dir}/cfg/service_nats_url.txt

        mustache --override ${COMPONENT_FILE} ${cfg_file} ${WORK_DIR}/templates/register-env.template >${device_dir}/register-env.list
        mustache --override ${COMPONENT_FILE} ${cfg_file} ${WORK_DIR}/templates/compose.template >${device_dir}/docker-compose.yaml
        mustache --override ${COMPONENT_FILE} ${cfg_file} ${WORK_DIR}/templates/certificate-setup.template >${device_dir}/certificate-setup.json
        mustache --override ${COMPONENT_FILE} ${cfg_file} ${WORK_DIR}/templates/proxy.template >${device_dir}/proxy-compose.yaml
        mustache ${cfg_file} ${WORK_DIR}/templates/nats-server-conf.template >${device_dir}/cfg/nats-server.conf
        mustache ${cfg_file} ${WORK_DIR}/templates/config-fmo-mavlink.template >${device_dir}/cfg/sec-udp/config-fmo-mavlink.yaml
        mustache ${cfg_file} ${WORK_DIR}/templates/serial-number.template >${device_dir}/serial-number.txt

        # Start device's pkcs11-proxy instance
        # docker compose -f ${device_dir}/proxy-compose.yaml up -d

        docker run --network host --rm --name registration-agent \
            --env-file ${device_dir}/register-env.list --volume ${device_dir}:/data \
            --user $(id -u ${USER}):$(id -g ${USER}) ${REGISTRATION_IMAGE} provision
        if (( $? != 0 )); then
            echo "Provisioning device \"${device_alias}\" failed."
            reply=""
            read -p "Do you want to check configuration and retry provisioning [Y/n]" reply
            if [ "${reply^^}" == "N" ]; then
                continue
            fi

            read -p "Press <Enter> when ready to retry"
            docker run --network host --rm --name registration-agent \
                --env-file ${device_dir}/register-env.list --volume ${device_dir}:/data \
                --user $(id -u ${USER}):$(id -g ${USER}) ${REGISTRATION_IMAGE} provision
            if (( $? != 0 )); then
                echo "Provisioning device \"${device_alias}\" failed again, skipping it."
                continue
            fi
        fi

        mustache ${cfg_file} ${WORK_DIR}/templates/device-registered.template >${device_dir}/device-registered.txt

        # Registering to be implemented in a later phase
        # docker run --network host --rm --name registration-agent \
        #     --env-file ${device_dir}/register-env.list --volume ${device_dir}:/data \
        #     --user $(id -u ${USER}):$(id -g ${USER}) ${REGISTRATION_IMAGE} register

        # if [ ! -f ${device_dir}/device-registered.txt ]; then
        #     echo "Provisioning device \"${device_alias}\" failed."
        #     do_exit
        # fi

        local drone_device_id=$(openssl x509 -in ${device_dir}/cert/client-certificate.pem -text | grep "Subject: CN" | awk '{split($0,a,"/"); print a[4]}')

        sed -i "s/xyzXYZxyz/${drone_device_id}/g" ${device_dir}/docker-compose.yaml
        sed -i "s/xyzXYZxyz/${drone_device_id}/g" ${device_dir}/device-registered.txt

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

read -p "Enter working folder [${DEFAULT_DIR}]: " WORK_DIR
WORK_DIR=${WORK_DIR:-${DEFAULT_DIR}}
COMPONENT_FILE="${WORK_DIR}/data/components.json"
MANIFEST_FILE="${WORK_DIR}/data/manifest.json"

if [ ! -d ${WORK_DIR} ]; then
    sudo mkdir -p ${WORK_DIR}
    sudo chown -R ghaf:ghaf ${WORKDIR}
fi

cd ${WORK_DIR}

mkdir -p ${WORK_DIR}/data
mkdir -p ${WORK_DIR}/scripts
mkdir -p ${WORK_DIR}/templates
mkdir -p ${WORK_DIR}/devices
mkdir -p ${WORK_DIR}/devices/common

echo "Logging in ghcr.io"
docker_login
echo "Starting Smart Card daemon if needed"
start_pcscd
echo "Checking Yubikey accessibility"
read_pin
echo "Acquiring adapter configuration and data"
get_compose_data
echo "Preparing needed components"
prepare_components
echo "Starting local provisioning server instance"
start_provisioning_server

choices
