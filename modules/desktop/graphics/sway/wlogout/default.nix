# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  pkgs,
  lib,
  config,
  ...
}:
with lib; let
  cfg = config.ghaf.graphics.sway;

  shareDir = "${pkgs.wlogout}/share/wlogout";
  styleCfg = ''
    * {
    	background-image: none;
    }
    window {
    	background-color: rgba(12, 12, 12, 0.8);
    }
    button {
    	color: rgba(180, 180, 180, 0.8);
    	text-decoration-color: rgba(180, 180, 180, 0.8);
      font-family: "Hack";
    	font-size: 22px;
    	font-weight: bold;
    	background-color: rgba(26, 26, 26, 0.8);
    	border-width: 0px;
    	border-style: solid;
    	border-color: rgba(26, 26, 26, 0.8);
    	border-radius: 10px;
    	background-repeat: no-repeat;
    	background-position: center;
    	background-size: 25%;
    	margin: 5px;
    }

    button:focus,
    button:active,
    button:hover {
    	background-color: rgba(50, 0, 160, 0.8);
    	outline-style: none;
    }

    #lock {
    	background-image: image(url("${shareDir}/icons/lock.png"));
    }

    #logout {
    	background-image: image(url("${shareDir}/icons/logout.png"));
    }

    #suspend {
    	background-image: image(url("${shareDir}/icons/suspend.png"));
    }

    #hibernate {
    	background-image: image(url("${shareDir}/icons/hibernate.png"));
    }

    #shutdown {
    	background-image: image(url("${shareDir}/icons/shutdown.png"));
    }

    #reboot {
    	background-image: image(url("${shareDir}/icons/reboot.png"));
    }
  '';
in {
  config = lib.mkIf cfg.enable {
    environment.etc."wlogout/layout" = {
      source = ./layout;
      mode = "0644";
    };
    environment.etc."wlogout/style.css" = {
      text = styleCfg;
      mode = "0644";
    };
  };
}
