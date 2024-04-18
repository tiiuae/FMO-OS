# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  pkgs,
  lib,
  config,
  ...
}: let
  inherit (config.ghaf.graphics) sway;
in {
  config = {
    fonts.fonts = with pkgs;
      lib.lists.optionals sway.enable [
        font-awesome_5
        font-awesome
      ];
  };
}
