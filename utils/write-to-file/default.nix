# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0

{
  pkgs,
  config,
  lib,
  ...
}: with lib;
let
  cfg = config.services.writeToFile;
    
in
{
  options.services.writeToFile = {
    enable = mkEnableOption "Include optional files";

    enabledFiles = mkOption {
      description = mdDoc ''
        Sequence of enabled modules.
      '';
      type = with types; listOf(str);
      default = [];
    };

    file-info = mkOption{
      type = with types; attrsOf (submodule {
        options = {  
          source = mkOption {
            type = types.oneOf [types.str  types.path types.attrs];
            description = "Path to source file to copy";
            default = "";
          };          
          des-path  = mkOption {
            type = types.path;
            default = "${config.users.users.ghaf.home}";
            description = "Path to paste output files";
          };
          write-once = mkOption {
            type = types.bool;
            default = false;
            description = "Files is rewritten on every boot unless set this to true";
          };
          owner  = mkOption {
            type = types.nullOr types.str;
            default = "root";
            description = "Owner of newly created destination folder";
          };
          permission  = mkOption {
            type = types.str;
            default = "";
            description = "File permission";
          };
        };
      });
      };
  };

  config.systemd =  mkIf (cfg.enable && cfg.enabledFiles != []) (
        let
          systemdConfig = map (filename:  
            let 
              src = cfg.file-info.${filename}.source;
              write-once = lib.boolToString cfg.file-info.${filename}.write-once; 
              permission = if ("${cfg.file-info.${filename}.permission}" != "")
                           then "-m " + "${cfg.file-info.${filename}.permission}"
                           else cfg.file-info.${filename}.permission;              
              owner = if ("${cfg.file-info.${filename}.owner}" != "root")
                      then "-o " + "${cfg.file-info.${filename}.owner} " + "-g users"
                      else cfg.file-info.${filename}.owner;
              src-data = (if (builtins.typeOf src == "set") then "${src.outPath}" 
                          else "${src}") ;
              # Needing adding file name when not directory
              des = if ("${src}" == "") 
                    then ( cfg.file-info.${filename}.des-path )
                    else (if (builtins.readFileType src-data == "directory") 
                          then "${cfg.file-info.${filename}.des-path}"
                          else ("${cfg.file-info.${filename}.des-path}"));
              mindepth = (if ("${src}" == "") 
                        then ( "0")
                        else (if (builtins.readFileType src-data == "directory") then "1" else "0"));

            in {
              services.${filename} = {  
                description = ''
                  Copy/Create "${filename}" files to "${des}" folder and set permission
                  '';
                script = ''
                    FILE_NAME="${filename}"
                    SRC="${src-data}"
                    DES="${des}"
                    DEPTH="${mindepth}"
                    EXECUTE_ONCE="${write-once}"
                    OWNER="${owner}"
                    PERMISSION="${permission}"
                    if [ "$EXECUTE_ONCE" == "true" ]
                    then
                    	FLAG="/var/log/$FILE_NAME.log"
                    	if [[ -f $FLAG ]]; then
                    		exit
                    	else
                    		touch "$FLAG"
                    	fi
                    fi

                    if [ ! -d "$DES" ]
                    then
                      ${pkgs.coreutils}/bin/install -d $OWNER $DES
                    fi

                    if [ ! -z "$SRC" ]
                    then
                      ${pkgs.findutils}/bin/find $SRC -mindepth $DEPTH -exec install $OWNER $PERMISSION {} $DES \;
                    fi
                    exit
                  '';
                serviceConfig = 
                   { Type = "oneshot";};
                
                wantedBy = [ "multi-user.target" ]; 
                enable = true;
              };
            }
          ) cfg.enabledFiles;  
    in
    builtins.foldl' recursiveUpdate {}  systemdConfig    
  );
    
}
    