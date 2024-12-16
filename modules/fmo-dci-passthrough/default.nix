# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.services.fmo-dci-passthrough;

    dockerDevPassScript = pkgs.writeShellScriptBin "docker-dev-pass" ''
      CONTAINERNAME="${cfg.container-name}"

      set -x

      echo "Device connection rule has been triggered" >> /tmp/opkey.log
      echo "$0 $1 $2 $3 $4 $5" >> /tmp/opkey.log

      if [ -z "$(${pkgs.docker}/bin/docker ps --quiet --filter name=$CONTAINERNAME)" ]; then
        echo "Container $CONTAINERNAME has not been found. Exit.." >> /tmp/opkey.log
        exit 0
      fi

      if [ -z "$2" ]; then
        echo "Device path has not been provided. Exit.." >> /tmp/opkey.log
        exit 0
      fi

      if [[ ! "$5" == ${cfg.vendor-id}/* ]]; then
        echo "Wrong vendorID, expected: '${cfg.vendor-id}', got: '$5'. Exit.." >> /tmp/opkey.log
        exit 0
      fi

      if [ "$1" == "plugged" ]; then
        echo "Device plugged.." >> /tmp/opkey.log
        ${pkgs.docker}/bin/docker exec --user root $CONTAINERNAME mkdir -p $(dirname $2)
        ${pkgs.docker}/bin/docker exec --user root $CONTAINERNAME mknod $2 c $3 $4
        ${pkgs.docker}/bin/docker exec --user root $CONTAINERNAME chmod --recursive 777 $2
        ${pkgs.docker}/bin/docker exec --user root $CONTAINERNAME service pcscd restart
      else
        echo "Device unplugged.." >> /tmp/opkey.log
        ${pkgs.docker}/bin/docker exec --user root $CONTAINERNAME rm -f $2
        ${pkgs.docker}/bin/docker exec --user root $CONTAINERNAME service pcscd restart
       fi
    '';
in {
  options.services.fmo-dci-passthrough = {
    enable = mkEnableOption
    ''Docker Compose Infrastructure devices passthrough
      Docker container must be run with cgroup allow rules:
      - docker run --device-cgroup-rule='c $Maj:$min rmw'
      - docker-compose:
        device_cgroup_rules:
          - "c $Maj:$min rmw"
    '';

    compose-path = mkOption {
      type = types.str;
      description = "Path to docker-compose's .yml file";
    };

    container-name = mkOption {
      type = types.str;
      description = "Container name to inject a usb device";
    };

    vendor-id = mkOption {
      type = types.str;
      description = "Vendor id to passthrough";
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
