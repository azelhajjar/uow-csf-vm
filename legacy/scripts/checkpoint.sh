#!/bin/bash
# ONE_SHOT checkpoint helper
# Usage: /srv/cav-csf/scripts/checkpoint.sh "Checkpoint description here"

STAMP=$(date +%Y%m%dT%H%M%S)
DESC="$1"
echo "$STAMP | $DESC" >> /srv/cav-csf/checkpoints/history.log
echo "$DESC" > /srv/cav-csf/checkpoints/latest.txt
