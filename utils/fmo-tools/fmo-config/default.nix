# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{ targetconf }:
{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.services.fmo-config;

  hyperConfigServices = {
    dynamic-portforwarding-service = {};
    monitoring-service = {};
    fmo-dynamic-device-passthrough = {};
    fmo-dci = {};
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
    alias = "NA";
    ipaddr = "NA";
    defaultGW = "NA";
    dockerCR = "NA";
    RAversion = "NA";
  };

  hyperConfigSystem = {
    name = "Unknown";
    release = "Unknown";
    vms = getConfigTarget hyperConfigVM {};
    fmo-system = getConfig hyperConfigFMOSystem hyperConfigFMOSystem;
  };

  getConfigTarget = config: default: target: field: (
    if lib.hasAttr "${field}" target
    then
      let
        newtarget = target.${field};
      in
        listToAttrs (
          map (
            attr:
              {
                name = "${attr}";
                value = getConfig config default newtarget attr;
              }
          ) (builtins.attrNames newtarget)
        )
    else
      default
  );

  getConfigMerged = config: default: target: field: (
    if lib.hasAttr "${field}" target
    then
      let
        newtarget = target.${field};
        merged = builtins.foldl' (acc: elem: acc // elem) {} target.${field};
      in
        getConfig config default { "${field}" = merged; } field
    else
      default
  );


  getConfig = config: default: target: field: (
    if lib.hasAttr "${field}" target
    then
      let
        newtarget = target.${field};
      in
        listToAttrs (
          map (
            attr:
              {
                name = "${attr}";
                value = if builtins.typeOf config.${attr} == "lambda"
                        then
                          config.${attr} newtarget attr
                        else
                          ifHasAttr newtarget "${attr}" config.${attr};
              }
          ) (builtins.attrNames config)
        )
    else
      default
  );

  hyperSystemConfig = getConfig hyperConfigSystem {} { inherit targetconf; } "targetconf";

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
    environment.systemPackages = [ pkgs.fmo-tool];
    environment.etc."fmo-config.yaml".source = (pkgs.formats.yaml { }).generate "fmo-config.yaml" hyperSystemConfig;
  };
}
