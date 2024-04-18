# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.ghaf.graphics.app-launchers;
  get_launcer = descr: (let
    extraArgs =
      if lib.hasAttr "extraArgs" descr
      then descr.extraArgs
      else "";
    launcers_description = {
      chromium = {
        name = "Chromium";
        path = "${pkgs.chromium}/bin/chromium --enable-features=UseOzonePlatform --ozone-platform=wayland ${extraArgs}";
        icon = "${pkgs.chromium}/share/icons/hicolor/48x48/apps/chromium.png";
        package = [pkgs.chromium];
      };
      terminal = {
        name = "Foot";
        path = "${pkgs.foot}/bin/foot ${extraArgs}";
        icon = "${pkgs.foot}/share/icons/hicolor/48x48/apps/foot.png";
        package = [pkgs.foot];
      };
      nmLauncher = {
        name = "nmLauncher";
        path = "${pkgs.nmLauncher}/bin/nmLauncher ${extraArgs}";
        icon = "${pkgs.networkmanagerapplet}/share/icons/hicolor/22x22/apps/nm-device-wwan.png";
        package = [pkgs.nmLauncher pkgs.networkmanagerapplet];
      };
    };
  in
    launcers_description."${descr.app}");
in {
  options.ghaf.graphics.app-launchers = with lib; {
    enabled-launchers = mkOption {
      description = "Application launchers to show in launch bar";
      default = [];
      type = with types;
        listOf
        (submodule {
          options.app = mkOption {
            description = "Application";
            type = str;
          };
          options.extraArgs = mkOption {
            description = "Extra arguments to execute app";
            default = "";
            type = str;
          };
        });
    };

    launchers = mkOption {
      description = "Application launchers to show in launch bar";
      default = [];
      type = with types;
        listOf
        (submodule {
          options.name = mkOption {
            description = "Name of executable when hovering the mouse over the icon";
            type = str;
          };
          options.package = mkOption {
            description = "Package to be added to environment.systemPackages";
            type = listOf package;
            default = [];
          };
          options.path = mkOption {
            description = "Path to the executable to be launched";
            type = path;
          };
          options.icon = mkOption {
            description = "Path of the icon";
            type = path;
          };
        });
    };
    enableAppLaunchers = mkEnableOption "some applications for demoing";
  };

  config = lib.mkIf cfg.enableAppLaunchers {
    ghaf.graphics.app-launchers.launchers = map get_launcer cfg.enabled-launchers;

    environment.systemPackages = lib.lists.flatten (
      builtins.map (launcher: launcher.package) config.ghaf.graphics.app-launchers.launchers
    );

    # Needed for nm-applet as defined in
    # https://github.com/NixOS/nixpkgs/blob/4cdde2bb35340a5b33e4a04e3e5b28d219985b7e/nixos/modules/programs/nm-applet.nix#L22
    # Requires further testing
    services.dbus.packages = [pkgs.gcr];
  };
}
