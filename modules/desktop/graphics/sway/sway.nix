# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.ghaf.graphics.sway;

  # bash script to let dbus know about important env variables and
  # propagate them to relevent services run at the end of sway config
  # see
  # https://github.com/emersion/xdg-desktop-portal-wlr/wiki/"It-doesn't-work"-Troubleshooting-Checklist
  # note: this is pretty much the same as  /etc/sway/config.d/nixos.conf but also restarts
  # some user services to make sure they have the correct environment variables
  update-sway-session-env = pkgs.writeShellApplication {
    name = "update-sway-session-env";
    runtimeInputs = [
      pkgs.systemd
      pkgs.dbus
    ];
    text = ''
      systemctl --user import-environment PATH DISPLAY XAUTHORITY DESKTOP_SESSION XDG_CONFIG_DIRS XDG_DATA_DIRS XDG_RUNTIME_DIR XDG_SESSION_ID DBUS_SESSION_BUS_ADDRESS || true
      dbus-update-activation-environment --systemd --all || true
      systemctl --user stop pipewire wireplumber xdg-desktop-portal xdg-desktop-portal-wlr
      systemctl --user start pipewire wireplumber xdg-desktop-portal xdg-desktop-portal-wlr
    '';
  };

  # currently, there is some friction between sway and gtk:
  # https://github.com/swaywm/sway/wiki/GTK-3-settings-on-Wayland
  # the suggested way to set gtk settings is with gsettings
  # for gsettings to work, we need to tell it where the schemas are
  # using the XDG_DATA_DIR environment variable
  # run at the end of sway config
  configure-gtk = pkgs.writeShellApplication {
    name = "configure-gtk";
    runtimeInputs = [
      pkgs.glib
    ];
    text = ''
      # For squeekboard
      gsettings set org.gnome.desktop.a11y.applications screen-keyboard-enabled true
      gsettings set org.gnome.desktop.input-sources show-all-sources true

      gsettings set org.gnome.desktop.interface gtk-theme 'Dracula'
      gsettings set org.gnome.desktop.interface icon-theme 'Adwaita'
      gsettings set org.gnome.desktop.interface cursor-theme 'Adwaita'
      gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
      gsettings set org.freedesktop.appearance color-scheme 'prefer-dark'
    '';
  };

  extraSessionCommands = ''
    # Session:
    export XDG_SESSION_TYPE=wayland

    # SDL:
    export SDL_VIDEODRIVER=wayland

    # QT (needs qt5.qtwayland in systemPackages):
    export QT_QPA_PLATFORM=wayland-egl
    #export QT_WAYLAND_DISABLE_WINDOWDECORATION="1"

    # Fix for some Java AWT applications (e.g. Android Studio),
    # use this if they aren't displayed properly:
    export _JAVA_AWT_WM_NONREPARENTING=1

    # Misc Wayland stuff
    export NIXOS_OZONE_WL=1
    export MOZ_ENABLE_WAYLAND=1

    export GTK_THEME='Dracula'
  '';

  swayConfig =
    ''
      # Default wallpaper
      output * bg ${../assets/wallpaper.jpg} fill
    ''
    + (builtins.readFile ./sway.conf);
