#!/bin/bash

filename=~/logs/timesheet
cmd="$1"

add_activity() {
  local activity="$1"
  if [ -z "$activity" ]; then
    echo "Usage: $0 add <activity>"
    exit 1
  fi

  last_activity=$(tail -n 1 "$filename" | awk -F'\t' '{print $3}')
  if [ "$last_activity" != "$activity" ]; then
    echo "$(date +'%s	%Y-%m-%d %H:%M:%S')	$activity" >> "$filename"
  fi
}

list_activities() {
  awk -F'\t' '{print $3}' "$filename" | sort | uniq
}

process_file() {
  awk -F'\t' '
    BEGIN {
      prev_time = 0
      prev_activity = ""
    }
    {
      if (prev_time != 0) {
        duration = $1 - prev_time
        printf "%s\t%d\n", prev_activity, duration
      }
      prev_time = $1
      prev_activity = $3
    }
    END {
      current_time = systime()
      if (prev_time != 0) {
        duration = current_time - prev_time
        printf "%s\t%d\n", prev_activity, duration
      }
    }' "$filename"
}
