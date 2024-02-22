# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0

{
  pkgs,
  env_path,
}:
let
  registrationAgentOrig = pkgs.callPackage ./registration-agent-laptop.nix {inherit pkgs;};
in
pkgs.writeScriptBin "registration-agent-laptop" ''
      #${pkgs.bash}/bin/bash
        echo "Usage: $0 register/provision [-e <absolute-path-to-env-file>]"; exit 1;
      }
      
      
      COMMAND=$1
      ENV=$2
      ENV_PATH=$3
      
      
      RED='\033[0;31m'
      GREEN='\033[0;32m'
      NC='\033[0m'
      
      while [[ "$COMMAND" != "register" ]] && [[ "$COMMAND" != "provision" ]]; do
          usage
      done
      
      while [[ ! -z "$ENV" ]]  && ([[ "$ENV" != "-e" ]] || [[ -z "$ENV_PATH" ]]); do
          usage
      done
      
      if [ ! -z "$ENV" ]; then
        if  [[ -f "$ENV_PATH" ]]; then
          env=$ENV_PATH
        else
          echo -e "''${RED}Environment file \"$ENV_PATH\" does not exist''${NC}"
        fi
      else
        env=${env_path}/.env
      fi

      echo -e "Use environment variables located at ''${GREEN}$env''${NC} and option ''${GREEN}$COMMAND''${NC}"
      export $(cat "''${env}")
      ${registrationAgentOrig}/bin/registration-agent-laptop-orig $COMMAND
      ''