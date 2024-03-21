# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
#
#
{inputs, ...}: {   
  flake.nixosModules = {
    fmo-services.imports = [
      ./custom-packages
      ./fmo-dci-service
      ./fmo-hostname-service
      ./portforwarding-service
      ./registration-agent-laptop
      ../utils/write-to-file
    ];
    installer.imports = [
      ./custom-packages
      ./includeOSS
      ./profiles/installer.nix
      ./pterm-installer
      ./registration-agent-laptop
      ./simple-installer
      ../utils/write-to-file
      ];
  };
}
