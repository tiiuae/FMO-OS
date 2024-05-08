# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{_prev}:
  _prev.writeShellScriptBin "workspace-switch" ''
    #${_prev.bash}/bin/bash

    current_workspace=$(swaymsg -p -t get_workspaces|grep focused|grep -o "[0-9]")

    if [ "$1" = "window" ]; then
    	category="${_prev.sway}/bin/swaymsg move window to workspace"
    	shift
    else
    	category="${_prev.sway}/bin/swaymsg workspace number"
    fi

    if [ "$1" = "next" ]; then
    	test $current_workspace -eq 9 && exit 1
    	$category $((current_workspace + 1))
    	swaymsg workspace number $((current_workspace + 1))
    elif [ "$1" = "prev" ]; then
    	test $current_workspace -eq 1 && exit 1
    	$category $((current_workspace - 1))
    	swaymsg workspace number $((current_workspace - 1))
    fi
        ''

