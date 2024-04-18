# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
#
# This overlay customizes ghaf packages
#
_: {
  nixpkgs.overlays = [
    # WAR: libsecret should be removed when the upstream error is fixed
    (import ./libsecret)
    (import ./nmLauncher)
    (import ./nwg-bar)
    (import ./nwg-panel)
    (import ./registration-agent)
    (import ./squeekboard)
  ];
}
