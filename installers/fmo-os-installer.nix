# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
#
# FMO-OS general installer includes images for FMO-OS x86_64 devices
#
{
  # system and host description
  sysconf = {
    name = "fmo-os-installer";
    description = "FMO-OS general installer includes images for FMO-OS x86_64 devices";
    systemPackages = [
      "vim"
    ]; # systemPackages

    extraModules = [
      {
        # For WLAN firmwares
        hardware.enableRedistributableFirmware = true;

        networking = {
          wireless.enable = false;
          networkmanager.enable = true;
        };

        services = {
          avahi.enable = true;
          avahi.nssmdns4 = true;

          registration-agent-laptop ={
            enable = true;
            certs_path = "/var/lib/fogdata/certs";
            config_path = "/var/lib/fogdata";
            token_path = "/var/lib/fogdata";
            hostname_path = "/var/lib/fogdata";
            ip_path = "/var/lib/fogdata";
            post_install_path = "/var/lib/fogdata/certs";
          }; # registration-agent-laptop
        }; # services
      }
    ]; # extraModules

    installer = {
      name = "pterm-installer";
      enable = true;
      run_on_boot = true;
      welcome_msg = "Welcome to FMO-OS installer";
      mount_path = "/home/ghaf/root";
      docker_urls = [
        "ghcr.io"
        "cr.airoplatform.com"
      ];
      docker_url_path = "/var/fogdata/cr.url";
      custom_script_path = "registration-agent-laptop";
      custom_script_env_path = [
        "/var/lib/fogdata"
        "/var/fogdata"
        "/var/fogdata/certs"
      ];
    }; # installer

    # OS to include
    oss = [
      "fmo-os-x86_64"
    ]; # oss
  }; # system
}
