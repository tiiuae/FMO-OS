# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
#
# fmo-os-disabled-for-public -target
{
  sysconf = {
    extend = "./fmo-os-x86_64.nix";
    name = "fmo-os-x86_64-public";
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
