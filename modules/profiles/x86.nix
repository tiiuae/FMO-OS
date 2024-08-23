# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.ghaf.profiles.x86;
in
{
  options.ghaf.profiles.x86 = {
    enable = lib.mkEnableOption "Enable the basic x86 laptop config";
    vms = lib.mkOption {
      type = lib.types.attrs;
      default = {};
      description = ''
        Set of VM's configuration.
      '';
    };
    device-info = lib.mkOption {
      type = lib.types.attrs;
      default = {};
      description = ''
        Hardware information.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    ghaf = {
      hardware.x86_64.common.enable = true;
      host.networking.enable = true;

      profiles.applications.enable = true;

      virtualization= {
        microvm-host.enable = true;
        microvm-host.networkSupport = true;
      }
      // builtins.foldl' lib.recursiveUpdate {}
        (map (vm: let
            vm-device = if builtins.hasAttr "hardware" cfg.vms."${vm}"
              then [{
                microvm.devices = (
                  builtins.map (d: {
                    bus = "pci";
                    inherit (d) path;
                  }) cfg.device-info."${cfg.vms."${vm}".hardware}".pciDevices
                );} ]
              else [];
          in {
            microvm.${cfg.vms."${vm}".name} = {
              enable = true;
              extraModules =
                cfg.vms."${vm}".extraModules ++ vm-device ;
            };
        }) (builtins.attrNames cfg.vms));
    };
  };
}
