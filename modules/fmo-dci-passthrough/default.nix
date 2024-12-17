# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.services.fmo-dci-passthrough;
in {
  options.services.fmo-dci-passthrough = {
    enable = mkEnableOption "Docker Compose Infrastructure devices passthrough";

    compose-path = mkOption {
      type = types.str;
      description = "Path to docker-compose's .yml file";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      docker-compose
    ];

    dockerDevPassScript = pkgs.writeShellScriptBin "docker-dev-pass" ''
      CONTAINERNAME=swarm-server-pmc01-swarm-server-1 if [ -n "$(docker ps --quiet --filter name=$CONTAINERNAME)" ] && [ -n "$2" ] && [[ "$5" == 1050/* ]]; then
      if [ "$1" == "plugged" ]; then
        echo "$1 $2 $3 $4 $5" >> /tmp/opkey.log
        docker exec --user root $CONTAINERNAME mkdir -p $(dirname $2)
        docker exec --user root $CONTAINERNAME mknod $2 c $3 $4
        docker exec --user root $CONTAINERNAME chmod --recursive 777 $2
        docker exec --user root $CONTAINERNAME service pcscd restart
      else
        echo "$1 $2 $3 $4 $5" >> /tmp/opkey.log
        docker exec --user root $CONTAINERNAME rm -f $2
       fi
     fi
    '';

    udev = {
      extraRules = ''
        ACTION=="add", SUBSYSTEM=="usb", ATTRS{idVendor}=="1050", RUN+="/usr/local/bin/operation-yubikey.sh 'plugged' '%E{DEVNAME}' '%M' '%m' '%E{PRODUCT}'"
        ACTION=="remove", SUBSYSTEM=="usb", RUN+="/usr/local/bin/operation-yubikey.sh 'unplugged' '%E{DEVNAME}' '%M' '%m' '%E{PRODUCT}'"
      '';
    };

    systemd.services.fmo-dci-passthrough = {
    script = ''
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
