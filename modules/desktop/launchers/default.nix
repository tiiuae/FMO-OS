# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.ghaf.graphics.app-launchers;
  getLauncers = descr: (let
    extraArgs =
      if lib.hasAttr "extraArgs" descr
      then descr.extraArgs
      else "";
    launchers = {
      google-chrome = {
        name = "Chrome";
        path = "${pkgs.google-chrome}/bin/google-chrome-stable --enable-features=UseOzonePlatform --ozone-platform=wayland ${extraArgs}";
        icon = "${pkgs.google-chrome}/share/icons/hicolor/48x48/apps/google-chrome.png";
        package = [pkgs.google-chrome];
      };
      chromium = {
        name = "Chromium";
        path = "${pkgs.chromium}/bin/chromium --enable-features=UseOzonePlatform --ozone-platform=wayland ${extraArgs}";
        icon = "${pkgs.chromium}/share/icons/hicolor/48x48/apps/chromium.png";
        package = [pkgs.chromium];
      };
      terminal = {
        name = "Terminal";
        path = "${pkgs.terminator}/bin/terminator ${extraArgs}";
        icon = "${pkgs.terminator}/share/icons/hicolor/48x48/apps/terminator.png";
        package = [pkgs.terminator];
      };
      nmLauncher = {
        name = "nmLauncher";
        path = "${pkgs.nmLauncher}/bin/nmLauncher ${extraArgs}";
        icon = "${pkgs.networkmanagerapplet}/share/icons/hicolor/22x22/apps/nm-device-wwan.png";
        package = [pkgs.nmLauncher pkgs.networkmanagerapplet];
      };
    };
  in
    launchers."${descr.app}");
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
    ghaf.graphics.app-launchers.launchers = map getLauncers cfg.enabled-launchers;

    environment.systemPackages = lib.lists.flatten (
      builtins.map (launcher: launcher.package) config.ghaf.graphics.app-launchers.launchers
    );

    # Needed for nm-applet as defined in
    # https://github.com/NixOS/nixpkgs/blob/4cdde2bb35340a5b33e4a04e3e5b28d219985b7e/nixos/modules/programs/nm-applet.nix#L22
    # Requires further testing
    services.dbus.packages = [pkgs.gcr];
  };
}
