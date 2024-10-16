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
  #inherit (import ../../../lib/icons.nix {inherit pkgs lib;}) svgToPNG;

  timeZone =
    if config.time.timeZone != null
    then config.time.timeZone
    else "UTC";

  mkLauncher = launcher: {
    "custom/${lib.toLower launcher.name}" = {
      interval = "once";
      format = " ";
      on-click = "${launcher.path}";
      tooltip = true;
      tooltip-format = "${launcher.name}";
    };
  };

  mkLauncherCSS = launcher: ''
    #custom-${lib.toLower launcher.name} {
        padding-left: 10px;
        padding-right: 10px;
        background-image: image(url("${launcher.icon}"));
        background-repeat: no-repeat;
        background-position: center;
        background-origin: padding-box;
        background-size: 24px;
    }
  '';

  # Create custom modules for app launchers
  launcherModules = builtins.foldl' lib.recursiveUpdate {} (builtins.map mkLauncher config.ghaf.graphics.app-launchers.launchers);
  launcherCSS = lib.concatStringsSep "\n" (builtins.map mkLauncherCSS config.ghaf.graphics.app-launchers.launchers);

  waybarConfig =
    {
      layer = "top";
      position = "top";
      height = 40;
      reload_style_on_change = true;

      # Add launchers to modules-left
      modules-left =
        [
          "custom/menu"
          "sway/workspaces"
          "idle_inhibitor"
          "custom/clipboard"
        ]
        ++ (builtins.map (launcher: "custom/${lib.toLower launcher.name}") config.ghaf.graphics.app-launchers.launchers);
      modules-center = [
        "wlr/taskbar"
        "sway/mode"
      ];

      modules-right = [
        "sway/language"
        "group/network"
        "group/hardware"
        "tray"
        "clock"
        "custom/power"
      ];

      "custom/menu" = {
        format = "";
        on-click = "swaymsg exec \\$menu";
        tooltip = false;
      };

      "sway/workspaces" = {
        format = "{name}";
        on-click = "activate";
        window-rewrite-default = "{name}";
      };

      "idle_inhibitor" = {
        format = "{icon}";
        format-icons = {
          activated = "";
          deactivated = "";
        };
      };

      "custom/clipboard" = {
        tooltip = false;
        format = "";
        interval = "once";
        #return-type = "json";
        on-click = "swaymsg -q exec '$clipboard'; waybar-signal clipboard";
        on-click-right = "swaymsg -q exec '$clipboard_delete'; waybar-signal clipboard";
        on-click-middle = "clipman clear --all; waybar-signal clipboard";
        #exec = "printf '{\"tooltip\":\"%s\"}' $(cliphist list | wc -l)' item(s) in the clipboard\r(Mid click to clear)'";
        #exec-if = "[[ $(cliphist list | wc -l) -gt 0 ]]";
        signal = 9;
      };

      "wlr/taskbar" = {
        format = "{icon}: {name}";
        icon-size = 32;
        on-click = "minimize-raise";
        on-click-middle = "close";
        on-click-right = "activate";
        tooltip-format = "{title}";
      };

      "sway/mode" = {
        format = "<span style=\"italic\">{}</span>";
        tooltip = false;
      };

      "sway/language" = {
        format = " {short}";
        tooltip-format = "{long}";
        on-click = "swaymsg input type:keyboard xkb_switch_layout next";
        on-scroll-up = "swaymsg input type:keyboard xkb_switch_layout next";
        on-scroll-down = "swaymsg input type:keyboard xkb_switch_layout prev";
        on-click-right = "swaymsg exec squeekboard-control";
      };

      "network" = {
        interval = 5;
        format-wifi = "{icon}";
        format-ethernet = "󰈀";
        format-disconnected = "󰖪";
        format-disabled = "󰀝";
        format-icons = [
          "󰤯"
          "󰤟"
          "󰤢"
          "󰤥"
          "󰤨"
        ];
        tooltip-format = "{icon} {ifname}: {ipaddr}";
        tooltip-format-ethernet = "{icon} {ifname}: {ipaddr}";
        tooltip-format-wifi = "{icon} {ifname} ({essid}): {ipaddr}";
        tooltip-format-disconnected = "{icon} disconnected";
        tooltip-format-disabled = "{icon} disabled";
        on-click = "swaymsg exec nmLauncher";
      };

      "cpu" = {
        interval = 5;
        format = " {usage}%";
        states = {
          warning = 70;
          critical = 90;
        };
      };

      "memory" = {
        interval = 5;
        format = "  {percentage}%";
        tooltip-format = "{used:0.1f}GiB used";
        states = {
          warning = 70;
          critical = 90;
        };
      };

      "battery" = {
        bat = "BAT0";
        states = {
          warning = 25;
          critical = 15;
        };
        interval = 15;
        format = "{icon} {capacity}%";
        format-charging = "󰢟 {capacity}%";
        format-plugged = " {capacity}%";
        format-alt = "{icon} {time}";
        format-icons = [
          ""
          ""
          ""
          ""
          ""
        ];
        tooltip-format = "{timeTo} {power}W";
      };
      "battery#bat2" = {
        bat = "BAT1";
      };

      "group/battery" = {
        drawer = {
          transition-duration = 500;
          transition-left-to-right = false;
        };
        modules = [
          "battery#bat0"
          "battery#bat1"
        ];
        orientation = "horizontal";
      };

      "backlight" = {
        device = "intel_backlight";
        format = "{percent}% {icon}";
        tooltip-format = "Brightness: {percent}%";
        on-scroll-up = "swaymsg exec \\$brightness_up";
        on-scroll-down = "swaymsg exec \\$brightness_down";
        format-icons = ["󰃞" "󰃟" "󰃠"];
      };

      "group/hardware" = {
        drawer = {
          transition-duration = 500;
          transition-left-to-right = false;
        };
        modules = [
          "cpu"
          "memory"
          "backlight"
        ];
        orientation = "horizontal";
      };

      "tray" = {
        icon-size = 21;
        spacing = 5;
      };

      "clock" = {
        interval = 60;
        tooltip = true;
        timezone = "${timeZone}";
        tooltip-format = "<big>{:%B %Y}</big>\n<tt>{calendar}</tt>";
        format = "{:%e %b %Y %H:%M}";
      };

      "custom/power" = {
        format = "⏻";
        tooltip = false;
        on-click = "swaymsg exec \\$powermenu";
      };
    }
    // launcherModules;
in {
  config = lib.mkIf cfg.enable {
    environment.etc."xdg/waybar/config" = {
      text = builtins.toJSON waybarConfig;
      mode = "0644";
    };
    environment.etc."xdg/waybar/style.css" = {
      text = (builtins.readFile ./style.css) + launcherCSS;
      mode = "0644";
    };
  };
}
