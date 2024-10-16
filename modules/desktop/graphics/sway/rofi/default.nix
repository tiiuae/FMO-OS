# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  pkgs,
  lib,
  config,
  ...
}:
with lib; let
  cfg = config.ghaf.graphics.sway;
in {
  config = lib.mkIf cfg.enable {
    environment.etc."rofi/config.rasi" = {
      source = ./config.rasi;
      mode = "0644";
    };
    environment.etc."rofi/theme.rasi" = {
      source = ./theme.rasi;
      mode = "0644";
    };
    environment.etc."rofi/menu.rasi" = {
      source = ./menu.rasi;
      mode = "0644";
    };
    environment.etc."rofi/dmenu.rasi" = {
      source = ./dmenu.rasi;
      mode = "0644";
    };
  };
}
