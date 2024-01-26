# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0

{pkgs, 
config,
lib,
systemImgCfg,
...}: with lib;
let 
  cfg = config.installer.includeOSS;
in
{
  options.installer.includeOSS = {
    enable = mkEnableOption "Build and enable installer script";

    oss_list_fname = mkOption {
      type = types.str;
      description = "OSS list file name, will be placed in /etc/";
      default = "installer_os_list";
    };

    systems = mkOption {
      type = with types; listOf (submodule {
        options = {  
          name = mkOption {
            type = types.str;
            description = "Name of the image";
            default = null;
          };   
          image = mkOption {
            type = types.attrs;
            description = "Image configuration";
            default = null;
          };     
        };
      });
      default = [];
    };
  };

  config.environment = mkIf (cfg.enable && cfg.systems != []) (   
  let
    imageText = map (system: "${system.name};${system.image.config.system.build.${system.image.config.formatAttr}}/nixos.img") cfg.systems; 
    imageListText = builtins.concatStringsSep "\n" imageText;
  in {
      etc."${cfg.oss_list_fname}" = {
        source = let
          script = pkgs.writeTextDir "etc/${cfg.oss_list_fname}" ''
            ${imageListText}
          '';
        in "${script}/etc/${cfg.oss_list_fname}";
        mode = "0555";
      };
  });
}
