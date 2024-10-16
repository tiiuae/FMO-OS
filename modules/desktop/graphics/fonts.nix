# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  pkgs,
  lib,
  config,
  ...
}: let
  sway = config.ghaf.graphics.sway;
in {
  config = lib.mkIf sway.enable {
    fonts.packages = with pkgs; [
      # Font Awesome are web icon fonts
      font-awesome # Version 6
      font-awesome_5 # Version 5

      hack-font

      (nerdfonts.override {
        fonts = [
          #"Hack"
          "JetBrainsMono"
          "RobotoMono"
        ];
      })
    ];
    fonts.fontconfig.enable = true;
  };
}
