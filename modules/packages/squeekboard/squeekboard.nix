# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{pkgs}:
pkgs.writeShellApplication {
  name = "squeekboard-control";
  runtimeInputs = [
    pkgs.systemd
  ];
  text = ''
    function isVisible {
      case "$(busctl --user get-property sm.puri.OSK0 /sm/puri/OSK0 sm.puri.OSK0 Visible)" in
        *true*) return 0;;
        *) return 1;;
      esac
    }

    echo "Toggling on-screen keyboard..."

    if isVisible; then
      busctl --user call sm.puri.OSK0 /sm/puri/OSK0 sm.puri.OSK0 SetVisible b false
    else
      busctl --user call sm.puri.OSK0 /sm/puri/OSK0 sm.puri.OSK0 SetVisible b true
    fi
  '';
}
