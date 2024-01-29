# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
#
{
  self,
  lib,
  ghafOS,
  nixos-generators,
  nixos-hardware,
  nixpkgs,
  microvm,
}: {
  sysconf,
}:
let
  name = sysconf.name;
  system = "x86_64-linux";
  vms = sysconf.vms;

  importvm = vmconf: (import ./modules/virtualization/microvm/vm.nix {inherit ghafOS vmconf;});
  enablevm = vm: {
    virtualization.microvm.${vm.name} = {
      enable = true;
      extraModules = vm.extraModules;
    };
  };
  addSystemPackages = {pkgs, ...}: {environment.systemPackages = map (app: pkgs.${app}) sysconf.systemPackages;};
  addCustomLaunchers = (import ./utils/launchers.nix {inherit sysconf;});

  formatModule = nixos-generators.nixosModules.raw-efi;
  target = variant: extraModules: let
    hostConfiguration = lib.nixosSystem {
      inherit system;
      specialArgs = {inherit lib; inherit ghafOS;};
      modules =
        [
          microvm.nixosModules.host
          (import "${ghafOS}/modules/host")
          (import "${ghafOS}/modules/virtualization/microvm/microvm-host.nix")
          {
            ghaf = lib.mkMerge (
              [
                {
                  hardware.x86_64.common.enable = true;

                  virtualization.microvm-host.enable = true;
                  host.networking.enable = true;

                  # Enable all the default UI applications
                  profiles = {
                    applications.enable = true;
                    #TODO clean this up when the microvm is updated to latest
                    release.enable = variant == "release";
                    debug.enable = variant == "debug";
                  };
                }
              ]
              ++ map (vm: enablevm vms.${vm}) (builtins.attrNames vms)
            );
          }

          addCustomLaunchers
          addSystemPackages
          formatModule

          {
            boot.kernelParams = [
              "intel_iommu=on,igx_off,sm_on"
              "iommu=pt"
            ];
          }
        ]
        ++ map (vm: importvm vms.${vm}) (builtins.attrNames vms)
        ++ (import "${ghafOS}/modules/module-list.nix")
        ++ (import ./modules/fmo-module-list.nix)
        ++ extraModules
        ++ (if lib.hasAttr "extraModules" sysconf then sysconf.extraModules else []);
    };
  in {
    inherit hostConfiguration;
    name = "${name}-${variant}";
    package = hostConfiguration.config.system.build.${hostConfiguration.config.formatAttr};
  };
  debugModules = [(import "${ghafOS}/modules/development/usb-serial.nix") {ghaf.development.usb-serial.enable = true;}];
  targets = [
    (target "debug" debugModules)
    (target "release" [])
  ];
in {
  nixosConfigurations =
    builtins.listToAttrs (map (t: lib.nameValuePair t.name t.hostConfiguration) targets);
  packages = {
    x86_64-linux =
      builtins.listToAttrs (map (t: lib.nameValuePair t.name t.package) targets);
  };
}
