# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
#
{
  config,
  lib,
  pkgs,
  ...
}:{
  config = {
    environment.systemPackages = [pkgs.konsave];
    time.timeZone = "Asia/Dubai";
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      pulse.enable = true;
    };
    services.xserver = {
      xkb.layout = "us,fi";
    };
    services.displayManager.defaultSession = "plasma";
    services.displayManager.sddm.enable = true;
    services.xserver.enable = true;
    services.displayManager.autoLogin.enable = true;
    services.displayManager.autoLogin.user = "ghaf";
    services.displayManager.sddm.wayland.enable = true;
    services.mydesktopManager.plasma6.enable = true;
    environment.sessionVariables.XDG_CONFIG_DIRS = lib.mkForce "/etc/xdg";
  };
}