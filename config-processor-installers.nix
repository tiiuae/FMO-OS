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
  oss = sysconf.oss;
  oss_list_name = "installer_os_list";
  oss_list_path = "/etc/${oss_list_name}";

  installerApp = inst_app: let
    installers = (builtins.removeAttrs inst_app ["name"]) //
                { oss_path = lib.mkDefault "${oss_list_path}"; };
  in installers;
  
  addSystemPackages = {pkgs, ...}: {environment.systemPackages = map (app: pkgs.${app}) sysconf.systemPackages;};

  formatModule = nixos-generators.nixosModules.iso;
  installer = variant: extraModules: let
    system = "x86_64-linux";

    pkgs = import nixpkgs {inherit system;};

    installerImgCfg = lib.nixosSystem {
      inherit system;
      specialArgs = {inherit lib; inherit ghafOS;};
      modules =
        [
          (import "${ghafOS}/modules/host")
          ({modulesPath, lib, config, ...}: {
            imports = [ (modulesPath + "/profiles/all-hardware.nix") ];

            nixpkgs.hostPlatform.system = system;
            nixpkgs.config.allowUnfree = true;

            hardware.enableAllFirmware = true;

            ghaf = {
              profiles.installer.enable = true;
            };
          })

          {
            installer.includeOSS = {
              enable = lib.mkDefault true;
              oss_list_fname = lib.mkDefault "${oss_list_name}";
              systems = map (os: rec {
                name = "${os}-${variant}";
                image = self.nixosConfigurations.${name};}) oss;
            };
          }

          {
            installer.${sysconf.installer.name} = installerApp sysconf.installer;
          }

          formatModule
          addSystemPackages

          {
            isoImage.squashfsCompression = "lz4"; 
          }
        ]
        ++ (import ./modules/fmo-module-list.nix)
        ++ (import "${ghafOS}/modules/module-list.nix")
        ++ extraModules
        ++ (if lib.hasAttr "extraModules" sysconf then sysconf.extraModules else []);
    };
  in {
    name = "${sysconf.name}-${variant}";
    inherit installerImgCfg system;
    installerImgDrv = installerImgCfg.config.system.build.${installerImgCfg.config.formatAttr};
  };
  debugModules = [(import "${ghafOS}/modules/development/usb-serial.nix") {ghaf.development.usb-serial.enable = true;}];
  targets = [
    (installer "debug" debugModules)
    (installer "release" [])
  ];
in {
  packages = lib.foldr lib.recursiveUpdate {} (map ({name, system, installerImgDrv, ...}: {
    ${system}.${name} = installerImgDrv;
  }) targets);
}
