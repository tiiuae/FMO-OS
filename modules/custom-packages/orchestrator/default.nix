# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
(final: _prev: {
  orchestrator = final.writeShellScriptBin "orchestrator" ''
    export DBUS_SESSION_BUS_ADDRESS=unix:path=/tmp/orchestrator_session_dbus.sock
    export DBUS_SYSTEM_BUS_ADDRESS=unix:path=/tmp/orchestrator_system_dbus.sock
    adaptervm_ip=''${1:-192.168.101.12}
    adaptervm_user=''${2:-ghaf}
    ${final.openssh}/bin/ssh-keygen -R $adaptervm_ip
    ${final.openssh}/bin/ssh -M -S /tmp/orchestrator_control_socket \
      -f -N -q $adaptervm_user@$adaptervm_ip \
      -i /run/ssh-keys/id_ed25519 \
      -o StrictHostKeyChecking=no \
      -o StreamLocalBindUnlink=yes \
      -o ExitOnForwardFailure=yes \
      -L /tmp/orchestrator_session_dbus.sock:/run/user/1000/bus \
      -L /tmp/orchestrator_system_dbus.sock:/run/dbus/system_bus_socket
    ${final.terminator}/bin/terminator --execute orchestrate.sh --working-directory /home/$adaptervm_user
    # Use the control socket to close the ssh tunnel.
    ${final.openssh}/bin/ssh -q -S /tmp/orchestrator_control_socket -O exit $adaptervm_user@$adaptervm_ip
  '';
})
