# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  sysconf,
}: {
  lib,
  pkgs,
  ...
}: with lib;
let
  get_launcer = descr: (
  let
    extraArgs = if lib.hasAttr "extraArgs" descr then descr.extraArgs else "";
    launcers_description = {
      weston-terminal = {
       path = "${pkgs.weston}/bin/weston-terminal ${extraArgs}";
       icon = "${pkgs.weston}/share/weston/icon_terminal.png";
      };

      chromium = {
        path = "${pkgs.chromium}/bin/chromium --enable-features=UseOzonePlatform --ozone-platform=wayland ${extraArgs}";
        icon = "${pkgs.chromium}/share/icons/hicolor/24x24/apps/chromium.png";
      };
    };
  in
    launcers_description."${descr.app}"
  );
in {
  ghaf.graphics.weston.enableDemoApplications = lib.mkIf (lib.hasAttr "launchers" sysconf) (lib.mkForce false);
  ghaf.graphics.weston.launchers = lib.mkIf (lib.hasAttr "launchers" sysconf) (map get_launcer sysconf.launchers);
}
