# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
#
{
  config,
  lib,
  ...
}: let
  cfg = config.ghaf.profiles.applications;
in
  with lib; {
    config.ghaf = mkIf cfg.enable {
      graphics.enableDemoApplications = lib.mkForce false;
      graphics.app-launchers.enableAppLaunchers = true;
    };
  }
