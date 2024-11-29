# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{ lib, pkgs, config, ... }:
with lib;
let
  orchestrate-src = builtins.readFile ./assets/orchestrate.sh;
  orchestrate = (pkgs.writeScriptBin "orchestrate.sh" orchestrate-src).overrideAttrs(old: {
    buildCommand = "${old.buildCommand}\n patchShebangs $out";
  });

  docker-login-src = builtins.readFile ./assets/docker-login.sh;
  docker-login = (pkgs.writeScriptBin "docker-login.sh" docker-login-src).overrideAttrs(old: {
    buildCommand = "${old.buildCommand}\n patchShebangs $out";
  });

  compose-image-src = builtins.readFile ./assets/compose-image.sh;
  compose-image = (pkgs.writeScriptBin "compose-image.sh" compose-image-src).overrideAttrs(old: {
    buildCommand = "${old.buildCommand}\n patchShebangs $out";
  });

  onYubikeyHotplug-src = builtins.readFile ./assets/on-yubikey-hotplug.sh;
  onYubikeyHotplug = (pkgs.writeShellScript "on-yubikey-hotplug.sh" onYubikeyHotplug-src).overrideAttrs(old: {
    buildCommand = "${old.buildCommand}\n patchShebangs $out";
  });

  cfg = config.services.fmo-adapter-yubikey-hotplug-service;
in {
  options.services.fmo-adapter-yubikey-hotplug-service = {
    enable = mkEnableOption "FMO adapter orchestration trigger service";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ orchestrate docker-login compose-image ];

    services.udev.extraRules = ''
      # FMO adapter orchestration triggering
      ACTION=="add", SUBSYSTEM=="usb", ATTRS{idVendor}=="1050", ATTRS{idProduct}=="0407", ENV{DISPLAY}=":0.0", RUN+="${onYubikeyHotplug} add $attr{busnum} $attr{devnum}"
      ACTION=="remove", SUBSYSTEM=="usb", ATTRS{idVendor}=="1050", ATTRS{idProduct}=="0407", ENV{DISPLAY}=":0.0", RUN+="${onYubikeyHotplug} remove"
    '';
  };
}
