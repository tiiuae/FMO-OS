# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.ghaf.hardware.usb.vhotplug;
  inherit (lib) mkEnableOption mkOption types mkIf literalExpression;

in {
  options.ghaf.hardware.usb.vhotplug = {
    enable = mkEnableOption "Enable hot plugging of USB devices";
    passthroughConfigPath = lib.mkOption {
      description = ''
        List of additional modules to be imported and evaluated as part of
        VM's NixOS configuration.
      '';
      default = "/var/microvm/vhotplug.conf";
    };
    rules = mkOption {
      type = types.listOf types.attrs;
      default = [];
      description = "List of virtual machines with USB hot plugging rules.";
      example = literalExpression ''
        [
         {
            name = "netvm";
            qmpSocket = "/var/lib/microvms/netvm/netvm.sock";
            usbPassthrough = [
              {
                class = 3;
                protocol = 1;
                description = "HID Keyboard";
                ignore = [
                  {
                    vendorId = "046d";
                    productId = "c52b";
                    description = "Logitech, Inc. Unifying Receiver";
                  }
                ];
              }
              {
                vendorId = "067b";
                productId = "23a3";
                description = "Prolific Technology, Inc. USB-Serial Controller";
                disable = true;
              }
              {
                vendorId = "090c";
                productId = "1000";
                description = "USB Storage";
                disable = true;
              }
            ];
          }
        ];
      '';
    };
  };

  config = mkIf cfg.enable {
    services.udev.extraRules = ''
      SUBSYSTEM=="usb", GROUP="kvm"
      KERNEL=="event*", GROUP="kvm"
    '';

    systemd.services.vhotplug = {
      enable = true;
      description = "vhotplug";
      wantedBy = ["microvms.target"];
      script = let
          vhotplugconf=(pkgs.formats.json {}).generate "vhotplug.conf" {vms = cfg.rules;};
        in
        ''
          ${pkgs.coreutils-full}/bin/mkdir -p $(dirname ${cfg.passthroughConfigPath})
          ${pkgs.rsync}/bin/rsync -a -v --ignore-existing ${vhotplugconf} ${cfg.passthroughConfigPath}
          ${pkgs.vhotplug}/bin/vhotplug -a -c ${cfg.passthroughConfigPath}
        '';
      serviceConfig = {
        Type = "simple";
        Restart = "always";
        RestartSec = "1";
      };
      startLimitIntervalSec = 0;
    };
  };
}
