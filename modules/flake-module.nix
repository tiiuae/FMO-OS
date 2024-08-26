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
      ./virtualization/vhotplug
      ../utils/write-to-file
    ];
    installer.imports = [
      ./packages
      ./installers
      ./fmo-services
      ../utils/write-to-file
    ];
    ghaf-common.imports = [
      inputs.ghafOS.nixosModules.hw-x86_64-generic
      inputs.ghafOS.nixosModules.desktop
      inputs.ghafOS.nixosModules.common
    ];
  };
}
