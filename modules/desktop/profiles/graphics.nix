# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
#
{
  config,
  lib,
  ...
}: let
  cfg = config.ghaf.profiles.graphics;
in
  with lib; {
    config.ghaf.graphics = mkIf cfg.enable {
       weston.enable = lib.mkForce false;
       sway.enable = true;
     };
  }
