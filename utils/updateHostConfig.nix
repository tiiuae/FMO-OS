# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
rec {
  updateHostConfig = 
    {lib, targetconf}:
    [
      {
        systemd.network = {
          networks."10-virbr0" = lib.mkIf (lib.hasAttr "ipaddr" targetconf) {
            addresses = [
              {
                addressConfig.Address = "${targetconf.ipaddr}/24";
              }
            ];
            routes =  lib.mkIf (lib.hasAttr "defaultgw" targetconf)
              [
                { routeConfig.Gateway = "${targetconf.defaultgw}"; }
              ];
          };
        };
      }
    ];
}
