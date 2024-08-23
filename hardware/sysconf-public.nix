# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
#
# fmo-os-system-configuration-public-version -target
{
  sysconf = {
    extend = "./sysconf.nix";
    suffix = "public";
    extraModules = [
    {
      services = {
        registration-agent-laptop = {
          enable = false;
        }; # services.registration-agent-laptop
      }; # services
    }]; # extraModules;
    vms = {
      dockervm = {
        extraModules = [
        {
          services = {
            registration-agent-laptop = {
              enable = false;
            }; # services.registration-agent-laptop
          }; # services
        }]; # extraModules
      }; # dockervm
    }; # vms
  }; # sysconf
}
