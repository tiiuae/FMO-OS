# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{pkgs, microvmConfig}:
  # FMO: A helper function to generate pci passthrough options in the qemu command
  pkgs.writeShellScriptBin "pci-passthrough-options" ''
      pciDevices=$(cat ${microvmConfig.pciConfigPath})
      for device in $pciDevices; do
        echo -n "-device vfio-pci,host=$device,multifunction=on "
      done
    ''
