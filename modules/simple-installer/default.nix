# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  lib,
  pkgs,
  config,
  ...
}:
with lib; let
  cfg = config.installer.simple-installer;
in {
  options.installer.simple-installer = {
    enable = mkEnableOption "simple-installer reference implementation";

    oss_path = mkOption {
      type = types.str;
      description = "Path to installer_os_list file";
    };

    welcome_msg = mkOption {
      type = types.str;
      description = "Welcome message to show";
      default = "Welcome to simple-installer";
    };

    run_on_boot = mkOption {
      description = "Enable installing script to run on boot";
      type = types.bool;
      default = false;
    };

    extraArgs = mkOption {
      type = types.listOf types.str;
      description = "List of extraArgs to pass into the script";
      example = "['-r sd*', '-m Override message']";
    };
  };

  config.environment = mkIf cfg.enable (
    let
      simple-installer = pkgs.writeShellScriptBin "simple-installer" ''
        function usage () {
          echo "Usage: $(basename $0) [-f installer_os_list file] [-r regexp for /dev/] [-m welcome message] "
          exit 1
        }

        while getopts 'f:r:h' opt; do
          case "$opt" in
            f)
              OSSFILE="$OPTARG"
              ;;

            r)
              REGEXPS="$OPTARG"
              ;;

            m)
              MSG="$OPTIND"
              ;;

            h)
              usage
              ;;

            :)
              echo -e "Option requires an argument"
              usage
              ;;

            ?)
              echo -e "Invalid command option"
              usage
              ;;
          esac
        done
        shift "$(($OPTIND -1))"

        if [ -z "$OSSFILE" ]
        then
          echo -e "no installer_os_list file have been provided"
          usage
        fi

        if [ -z "$REGEXPS" ]
        then
          REGEXPS="nvme.n.$"
        fi

        if [ -z "$MSG" ]
        then
          MSG="${cfg.welcome_msg}"
        fi

        OSS=$(cat $OSSFILE 2> /dev/null) || { echo "can't read file: '$OSSFILE' exit..."; exit 1; }

        DEVS=$(ls /dev 2> /dev/null | grep $REGEXPS) || { echo "can't find devices: '$REGEXPS' exit..."; exit 1; }

        echo ""
        echo ""
        echo "$MSG"

        for OS in $OSS
        do
          OSNAME=$(echo $OS | cut -d ";" -f 1) || { echo "wrong file format exit"; exit 1; }
          OSPATH=$(echo $OS | cut -d ";" -f 2) || { echo "wrong file format exit"; exit 1; }
          echo ""
          echo ""
          echo "found OS: $OSNAME"
          echo "path: $OSPATH"
          echo "possible installation cmds:"

          for DEV in $DEVS
          do
            echo "sudo dd if=$OSPATH of=/dev/$DEV bs=4M conv=fsync status=progress"
          done
        done
      '';
    in {
      systemPackages = [simple-installer];
      loginShellInit = mkIf cfg.run_on_boot ''${simple-installer}/bin/simple-installer -f ${cfg.oss_path}'';
    }
  );
}
