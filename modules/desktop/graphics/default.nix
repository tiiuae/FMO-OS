# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
#
{
  config,
  lib,
  ...
}:{
  imports = [
    ./plasma6
    ./plasma6/plasma6.nix
    ./sway/sway.nix
    ./sway/sway.ini.nix
    ./fonts.nix
  ];
}
