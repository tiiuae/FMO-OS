# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
#
# FMO PCI-device maps for rugged devices
{
  # Device information of Dell Rugged Tablet 7230
  "0BB7 Latitude 7230 Rugged Extreme Tablet" = {
    touchDevices = [
      "3823:49156:EETI8082:00_0EEF:C004"
    ];
    pciDevices = {
      netvm =  [
          "0000:00:14.3"
          ];
      dockervm = [];
    };
  };
  # Device information of Dell Rugged Laptop 7330
  "0A9E Latitude 7330 Rugged Extreme" = {
    touchDevices = [
      "3823:49155:CUST0000:00_0EEF:C003"
    ];
    pciDevices = {
      netvm = [
        "0000:72:00.0"
        "0000:00:1f.0"
        "0000:00:1f.3"
        "0000:00:1f.4"
        "0000:00:1f.5"
        "0000:00:1f.6"
      ];
      dockervm = [];
    };
  };
}
