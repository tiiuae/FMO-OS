# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.ghaf.graphics.sway;
  mkLauncherModule = (launcher:
    "button-${lib.strings.toLower launcher.name}");

  mkLauncher = (launcher:
    {
    "button-${lib.strings.toLower launcher.name}" =  {
          command =  "${launcher.path}";
          icon = "${launcher.icon}";
          label = "";
          label-position = "bottom";
          tooltip = "${launcher.name}";
          css-name = "";
          icon-size = 36;
        };
    });

  mkLaunchers = builtins.map mkLauncher;
  mkLauncherModules = builtins.map mkLauncherModule;

  # Read config for top and bottom panel
  panelTopConfig = builtins.elemAt (builtins.fromJSON ( builtins.readFile ./config)) 0;
  panelBottomConfig = builtins.elemAt (builtins.fromJSON ( builtins.readFile ./config)) 1;

  # Create launchers for app-launchers and place them in module-left
  launcherIcons = builtins.foldl' lib.recursiveUpdate {} (mkLaunchers config.ghaf.graphics.app-launchers.launchers);

  # Create power button and place it in module-right
  powerIcons =  {
    button-power = {
      command =  "nwg-bar";
      icon = "${../../assets/system-shutdown-symbolic.svg}";
      label = "";
      label-position = "bottom";
      tooltip = "Power Menu";
      css-name = "";
      icon-size = 36;
    };
  };

  # Create keyboard button and place it in module-right
  keyboardIcons =  {
    button-keyboard = {
      command =  "squeekboard-control";
      icon = "${../../assets/keyboard.png}";
      label = "";
      label-position = "bottom";
      tooltip = "Keyboard";
      css-name = "";
      icon-size = 36;
    };
  };
   # Create next and prev buttons and place them in module-right
  wsSwitchIcons =  {
    button-ws-next = {
      command =  "${pkgs.workspace-switch}/bin/workspace-switch window next; ${pkgs.workspace-switch}/bin/workspace-switch next";
      icon = "${../../assets/arrow-circle-right-svgrepo-com.svg}";
      label = "";
      label-position = "bottom";
      tooltip = "Next";
      css-name = "";
      icon-size = 36;
    };
    
    button-ws-prev = {
      command =  "${pkgs.workspace-switch}/bin/workspace-switch window prev; ${pkgs.workspace-switch}/bin/workspace-switch prev";
      icon = "${../../assets/arrow-circle-left-svgrepo-com.svg}";
      label = "";
      label-position = "bottom";
      tooltip = "Prev";
      css-name = "";
      icon-size = 36;
    };

    button-win-kill = {
      command =  "swaymsg kill";
      icon = "${../../assets/close-circle-svgrepo-com.svg}";
      label = "";
      label-position = "bottom";
      tooltip = "Window close";
      css-name = "";
      icon-size = 36;
    };
  };

  panel-top-modules = {
    modules-left = (mkLauncherModules config.ghaf.graphics.app-launchers.launchers);
  };

  panel-bottom-modules = {
    modules-left = [ "button-keyboard" "sway-taskbar"];
    modules-right = [ "button-ws-prev" "button-ws-next" "button-win-kill" "button-power" ];
  };

  panelConfig = builtins.toJSON [
                  (panelTopConfig // launcherIcons
                    // panel-top-modules)

                  (panelBottomConfig // powerIcons // keyboardIcons // wsSwitchIcons
                    // panel-bottom-modules)
                  ];

  panelConfigFile =  pkgs.writeTextDir "config" panelConfig;

in {

  config =  lib.mkIf cfg.enable {
    services.upower.enable = true;
    environment.etc."xdg/nwg-panel/config" = {
      text = panelConfig;
      # The UNIX file mode bits
      mode = "0644";
    };

    environment.etc."xdg/nwg-panel/style.css" = {
      source = ./style.css;
      # The UNIX file mode bits
      mode = "0644";
    };

    environment.systemPackages = with pkgs;
      [
        gopsuinfo
        nwg-panel
        brightnessctl
        nwg-bar
      ];

  };
}
