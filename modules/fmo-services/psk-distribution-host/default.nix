# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.services.fmo-psk-distribution-service-host;
in {
  options.services.fmo-psk-distribution-service-host = {
    enable = mkEnableOption "fmo-psk-distribution-service-host";
  };

  config = mkIf cfg.enable {
    ### host part ###
    systemd.services."psk-ssh-keygen" = let
      keygenScript = pkgs.writeShellScriptBin "psk-ssh-keygen" ''
        set -xeuo pipefail
        mkdir -p /run/ssh-keys
        echo -en "\n\n\n" | ${pkgs.openssh}/bin/ssh-keygen -t ed25519 -f /run/ssh-keys/id_ed25519 -C ""
        chown ghaf:ghaf /run/ssh-keys/*
        chmod 600 /run/ssh-keys/*
        cp /run/ssh-keys/id_ed25519.pub /run/ssh-public-key/id_ed25519.pub
        chmod 644 /run/ssh-public-key/id_ed25519.pub
      '';
    in {
      enable = true;
      description = "Generate SSH keys for Waypipe";
      path = [keygenScript];
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        StandardOutput = "journal";
        StandardError = "journal";
        ExecStart = "${keygenScript}/bin/psk-ssh-keygen";
      };
    };

   # This directory needs to be created before any of the microvms start.
    systemd.services."create-ssh-public-key-directory" = let
      script = pkgs.writeShellScriptBin "create-ssh-public-key-directory" ''
        mkdir -pv /run/ssh-public-key
        chown -v microvm /run/ssh-public-key
      '';
    in {
      enable = true;
      description = "Create shared directory on host";
      path = [];
      wantedBy = ["microvms.target"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        StandardOutput = "journal";
        StandardError = "journal";
        ExecStart = "${script}/bin/create-ssh-public-key-directory";
      };
    };
  };
}
