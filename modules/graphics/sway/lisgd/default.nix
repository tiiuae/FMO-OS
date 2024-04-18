# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.ghaf.graphics.sway;

  lisgd = pkgs.lisgd.overrideAttrs (_oldAttrs: {
    postPatch = ''
      cp ${./config} config.def.h
    '';
  });
in {
  config = lib.mkIf cfg.enable {
    users.users."ghaf".extraGroups = ["input"];
    environment.systemPackages = [
      lisgd
    ];
  };
}
