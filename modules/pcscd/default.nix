# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{ lib, config, ... }:
with lib;
let
  cfg = config.services.pcscd;
in {
  config = mkIf cfg.enable {
    systemd.services."pcscd" = {
      serviceConfig.Restart = "always";
      wantedBy = [ "multi-user.target" ];
    };
  };
}
