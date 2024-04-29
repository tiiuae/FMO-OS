# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
#
#
{inputs, ...}: {   
  flake.nixosModules = {
    fmo-configs.imports = [
      ./packages
      ./fmo-services
      ./desktop
      ../utils/write-to-file
    ];
    installer.imports = [
      ./packages
      ./installers
      ./fmo-services
      ../utils/write-to-file
      ];
  };
}
