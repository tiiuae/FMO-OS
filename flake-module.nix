# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
#
# Configuration for laptop devices based on the hardware and usecase profile
{
  lib,
  self,
  inputs,
  ...
}:
let
  # Get builder for fmo-os and installers
  os-builder = import ./config-processor-hardware.nix { inherit lib self; ghafOS = inputs.ghafOS; };
  installer-builder = import ./config-processor-installers.nix { inherit lib self; ghafOS = inputs.ghafOS; };

  # Get system and installer configuration
  sysconf = (import ./hardware/sysconf.nix).sysconf;
  sysconf-public = (import ./hardware/sysconf-public.nix).sysconf;

  installerconf = (import ./installers/fmo-os-installer.nix).sysconf;
  installerconf-public = (import ./installers/fmo-os-installer-public.nix).sysconf;

  # Create different-variants targets with builders and configurations
  targets = lib.flatten ((map (variant: [
      (installer-builder installerconf variant)
      (installer-builder installerconf-public variant) ]) ["debug" "release"])
    ++ (map (hardware: (map (variant: [
      (os-builder sysconf hardware.device variant)
      (os-builder sysconf-public hardware.device variant) ]) ["debug" "release"]))  [
        # Hardware information
        (import ./hardware/devices/dell-latitude-tablet-7230.nix)
        (import ./hardware/devices/dell-latitude-laptop-7330.nix)
    ])) ;
in
{
  flake = {
    nixosConfigurations =
      builtins.listToAttrs (map (t: lib.nameValuePair t.name (t.hostConfiguration or t.installerImgCfg)) targets);
    packages = {
      x86_64-linux =
        builtins.listToAttrs (map (t: lib.nameValuePair t.name (t.package or t.installerImgDrv)) targets);
    };
  };
}
