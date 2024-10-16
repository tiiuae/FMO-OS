# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
(final: prev: {
  waybar = prev.waybar.overrideAttrs (finalAttrs: previousAttrs: {
    version = "0.11.0";
    src = prev.fetchFromGitHub {
      owner = "Alexays";
      repo = "Waybar";
      rev = "refs/tags/${finalAttrs.version}";
      hash = "sha256-3lc0voMU5RS+mEtxKuRayq/uJO09X7byq6Rm5NZohq8=";
    };
  });
})
#.override {
#  hyprlandSupport = false;
#  jackSupport = false;
#  cavaSupport = false;
#  pulseSupport = false;
#};
