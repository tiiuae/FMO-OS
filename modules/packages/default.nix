# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
#
# This overlay customizes ghaf packages
#
_: {
  nixpkgs.overlays = [
    (import ./lisgd)
    (import ./nmLauncher)
    (import ./nwg-panel)
    (import ./registration-agent)
    (import ./squeekboard)
    (import ./sway-scripts)
    (import ./terminator)
    (import ./waybar)
  ];
}
