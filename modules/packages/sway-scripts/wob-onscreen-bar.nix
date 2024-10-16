# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{pkgs, ...}:
pkgs.writeShellApplication {
  name = "wob-onscreen-bar";
  runtimeInputs = [
    pkgs.coreutils
    pkgs.procps
    pkgs.wob
  ];
  text = ''
    # https://github.com/francma/wob/wiki/wob-wrapper-script
    #
    # $1 - accent color
    # $2 - background color
    # $3 - new value

    function is_running_on_this_screen() {
      pkill -x -0 "wob" || return 1
      for pid in $(pgrep "wob"); do
        WOB_SWAYSOCK="$(tr '\0' '\n' </proc/"$pid"/environ | awk -F'=' '/^SWAYSOCK/ {print $2}')"
        if [[ "$WOB_SWAYSOCK" = "$SWAYSOCK" ]]; then
          return 0
        fi
       done
      return 1
    }

    WOB_PIPE="$SWAYSOCK.wob"
    [[ -p "$WOB_PIPE" ]] || mkfifo "$WOB_PIPE"

    WOB_INI=/tmp/wob.ini

    function refresh() {
      pkill -x wob
      rm "$WOB_INI"
      {
        printf "anchor = top center\n"
        printf "margin = 20\n"
        printf "border_color = %s\n" "$(printf "%s" "$1" | sed 's/#//')"
        printf "bar_color = %s\n" "$(printf "%s" "$1" | sed 's/#//')"
        printf "background_color = %s\n" "$(printf "%s" "$2" | sed 's/#//')"
      } >> "$WOB_INI"
    }

    if [[ ! -f "$WOB_INI" ]] || [ "$3" = "--refresh" ]; then
      refresh "$1" "$2"
    fi

    # wob does not appear in $(swaymsg -t get_msg), so:
    is_running_on_this_screen || {
      tail -f "$WOB_PIPE" | wob -c "$WOB_INI" &
    }

    if [[ "$3" = "--refresh" ]]; then
      exit 0;
    elif [[ -n "$3" ]]; then
      echo "$3" > "$WOB_PIPE"
    else
      cat > "$WOB_PIPE"
    fi
  '';
}
