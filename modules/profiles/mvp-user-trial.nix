# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  config,
  lib,
  ghafOS,
  ...
}: let
  cfg = config.ghaf.profiles.mvp-user-trial;
in {
  imports = [
    (import "${ghafOS}/modules/reference/appvms")
    (import "${ghafOS}/modules/reference/programs")
    (import "${ghafOS}/modules/reference/services")
  ];

  options.ghaf.profiles.mvp-user-trial = {
    enable = lib.mkEnableOption "Enable the mvp configuration for apps and services";
  };

  config = lib.mkIf cfg.enable {
    ghaf = {
      #reference = {
      #  #appvms = {
      #  #  enable = true;
      #  #  chromium-vm = true;
      #  #  gala-vm = true;
      #  #  zathura-vm = true;
      #  #  element-vm = true;
      #  #  appflowy-vm = true;
      #  #  business-vm = true;
      #  #};
#
      #  services = {
      #    enable = true;
      #    dendrite = true;
      #  };
#
      #  programs = {
      #    windows-launcher = {
      #      enable = false;
      #      spice = false;
      #    };
      #  };
      #};

      profiles = {
        laptop-x86 = {
          enable = true;
          netvmExtraModules = ["${ghafOS}/modules/reference/services"];
          guivmExtraModules = ["${ghafOS}/modules/reference/programs"];
          #inherit (config.ghaf.reference.appvms) enabled-app-vms;
        };
      };
    };
  };
}