in {
  options.ghaf.graphics.sway = {
    enable = lib.mkEnableOption "sway";
  };

  config = lib.mkIf cfg.enable {
    ghaf.graphics.window-manager-common.enable = true;

    # Main Sway config
    environment.etc."sway/config" = {
      text = swayConfig;
      mode = "0644";
    };
    environment.etc."sway/theme.conf" = {
      source = ./theme.conf;
      mode = "0644";
    };

    # Allow members of 'video' group to adjust display brightness
    users.users."ghaf".extraGroups = ["video" "input"];
    services.udev.extraRules = ''
      ACTION=="add", SUBSYSTEM=="backlight", RUN+="${pkgs.coreutils}/bin/chgrp video $sys$devpath/brightness", RUN+="${pkgs.coreutils}/bin/chmod a+w $sys$devpath/brightness"
    '';

    # Refer in https://nixos.wiki/wiki/Sway
    #TODO: remove some unused apps
    environment.systemPackages = with pkgs; [
      acpi # Show battery status and other ACPI information
      #alacritty # Cross-platform, GPU-accelerated terminal emulator
      brightnessctl # Read and control device brightness
      clipman # A simple clipboard manager for Wayland
      #dracula-icon-theme # Dracula Icon theme
      dracula-theme # Dracula GTK theme
      glib # GTK/GNOME core library (e.g. gsettings)
      gnome3.adwaita-icon-theme # Default gnome cursors
      grim # Grab images from a Wayland compositor
      gsettings-desktop-schemas # GSettings schemas for settings shared by various components of a desktop
      jq # Lightweight and flexible command-line JSON processor
      kanshi # Dynamic display configuration tool
      mako # Lightweight Wayland notification daemon
      pwvucontrol # Pipewire Volume Control
      slurp # Select a region in a Wayland compositor
      squeekboard # Virtual keyboard supporting Wayland
      squeekboard-control
      sway-contrib.grimshot # A helper for screenshots within sway
      swaybg # Wallpaper tool for Wayland compositors
      swaycwd # Returns cwd for shell in currently focused sway window, or home directory if cannot find shell
      swayidle # Idle management daemon for Wayland
      swaylock # Screen locker for Wayland
      terminator # Terminal emulator with support for tiling and tabs
      waybar # Highly customizable Wayland bar for Sway and Wlroots based compositors
      wayland # Core Wayland window system code and protocol
      wdisplays # Graphical application for configuring displays in Wayland compositors
      wl-clipboard # Command-line copy/paste utilities for Wayland
      wl-mirror # Simple Wayland output mirror client
      wob # Lightweight overlay bar for Wayland
      xdg-utils # For opening default programs when clicking links
      xwayland # An X server for interfacing X11 apps with the Wayland protocol
      #yaru-remix-theme # Fork of the Yaru GTK theme
      upower # D-Bus service for power management
      lisgd # Bind gestures via libinput touch events
      rofi-wayland # Window switcher, run dialog and dmenu replacement for Wayland
      wlogout # Wayland based logout menu

      # Custom scripts
      #configure-gtk
      update-sway-session-env
      wob-onscreen-bar
      display-scale
    ];

    # Enable Sway window manager
    programs.sway = {
      enable = true;
      wrapperFeatures.base = true;
      wrapperFeatures.gtk = true;
      inherit extraSessionCommands;
    };

    # Enable PipeWire audio server
    # rtkit is optional but recommended
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      pulse.enable = true;
    };

    # xdg-desktop-portal works by exposing a series of D-Bus interfaces
    # known as portals under a well-known name
    # (org.freedesktop.portal.Desktop) and object path
    # (/org/freedesktop/portal/desktop).
    # The portal interfaces include APIs for file access, opening URIs,
    # printing and others.
    services.dbus = {
      enable = true;
      packages = [pkgs.squeekboard];
    };

    xdg = {
      icons.enable = true;
      mime.enable = true;
      portal = {
        enable = true;
        xdgOpenUsePortal = true;

        # GTK portal needed to make GTK apps happy
        extraPortals = with pkgs; [
          xdg-desktop-portal-gtk
          xdg-desktop-portal-wlr
        ];
      };
    };

    # configuring sway itself (assmung a display manager starts it)
    systemd.user.targets.sway-session = {
      description = "Sway compositor session";
      documentation = ["man:systemd.special(7)"];
      bindsTo = ["graphical-session.target"];
      wants = ["graphical-session-pre.target"];
      after = ["graphical-session-pre.target"];
    };

    # Sway gets started by greetd greeter service
    services.greetd = {
      enable = true;
      settings = rec {
        initial_session = {
          command = "${pkgs.sway}/bin/sway --config /etc/sway/config";
          user = "ghaf";
        };
        default_session = initial_session;
      };
    };

    systemd.user.services.kanshi = {
      description = "Kanshi output autoconfig ";
      wantedBy = ["graphical-session.target"];
      partOf = ["graphical-session.target"];
      serviceConfig = {
        # kanshi doesn't have an option to specifiy config file yet, so it looks
        # at .config/kanshi/config
        ExecStart = ''
          ${pkgs.kanshi}/bin/kanshi
        '';
        RestartSec = 5;
        Restart = "always";
      };
    };
  };
}
