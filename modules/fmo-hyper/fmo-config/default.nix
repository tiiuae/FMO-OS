# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{ targetconf }:
{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.services.fmo-config;
  
  hyperConfigServices = {
    portforwarding-service = "";
    monitoring-service = "";
  };

  hyperConfigExtraModules = {
    services = getConfig hyperConfigServices {};
  };

  hyperConfigVM = {
    name = "Unknown";
    ipaddr = "Unknow";
    extraModules = getConfigMerged hyperConfigExtraModules {};
  };

  hyperConfigFMOSystem = {
    alias = "na";
    ipaddr = "na";
    defaultGW = "na";
    dockerCR = "na";
    RAversion = "na";
  };

  hyperConfigSystem = {
    name = "Unknown";
    release = "NA-3";
    vms = getConfigTarget hyperConfigVM {};
    fmo-system = getConfig hyperConfigFMOSystem hyperConfigFMOSystem;
  };

  getConfigTarget = config: default: target: listToAttrs (
    map (
      attr:
        {
          name = "${attr}";
          value = getConfig config default target.${attr};
        }
    ) (builtins.attrNames target)
  );

  getConfigMerged = config: default: target: 
    let 
      merged = builtins.foldl' (acc: elem: acc // elem) {} target;
    in
      getConfig config default merged;


  getConfig = config: default: target: listToAttrs (
    map (
      attr:
        {
          name = "${attr}";
          value = if builtins.typeOf config.${attr} == "lambda"
                  then
                    if (lib.hasAttr "${attr}" target) then (config.${attr} target.${attr}) else default
                  else
                    ifHasAttr target "${attr}" config.${attr};
        }
    ) (builtins.attrNames config)
  );

  hyperSystemConfig = getConfig hyperConfigSystem {} targetconf;

  ifHasAttr = set: attr: default: if lib.hasAttr "${attr}" set then set.${attr} else default;
in {
  options.services.fmo-config = {
    enable = mkEnableOption "FMO configuration store";

    conf-path = mkOption {
      type = types.str;
      description = "Path to store config";
    };
  };

  config = mkIf cfg.enable {
    environment.etc."fmo-config.yaml".source = (pkgs.formats.yaml { }).generate "fmo-config.yaml" hyperSystemConfig;
  };
}
