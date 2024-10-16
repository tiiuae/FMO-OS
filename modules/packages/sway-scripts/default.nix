# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
(final: _prev: {
  workspace-switch = import ./workspace-switch.nix {pkgs = final;};
  wob-onscreen-bar = import ./wob-onscreen-bar.nix {pkgs = final;};
  cliphist-rofi-img = import ./cliphist-rofi-img.nix {pkgs = final;};
  display-scale = import ./display-scale.nix {pkgs = final;};
})
