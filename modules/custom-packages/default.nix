# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
#
# This overlay customizes ghaf packages
#
_: {
  nixpkgs.overlays = [
    (import ./nmLauncher)
    (import ./registration-agent)
    (import ./squeekboard)
  ];
}
