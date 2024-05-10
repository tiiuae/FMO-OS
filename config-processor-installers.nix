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
  updateAttrs = (import ./utils/updateAttrs.nix).updateAttrs;

  oss = sysconf.oss;
  oss_list_name = "installer_os_list";
  oss_list_path = "/etc/${oss_list_name}";

  installerconf = if lib.hasAttr "extend" sysconf
               then updateAttrs false (import (lib.path.append ./installers sysconf.extend) ).sysconf sysconf
               else sysconf;


  installerApp = inst_app: let
    installers = (builtins.removeAttrs inst_app ["name"]) //
                { oss_path = lib.mkDefault "${oss_list_path}"; };
  in installers;
  
  addSystemPackages = {pkgs, ...}: {environment.systemPackages = map (app: pkgs.${app}) installerconf.systemPackages;};

  formatModule = nixos-generators.nixosModules.iso;
  installer = variant: extraModules: let
    system = "x86_64-linux";

    pkgs = import nixpkgs {inherit system;};

    installerImgCfg = lib.nixosSystem {
      inherit system;
      specialArgs = {inherit lib; inherit ghafOS;};
      modules =
        [
          self.nixosModules.installer
          (import "${ghafOS}/modules/host")
          ({modulesPath, lib, config, ...}: {
            imports = [ (modulesPath + "/profiles/all-hardware.nix") ];

            nixpkgs.hostPlatform.system = system;
            nixpkgs.config.allowUnfree = true;

            hardware.enableAllFirmware = true;
                   
            # Installer system profile
            # Use less privileged ghaf user
            users.users.ghaf = {
              isNormalUser = true;
              extraGroups = ["wheel" "networkmanager" "video"];
              # Allow the graphical user to login without password
              initialHashedPassword = "";
            };

            # Allow the user to log in as root without a password.
            users.users.root.initialHashedPassword = "";

            # Allow passwordless sudo from ghaf user
            security.sudo = {
              enable = lib.mkDefault true;
              wheelNeedsPassword = lib.mkImageMediaOverride false;
            };

            # Automatically log in at the virtual consoles.
            services.getty.autologinUser = lib.mkDefault "ghaf";
          })

          # Configs for installation
          {
            installer.includeOSS = {
              enable = lib.mkDefault true;
              oss_list_fname = lib.mkDefault "${oss_list_name}";
              systems = map (os: rec {
                name = "${os}-${variant}";
                image = self.nixosConfigurations.${name};}) oss;
            };
          }

          # Installer app
          {
            installer.${installerconf.installer.name} = installerApp installerconf.installer;
          }

          formatModule
          addSystemPackages

          {
            isoImage.squashfsCompression = "lz4"; 
          }
        ]
        ++ (import "${ghafOS}/modules/module-list.nix")
        ++ extraModules
        ++ (if lib.hasAttr "extraModules" installerconf then installerconf.extraModules else []);
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
  flake = {
    packages = lib.foldr lib.recursiveUpdate {} (map ({name, system, installerImgDrv, ...}: {
      ${system}.${name} = installerImgDrv;
    }) targets);
  };
}
