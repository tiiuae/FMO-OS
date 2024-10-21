# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.services.fmo-hostname-service;
in {
  options.services.fmo-hostname-service = {
    enable = mkEnableOption "hostname-service";

    hostname-override = mkOption {
      type = types.str;
      default = "";
      description = "Given hostname used instead of one from file";
    };

    hostname-path = mkOption {
      type = types.str;
      default = "";
      description = "Path to hostname file";
    };
  };

  config = mkIf cfg.enable {
    systemd.services.fmo-hostname-service = {
      script = ''
        HNAME=""

        if [ "${cfg.hostname-override}x" == "x"]; then
          HNAME=$(${pkgs.gawk}/bin/gawk '{print $1}' ${cfg.hostname-path})
        else
          HNAME="${cfg.hostname-override}"
        fi

        echo "Apply a new hostname: {$HNAME}"

        ${pkgs.nettools}/bin/hostname $HNAME
      '';

      wantedBy = ["network.target"];
    };
  };
}
