#!/usr/bin/env bash

/run/current-system/sw/bin/su - ghaf -c 'xhost local:ghaf; bash -c "terminator -e orchestrate.sh &"'
