# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.ghaf.graphics.sway;
  map-touch-devices = pkgs.writeShellScriptBin "map-touch-devices" ''
    #${pkgs.bash}/bin/bash
    while [ ! -f ${config.device.hardwareInfo.skuFile} ]; do
      :
    done
    system_sku=$(cat ${config.device.hardwareInfo.skuFile})
    devices=$(echo '${config.device.hardwareInfo.configJson}' | ${pkgs.jq}/bin/jq -r --arg sku "$system_sku" '.[$sku].touchDevices.[]')
    for device in $devices; do
      swaymsg "input $device map_to_output eDP-1"
    done
  '';

  swayConfig = pkgs.writeTextFile {
    name = "generated-sway-config";
    destination = "/config";
    text = ''
      ${lib.optionalString (cfg.extraConfig != null) cfg.extraConfig}

      # Default wallpaper
      output * bg ${../assets/wallpaper.jpg} fill

      ${builtins.readFile ./config}
      exec ${map-touch-devices}/bin/map-touch-devices
    '';
  };
in {
  imports = [
    ./nwg-panel
  ];

  config = lib.mkIf cfg.enable {

    users.users."ghaf".extraGroups = ["input"];
    environment.systemPackages = [
        pkgs.lisgd
      ];

    services.writeToFile = {
      enable = true;
      enabledFiles = [ "config-folder" "sway-config" ];
      file-info = {
        config-folder = {
          des-path = "${config.users.users.ghaf.home}/.config";
          write-once = true;
          owner = config.ghaf.users.accounts.user;
        };
        sway-config = {
          source = "${swayConfig}/config";
          des-path = "${config.users.users.ghaf.home}/.config/sway";
          write-once = true;
          owner = config.ghaf.users.accounts.user;
          permission = "664";
        };
      };
    };

  };
}
