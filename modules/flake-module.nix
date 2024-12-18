# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
#
#
{inputs, ...}: {   
  flake.nixosModules = {
    # Common fmo services/ultilities
    fmo-common.imports = [
      inputs.ghafOS.nixosModules.common
      ./packages
      ../utils/write-to-file
    ];

    # fmo services/ultilities that runs only on host
    fmo-host.imports = [
      inputs.ghafOS.nixosModules.hw-x86_64-generic
      inputs.ghafOS.nixosModules.host
      inputs.ghafOS.nixosModules.desktop
      ./fmo-services/host-services.nix
      ./profiles/x86.nix
      ./desktop
      ./hardwareInfo
    ];

    # fmo services/ultilities that runs only on VMs
    fmo-vm.imports = [
      ./fmo-services/vm-services.nix
    ];

    microvm.imports = let
      override_input = inputs.ghafOS.inputs // {
        self.nixosModules = inputs.ghafOS.nixosModules;
      };
      in [
        inputs.ghafOS.inputs.microvm.nixosModules.host
        (import "${inputs.ghafOS}/modules/microvm/networking.nix")
        (import "${inputs.ghafOS}/modules/microvm/virtualization/microvm/microvm-host.nix" {inputs=override_input;})
        # WAR: ghaf mainline has audiovm hardcoded. This causes audiovm defined here
        # This should be removed when audiovm on ghaf mainline is fixed.
        # JIRA: FMO-43 for monitoring this issue.
        (import "${inputs.ghafOS}/modules/microvm/virtualization/microvm/audiovm.nix" {inputs=override_input;})
        (import "${inputs.ghafOS}/modules/microvm/virtualization/microvm/guivm.nix" {inputs=override_input;})
      ];
    installer.imports = [
      ./installers
      ./fmo-services/registration-agent-laptop
    ];
  };
}
