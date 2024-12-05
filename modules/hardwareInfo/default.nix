# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.device.hardwareInfo;
in {
  options.device.hardwareInfo = {
    configJson = mkOption {
      type = types.str;
      description = "Device Config in JSON format";
      default = "";
    };
    systemConfig = mkOption {
      type = types.str;
      description = "Folder contains system config in nix format";
      default = "/var/host/FMO-OS";
    };
    systemConfigSymlink = mkOption {
      type = types.str;
      description = "Folder contains system config in nix format";
      default = "/home/ghaf/.sysconf";
    };
    skuFile = mkOption {
      type = types.str;
      description = "File contains SKU information generated at runtime";
      default = "/var/host/SKU";
    };
  };

  config = {
    environment.systemPackages = [ pkgs.dmidecode ];
    
    # Read device SKU and write in to ${skuFile}
    systemd.services."device-sku" = {
      script = ''
          system_product_name=$(${pkgs.dmidecode}/bin/dmidecode -s system-product-name)
          system_sku_number=$(${pkgs.dmidecode}/bin/dmidecode -s system-sku-number)
          system_sku="$system_sku_number $system_product_name"
          mkdir -p $(dirname ${cfg.skuFile})
          echo $system_sku > ${cfg.skuFile}
          chmod 444 ${cfg.skuFile}

          if [ -d "'${cfg.systemConfig}" ]; then
            echo "FMO-OS config exists"
          else
            mkdir -p ${cfg.systemConfig}
            cp -R ${../../.}/* ${cfg.systemConfig}/
          fi
          chmod 666 ${cfg.systemConfig}/hardware/fmo-os-x86_64.nix
          ln -sf ${cfg.systemConfig}/hardware/fmo-os-x86_64.nix ${cfg.systemConfigSymlink}
      '';

      wantedBy = ["multi-user.target"];
      before = [
        "microvms.target"
        "graphical-session.target"
      ];

      # TODO: restart always
      serviceConfig = {
        Restart = lib.mkForce "on-failure";
        RestartSec = "5";
      };
    };
  };
}
