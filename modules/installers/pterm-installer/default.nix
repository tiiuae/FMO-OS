# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  lib,
  pkgs,
  config,
  ... 
}: with lib;
let
  cfg = config.installer.pterm-installer;
  includeOSS = config.installer.includeOSS;
in
{
  options.installer.pterm-installer = {
    enable = mkEnableOption "Build and enable installer script";

    oss_path = mkOption {
      type = types.str;
      description = "Path to installer_os_list file";
    };

    run_on_boot = mkOption {
      description = mdDoc ''
        Enable installing script to run on boot.
      '';
      type = types.bool;
      default = false;
    };

    welcome_msg = mkOption {
      type = types.str;
      description = "Welcome message to show";
      default = "Welcome to pterm-installer";
    };

    mount_path = mkOption {
      type = types.str;
      description = "Path to mount the installed system";
      default = "${config.users.users.ghaf.home}/root";
    };

    custom_script_path = mkOption {
      type = types.str;
      description = "Path to script that executes after mounting system";
      default = "";
    };

    custom_script_env_path = mkOption {
      type = types.listOf types.str;
      description = "Folders created for custom script to run";
      default = [];
    };
  };

  config.environment = mkIf (cfg.enable) (
    let
      scriptEnvPath = (builtins.concatStringsSep ";"
            ((lib.optional config.services.registration-agent-laptop.enable
            (config.services.registration-agent-laptop.env_path + "/.env"))
             ++ cfg.custom_script_env_path));
      installerGoScript = pkgs.buildGoModule {
        name = "ghaf-installer";
        src = builtins.fetchGit {
          url = "https://github.com/tiiuae/FMO-OS-Installer.git";
          rev = "688dd34da9f57a9cbf99ef57c43dcdfd5e7c50a2";
          ref = "refs/heads/main";
        };
        vendorHash = "sha256-MKMsvIP8wMV86dh9Y5CWhgTQD0iRpzxk7+0diHkYBUo=";
        proxyVendor=true;
        ldflags = [
          "-X 'ghaf-installer/global.OSSfile=${cfg.oss_path}'"
          "-X 'ghaf-installer/global.WelcomeMsg=${cfg.welcome_msg}'"
          "-X 'ghaf-installer/screen.mountPoint=${cfg.mount_path}'"
          "-X 'ghaf-installer/screen.sourceDir=${installerGoScript.src.outPath}'"
        ] ++ lib.optionals (cfg.custom_script_path != "") [
          "-X ghaf-installer/screen.folderPaths=${scriptEnvPath}"
          "-X ghaf-installer/screen.customScript=${pkgs.${cfg.custom_script_path}}/bin/${cfg.custom_script_path}"
        ];
      };
  in {
      systemPackages = [installerGoScript];
      loginShellInit = mkIf (cfg.run_on_boot) (''sudo ${installerGoScript}/bin/ghaf-installer'');
    });
}