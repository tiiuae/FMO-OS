# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.services.dynamic-portforwarding-service;

in {
  options.services.dynamic-portforwarding-service = {
    enable = mkEnableOption "dynamic-portforwarding-service";

    ipaddress-path = mkOption {
      type = types.str;
      description = "Path to ipaddress file for dynamic use";
      default = "";
    };

    config-path = mkOption {
      type = types.str;
      description = "Path to dynamic configuraiton config";
      default = "";
    };

    ipaddress = mkOption {
      type = types.str;
      description = "Static IP address to use instead for dynamic from file";
      default = "";
    };

    configuration = mkOption {
      type = types.listOf types.attrs;
      description = ''
        List of
          {
            dip = destanation IP address,
            sport = source port,
            dport = destanation port,
            proto = protocol (udp, tcp)
          }
      '';
    };

  };

  config = mkIf cfg.enable {
    systemd.services.fmo-dynamic-portforwarding-service = {
      script = ''
          IP=$(${pkgs.gawk}/bin/gawk '{print $1}' ${cfg.ipaddress-path} || echo ${cfg.ipaddress})

          while IFS= read -r line; do
            SRC_IP=$(echo $line | ${pkgs.gawk}/bin/gawk '{print $1}')
            SRC_PORT=$(echo $line | ${pkgs.gawk}/bin/gawk '{print $2}')
            DST_PORT=$(echo $line | ${pkgs.gawk}/bin/gawk '{print $3}')
            DST_IP=$(echo $line | ${pkgs.gawk}/bin/gawk '{print $4}')
            PROTO=$(echo $line | ${pkgs.gawk}/bin/gawk '{print $5}')

            SRC_IP=$([[ "$SRC_IP" = "NA" ]] && echo $IP || echo $SRC_IP)

            echo "Apply a new port forwarding: $SRC_IP:$SRC_PORT to $DST_IP:$DST_PORT proto: $PROTO"
            ${pkgs.iptables}/bin/iptables -I INPUT -p $PROTO --dport $SRC_PORT -j ACCEPT
            ${pkgs.iptables}/bin/iptables -t nat -I PREROUTING -p $PROTO -d $SRC_IP --dport $SRC_PORT -j DNAT --to-destination $DST_IP:$DST_PORT
          done < ${cfg.config-path}
      '';

      wantedBy = ["network.target"];
    };
  };
}
