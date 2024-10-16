# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{pkgs, ...}:
pkgs.writeShellApplication {
  name = "workspace-switch";
  runtimeInputs = [
    pkgs.sway
  ];
  text = ''
    current_workspace="$(swaymsg -p -t get_workspaces|grep focused|grep -o "[0-9]")"

    if [[ "$1" = "window" ]]; then
    	category="swaymsg move window to workspace"
    	shift
    else
    	category="swaymsg workspace number"
    fi

    if [[ "$1" = "next" ]]; then
      [[ $current_workspace -eq 9 ]] && exit 1
    	$category $((current_workspace + 1))
    	swaymsg workspace number $((current_workspace + 1))
    elif [[ "$1" = "prev" ]]; then
      [[ $current_workspace -eq 1 ]] && exit 1
    	$category $((current_workspace - 1))
    	swaymsg workspace number $((current_workspace - 1))
    fi
  '';
}
