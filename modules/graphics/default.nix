# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
#
{
  config,
  lib,
  ...
}: {
  imports = [
    ./sway/sway.nix
    ./sway/sway.ini.nix
    ./fonts.nix
    ./window-manager.nix
  ];
}
