# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0

{
  pkgs,
  env_path,
}:
let
  registrationAgentOrig = if (builtins.pathExists ./RA-local) then
                            pkgs.callPackage ./registration-agent-laptop-local.nix {inherit pkgs;} else
                            ( if (builtins.pathExists ./RA-binary) then
                                pkgs.callPackage ./registration-agent-laptop-binary.nix {inherit pkgs;} else
                                pkgs.callPackage ./registration-agent-laptop-git.nix {inherit pkgs;});
in
pkgs.writeScriptBin "registration-agent-laptop" ''
      #${pkgs.bash}/bin/bash
      function usage() {
        echo "Usage: $0 [-e <absolute-path-to-env-file>]"; exit 1;
      }
      while getopts ":e:o" o; do
          case "''${o}" in
              e)
                  env=''${OPTARG}
                  ;;
              o)
                  echo -n "${registrationAgentOrig}/bin/registration-agent-laptop-orig"
                  exit 1
                  ;;
              *)
                  usage
                  ;;
          esac
      done
      shift $((OPTIND-1))

      if [ -z "''${env}" ]
      then
        if [ -f /home/ghaf/.env ]
        then 
          env=/home/ghaf/.env
        else
          env=${env_path}/.env
        fi
      fi

      echo "Use environment variables located at ''${env}"
      export $(cat "''${env}")
      ${registrationAgentOrig}/bin/registration-agent-laptop-orig
      ''