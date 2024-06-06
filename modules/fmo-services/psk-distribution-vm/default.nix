# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.services.fmo-psk-distribution-service-vm;
in {
  options.services.fmo-psk-distribution-service-vm = {
    enable   = mkEnableOption "fmo-psk-distribution-service-vm";
  };

  config = mkIf cfg.enable {
    ### vm part ###
    # SSH is very picky about the file permissions and ownership and will
    # accept neither direct path inside /nix/store or symlink that points
    # there. Therefore we copy the file to /etc/ssh/get-auth-keys (by
    # setting mode), instead of symlinking it.
    environment.etc."ssh/get-auth-keys" = {
      source = let
        script = pkgs.writeShellScriptBin "get-auth-keys" ''
          [[ "$1" != "ghaf" ]] && exit 0
          ${pkgs.coreutils}/bin/cat /run/ssh-public-key/id_ed25519.pub
        '';
      in "${script}/bin/get-auth-keys";
      mode = "0555";
    };
    services.openssh = {
      authorizedKeysCommand = "/etc/ssh/get-auth-keys";
      authorizedKeysCommandUser = "nobody";
    };
  };
}
