# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
#
{
  self,
  lib,
  ghafOS,
}: sysconf:
let
  inherit (import ./utils {inherit lib self ghafOS;}) 
      updateAttrs updateHostConfig addHardwareInfo addCustomLaunchers addSystemPackages importvm generateFMOToolConfig;

  targetconf = sysconf;
  name = targetconf.name;
  system = "x86_64-linux";

  target = variant: let
    hostConfiguration = lib.nixosSystem {
      inherit system;
      specialArgs = {inherit lib; inherit ghafOS;};
      modules =
        [
          ghafOS.inputs.nixos-generators.nixosModules.raw-efi
          self.nixosModules.fmo-common
          self.nixosModules.fmo-host
          self.nixosModules.microvm
          {
            ghaf = {
              # Enable all the default UI applications
              profiles = {
                x86 = {
                  enable = true;
                  vms = targetconf.vms;
                };
                #TODO clean this up when the microvm is updated to latest
                release.enable = variant == "release";
                debug.enable = variant == "debug";
              };
            };
            boot.kernelParams = [
              "intel_iommu=on,igfx_off,sm_on"
              "iommu=pt"
            ];
          }
        ]
        ++ (addCustomLaunchers    targetconf.launchers)
        ++ (addSystemPackages     targetconf.systemPackages)
        ++ (importvm              targetconf.vms)
        ++ (updateHostConfig      targetconf)
        ++ (generateFMOToolConfig targetconf)
        ++ (if lib.hasAttr "device-info" targetconf then addHardwareInfo (import targetconf.device-info) else [])
        ++ (if lib.hasAttr "extraModules" targetconf then targetconf.extraModules else []);
    };
  in {
    inherit hostConfiguration;
    name = "${name}-${variant}";
    package = hostConfiguration.config.system.build.${hostConfiguration.config.formatAttr};
  };
  targets = [
    (target "debug")
    (target "release")
  ];
in {
  flake = {
    nixosConfigurations =
      builtins.listToAttrs (map (t: lib.nameValuePair t.name t.hostConfiguration) targets);
    packages.${system} =
      builtins.listToAttrs (map (t: lib.nameValuePair t.name t.package) targets);
  };
}
