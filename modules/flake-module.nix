# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
#
#
{inputs, ...}: {   
  flake.nixosModules = {
    host-configs.imports = [
      inputs.ghafOS.nixosModules.hw-x86_64-generic
      inputs.ghafOS.nixosModules.host
      inputs.ghafOS.nixosModules.desktop
      ./profiles/x86.nix
      ./desktop
    ];
    microvm.imports = [
      inputs.ghafOS.inputs.microvm.nixosModules.host
      (import "${inputs.ghafOS}/modules/microvm/networking.nix")
      (import "${inputs.ghafOS}/modules/microvm/virtualization/microvm/microvm-host.nix")
      # WAR: ghaf mainline has audiovm hardcoded. This causes audiovm defined here
      # This should be removed when audiovm on ghaf mainline is fixed.
      # JIRA: FMO-43 for monitoring this issue.
      (import "${inputs.ghafOS}/modules/microvm/virtualization/microvm/audiovm.nix")
    ];
    fmo-common.imports = [
      inputs.ghafOS.nixosModules.common
      ./packages
      ./fmo-services
      ../utils/write-to-file
    ];
    installer.imports = [
      ./installers
    ];
  };
}
