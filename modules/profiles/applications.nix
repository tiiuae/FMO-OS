# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
#
{
  config,
  lib,
  ...
}: let
  cfg = config.ghaf.profiles.applications;
  compositors = ["weston" "sway"];
in
  with lib; {
    options.ghaf.profiles.applications = {
      compositor = mkOption {
        type = types.enum compositors;
        default = "sway";
        description = ''
          Which Wayland compositor to use.

          Choose one of: ${lib.concatStringsSep "," compositors}
        '';
      };
    };

    config.ghaf.graphics = mkIf cfg.enable {
      weston.enable = lib.mkDefault (cfg.compositor == "weston");
      sway.enable = cfg.compositor == "sway";
      app-launchers.enableAppLaunchers = true;
    };
  }
