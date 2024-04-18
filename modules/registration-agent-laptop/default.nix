# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
#
{
  pkgs,
  config,
  lib,
  ...
}: with lib;
let
    cfg = config.services.registration-agent-laptop;
in
  with lib; {
    options.services.registration-agent-laptop = {
      enable = mkEnableOption "Install and setup registration-agent on system";

      run_on_boot = mkOption {
        description = mdDoc ''
          Enable registration agent laptop to run on boot.
        '';
        type = types.bool;
        default = false;
       };

      certs_path = mkOption {
        type = types.path;
        default = "/var/fogdata/certs";
        description = "Path to certificate files, used for environment variables";
      };

      config_path = mkOption {
        type = types.path;
        default = "/var/fogdata";
        description = "Path to config file, docker-compose.yml, used for environment variables";
      };

      token_path = mkOption {
        type = types.path;
        default = "/var/fogdata";
        description = "Path to token file, used for environment variables";
      };

      hostname_path = mkOption {
        type = types.path;
        default = "/var/fogdata";
        description = "Path to hostname file, used for environment variables";
      };

      ip_path = mkOption {
        type = types.path;
        default = "/var/fogdata";
        description = "Path to ip file, used for environment variables";
      };

      post_install_path = mkOption {
        type = types.path;
        default = "/var/fogdata/certs";
        description = "Path to certificates after installation";
      };

      env_path = mkOption {
        type = types.path;
        default = "${config.users.users.ghaf.home}";
        description = "Path to create .env file";
      };
    };

    config =  mkIf (cfg.enable) {
        environment.systemPackages = [ pkgs.registration-agent-laptop];

        services.writeToFile = {
          enable = true;
          enabledFiles = [
            "fmo-registration-agent-laptop"
            "fmo-registration-agent-certs"
            "fmo-registration-agent-config"
            "fmo-registration-agent-hostname"
            "fmo-registration-agent-token"
            ];
          file-info = {
            # Write .env file into env_path
            fmo-registration-agent-laptop = {
              source = pkgs.writeTextDir ".env" ''
                AUTOMATIC_PROVISIONING=false
                TLS=true
                PROVISIONING_URL=
                DEVICE_ALIAS=
                DEVICE_IDENTITY_FILE=${cfg.certs_path}/identity.txt
                DEVICE_CONFIGURATION_FILE=${cfg.config_path}/docker-compose.yml
                DEVICE_AUTH_TOKEN_FILE=${cfg.token_path}/PAT.pat
                DEVICE_HOSTNAME_FILE=${cfg.hostname_path}/hostname
                DEVICE_ID_FILE=${cfg.certs_path}/device_id.txt
                FLEET_NATS_LEAF_CONFIG_FILE=${cfg.certs_path}/leaf.conf
                SERVICE_NATS_URL_FILE=${cfg.certs_path}/service_nats_url.txt
                SERVICE_IDENTITY_KEY_FILE=${cfg.certs_path}/identity.key
                SERVICE_IDENTITY_CERTIFICATE_FILE=${cfg.certs_path}/identity.crt
                SERVICE_IDENTITY_CA_FILE=${cfg.certs_path}/identity_ca.crt
                SERVICE_FLEET_LEAF_CERTIFICATE_FILE=${cfg.certs_path}/fleet.crt
                SERVICE_FLEET_LEAF_CA_FILE=${cfg.certs_path}/fleet_ca.crt
                SERVICE_SWARM_KEY_FILE=${cfg.certs_path}/swarm.key
                SERVICE_SWARM_CA_FILE=${cfg.certs_path}/swarm.crt
                IP_ADDRESS_FILE=${cfg.ip_path}/ip-address
                UTM_CLIENT_SECRET_FILE=${cfg.certs_path}/utm-client-secret
                RABBIT_MQ_SECRET_FILE=${cfg.certs_path}/rabbit-mq-secret
                POST_INSTALLATION_DIRECTORY=${cfg.post_install_path}
              '';
              des-path = cfg.env_path;
              permission = "666";
            };

            # Create and set permission of certs_path, config_path, token_path, hostname_path
            # If already created ignore the folder
            fmo-registration-agent-certs = {
              source = "";
              des-path = cfg.certs_path;
            };
            fmo-registration-agent-config = {
              source = "";
              des-path = cfg.config_path;
            };
            fmo-registration-agent-token = {
              source = "";
              des-path = cfg.token_path;
            };
            fmo-registration-agent-hostname = {
              source = "";
              des-path = cfg.hostname_path;
            };
          };
        };

        systemd = {
          # Service that execute registration-agent binary on boot
          services.fmo-registration-agent-execution = mkIf (cfg.run_on_boot) {
            description = "Execute registration agent on boot for registration phase";
            after = [
               "fmo-registration-agent-network-interface.service"
               "network-online.target"
            ];
            requires = [ "network-online.target" ];
            serviceConfig = {
              Type = "oneshot";
              Restart="on-failure";
              RestartSec=5;
              ExecStart = ''
                ${pkgs.bash}/bin/bash -c '${pkgs.registration-agent-laptop}/bin/registration-agent-laptop'
              '';
            };
            wantedBy = [ "multi-user.target" ];
            enable = true;
          };
        };
      };
  }
