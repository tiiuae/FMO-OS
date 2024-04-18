# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  lib,
  pkgs,
  config,
  ...
}:
with lib; let
  cfg = config.services.fmo-hostname-service;
in {
  options.services.fmo-hostname-service = {
    enable = mkEnableOption "hostname-service";

    hostname-path = mkOption {
      type = types.str;
      description = "Path to hostname file";
    };
  };

  config = mkIf cfg.enable {
    systemd.services.fmo-hostname-service = {
      script = ''
        HNAME=$(${pkgs.gawk}/bin/gawk '{print $1}' ${cfg.hostname-path})

        echo "Apply a new hostname: {$HNAME}"

        ${pkgs.nettools}/bin/hostname $HNAME
      '';

      wantedBy = ["network.target"];
    };
  };
}
