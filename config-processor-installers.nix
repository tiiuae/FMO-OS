# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
#
{
  self,
  lib,
  ghafOS,
}: let
  inherit (import ./utils {inherit lib self ghafOS;}) updateAttrs addSystemPackages;

  builder = sysconf: variant: let
    system = "x86_64-linux";

    oss = sysconf.oss;
    oss_list_name = "installer_os_list";
    oss_list_path = "/etc/${oss_list_name}";

    installerApp = inst_app: let
                  installers = (builtins.removeAttrs inst_app ["name"]) //
                    { oss_path = lib.mkDefault "${oss_list_path}"; };
                  in installers;

    installerconf = if lib.hasAttr "extend" sysconf
               then updateAttrs false (import (lib.path.append ./installers sysconf.extend) ).sysconf sysconf
               else sysconf;

    installerImgCfg = lib.nixosSystem {
      inherit system;
      specialArgs = {inherit lib; inherit ghafOS;};
      modules =
        [
          ghafOS.inputs.nixos-generators.nixosModules.iso
          self.nixosModules.installer
          self.nixosModules.fmo-common
          
          ({modulesPath, lib, config, ghafOS, ...}: {
            imports = [ (modulesPath + "/profiles/all-hardware.nix") ];

            nixpkgs.hostPlatform.system = system;
            nixpkgs.config.allowUnfree = true;

            hardware.enableAllFirmware = true;

            ghaf.development.usb-serial.enable = variant == "debug";
                   
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
          {
            isoImage.squashfsCompression = "lz4"; 
          }
        ]
        ++ (addSystemPackages installerconf.systemPackages)
        ++ (if lib.hasAttr "extraModules" installerconf then installerconf.extraModules else []);
    };
  in {
    name = "${installerconf.name}-${variant}";
    inherit installerImgCfg system;
    installerImgDrv = installerImgCfg.config.system.build.${installerImgCfg.config.formatAttr};
  };
in
  builder
