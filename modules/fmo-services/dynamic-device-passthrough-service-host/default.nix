# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.services.fmo-dynamic-device-passthrough-service-host;
in {
  options.services.fmo-dynamic-device-passthrough-service-host = {
    enable = mkEnableOption "FMO dynamic device passthrough service";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.vhotplug ];

    services.udev.extraRules = ''
      SUBSYSTEM=="usb", GROUP="kvm"
      KERNEL=="event*", GROUP="kvm"
    '';

    systemd.services."fmo-dynamic-device-passthrough-service" = {
      script = ''
        if ! [ -f /var/host/vmddp.conf ]; then
          ${pkgs.fmo-tool}/bin/fmo-tool ddp generate
        fi
        ${pkgs.vhotplug}/bin/vhotplug -a -c /var/host/vmddp.conf
      '';
      serviceConfig = {
        Type = "simple";
        RemainAfterExit = true;
      };
      wantedBy = [ "multi-user.target" ];
    };
  };
}
