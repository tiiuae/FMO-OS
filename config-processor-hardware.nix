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
  inherit (builtins) toString typeOf;
  inherit (lib) mkOption types concatImapStrings concatMapStringsSep;

  updateAttrs = (import ./utils/updateAttrs.nix).updateAttrs;
  updateHostConfig = (import ./utils/updateHostConfig.nix).updateHostConfig;

  targetconf = if lib.hasAttr "extend" sysconf
               then updateAttrs false (import (lib.path.append ./hardware sysconf.extend) ).sysconf sysconf
               else sysconf;

  name = targetconf.name;
  system = "x86_64-linux";
  vms = targetconf.vms;

  importvm = vmconf: (import ./modules/virtualization/microvm/vm.nix {inherit ghafOS vmconf self;});
  enablevm = vm: {
    virtualization.microvm.${vm.name} = {
      enable = true;
      extraModules = vm.extraModules;
    };
  };
  addSystemPackages = {pkgs, ...}: {environment.systemPackages = map (app: pkgs.${app}) targetconf.systemPackages;};
  addCustomLaunchers =  { ghaf.graphics.app-launchers.enabled-launchers = targetconf.launchers; };

  formatModule = nixos-generators.nixosModules.raw-efi;
  hwDefinition = import (./modules/hardware/dell-latitude-7230.nix);

  # Helper function to create udev rules for input devices
  generateUdevRules = devlink: deviceList:
    concatImapStrings (
      i: d:
        if (typeOf d) == "list"
        then ''${concatMapStringsSep "\n" (sd: ''SUBSYSTEM=="input", ATTRS{name}=="${sd}", KERNEL=="event*", GROUP="kvm", SYMLINK+="${devlink}${toString (i - 1)}"'') d}''\n''
        else ''SUBSYSTEM=="input", ATTRS{name}=="${d}", KERNEL=="event*", GROUP="kvm", SYMLINK+="${devlink}${toString (i - 1)}"''\n''
    )
    deviceList;
  target = variant: extraModules: let
    hostConfiguration = lib.nixosSystem {
      inherit system;
      specialArgs = {inherit lib; inherit ghafOS;};
      modules =
        [
          #microvm.nixosModules.host
          self.nixosModules.fmo-configs
          #self.nixosModules.ghaf-common
          #ghafOS.nixosModules.host
          self.nixosModules.fmo-vm-profiles
         # ghafOS.nixosModules.laptop
          self.nixosModules.ghaf-vms
          ghafOS.inputs.lanzaboote.nixosModules.lanzaboote
          (import ./modules/virtualization/microvm/guivm.nix {inherit ghafOS self;})
          #(import "${ghafOS}/modules/hardware/definition.nix")
          (import "${ghafOS}/modules/hardware/x86_64-generic")
          #(import "${ghafOS}/modules/hardware/laptop.nix")
          (import "${ghafOS}/modules/hardware/common")
          #(import "${ghafOS}/modules/microvm/networking.nix")
          #(import "${ghafOS}/modules/microvm/virtualization/microvm/microvm-host.nix")
          
          # WAR: ghaf mainline has audiovm hardcoded. This causes audiovm defined here
          # This should be removed when audiovm on ghaf mainline is fixed.
          # JIRA: FMO-43 for monitoring this issue.
          #(import "${ghafOS}/modules/microvm/virtualization/microvm/audiovm.nix")
          {
            time.timeZone = "Asia/Dubai";
            ghaf = lib.mkMerge (
              [
                {
                  #hardware.x86_64.common.enable = true;

                  #virtualization.microvm-host.enable = true;
                  #virtualization.microvm-host.networkSupport = true;
                  #host.networking.enable = true;

                  # Enable all the default UI applications
                  profiles = {
                  #  applications.enable = true;
                    #TODO clean this up when the microvm is updated to latest
                    release.enable = variant == "release";
                    debug.enable = variant == "debug";
                    mvp-user-trial.enable = true;
                    # Enable below option for host hardening features
                    host-hardening.enable = false;
                  };
                  hardware.definition = lib.mkForce {
                    inherit (hwDefinition) host;
                    inherit (hwDefinition) input;
                    inherit (hwDefinition) disks;
                    inherit (hwDefinition) network;
                    inherit (hwDefinition) gpu;
                    inherit (hwDefinition) audio;
                    inherit (hwDefinition) usb;
                  };
                }
              ]
              ++ map (vm: enablevm vms.${vm}) (builtins.attrNames vms)
            );
        
            # Disk configuration
            #disko.devices.disk = hwDefinition.disks;
        
            # Host udev rules for input devices
            services.udev.extraRules = ''
              # Keyboard
              ${generateUdevRules "keyboard" hwDefinition.input.keyboard.name}
              # Mouse
              ${generateUdevRules "mouse" hwDefinition.input.mouse.name}
              # Touchpad
              ${generateUdevRules "touchpad" hwDefinition.input.touchpad.name}
              # Misc
              ${lib.strings.concatMapStringsSep "\n" (d: ''SUBSYSTEM=="input", ATTRS{name}=="${d}", GROUP="kvm"'') hwDefinition.input.misc.name}
            '';
          }

          #addCustomLaunchers
          #addSystemPackages
          formatModule

          #{
          #  boot.kernelParams = [
          #    "intel_iommu=on,igx_off,sm_on"
          #    "iommu=pt"
          #  ];
          #}
        ]
        ++ updateHostConfig {inherit lib; inherit targetconf;}
        ++ map (vm: importvm vms.${vm}) (builtins.attrNames vms)
        #++ extraModules
        ++ (if lib.hasAttr "extraModules" targetconf then targetconf.extraModules else []);
    };
  in {
    inherit hostConfiguration;
    name = "${name}-${variant}";
    package = hostConfiguration.config.system.build.${hostConfiguration.config.formatAttr};
  };
  debugModules = [{ghaf.development.usb-serial.enable = true;}];
  targets = [
    (target "debug" debugModules)
    (target "release" [])
  ];
in {
  flake = {
    nixosConfigurations =
      builtins.listToAttrs (map (t: lib.nameValuePair t.name t.hostConfiguration) targets);
    packages = {
      x86_64-linux =
        builtins.listToAttrs (map (t: lib.nameValuePair t.name t.package) targets);
    };
  };
}
