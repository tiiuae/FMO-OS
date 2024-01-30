# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.services.fmo-dci;
  preload_path = ./images;
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
   preloaded-images = mkOption {
      type = types.str;
      description = "Preloaded docker images file names separated by spaces";
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
        DCPATH=$(echo ${cfg.compose-path} )
        PRELOAD_PATH=$(echo ${preload_path})

        echo "Login ghcr.io"
        echo $PAT | ${pkgs.docker}/bin/docker login ghcr.io -u $USR --password-stdin || echo "login to ghcr.io failed continue as is"

        echo "Load preloaded docker images"
        for FNAME in ${cfg.preloaded-images}; do
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
