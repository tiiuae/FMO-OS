
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.networking.loadProfiles;

in
{
  ###### interface
  options = {
    services.networking.loadProfiles = {
      enable = mkEnableOption "load network manager profiles";
      profileList = mkOption {
        description = "List of profiles";
        default = [];
        type = with types; listOf str;
      };
    };
  };

  config = mkIf cfg.enable {
    systemd.services.networkProfiles = {
      script = let
          profileList=concatStringsSep " " cfg.profileList;
        in  ''
        PROFILE_LIST=${profileList}
        EXIT_CODE=0

        ${pkgs.networkmanager}/bin/nmcli connection reload
        for PROFILE in $PROFILE_LIST
        do
          CONNECTION_STATE=$(${pkgs.networkmanager}/bin/nmcli -g GENERAL.STATE c s $PROFILE|grep -q -E '\bactiv';echo "''${?}")
          if [[ "$CONNECTION_STATE" == '0' ]]; then
            continue
          fi
          ${pkgs.networkmanager}/bin/nmcli connection up $PROFILE
          if [ $? -ne 0 ]; then
              EXIT_CODE=1
          fi
        done
        exit $EXIT_CODE
      '';
      serviceConfig = {
        Type = "simple";
        Restart="on-failure";
        RestartSec=5;
      };
      wantedBy = [ "multi-user.target" ];
      enable = true;
    };
  };
}
