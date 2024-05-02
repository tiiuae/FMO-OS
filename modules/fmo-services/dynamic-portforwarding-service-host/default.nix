# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.services.fmo-dynamic-portforwarding-service-host;

  mkPortForwardingRules = vmname: path: ''
    ${pkgs.fmo-tool}/bin/fmo-tool dpf rules -r ${vmname} > ${path}

  '';
in {
  options.services.fmo-dynamic-portforwarding-service-host = {
    enable = mkEnableOption "fmo-dynamic-portforwarding-service-host";

    config-paths = mkOption {
      type = types.attrsOf types.str;
      description = "";
      default = {};
    };
  };

  config = mkIf cfg.enable {
    ### host part ###
    systemd.services.fmo-generate-dynamic-portforwarding-rules = {
      script = ''
        ${ lib.concatStrings (lib.attrsets.attrValues (lib.attrsets.mapAttrs (name: value: mkPortForwardingRules name value) cfg.config-paths)) }
      '';

      wantedBy = ["network.target"];
    };
  };
}
