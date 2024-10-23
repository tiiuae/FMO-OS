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
}: sysconf:
let

  oss = sysconf.oss;
  oss_list_name = "installer_os_list";
  oss_list_path = "/etc/${oss_list_name}";

  installerconf = sysconf;

  installerApp = inst_app: let
    installers = (builtins.removeAttrs inst_app ["name"]) //
                { oss_path = lib.mkDefault "${oss_list_path}"; };
  in installers;
  
  addSystemPackages = {pkgs, ...}: {environment.systemPackages = map (app: pkgs.${app}) installerconf.systemPackages;};

  formatModule = nixos-generators.nixosModules.iso;
  installer = variant: extraModules: compressed: let
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

          ({lib, ...}: {
            installer.includeOSS = {
              enable = lib.mkDefault true;
              oss_list_fname = lib.mkDefault "${oss_list_name}";
              systems = map (os: rec {
                name = "${os}-${variant}";
                image = self.nixosConfigurations.${name};}) oss;
            };
            services.registration-agent-laptop.createAllConfig = lib.mkForce false;
          })
          {
            installer.${installerconf.installer.name} = installerApp installerconf.installer;
          }

          formatModule
          addSystemPackages

          {
            isoImage.squashfsCompression = if compressed=="compressed" then "zstd" else "lz4";
          }
        ]
        ++ (import ./modules/fmo-module-list.nix)
        ++ (import "${ghafOS}/modules/module-list.nix")
        ++ extraModules
        ++ (if lib.hasAttr "extraModules" installerconf then installerconf.extraModules else []);
    };
  in {
    name = if compressed == "compressed"
          then "${installerconf.name}-${variant}-compressed"
          else "${installerconf.name}-${variant}";
    inherit installerImgCfg system;
    installerImgDrv = installerImgCfg.config.system.build.${installerImgCfg.config.formatAttr};
  };
  debugModules = [(import "${ghafOS}/modules/development/usb-serial.nix") {ghaf.development.usb-serial.enable = true;}];
  targets = [
    (installer "debug" debugModules "")
    (installer "release" [] "")
    (installer "debug" debugModules "compressed")
    (installer "release" [] "compressed")
  ];
in {
  packages = lib.foldr lib.recursiveUpdate {} (map ({name, system, installerImgDrv, ...}: {
    ${system}.${name} = installerImgDrv;
  }) targets);
}
