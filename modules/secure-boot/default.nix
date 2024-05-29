# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
#
# fmo's integration to lanzaboote
{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.ghaf.host.secureboot;
in {
  options.ghaf.host.secureboot = {
    enable = lib.mkEnableOption "Host secureboot";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
        # For debugging and troubleshooting Secure Boot.
        pkgs.sbctl
      ];

    # Disable systemd-boot because Lanzaboote has its own configuration for boot.
    boot = {
      loader = {
        systemd-boot.enable = lib.mkForce false;
        efi.canTouchEfiVariables = lib.mkForce false;
      };

      lanzaboote = {
        enable = true;
        publicKeyFile = "${./demo-keys/db.pem}";
        privateKeyFile = "${./demo-keys/db.key}";
      };
    };
  };
}
