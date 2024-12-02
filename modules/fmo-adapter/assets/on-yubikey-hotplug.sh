#!/usr/bin/env bash

set -eou pipefail

CMD=$1
BUSNUM="${2:-$BUSNUM}"
PORTNUM="${3:-$DEVNUM}"

function print_date() {
    date +%Y-%m-%d_%H%M%S
}

if [ -f /tmp/on-yubikey-hotplug ]; then
    if [ "${CMD}" == "remove" ]; then
        rm -f /tmp/on-yubikey-hotplug
    fi

    exit 0
else
    if [ "${CMD}" == "add" ]; then
        touch /tmp/on-yubikey-hotplug
    fi
fi

# The first "add" gets logged
echo "$(print_date) Yubikey plugged in: $CMD bus=$BUSNUM port=$PORTNUM" >> /tmp/on-yubikey-hotplug.txt

# /run/current-system/sw/bin/su - ghaf -c 'xhost local:ghaf; bash -c "terminator -e orchestrate.sh &"'
