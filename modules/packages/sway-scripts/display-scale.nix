# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{pkgs, ...}:
pkgs.writeShellApplication {
  name = "display-scale";
  runtimeInputs = [
    pkgs.bc
    pkgs.coreutils
    pkgs.jq
    pkgs.sway
  ];
  text = ''
    name="$(swaymsg -t get_outputs | jq -r '.[] | select(.focused==true) | .name')"
    increment=0.25

    function current_scale {
      swaymsg -t get_outputs | jq -r '.[] | select(.focused==true) | .scale'
    }

    function do_scale {
      swaymsg output "\"$name\"" scale "$1"
    }

    case "$1" in
      'up')
        do_scale "$(echo "$(current_scale) + $increment" | bc)"
        ;;
      'down')
        do_scale "$(echo "$(current_scale) - $increment" | bc)"
        ;;
      'default')
        do_scale 1
        ;;
      *)
        current_scale
        ;;
    esac
  '';
}
