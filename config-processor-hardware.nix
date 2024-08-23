# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
#
{
  self,
  lib,
  ghafOS,
}:
let
  inherit (import ./utils {inherit lib self ghafOS;}) updateAttrs updateHostConfig addCustomLaunchers addSystemPackages importvm;

  builder = sysconf: device: variant: let
    name = device.name + (if lib.hasAttr "suffix" sysconf then "-${sysconf.suffix}" else "");
    targetconf = if lib.hasAttr "extend" sysconf
               then updateAttrs false (import (lib.path.append ./hardware sysconf.extend) ).sysconf sysconf
               else sysconf;

    system = "x86_64-linux";

    hostConfiguration = lib.nixosSystem {
      inherit system;
      specialArgs = {inherit lib; inherit ghafOS;};
      modules =
        [
          ghafOS.inputs.nixos-generators.nixosModules.raw-efi
          self.nixosModules.host-configs
          self.nixosModules.microvm
          self.nixosModules.fmo-common
          {
            ghaf = {
              # Enable all the default UI applications
              profiles = {
                x86 = {
                  enable = true;
                  vms = targetconf.vms;
                  device-info = device;
                };
                #TODO clean this up when the microvm is updated to latest
                release.enable = variant == "release";
                debug.enable = variant == "debug";
              };
            };
            boot.kernelParams = [
              "intel_iommu=on,igx_off,sm_on"
              "iommu=pt"
            ];
          }
        ]
        ++ (addCustomLaunchers targetconf.launchers)
        ++ (addSystemPackages targetconf.systemPackages)
        ++ (importvm targetconf.vms)
        ++ (updateHostConfig targetconf)
        ++ (if lib.hasAttr "extraModules" targetconf then targetconf.extraModules else []);
    };
  in {
    inherit hostConfiguration;
    name = "${name}-${variant}";
    package = hostConfiguration.config.system.build.${hostConfiguration.config.formatAttr};
  };
in
  builder
