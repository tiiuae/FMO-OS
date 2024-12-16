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
