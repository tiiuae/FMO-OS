# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
#
{
  self,
  lib,
  ghafOS,
  nixos-generators,
  nixpkgs,
}: {sysconf}: let
  inherit ((import ./utils/updateAttrs.nix)) updateAttrs;

  inherit (sysconf) oss;
  oss_list_name = "installer_os_list";
  oss_list_path = "/etc/${oss_list_name}";

  installerconf =
    if lib.hasAttr "extend" sysconf
    then updateAttrs false (import (lib.path.append ./installers sysconf.extend)).sysconf sysconf
    else sysconf;

  installerApp = inst_app: let
    installers =
      (builtins.removeAttrs inst_app ["name"])
      // {oss_path = lib.mkDefault "${oss_list_path}";};
  in
    installers;

  addSystemPackages = {pkgs, ...}: {environment.systemPackages = map (app: pkgs.${app}) installerconf.systemPackages;};

  formatModule = nixos-generators.nixosModules.iso;
  installer = variant: extraModules: let
    system = "x86_64-linux";

    installerImgCfg = lib.nixosSystem {
      inherit system;
      specialArgs = {
        inherit lib;
        inherit ghafOS;
      };
      modules =
        [
          (import "${ghafOS}/modules/host")
          ({
            modulesPath,
            config,
            ...
          }: {
            imports = [(modulesPath + "/profiles/all-hardware.nix")];

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
              systems =
                map (os: rec {
                  name = "${os}-${variant}";
                  image = self.nixosConfigurations.${name};
                })
                oss;
            };
          }

          {
            installer.${installerconf.installer.name} = installerApp installerconf.installer;
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
        ++ (
          if lib.hasAttr "extraModules" installerconf
          then installerconf.extraModules
          else []
        );
    };
  in {
    name = "${installerconf.name}-${variant}";
    inherit installerImgCfg system;
    installerImgDrv = installerImgCfg.config.system.build.${installerImgCfg.config.formatAttr};
  };
  debugModules = [(import "${ghafOS}/modules/development/usb-serial.nix") {ghaf.development.usb-serial.enable = true;}];
  targets = [
    (installer "debug" debugModules)
    (installer "release" [])
  ];
in {
  packages = lib.foldr lib.recursiveUpdate {} (map ({
      name,
      system,
      installerImgDrv,
      ...
    }: {
      ${system}.${name} = installerImgDrv;
    })
    targets);
}
