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
          # TODO: Ghaf implement different types of users. Currently use admin user for all VMs
          users.admin.enable = lib.mkDefault configHost.ghaf.users.admin.enable;
          development = {
            ssh.daemon.enable = lib.mkDefault configHost.ghaf.development.ssh.daemon.enable;
            debug.tools.enable = lib.mkDefault configHost.ghaf.development.debug.tools.enable;
          };
        };

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
      self.nixosModules.fmo-common
      self.nixosModules.fmo-vm
    ];
  };
  cfg = config.ghaf.virtualization.microvm.${vmconf.name};

  fmo-qemu  = pkgs.callPackage ../../packages/fmo-qemu {
                inherit pkgs ghafOS;
                inherit (config.microvm.vms."${vmconf.name}".config.config.system.build) toplevel;
                microvmConfig = {
                  inherit (cfg) pciConfigPath;
                  inherit (config.microvm.vms."${vmconf.name}".config.config.networking) hostName;
                  hypervisor="qemu";
                }
                // config.microvm.vms."${vmconf.name}".config.config.microvm;};
in {
  options.ghaf.virtualization.microvm.${vmconf.name} = {
    enable = lib.mkEnableOption "${vmconf.name}";

    pciConfigPath = lib.mkOption {
      type = lib.types.str;
      description = "Path to pci-device-path file";
      default = "/var/host/pciDevices/${vmconf.name}";
    };

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
          config.microvm.declaredRunner =  (lib.mkForce fmo-qemu);
        };
      specialArgs = {inherit lib;};
    };

    # Write all pci device information for passthrough
    systemd.services."microvm-pci-declaration@${vmconf.name}" = {
      description = "Declare MicroVM '${vmconf.name}' pci devices";
      before = [
        "install-microvm-${vmconf.name}.service"
        "microvm@${vmconf.name}.service"
        "microvm-tap-interfaces@${vmconf.name}.service"
        "microvm-pci-devices@${vmconf.name}.service"
        "microvm-virtiofsd@${vmconf.name}.service"
      ];
      partOf = [ "microvm@${vmconf.name}.service" ];
      wantedBy = [ "microvms.target" ];
      # Read create source for symlink file that contains information about
      # pci devices
      serviceConfig.Type = "oneshot";
      script = ''
        system_product_name=$(${pkgs.dmidecode}/bin/dmidecode -s system-product-name)
        system_sku_number=$(${pkgs.dmidecode}/bin/dmidecode -s system-sku-number)
        system_sku="$system_sku_number $system_product_name"

        mkdir -p $(dirname ${cfg.pciConfigPath})

        devices=$(echo '${config.device.hardwareInfo.configJson}' | ${pkgs.jq}/bin/jq -r --arg sku "$system_sku" '.[$sku].pciDevices.${vmconf.name}.[]')
        for device in $devices; do
          if [ -f ${cfg.pciConfigPath} ]; then
            assigned_devices=$(cat ${cfg.pciConfigPath})
            if [[ $assigned_devices == *$device* ]]; then
              continue
            fi
          fi
          echo "$device" >> ${cfg.pciConfigPath}
        done
      '';
      serviceConfig.SyslogIdentifier = "microvm-pci-declaration-${vmconf.name}";
    };
  };
}
