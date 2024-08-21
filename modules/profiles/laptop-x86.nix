# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  config,
  lib,
  pkgs,
  ghafOS,
  ...
}: let
  powerControl = pkgs.callPackage "${ghafOS}/packages/powercontrol" {};
  cfg = config.ghaf.profiles.laptop-x86;
  listenerAddress = config.ghaf.logging.listener.address;
  listenerPort = toString config.ghaf.logging.listener.port;
in {
  imports = [
    (import "${ghafOS}/modules/desktop/graphics")
    (import "${ghafOS}/modules/common")
    (import "${ghafOS}/modules/host")
    (import "${ghafOS}/modules/hardware/x86_64-generic")
    (import "${ghafOS}/modules/hardware/common")
    #(import "${ghafOS}/modules/hardware/definition.nix")
    (import "${ghafOS}/modules/lanzaboote")
  ];

  options.ghaf.profiles.laptop-x86 = {
    enable = lib.mkEnableOption "Enable the basic x86 laptop config";

    netvmExtraModules = lib.mkOption {
      description = ''
        List of additional modules to be passed to the netvm.
      '';
      default = [];
    };

    guivmExtraModules = lib.mkOption {
      description = ''
        List of additional modules to be passed to the guivm.
      '';
      default = [];
    };

    enabled-app-vms = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      default = [];
      description = ''
        List of appvms to include in the Ghaf reference appvms module
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    security.polkit = {
      enable = true;
      extraConfig = powerControl.polkitExtraConfig;
    };

    ghaf = {
      # Hardware definitions
      hardware = {
        x86_64.common.enable = true;
        tpm2.enable = true;
        usb.internal.enable = true;
        usb.external.enable = true;
      };

      # Virtualization options
      virtualization = {
        microvm-host = {
          enable = true;
          networkSupport = true;
        };

        microvm = {
          netvm = {
            enable = true;
          #  wifi = true;
            extraModules = cfg.netvmExtraModules;
          };

          guivm = {
            enable = true;
            extraModules = cfg.guivmExtraModules;
          };

          #appvm = {
          #  enable = true;
          #  vms = cfg.enabled-app-vms;
          #};
        };
      };

      host = {
        networking.enable = true;
        powercontrol.enable = true;
      };

      # UI applications
      # TODO fix this when defining desktop and apps
      profiles = {
        applications.enable = false;
      };

      # Logging configuration
      #logging.client.enable = true;
      #logging.client.endpoint = "http://${listenerAddress}:${listenerPort}/loki/api/v1/push";
      #logging.listener.address = "admin-vm-debug";
      #logging.listener.port = 9999;
    };
  };
}
