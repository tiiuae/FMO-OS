# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
(final: _prev: {
  fmo-ota = final.writeShellScriptBin "fmo-ota" ''
          function usage() {
            echo "Usage: $0 [-t <version-tag>/-c <commit-hash>] [-r <absolute-path-to-registration-agent-folder]"; exit 1;
          }
          while getopts ":c:t:r:s:" o; do
              case "''${o}" in
                  c)
                    COMMIT=''${OPTARG}
                    ;;
                  t)
                    TAGS=''${OPTARG}
                    ;;
                  r)
                    REGISTRATION_AGENT=$(realpath ''${OPTARG})
                    ;;
                  s) 
                    HASH="    ''${OPTARG//\//\\/}"
                    ;;
                  *)
                    usage
                    ;;
              esac
          done
          shift $((OPTIND-1))

          LOCAL_SOURCE=/var/host

          if [ -z "''${COMMIT}" ] && [ -z "''${TAGS}" ]; then
            if [ ! -d $LOCAL_SOURCE/FMO-OS ]; then
              echo "Cannot find current system config"
              exit 1
            fi 
            cd $LOCAL_SOURCE/FMO-OS/

            if [ -z "''${REGISTRATION_AGENT}" ]; then
              rm -rf ./modules/packages/registration-agent/RA-local
              cp -R $(registration-agent-laptop -o) ./modules/packages/registration-agent/RA-binary
            else
              if [ ! -d "''${REGISTRATION_AGENT}" ]; then
                echo "Registration Agent path not found"
                exit 1
              fi
              rm -rf ./modules/packages/registration-agent/RA-binary
              mkdir -p ./modules/packages/registration-agent/RA-local
              cp -R ''${REGISTRATION_AGENT}/* ./modules/packages/registration-agent/RA-local
              if [ ! -z "''${HASH}" ]; then
                sed -i "11s/.*/$HASH/" ./modules/packages/registration-agent/registration-agent-laptop-local.nix
              fi 
            fi
            git init
            git add *

            sudo nixos-rebuild switch --flake .#fmo-os-x86_64-debug --accept-flake-config
            if [ $? -eq 0 ]; then
              echo "System update successfully"
            else
              echo "System update failed"
            fi
          
          else
            cd /tmp/
            git clone https://github.com/tiiuae/FMO-OS.git
            cd FMO-OS/
            if [ ! -z "''${TAGS}" ]; then
              git checkout tags/''${TAGS}
              if [ $? -eq 0 ]; then
                  echo "Tag: ''${TAGS} found"
              else
                  echo "Tag: ''${TAGS} not found"
              fi

            else
              if [ ! -z "''${COMMIT}" ]; then
                git checkout ''${COMMIT}
                if [ $? -eq 0 ]; then
                    echo "Commit: ''${TAGS} found"
                else
                    echo "Commit: ''${TAGS} not found"
                fi
              fi
            fi
            if [ -z "''${REGISTRATION_AGENT}" ]; then
              rm -rf ./modules/packages/registration-agent/RA-local
              cp -R $(registration-agent-laptop -o) ./modules/packages/registration-agent/RA-binary
            else
              if [ ! -d "''${REGISTRATION_AGENT}" ]; then
                echo "Registration Agent path not found"
                exit 1
              fi
              rm -rf ./modules/packages/registration-agent/RA-binary
              mkdir -p ./modules/packages/registration-agent/RA-local
              cp -R ''${REGISTRATION_AGENT}/* ./modules/packages/registration-agent/RA-local
              rm -rf ./modules/packages/registration-agent/RA-local/.git
              if [ ! -z "''${HASH}" ]; then
                sed -i "11s/.*/$HASH/" ./modules/packages/registration-agent/registration-agent-laptop-local.nix
              fi 
            fi
            git config --global --add safe.directory $(realpath .)
            git add *

            sudo nixos-rebuild switch --flake .#fmo-os-x86_64-debug --accept-flake-config
            if [ $? -eq 0 ]; then
              echo "System update successfully"
              rm -rf $LOCAL_SOURCE/FMO-OS
              mv /tmp/FMO-OS $LOCAL_SOURCE
            else
              echo "System update failed"
            fi
          fi
        '';
})
