#!/usr/bin/env bash

set -eou pipefail

CMD=$1
BUSNUM="${2:-$BUSNUM}"
PORTNUM="${3:-$DEVNUM}"

function print_date() {
    date +%Y-%m-%d_%H%M%S
}

echo "$(print_date) USB change detected: $CMD bus=$BUSNUM port=$PORTNUM" >> /tmp/on-yubikey-hotplug.txt

# /run/current-system/sw/bin/su - ghaf -c 'xhost local:ghaf; bash -c "terminator -e orchestrate.sh &"'
