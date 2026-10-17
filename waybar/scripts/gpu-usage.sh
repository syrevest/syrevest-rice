#!/usr/bin/env bash
f=/sys/class/drm/card1/device/gpu_busy_percent
if [ -r "$f" ]; then
    printf 'GPU %s%%\n' "$(cat "$f")"
else
    echo "GPU --"
fi
