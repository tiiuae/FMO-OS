# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
#
{
  self,
  lib,
  ghafOS,
}: sysconf:
let
  inherit (import ./utils {inherit lib self ghafOS;}) updateAttrs addSystemPackages;

  oss = sysconf.oss;
  oss_list_name = "installer_os_list";
  oss_list_path = "/etc/${oss_list_name}";

  installerconf = sysconf;

  installerApp = inst_app: let
      installers = (builtins.removeAttrs inst_app ["name"]) //
                { oss_path = lib.mkDefault "${oss_list_path}"; };
    in installers;
  

  installer = variant: compressed: let
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

            ghaf = {
              profiles = {
                # variant type, turn on debug or release
                debug.enable = variant == "debug";
                release.enable = variant == "release";
              };
            };
                   
            # Installer system profile
            # Use less privileged ghaf user
            users = {
              allowNoPasswordLogin = true;
              users.ghaf = {
                isNormalUser = true;
                extraGroups = ["wheel" "networkmanager" "video"];
              };
            };

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
            isoImage.squashfsCompression = if compressed=="compressed" then "zstd" else "lz4";
          }
        ]
        ++ (addSystemPackages installerconf.systemPackages)
        ++ (if lib.hasAttr "extraModules" installerconf then installerconf.extraModules else []);
    };
  in {
    name = if compressed == "compressed"
          then "${installerconf.name}-${variant}-compressed"
          else "${installerconf.name}-${variant}";
    inherit installerImgCfg system;
    installerImgDrv = installerImgCfg.config.system.build.${installerImgCfg.config.formatAttr};
  };
  targets = [
    (installer "debug" "")
    (installer "release" "")
    (installer "debug" "compressed")
    (installer "release" "compressed")
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
