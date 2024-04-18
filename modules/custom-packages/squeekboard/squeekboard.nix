# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{pkgs}:
pkgs.writeScriptBin "squeekboard-control" ''
  #${pkgs.bash}/bin/bash
  i=$(busctl --user get-property sm.puri.OSK0 /sm/puri/OSK0 sm.puri.OSK0 Visible)
  echo $i
  if [ "$i" == "b true" ]
  then
  pkill squeekboard
  else
  busctl --user call sm.puri.OSK0 /sm/puri/OSK0 sm.puri.OSK0 SetVisible b true
  fi
  echo "Toggling on-screen keyboard..."
''
