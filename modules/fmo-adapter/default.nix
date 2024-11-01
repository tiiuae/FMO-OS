# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{ pkgs, ... }:
let
  orchestrate = pkgs.writeShellScriptBin "orchestrate" ''
    set -euo pipefail

    CWD=''${PWD}

    if [ -f ''${CWD}/.orchestrate_running ]; then
        exit 0
    fi

    touch ''${CWD}/.orchestrate_running

    ret=2

    do_exit() {
        rm -f ''${CWD}/.orchestrate_running
        exit $ret
    }

    trap do_exit INT

    WORKDIR=""

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

    DRONES=()

    docker_login() {
        local credentials_file=/var/lib/fogdata/PAT.pat

        if [ ! -f ''${credentials_file} ]; then
            echo "Docker credentials file not found"
            do_exit
        fi

        local credentials=$(cat ''${credentials_file})
        local docker_user=$(echo ''${credentials} | awk '{print $1}')
        local docker_pwd=$(echo ''${credentials} | awk '{print $2}')

        echo ''${docker_pwd} | docker login --username ''${docker_user} --password-stdin

        if (( $(grep "auth" ''${HOME}/.docker/config.json | wc -l) < 2 )); then
            echo "Docker login failed"
            do_exit
        fi
    }

    read_pin() {
        for i in {1..3}; do
            read -p "Enter secure store PIN: " PIN
            yubico-piv-tool --action verify-pin --pin ''${PIN}

            if (( $? == 0 )); then
                return
            fi
        done

        do_exit
    }

    get_compose_image() {
        for i in {1..3}; do
            COMPOSE_IMAGE=""
            read -p "Enter adapter image [''${DEFAULT_IMAGE}]: " COMPOSE_IMAGE
            COMPOSE_IMAGE="''${COMPOSE_IMAGE:-''${DEFAULT_IMAGE}}"
            if (( $(awk -F: '{print length($1)}' <<< "''${COMPOSE_IMAGE}") == $(awk '{print length($1)}' <<< "''${COMPOSE_IMAGE}") )); then
                read -p "Enter tag for \"''${COMPOSE_IMAGE}\": " TAG
                COMPOSE_IMAGE=''${COMPOSE_IMAGE}:''${TAG}
            fi

            docker pull ''${COMPOSE_IMAGE}

            if (( $? == 0 )); then
                local container_id=$(docker create ''${COMPOSE_IMAGE})
                docker cp $container_id:/data/ ''${WORKDIR}
                docker cp $container_id:/templates/ ''${WORKDIR}
                docker rm $container_id

                return
            fi

            echo "Fetching adapter image \"''${COMPOSE_IMAGE}\" failed."
        done

        do_exit
    }

    prepare_components() {
        # extract required components' images into ''${COMPONENT_FILE}
        jq '[ .Components[] |
            select(.Name == "registration-agent" or .Name == "pkcs11-proxy" or
            .Name == "certificate-setup" or .Name == "fog-navigation-lite" or
            .Name == "telem-nats" or .Name == "path-worker" or
            .Name == "swarm-agent" or .Name == "sec-udp-rev-proxy" or
            .Name == "nats-server-swarm" or .Name == "mocap-pose" or
            .Name == "ntrip-client") |
            {(.Name|tostring): .Artifacts[].ImageRef}] | add' ''${MANIFEST_FILE} >''${COMPONENT_FILE}

        REGISTRATION_IMAGE=$(grep "registration-agent" ''${COMPONENT_FILE} | awk '{print $2}' | tr -d '",')
    }

    prepare_common() {
        local container_id=$(docker create ghcr.io/tiiuae/fog-hyper:20240913_0624_141489ed)
        docker cp $container_id:/usr/bin/fog ''${WORKDIR}
        docker rm $container_id

        sudo ./fog debug secrets-pull

        sudo ./fog debug ejson decrypt-secrets.ejson | grep "\"ca_cert\"" | awk 'BEGIN{FS=": "} ; {print $2}' | tr -d "," | \
            xargs echo -e >''${WORKDIR}/devices/common/provisioning-ca.cert.pem

        sudo ./fog debug ejson decrypt-secrets.ejson | grep "\"ca_key\"" | awk 'BEGIN{FS=": "} ; {print $2}' | tr -d "," | \
            xargs echo -e >''${WORKDIR}/devices/common/provisioning-ca.key.pem

        sudo ./fog debug ejson decrypt-secrets.ejson | grep "\"root_ca_cert\"" | awk 'BEGIN{FS=": "} ; {print $2}' | \
            xargs echo -e >''${WORKDIR}/devices/common/root-ca.cert.pem
    }

    prepare_drones() {
        for cfg_file in ''${WORKDIR}/data/*_cfg.json; do
            local reply=""
            read -p "Do you want to add device configuration $(basename ''${cfg_file}) to adapter [Y/n]: " reply
            if [ "''${reply^^}" == "N" ]; then
                continue
            fi

            DRONES+=("''${cfg_file}")

            local device_alias=$(grep "device_alias" ''${cfg_file} | awk '{print $2}' | tr -d '",')
            local device_dir="''${WORKDIR}/devices/''${device_alias}"

            mkdir ''${device_dir}
            mkdir ''${device_dir}/cfg
            mkdir ''${device_dir}/cert
            mkdir -p ''${device_dir}/enclave/nats

            grep "provisioning_nats_url" ''${cfg_file} | awk '{print $2}' | tr -d '",' >''${device_dir}/cfg/service_nats_url.txt

            mustache --override ''${COMPONENT_FILE} ''${cfg_file} ''${WORKDIR}/templates/register-env.template >''${device_dir}/register-env.list
            mustache --override ''${COMPONENT_FILE} ''${cfg_file} ''${WORKDIR}/templates/compose.template >''${device_dir}/docker-compose.yaml
            mustache --override ''${COMPONENT_FILE} ''${cfg_file} ''${WORKDIR}/templates/certificate-setup.template >''${device_dir}/certificate-setup.json

            # Each drone requires own drone-nats-server but the configuration is same to all
            if [ ! -f ''${WORKDIR}/devices/common/nats-server.conf ]; then
                mustache ''${cfg_file} ''${WORKDIR}/templates/nats-server-conf.template >''${WORKDIR}/devices/common/nats-server.conf
            fi

            docker run --network host --rm --name registration-agent \
                --env-file ''${device_dir}/register-env.list --volume ''${device_dir}:/data \
                --user $(id -u ''${USER}):$(id -g ''${USER}) ''${REGISTRATION_IMAGE} provision

            docker run --network host --rm --name registration-agent \
                --env-file ''${device_dir}/register-env.list --volume ''${device_dir}:/data \
                --user $(id -u ''${USER}):$(id -g ''${USER}) ''${REGISTRATION_IMAGE} register

            if [ ! -f ''${device_dir}/device-registered.txt ]; then
                echo "Provisioning device \"''${device_alias}\" failed."
                do_exit
            fi

            local drone_device_id=$(grep "\"id\":" ''${device_dir}/device-registered.txt | awk '{print $2}' | tr -d '",')

            sed -i "s/xyzXYZxyz/''${drone_device_id}/g" ''${device_dir}/docker-compose.yaml
        done
    }

    read -p "Enter working folder [''${PWD}]: " WORKDIR
    WORKDIR="''${WORKDIR:-''${PWD}}"
    COMPONENT_FILE="''${WORKDIR}/data/components.json"
    MANIFEST_FILE="''${WORKDIR}/data/foghyper/fog_system/manifest.json"

    if [ ! -d ''${WORKDIR} ]; then
        mkdir -p ''${WORKDIR}
    fi

    mkdir ''${WORKDIR}/data
    mkdir ''${WORKDIR}/templates
    mkdir ''${WORKDIR}/devices
    mkdir ''${WORKDIR}/devices/common

    # docker_login
    # read_pin
    get_compose_image
    prepare_components
    prepare_common
    prepare_drones

    echo ''${PIN}
    echo ''${COMPOSE_IMAGE}

    ret=0
    do_exit
  '';
in {
  environment.systemPackages = [ orchestrate ];
}
