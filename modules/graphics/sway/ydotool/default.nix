# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  pkgs,
  lib,
  config,
  ...
}: {
  config = {
    # Environment variable for ydotool
    environment.variables = {
        YDOTOOL_SOCKET="/etc/xdg/ydotool/.ydotool_socket";
    };

    # Create ydotool socket and initialize the service
    systemd.services.ydotoold = {
      description = "Starts ydotoold service";
      after = [ "network.target"  ];
      serviceConfig = {
        Type = "simple";
        Restart="on-failure";
        RemainAfterExit = "yes";
        ExecStartPre = ''
          ${pkgs.coreutils}/bin/mkdir -p /etc/xdg/ydotool
        '';
        ExecStart = ''
          ${pkgs.ydotool}/bin/ydotoold --socket-path="/etc/xdg/ydotool/.ydotool_socket" --socket-own="1000:100"
        '';
      };
      wantedBy = [ "multi-user.target" ];
      enable = true;
    };
  };
}
