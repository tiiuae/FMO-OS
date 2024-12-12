# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
#
# fmo-os-disabled-for-public -target
{
  sysconf = {
    extend = "./fmo-os-rugged-devices.nix";
    name = "fmo-os-rugged-devices-public";
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
