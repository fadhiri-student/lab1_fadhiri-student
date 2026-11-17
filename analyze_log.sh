#!/usr/bin/env bash
# analyze_log.sh - summarise the Kigali FSD simulation log
# Usage: bash analyze_log.sh [logfile]      (default: transit_session.log)

if [ "$#" -gt 1 ]; then
    echo "Error: too many arguments. Usage: bash analyze_log.sh [logfile]" >&2
    echo "Example: bash analyze_log.sh transit_session.log" >&2
    exit 1
fi

LOG_FILE="${1:-transit_session.log}"

if [ -d "$LOG_FILE" ]; then
    echo "Error: '$LOG_FILE' is a directory, not a log file." >&2
    echo "Pass the log file itself, e.g. bash analyze_log.sh transit_session.log" >&2
    exit 1
fi

if [ ! -f "$LOG_FILE" ]; then
    echo "Error: log file '$LOG_FILE' not found." >&2
    echo "Run 'python road_simulation.py' at least once, or pass a log path, e.g. bash analyze_log.sh transit_session.log" >&2
    exit 1
fi

if [ ! -r "$LOG_FILE" ]; then
    echo "Error: log file '$LOG_FILE' cannot be read. Check its permissions." >&2
    exit 1
fi

if [ ! -s "$LOG_FILE" ]; then
    echo "Error: log file '$LOG_FILE' is empty. Run 'python road_simulation.py' to record a trip." >&2
    exit 1
fi

# Every run of road_simulation.py starts with this banner line
sessions=$(grep -c "===== New session started" "$LOG_FILE")
zebra_stops=$(grep -c "Zebra crossing! Stopping" "$LOG_FILE")
lane_changes=$(grep -c "Changing lane:" "$LOG_FILE")
completed_trips=$(grep -c "Arrived at" "$LOG_FILE")

if [ "$sessions" -eq 0 ]; then
    echo "Error: '$LOG_FILE' has no simulation sessions. Is it a transit_session.log file?" >&2
    exit 1
fi

# The trip report is only written when a drive finishes, so take the last one.
# Python on Windows writes CRLF line endings, so strip the trailing \r too.
latest_driver=$(grep "Driver            :" "$LOG_FILE" | tail -n 1 | cut -d':' -f4- | tr -d '\r' | sed 's/^ *//')
latest_top_speed=$(grep "Top speed         :" "$LOG_FILE" | tail -n 1 | cut -d':' -f4- | tr -d '\r' | sed 's/^ *//')

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
