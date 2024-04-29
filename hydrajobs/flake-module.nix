# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{self, ...}: 
{  
  flake.hydraJobs = {
    fmo-os-installer-public-debug.x86_64-linux = self.packages.x86_64-linux.fmo-os-installer-public-debug;
    fmo-os-installer-public-release.x86_64-linux = self.packages.x86_64-linux.fmo-os-installer-public-release;
    fmo-os-rugged-laptop-7330-public-debug.x86_64-linux = self.packages.x86_64-linux.fmo-os-rugged-laptop-7330-public-debug;
    fmo-os-rugged-laptop-7330-public-release.x86_64-linux = self.packages.x86_64-linux.fmo-os-rugged-laptop-7330-public-release;
    fmo-os-rugged-tablet-7230-public-debug.x86_64-linux = self.packages.x86_64-linux.fmo-os-rugged-tablet-7230-public-debug;
    fmo-os-rugged-tablet-7230-public-release.x86_64-linux = self.packages.x86_64-linux.fmo-os-rugged-tablet-7230-public-release;
  };
}
