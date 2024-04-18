# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.ghaf.graphics.sway;
  sway_config = pkgs.substituteAll {
    dir = "share";
    isExecutable = false;
    pname = "config";
    src = ./config;
    wallpaper = "${../assets/wallpaper.jpg}";
  };
in {
  imports = [
    ./lisgd
    ./nwg-panel
  ];

  config = lib.mkIf cfg.enable {
    services.writeToFile = {
      enable = true;
      enabledFiles = ["config-folder" "sway-config"];
      file-info = {
        config-folder = {
          des-path = "${config.users.users.ghaf.home}/.config";
          write-once = true;
          owner = config.ghaf.users.accounts.user;
        };
        sway-config = {
          source = "${sway_config}/share/config";
          des-path = "${config.users.users.ghaf.home}/.config/sway";
          write-once = true;
          owner = config.ghaf.users.accounts.user;
          permission = "664";
        };
      };
    };
  };
}
