# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  ghafOS,
  vmconf,
  self,
}:{
  config,
  lib,
  pkgs,
  ...
}: let
  addSystemPackages = {pkgs, ...}: {environment.systemPackages = lib.mkIf (lib.hasAttr "systemPackages" vmconf) (map (app: pkgs.${app}) vmconf.systemPackages);};
  configHost = config;
  vmBaseConfiguration = {
    imports = [
      ({lib, ...}: {
        ghaf = {
          users.accounts.enable = lib.mkDefault configHost.ghaf.users.accounts.enable;
          development = {
            ssh.daemon.enable = lib.mkDefault configHost.ghaf.development.ssh.daemon.enable;
            debug.tools.enable = lib.mkDefault configHost.ghaf.development.debug.tools.enable;
          };
        };

        # noXlibs=false; needed for NetworkManager stuff
        environment.noXlibs = false;

        networking.hostName = vmconf.name;
        system.stateVersion = lib.trivial.release;

        nixpkgs.buildPlatform.system = configHost.nixpkgs.buildPlatform.system;
        nixpkgs.hostPlatform.system = configHost.nixpkgs.hostPlatform.system;

        microvm.hypervisor = "qemu";
        microvm.optimize.enable = false;

        networking = {
          enableIPv6 = false;
          interfaces.ethint0.useDHCP = false;
          firewall.allowedTCPPorts = lib.mkDefault [22];
          firewall.allowedUDPPorts = lib.mkDefault [67];
          firewall.enable = lib.mkDefault true;
          useNetworkd = true;
        };

        microvm.interfaces = [
          {
            type = "tap";
            id = "tap-${vmconf.name}";
            mac = "${vmconf.macaddr}";
          }
        ];

        microvm.shares = [
          # Use host's /nix/store to reduce size of the image
          # WAR: to enable -M q35 option need to share any fs or pcie devices
          # WAR: otherwise machine is not able to start, why?
          {
            tag = "ro-store";
            source = "/nix/store";
            mountPoint = "/nix/.ro-store";
         }
        ]; # microvm.shares

        microvm.qemu.extraArgs = [
          "-device"
          "qemu-xhci"
        ];

        microvm.writableStoreOverlay = lib.mkIf config.ghaf.development.debug.tools.enable "/nix/.rw-store";

        networking.nat = {
          enable = lib.mkDefault false;
          internalInterfaces = lib.mkDefault ["ethint0"];
        };

        # Set internal network's interface name to ethint0
        systemd.network.links."10-ethint0" = {
          matchConfig.PermanentMACAddress = "${vmconf.macaddr}";
          linkConfig.Name = "ethint0";
        };

        systemd.network = {
          enable = true;
          networks."10-ethint0" = {
            matchConfig.MACAddress = "${vmconf.macaddr}";
            addresses = [
              {
                # IP-address for debugging subnet
                Address = "${vmconf.ipaddr}/24";
              }
            ];
            routes =  lib.mkIf (lib.hasAttr "defaultgw" vmconf)
            [
              { Gateway = "${vmconf.defaultgw}"; }
            ];
            linkConfig.RequiredForOnline = "routable";
            linkConfig.ActivationPolicy = "always-up";
          };
        };

        microvm.storeDiskType = "squashfs";
        
      })
      addSystemPackages
      self.nixosModules.fmo-configs
      self.nixosModules.ghaf-common
    ];
  };
  cfg = config.ghaf.virtualization.microvm.${vmconf.name};
in {
  options.ghaf.virtualization.microvm.${vmconf.name} = {
    enable = lib.mkEnableOption "${vmconf.name}";

    extraModules = lib.mkOption {
      description = ''
        List of additional modules to be imported and evaluated as part of
        VM's NixOS configuration.
      '';
      default = [];
    };
  };

  config = lib.mkIf cfg.enable {
    microvm.vms."${vmconf.name}" = {
      autostart = true;
      config =
        vmBaseConfiguration
        // {
          imports =
            vmBaseConfiguration.imports
            ++ cfg.extraModules;
        };
      specialArgs = {inherit lib;};
    };
  };
}
