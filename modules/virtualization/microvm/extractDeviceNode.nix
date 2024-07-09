# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{pkgs}: pkgs.writeShellScriptBin "getDeviceNode" ''
    #${_prev.bash}/bin/bash

    v=''${1%:*}; p=''${1#*:}  # split vid:pid into 2 vars
    v=''${v#''${v%%[!0]*}}; p=''${p#''${p%%[!0]*}}  # strip leading zeros
    udevadm info --export-db |
    sed 's|^[^=]*DEVNAME=||
         \|^[^/]|!h;/MAJOR=/N
         \|='"$v\n.*=$p"'$|!d;g'
        ''

