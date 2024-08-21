# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
#
#
{inputs, self, ...}: {   
  flake.nixosModules = {
    fmo-configs.imports = [
      ./packages
      ./fmo-services
     # ./desktop
      ../utils/write-to-file
    ];
    fmo-vm-profiles.imports = [
      ./profiles
    ];
    installer.imports = [
      ./packages
      ./installers
      ./fmo-services
      ../utils/write-to-file
    ];
    ghaf-common.imports = [
      #inputs.ghafOS.nixosModules.hw-x86_64-generic
      inputs.ghafOS.nixosModules.desktop
      inputs.ghafOS.nixosModules.common
    ];
    ghaf-vms.imports = [
      inputs.ghafOS.inputs.microvm.nixosModules.host
      ./virtualization/microvm-host.nix
      #(import "${inputs.ghafOS}/modules/microvm/virtualization/microvm/netvm.nix")
      #(import "${inputs.ghafOS}/modules/microvm/virtualization/microvm/adminvm.nix")
      #(import "${inputs.ghafOS}/modules/microvm/virtualization/microvm/idsvm/idsvm.nix")
      #(import "${inputs.ghafOS}/modules/microvm/virtualization/microvm/idsvm/mitmproxy")
      #(import "${inputs.ghafOS}/modules/microvm/virtualization/microvm/appvm.nix")
      #(import "${inputs.ghafOS}/modules/microvm/virtualization/microvm/audiovm.nix")
      ./virtualization/microvm/modules.nix
      (import "${inputs.ghafOS}/modules/microvm/networking.nix")
      (import "${inputs.ghafOS}/modules/microvm/power-control.nix")

    ];
  };
}
