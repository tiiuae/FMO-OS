# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.services.fmo-dci-passthrough;

    dockerDevPassScript = pkgs.writeShellScriptBin "docker-dev-pass" ''
      CONTAINERNAME=swarm-server-pmc01-swarm-server-1

      echo "\n\n\nDevice connection rule has been triggered" >> /tmp/opkey.log

      if [ -n "$(${pkgs.docker}/bin/docker ps --quiet --filter name=$CONTAINERNAME)" ] && [ -n "$2" ] && [[ "$5" == 1050/* ]]; then
        echo "Container $CONTAINERNAME has been found" >> /tmp/opkey.log
        if [ "$1" == "plugged" ]; then
          echo "Device plugged $1 $2 $3 $4 $5" >> /tmp/opkey.log
          ${pkgs.docker}/bin/docker exec --user root $CONTAINERNAME mkdir -p $(dirname $2)
          ${pkgs.docker}/bin/docker exec --user root $CONTAINERNAME mknod $2 c $3 $4
          ${pkgs.docker}/bin/docker exec --user root $CONTAINERNAME chmod --recursive 777 $2
          ${pkgs.docker}/bin/docker exec --user root $CONTAINERNAME service pcscd restart
        else
          echo "Device unplugged $1 $2 $3 $4 $5" >> /tmp/opkey.log
          ${pkgs.docker}/bin/docke exec --user root $CONTAINERNAME rm -f $2
         fi
      else
        echo "Container $CONTAINERNAME has not been found" >> /tmp/opkey.log
        echo "Unknown error $1 $2 $3 $4 $5" >> /tmp/opkey.log
      fi
    '';
in {
  options.services.fmo-dci-passthrough = {
    enable = mkEnableOption "Docker Compose Infrastructure devices passthrough";

    compose-path = mkOption {
      type = types.str;
      description = "Path to docker-compose's .yml file";
    };
  };

  config = mkIf cfg.enable {
    services.udev = {
      extraRules = ''
        ACTION=="add", SUBSYSTEM=="usb", ATTRS{idVendor}=="1050", RUN+="${dockerDevPassScript}/bin/docker-dev-pass 'plugged' '%E{DEVNAME}' '%M' '%m' '%E{PRODUCT}'"
        ACTION=="remove", SUBSYSTEM=="usb", RUN+="${dockerDevPassScript}/bin/docker-dev-pass 'unplugged' '%E{DEVNAME}' '%M' '%m' '%E{PRODUCT}'"
      '';
    };
  };
}
