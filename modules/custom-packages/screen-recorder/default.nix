# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
(final: _prev: {
  screenRecord = final.writeShellScriptBin "screenRecord" ''
          RECORDING_STATE=$(${final.ps}/bin/ps cax -o stat,comm | grep '^S.*wf-recorder')
          FILE_NAME="/home/ghaf/recordings/$(date '+%Y-%m-%d_%H:%M:%S').mp4"
          CURRENT_DISPLAY=$(${final.sway}/bin/swaymsg -t get_outputs --raw | ${final.jq}/bin/jq '. | map(select(.focused == true)) | .[0].name' -r)
          if [ $# == 0 ]; then
            if [[ -z $RECORDING_STATE ]]; then
              echo ${../../graphics/assets/record.png}
              echo "$CURRENT_DISPLAY"
            else
              echo ${../../graphics/assets/stop-record.png}
              echo Recording
            fi
            exit
          fi

          if [[ "$1" != "s" ]] then
            exit
          fi
          if [[ -z $RECORDING_STATE ]]; then
            mkdir -p /home/ghaf/recordings
            ${final.coreutils-full}/bin/nohup ${final.wf-recorder}/bin/wf-recorder -a -f $FILE_NAME -o $CURRENT_DISPLAY </dev/null &>/dev/null &
            echo Started
          else
            ${final.killall}/bin/killall -s SIGINT wf-recorder
            echo Stopped
          fi
        '';
})
