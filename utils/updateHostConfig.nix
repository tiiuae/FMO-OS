# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{lib,}: (targetconf:
      [{
        systemd.network = {
          networks."10-virbr0" = lib.mkIf (lib.hasAttr "ipaddr" targetconf) {
            addresses = [
              {
                Address = "${targetconf.ipaddr}/24";
              }
            ];
            routes =  lib.mkIf (lib.hasAttr "defaultgw" targetconf)
              [
                { Gateway = "${targetconf.defaultgw}"; }
              ];
          };
        };
      }]
    )
