# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.services.fmo-dynamic-device-passthrough;
in {
  options.services.fmo-dynamic-device-passthrough = {
    enable = mkEnableOption "FMO dynamic device passthrough devices";

    devices = mkOption {
      type = types.listOf types.attrs;
      description = ''
        Device list to passthrough
        {
          bus = bus type "usb | pci", only usb is valid for now,
          vendorid = vendorid for device,
          productid = productid for device,
        }
      '';
    };
  };
}
