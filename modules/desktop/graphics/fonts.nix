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
  config = {
    fonts.packages = with pkgs;
      lib.lists.optionals sway.enable [
        font-awesome_5
        font-awesome
        hack-font
      ];
  };
}
