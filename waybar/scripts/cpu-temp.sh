#!/usr/bin/env bash
for h in /sys/class/hwmon/hwmon*; do
    [ -r "$h/name" ] || continue
    [ "$(cat "$h/name")" = "coretemp" ] || continue
    for t in "$h"/temp*_input; do
        [ -r "$t" ] || continue
        label="${t%_input}_label"
        if [ -r "$label" ] && [ "$(cat "$label")" = "Package id 0" ]; then
            awk '{printf "CPU %.0f°C\n", $1/1000}' "$t"
            exit
        fi
    done
done
echo "CPU --"
