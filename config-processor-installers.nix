# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
#
{
  self,
  lib,
  ghafOS,
}: {
  sysconf,
}:
let
  inherit (import ./utils {inherit lib self ghafOS;}) updateAttrs addSystemPackages;

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
  

  installer = variant: let
    system = "x86_64-linux";

    installerImgCfg = lib.nixosSystem {
      inherit system;
      specialArgs = {inherit lib; inherit ghafOS;};
      modules =
        [
          ghafOS.inputs.nixos-generators.nixosModules.iso
          self.nixosModules.installer
          self.nixosModules.fmo-common
          
          ({modulesPath, lib, config, ...}: {
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
  targets = [
    (installer "debug")
    (installer "release")
  ];
in {
  flake = {
    nixosConfigurations =
      builtins.listToAttrs (map (t: lib.nameValuePair t.name t.installerImgCfg) targets);
    packages = lib.foldr lib.recursiveUpdate {} (map ({name, system, installerImgDrv, ...}: {
      ${system}.${name} = installerImgDrv;
    }) targets);
  };
}
