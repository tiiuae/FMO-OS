# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.services.fmo-monitor-service;

  genServiceTopic = service: topic: '' ["${service}"]="${topic}" '';
in {
  options.services.fmo-monitor-service = {
    enable = mkEnableOption "fmo-monitor-service";

    nats-ip = mkOption {
      type = types.str;
      description = "NATS ip address";
      default = "";
    };

    nats-port = mkOption {
      type = types.str;
      description = "NATS ip address";
      default = "4222";
    };

    ca-crt-path = mkOption {
      type = types.str;
      description = "Path to CA cert.crt";
      default = "";
    };

   client-key-path = mkOption {
      type = types.str;
      description = "Paths to client's cert.key";
      default = "";
    };

   client-crt-path = mkOption {
      type = types.str;
      description = "Paths to client's cert.crt";
      default = "";
    };

    services = mkOption {
      type = types.listOf types.str;
      description = "Services list to monitor";
      default = "";
    };

    topics = mkOption {
      type = types.listOf types.str;
      description = "Topics to push messages";
      default = "";
    };
  };

  config = mkIf cfg.enable {
    systemd.services."monitor-services" = let
      monitorScript = pkgs.writeShellScriptBin "monitor-services" ''
        set -xeuo pipefail

        NATS_URL="nats://${cfg.nats-ip}:${cfg.nats-port}"

        declare -A SERVICES
        SERVICES=(
          ${ concatStringsSep "\n" (zipListsWith genServiceTopic cfg.services cfg.topics ) }
        )

        for SERVICE in "''${!SERVICES[@]}"; do
          # Get the corresponding NATS topic
          NATS_TOPIC=''${SERVICES[$SERVICE]}

          # Read logs for the service for the last 5 seconds
          LOGS=$(journalctl -u "$SERVICE" --since "5 seconds ago" -o cat)

          # If there are logs, send them to NATS
          if [[ ! -z "$LOGS" ]]; then
            echo "$LOGS" | while IFS= read -r line; do
              # Send each log line to the NATS server
              ${pkgs.natscli}/bin/nats -s "$NATS_URL" --tlsca ${cfg.ca-crt-path} --tlskey ${cfg.client-key-path} --tlscert ${cfg.client-crt-path} pub "$NATS_TOPIC" "$line"
            done
          fi
        done
      '';
    in {
      enable = true;
      description = "Generate encryption certs";
      path = [monitorScript];
      wantedBy = cfg.services;
      serviceConfig = {
        RemainAfterExit = false;
        StandardOutput = "journal";
        StandardError = "journal";
        Restart = "always";
        RestartSec = 5;
        ExecStart = "${monitorScript}/bin/monitor-services";
      };
    };
  };
}
