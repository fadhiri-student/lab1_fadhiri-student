#!/usr/bin/env bash
# analyze_log.sh - summarise the Kigali FSD simulation log
# Usage: bash analyze_log.sh [logfile]      (default: transit_session.log)

LOG_FILE="${1:-transit_session.log}"

if [ ! -f "$LOG_FILE" ]; then
    echo "Error: log file '$LOG_FILE' not found." >&2
    echo "Run 'python road_simulation.py' at least once, or pass a log path, e.g. bash analyze_log.sh transit_session.log" >&2
    exit 1
fi

# Every run of road_simulation.py starts with this banner line
sessions=$(grep -c "===== New session started" "$LOG_FILE")
zebra_stops=$(grep -c "Zebra crossing! Stopping" "$LOG_FILE")
lane_changes=$(grep -c "Changing lane:" "$LOG_FILE")
completed_trips=$(grep -c "Arrived at" "$LOG_FILE")

# The trip report is only written when a drive finishes, so take the last one
latest_driver=$(grep "Driver            :" "$LOG_FILE" | tail -n 1 | cut -d':' -f4- | sed 's/^ *//')
latest_top_speed=$(grep "Top speed         :" "$LOG_FILE" | tail -n 1 | cut -d':' -f4- | sed 's/^ *//')

echo "===== TRANSIT LOG SUMMARY ====="
echo "Log file            : $LOG_FILE"
echo "Sessions (runs)     : $sessions"
echo "Completed trips     : $completed_trips"
echo "Zebra crossing stops: $zebra_stops"
echo "Lane changes        : $lane_changes"
echo "----- Latest trip -----"
if [ -z "$latest_driver" ]; then
    echo "No finished trip found yet. Drive to the Convention Center to get a trip report."
else
    echo "Driver              : $latest_driver"
    echo "Top speed           : $latest_top_speed"
fi
