# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{self, ...}: 
{  
  flake.hydraJobs = {
    fmo-os-installer-public-debug.x86_64-linux = self.packages.x86_64-linux.fmo-os-installer-public-debug;
    fmo-os-installer-public-release.x86_64-linux = self.packages.x86_64-linux.fmo-os-installer-public-release;
    fmo-os-rugged-devices-public-debug.x86_64-linux = self.packages.x86_64-linux.fmo-os-rugged-devices-public-debug;
    fmo-os-rugged-devices-public-release.x86_64-linux = self.packages.x86_64-linux.fmo-os-rugged-devices-public-release;
  };
}
