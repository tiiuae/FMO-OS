# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  config,
  pkgs,
  lib,
  ...
}:
with lib; let
  cfg = config.ghaf.graphics.sway;

  # This configuration system is adapted from Nix Home-Manager.
  # This is strongly in WIP stage.
  # https://github.com/nix-community/home-manager/tree/master/modules/services/window-managers/i3-sway

  swayConfigModule = types.submodule {
    options = {
      modifierKey = mkOption {
        type = types.enum ["Shift" "Control" "Mod1" "Mod2" "Mod3" "Mod4" "Mod5"];
        default = "Mod1";
        description = ''
          Modifier key that is used for all default keybindings.
        '';
      };

      modifierAlias = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to insert literal modifier key in the Sway config.
          If true, the key is inserted to config as is, otherwise
          the modifier key is aliased to '$mod' variable.
        '';
      };

      leftKey = mkOption {
        type = types.str;
        default = "h";
        description = "Home row direction key for moving left.";
      };

      rightKey = mkOption {
        type = types.str;
        default = "l";
        description = "Home row direction key for moving right.";
      };

      upKey = mkOption {
        type = types.str;
        default = "k";
        description = "Home row direction key for moving up.";
      };

      downKey = mkOption {
        type = types.str;
        default = "j";
        description = "Home row direction key for moving down.";
      };

      keyBindings = mkOption {
        type = types.attrsOf (types.nullOr types.str);
        default = let
          modKey =
            if cfg.swayConfig.modifierAlias
            then "${cfg.swayConfig.modifierKey}"
            else "$mod";
        in
          mapAttrs (n: mkOptionDefault) {
            "${modKey}+Return" = "exec ${cfg.swayConfig.terminal}";
            "${modKey}+Shift+q" = "kill";
            "${modKey}+d" = "exec ${cfg.swayConfig.menu}";
            "${modKey}+Shift+c" = "reload";
            "${modKey}+Shift+e" = "exec swaynag -t warning -m 'You pressed the exit shortcut. Do you really want to exit sway? This will end your Wayland session.' -b 'Yes, exit sway' 'swaymsg exit'";

            "${modKey}+${cfg.swayConfig.leftKey}" = "focus left";
            "${modKey}+${cfg.swayConfig.rightKey}" = "focus right";
            "${modKey}+${cfg.swayConfig.upKey}" = "focus up";
            "${modKey}+${cfg.swayConfig.downKey}" = "focus down";

            "${modKey}+Left" = "focus left";
            "${modKey}+Right" = "focus right";
            "${modKey}+Up" = "focus up";
            "${modKey}+Down" = "focus down";

            "${modKey}+Shift+${cfg.swayConfig.leftKey}" = "move left";
            "${modKey}+Shift+${cfg.swayConfig.rightKey}" = "move right";
            "${modKey}+Shift+${cfg.swayConfig.upKey}" = "move up";
            "${modKey}+Shift+${cfg.swayConfig.downKey}" = "move down";

            "${modKey}+Shift+Left" = "move left";
            "${modKey}+Shift+Right" = "move right";
            "${modKey}+Shift+Up" = "move up";
            "${modKey}+Shift+Down" = "move down";

            "${modKey}+1" = "workspace number 1";
            "${modKey}+2" = "workspace number 2";
            "${modKey}+3" = "workspace number 3";
            "${modKey}+4" = "workspace number 4";
            "${modKey}+5" = "workspace number 5";
            "${modKey}+6" = "workspace number 6";
            "${modKey}+7" = "workspace number 7";
            "${modKey}+8" = "workspace number 8";
            "${modKey}+9" = "workspace number 9";
            "${modKey}+0" = "workspace number 10";

            "${modKey}+Shift+1" = "move container to workspace number 1";
            "${modKey}+Shift+2" = "move container to workspace number 2";
            "${modKey}+Shift+3" = "move container to workspace number 3";
            "${modKey}+Shift+4" = "move container to workspace number 4";
            "${modKey}+Shift+5" = "move container to workspace number 5";
            "${modKey}+Shift+6" = "move container to workspace number 6";
            "${modKey}+Shift+7" = "move container to workspace number 7";
            "${modKey}+Shift+8" = "move container to workspace number 8";
            "${modKey}+Shift+9" = "move container to workspace number 9";
            "${modKey}+Shift+0" = "move container to workspace number 10";

            "${modKey}+b" = "splith";
            "${modKey}+v" = "splitv";
            "${modKey}+s" = "layout stacking";
            "${modKey}+w" = "layout tabbed";
            "${modKey}+e" = "layout toggle split";

            "${modKey}+f" = "fullscreen toggle";
            "${modKey}+a" = "focus parent";
            "${modKey}+Shift+space" = "floating toggle";
            "${modKey}+space" = "focus mode_toggle";

            "${modKey}+Shift+minus" = "move scratchpad";
            "${modKey}+minus" = "scratchpad show";

            "${modKey}+r" = "mode resize";

            "${modKey}+c" = "exec grim -g $(slurp) /tmp/$(date +'%H:%M:%S.png')";
          };
        defaultText = "Default Sway keybindings.";
        description = ''
          An attribute set that assigns a key press to an action using a key symbol.
          See <https://i3wm.org/docs/userguide.html#keybindings>.

          Consider to use 'lib.mkOptionDefault' function to extend or override
          default keybindings instead of specifying all of them from scratch.
        '';
        example = literalExpression ''
          let
            modifierKey = config.ghaf.graphics.sway.swayConfig.modifierKey;
          in lib.mkOptionDefault {
            "''${modifierKey}+Return" = "exec ${cfg.swayConfig.terminal}";
            "''${modifierKey}+Shift+q" = "kill";
            "''${modifierKey}+d" = "exec ${cfg.swayConfig.menu}";
          }
        '';
      };

      bindKeysToCode = mkOption {
        type = types.bool;
        default = false;
        example = true;
        description = "Whether to make use of {option}`--to-code` in keybindings.";
      };

      input = mkOption {
        type = types.attrsOf (types.attrsOf types.str);
        default = {};
        example = {"*" = {xkb_variant = "dvorak";};};
        description = ''
          An attribute set that defines input modules. See
          {manpage}`sway-input(5)`
          for options.
        '';
      };

      output = mkOption {
        type = types.attrsOf (types.attrsOf types.str);
        default = {"*" = {bg = "${../assets/wallpaper.jpg} fill";};};
        example = {"eDP-1" = {bg = "~/path/to/background.png fill";};};
        description = ''
          An attribute set that defines output modules. See
          {manpage}`sway-output(5)`
          for options.
        '';
      };

      startupCommands = mkOption {
        type = types.listOf (types.submodule {
          options = {
            command = mkOption {
              type = types.str;
              description = "Command that will be executed on Sway startup.";
            };

            always = mkOption {
              type = types.bool;
              default = false;
              description = "Whether to run command on each Sway restart.";
            };
          };
        });

        default = [
          {command = "dbus-sway-environment";}
          {command = "configure-gtk";}
          {command = "wl-paste -t text --watch clipman store";}
          {
            command = "nwg-panel";
            always = true;
          }
          {
            command = "lisgd";
            always = true;
          }
        ];
        example = literalExpression ''
          [
          { command = "systemctl --user restart waybar"; always = true; }
          { command = "dropbox start"; }
          { command = "firefox"; }
          ]
        '';
        description = ''
          Commands that should be executed at startup.

          See <https://i3wm.org/docs/userguide.html#_automatically_starting_applications_on_i3_startup>.
        '';
      };

      terminal = mkOption {
        type = types.str;
        default = "alacritty";
        example = "${pkgs.foot}/bin/foot";
        description = "Default terminal to run.";
      };

      menu = mkOption {
        type = types.str;
        default = "dmenu_path | dmenu | xargs swaymsg exec --";
        example = "${pkgs.dmenu}/bin/dmenu_path | ${pkgs.dmenu}/bin/dmenu | ${pkgs.findutils}/bin/xargs swaymsg exec --";
        description = "Default launcher to use.";
      };

      modes = mkOption {
        type = types.attrsOf (types.attrsOf types.str);
        default = {
          resize = {
            "${cfg.swayConfig.leftKey}" = "resize shrink width 10 px";
            "${cfg.swayConfig.rightKey}" = "resize grow width 10 px";
            "${cfg.swayConfig.upKey}" = "resize shrink height 10 px";
            "${cfg.swayConfig.downKey}" = "resize grow height 10 px";

            "Left" = "resize shrink width 10 px";
            "Right" = "resize grow width 10 px";
            "Up" = "resize shrink height 10 px";
            "Down" = "resize grow height 10 px";

            "Escape" = "mode default";
            "Return" = "mode default";
          };
        };
        description = ''
          An attribute set that defines binding modes and keybindings
          inside them

          Only basic keybindings are supported (bindsym keycomb action).
          For more advanced setup, use 'sway.extraConfig'.
        '';
      };
    };
  };

  genModuleConfig = {
    moduleType,
    inputAttrs,
    indent ? "  ",
  }:
    concatStringsSep "\n"
    (mapAttrsToList (
        name: attrs: ''
          ${toString moduleType} "${toString name}" {
          ${concatStringsSep "\n"
            (mapAttrsToList (k: v: "${indent}${toString k} ${toString v}") attrs)}
          }
        ''
      )
      inputAttrs);

  genKeyBindingsConfig = {
    keyBindings,
    bindSymArgs ? "",
    indent ? "",
  }:
    concatStringsSep "\n"
    (mapAttrsToList (
        keycomb: action:
          optionalString (action != null) "${indent}bindsym ${optionalString (bindSymArgs != "") "${bindSymArgs} "}${keycomb} ${action}"
      )
      keyBindings);

  genModeConfig = {
    modeAttrs,
    bindKeysToCode ? false,
    indent ? "  ",
  }:
    concatStringsSep "\n"
    (mapAttrsToList (
        name: attrs: ''
          mode "${toString name}" {
            ${genKeyBindingsConfig {
            keyBindings = attrs;
            bindSymArgs = optionalString bindKeysToCode "--to-code";
            inherit indent;
          }}
          }
        ''
      )
      modeAttrs);

  genStartupEntries = commands:
    concatStringsSep "\n"
    (
      map (cmd: let
        exec =
          if cmd.always
          then "exec_always"
          else "exec";
      in "${exec} ${cmd.command}")
      commands
    );

  swayConfigFile = pkgs.writeTextFile {
    name = "sway-config";
    executable = false;
    text =
      concatStringsSep "\n"
      ((optional (cfg.extraConfigEarly != "") cfg.extraConfigEarly)
        ++ (
          if cfg.swayConfig != null
          then
            (
              with cfg.swayConfig; [
                "####################################"
                "# Sway display manager configuration"
                "####################################"
                ""
                "# Modifier key, set to 'Mod1' for 'Alt' key."
                "set $mod ${modifierKey}"
                ""
                "# Home row direction keys."
                "set $left ${leftKey}"
                "set $right ${rightKey}"
                "set $up ${upKey}"
                "set $down ${downKey}"
                ""
                "# Your preferred terminal emulator."
                "set $term ${terminal}"
                ""
                "# Your preferred application launcher."
                "# NOTE: Pass the final command to 'swaymsg' so that the resulting window can be opened"
                "# on the original workspace that the command was run on."
                "set $menu ${menu}"
                ""
                "# Keybind configuration"
                (genKeyBindingsConfig {
                  keyBindings = keyBindings;
                  bindSymArgs = optionalString bindKeysToCode "--to-code";
                })
                ""
                "# Drag floating windows by holding down $mod and left mouse button."
                "# Resize them with right mouse button + $mod. Despite the name, this"
                "also works for non-floating windows. Change 'normal' to 'inverse' to"
                "use left mouse button for resizing and right mouse button for dragging."
                "floating_modifier $mod normal"
                ""
                "# Input configuration"
                (genModuleConfig {
                  moduleType = "input";
                  inputAttrs = input;
                })
                ""
                "# Output configuration"
                (genModuleConfig {
                  moduleType = "output";
                  inputAttrs = output;
                })
                ""
                "# Modes configuration"
                (genModeConfig {
                  modeAttrs = modes;
                  inherit bindKeysToCode;
                })
                ""
                "# Sway startup configuration"
                (genStartupEntries startupCommands)
              ]
            )
          else []
        )
        ++ (optional (cfg.extraConfig != "") cfg.extraConfig));
  };
in {
  imports = [
    ./lisgd
    ./nwg-panel
  ];

  options.ghaf.graphics.sway = {
    swayConfig = mkOption {
      type = types.nullOr swayConfigModule;
      default = {};
      description = "Sway configuration options.";
    };

    extraConfig = mkOption {
      type = types.lines;
      default = "";
      description = "Extra configuration lines to add to ~/.config/sway/config.";
    };

    extraConfigEarly = mkOption {
      type = types.lines;
      default = "";
      description = "Like extraConfig, except lines are added to ~/.config/sway/config before all other configuration.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.writeToFile = {
      enable = true;
      enabledFiles = ["config-folder" "sway-config"];
      file-info = {
        config-folder = {
          des-path = "${config.users.users.ghaf.home}/.config";
          write-once = true;
          owner = config.ghaf.users.accounts.user;
        };
        sway-config = {
          source = "${swayConfigFile}";
          des-path = "${config.users.users.ghaf.home}/.config/sway";
          write-once = true;
          owner = config.ghaf.users.accounts.user;
          permission = "664";
        };
      };
    };
  };
}
