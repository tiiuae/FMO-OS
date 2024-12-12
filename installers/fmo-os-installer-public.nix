# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
#
# FMO-OS general installer includes images for FMO-OS x86_64 devices without registration agent
#
{
  # system and host description
  sysconf = {
    extend = "./fmo-os-installer.nix";
    name = "fmo-os-installer-public";
    extraModules = [
      {
        services = {
          registration-agent-laptop ={
            enable = false;
          }; # services.registration-agent-laptop
        }; # services
      }
    ]; # extraModules

    installer = {
      name = "pterm-installer";
      enable = true;
      run_on_boot = true;
      welcome_msg = "Welcome to FMO-OS installer";
      mount_path = "/home/ghaf/root";
      custom_script_path = "";
      custom_script_env_path = [];
    }; # installer

    # OS to include
    oss = [
      "fmo-os-rugged-devices-public"
    ]; # oss
  }; # system
}
