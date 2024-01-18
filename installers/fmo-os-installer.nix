# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
#
# FMO-OS general installer includes images for Rugged tablet and laptop
#
{
  # system and host description
  sysconf = {
    name = "fmo-os-installer";
    description = "FMO-OS general installer includes images for Rugged tablet and laptop";
    systemPackages = [
      "vim"
    ]; # systemPackages

    extraModules = [
      {
        environment.noXlibs = false;
        # For WLAN firmwares
        hardware.enableRedistributableFirmware = true;

        networking = {
          wireless.enable = false;
          networkmanager.enable = true;
        };

        services = {
          avahi.enable = true;
          avahi.nssmdns = true;
        };
      }
    ]; # extraModules

    installer = {
      name = "simple-installer";
      enable = true;
      run_on_boot = true;
      welcome_msg = "Welcome to FMO-OS installer";
    };

    # OS to include
    oss = [
      "fmo-os-rugged-laptop-7330"
      "fmo-os-rugged-tablet-7230"
    ]; # oss
  }; # system
}
