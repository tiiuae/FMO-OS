# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
(final: _prev: {
  nmLauncher = final.writeShellScriptBin "nmLauncher" ''
          export DBUS_SESSION_BUS_ADDRESS=unix:path=/tmp/ssh_session_dbus.sock
          export DBUS_SYSTEM_BUS_ADDRESS=unix:path=/tmp/ssh_system_dbus.sock
          netvmip=''${1:-192.168.101.1}
          netvmuser=''${2:-ghaf}
          ${final.openssh}/bin/ssh-keygen -R $netvmip
          ${final.openssh}/bin/ssh -M -S /tmp/ssh_control_socket \
              -f -N -q $netvmuser@$netvmip \
              -i /run/ssh-keys/id_ed25519 \
              -o StrictHostKeyChecking=no \
              -o StreamLocalBindUnlink=yes \
              -o ExitOnForwardFailure=yes \
              -L /tmp/ssh_session_dbus.sock:/run/user/1000/bus \
              -L /tmp/ssh_system_dbus.sock:/run/dbus/system_bus_socket
          ${final.networkmanagerapplet}/bin/nm-connection-editor
          # Use the control socket to close the ssh tunnel.
          ${final.openssh}/bin/ssh -q -S /tmp/ssh_control_socket -O exit $netvmuser@$netvmip
        '';
})
