# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.services.fmo-dci;
in {
  options.services.fmo-dci = {
    enable = mkEnableOption "Docker Compose Infrastructure service";

    pat-path = mkOption {
      type = types.str;
      description = "Path to PAT .pat file";
    };
    compose-path = mkOption {
      type = types.str;
      description = "Path to docker-compose's .yml file";
    };
    update-path = mkOption {
      type = types.str;
      description = "Path to docker-compose's .yml file for update";
    };
    backup-path = mkOption {
      type = types.str;
      description = "Path to docker-compose's .yml file for backup";
    };
    preloaded-images = mkOption {
      type = types.str;
      description = "Preloaded docker images file names separated by spaces";
    };
    preloaded-list = mkOption {
      type = types.str;
      description = "Preloaded docker images container.list path";
    };
    preloaded-path = mkOption {
      type = types.str;
      description = "Preloaded docker images path";
    };
    preloaded-docker-compose = mkOption {
      type = types.str;
      description = "Preloaded docker-compose path";
    };
    preloaded-docker-compose-path = mkOption {
      type = types.str;
      description = "Preloaded docker-compose path";
    };
    docker-url = mkOption {
      type = types.str;
      default = "";
      description = "Default container repository URL to use";
    };
    docker-url-path = mkOption {
      type = types.str;
      default = "";
      description = "Path to docker url file";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      docker-compose
    ];

    virtualisation.docker.enable = true;

    systemd.services.fmo-dci = {
    script = ''
        USR=$(${pkgs.gawk}/bin/gawk '{print $1}' ${cfg.pat-path} || echo "")
        PAT=$(${pkgs.gawk}/bin/gawk '{print $2}' ${cfg.pat-path} || echo "")
        DCPATH=$(echo ${cfg.compose-path})
        UPDPATH=$(echo ${cfg.update-path})
        BCPPATH=$(echo ${cfg.backup-path})
        PRELOAD_PATH=$(echo ${cfg.preloaded-path})
        ROOT="/var/lib/fogdata"


        # Process docker-compose with sed
        # Read file contents into variables
        device_id_file_contents=$(cat $ROOT/certs/device_id.txt)
        ip_address=$(cat $ROOT/ip-address)
        hostname=$(cat $ROOT/hostname)

        # Extract 'id' from the JSON device_id_file_contents using jq (JSON parser)
        device_id=$(echo "$device_id_file_contents" | ${pkgs.jq}/bin/jq -r '.id')

        # Define the template parameters as shell variables
        leaf_config="$ROOT/certs/leaf.conf"
        utm_secret_file="$ROOT/certs/utm-client-secret"
        rabbit_mq_secret_file="$ROOT/certs/rabbit-mq-secret"

        # Perform replacements on the template file
        ${pkgs.gnused}/bin/sed -e "s|{{device-id}}|$device_id|g" \
            -e "s|{{ip-address}}|$ip_address|g" \
            -e "s|{{hostname}}|$hostname|g" \
            -e "s|{{leaf-config}}|$leaf_config|g" \
            -e "s|{{utm-secret-file}}|$utm_secret_file|g" \
            -e "s|{{rabbit-mq-secret-file}}|$rabbit_mq_secret_file|g" \
            ${cfg.preloaded-docker-compose} > ${cfg.preloaded-docker-compose-path}/docker-compose-new.yaml

        # Perform replacements on the template file
        ${pkgs.gnused}/bin/sed -e "s|{{device-id}}|$device_id|g" \
            -e "s|{{ip-address}}|$ip_address|g" \
            -e "s|{{hostname}}|$hostname|g" \
            -e "s|{{leaf-config}}|$leaf_config|g" \
            -e "s|{{utm-secret-file}}|$utm_secret_file|g" \
            -e "s|{{rabbit-mq-secret-file}}|$rabbit_mq_secret_file|g" \
            ${cfg.preloaded-docker-compose-path}/leaf.conf > ${cfg.preloaded-docker-compose-path}/leaf-new.conf


        # Check if the update file exists
        if [ -e "$UPDPATH" ]; then
            echo "Update file exists. Proceeding with backup and update operations"

            # Backup the original file if it exists
            if [ -e "$DCPATH" ]; then
                echo "Backing up the original file"
                mv "$DCPATH" "$BCPPATH"
            else
                echo "No original file to backup"
            fi

            # Move the new file to replace the original file
            mv "$UPDPATH" "$DCPATH"
            echo "Move completed successfully"
        else
            echo "Update file does not exist. No operations performed"
        fi

        # Check if the docker-compose file exists
        if [ -e "$DCPATH" ]; then
          echo "docker-compose exist -- skip"
        else
          cp ${cfg.preloaded-docker-compose-path}/docker-compose-new.yaml $DCPATH
        fi

        # Check if the leaf.conf file exists
        LPATH="/var/lib/fogdata/certs/leaf.conf"
        if [ -e "$LPATH" ]; then
          echo "leaf.conf exist -- skip"
        else
          cp ${cfg.preloaded-docker-compose-path}/leaf-new.conf $LPATH
        fi

        echo "Load preloaded docker images"
        IMGLIST=$(cat ${cfg.preloaded-list})
        for FNAME in $IMGLIST; do
          IM_NAME=''${FNAME%%.*}

          if test -f "$PRELOAD_PATH/$FNAME"; then
            echo "Preloaded image $FNAME exists"

            if ${pkgs.docker}/bin/docker images | grep $IM_NAME; then
              echo "Image already loaded to docker, skip..."
            else
              echo "There is no such image in docker, load $PRELOAD_PATH/$FNAME..."
              ${pkgs.docker}/bin/docker load < $PRELOAD_PATH/$FNAME || echo "Preload image $PRELOAD_PATH/$FNAME failed continue"
            fi
          else
            echo "Preloaded image $IM_NAME does not exist, skip..."
          fi
        done

        echo "Start docker-compose"
        ${pkgs.docker-compose}/bin/docker-compose -f $DCPATH up
      '';

      wantedBy = ["multi-user.target"];
      # If you use podman
      # after = ["podman.service" "podman.socket"];
      # If you use docker
      after = [
        "docker.service"
        "docker.socket"
        "network-online.target"
      ];

      # TODO: restart always
      serviceConfig = {
        Restart = lib.mkForce "always";
        RestartSec = "30";
      };
    };
  };
}
