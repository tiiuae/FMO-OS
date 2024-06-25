# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.services.fmo-certs-distribution-service-host;

  mkClintCert = client-path: n: ''
    echo "Generate private key for the client-${n}"
    ${pkgs.openssl}/bin/openssl genpkey -algorithm RSA -out ${client-path}/client.key
    echo "Create a certificate signing request (CSR) for the client-${n}"
    ${pkgs.openssl}/bin/openssl req -new -key ${client-path}/client.key -out ${client-path}/client.csr -subj "/CN=client-${n}"
    echo "Sign the client CSR with the CA certificate-${n}"
    ${pkgs.openssl}/bin/openssl x509 -req -in ${client-path}/client.csr -CA ${cfg.ca-path}/ca.crt -CAkey ${cfg.ca-path}/ca.key \
      -CAcreateserial -out ${client-path}/client.crt -days 365 -sha256
  '';

  addIP = ip: "IP: ${ip}";


  numOfClients = genList (i: toString i) (length cfg.clients-paths);

in {
  options.services.fmo-certs-distribution-service-host = {
    enable = mkEnableOption "fmo-certs-distribution-service-host";

    ca-name = mkOption {
      type = types.str;
      description = "CA name";
      default = "";
    };

    ca-path = mkOption {
      type = types.str;
      description = "Path to generate CA cert";
      default = "";
    };

    server-name =  mkOption {
      type = types.str;
      description = "Server name";
      default = ["127.0.0.1"];
    };

    server-path = mkOption {
      type = types.str;
      description = "Path to generate server cert";
      default = "";
    };

    server-ips = mkOption {
      type = types.listOf types.str;
      description = "Server allowed IPs";
      default = "";
    };

   clients-paths = mkOption {
      type = types.listOf types.str;
      description = "Paths to generate clients certs";
      default = "";
    };
  };

  config = mkIf cfg.enable {
    systemd.services."openssl-certs-gen" = let
      keygenScript = pkgs.writeShellScriptBin "openssl-certs-gen" ''
        set -xeuo pipefail

        EXT_CONF="basicConstraints=CA:FALSE
                 keyUsage=digitalSignature,keyEncipherment
                 extendedKeyUsage=serverAuth
                 subjectAltName=${ concatStringsSep ", " (map addIP cfg.server-ips) }"

        echo "Create CA dir"
        mkdir -pv ${cfg.ca-path}
        # chown -v microvm ${cfg.ca-path}

        echo "Create Server cert dir"
        mkdir -pv ${cfg.server-path}
        # chown -v microvm ${cfg.server-path}

        echo "Create Clients certs dirs"
        for path in ${ concatStringsSep " " cfg.clients-paths }; do
          mkdir -pv $path
          # chown -v microvm $path
        done

        echo "Generate private key for CA"
        ${pkgs.openssl}/bin/openssl genpkey -algorithm RSA -out ${cfg.ca-path}/ca.key
        echo "Generate self-signed CA certificate"
        ${pkgs.openssl}/bin/openssl req -x509 -new -nodes -key ${cfg.ca-path}/ca.key -sha256 -days 365 -out ${cfg.ca-path}/ca.crt \
          -subj "/CN=${cfg.ca-name}"

        echo "Generate private key for the server"
        ${pkgs.openssl}/bin/openssl genpkey -algorithm RSA -out ${cfg.server-path}/server.key
        echo "Create a certificate signing request (CSR) for the server"
        ${pkgs.openssl}/bin/openssl req -new -key ${cfg.server-path}/server.key -out ${cfg.server-path}/server.csr \
          -subj "/CN=${cfg.server-name}" \
          -addext "subjectAltName=IP:192.168.101.111,IP:127.0.0.1"
        echo "Sign the server CSR with the CA certificate"
        ${pkgs.openssl}/bin/openssl x509 -req -in ${cfg.server-path}/server.csr -CA ${cfg.ca-path}/ca.crt -CAkey ${cfg.ca-path}/ca.key \
          -CAcreateserial -out ${cfg.server-path}/server.crt -days 365 -sha256 \
            -extfile <(printf "$EXT_CONF")

        echo "Generate certs for clients"
        ${ concatStringsSep "\n" (zipListsWith mkClintCert cfg.clients-paths numOfClients) }
      '';
    in {
      enable = true;
      description = "Generate encryption certs";
      path = [keygenScript];
      wantedBy = ["microvms.target"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        StandardOutput = "journal";
        StandardError = "journal";
        ExecStart = "${keygenScript}/bin/openssl-certs-gen";
      };
    };
  };
}
