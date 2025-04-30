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

list() {
   awk -F'\t' '
    {
      activity = $1
      duration = $2

      activities[activity] += duration
    }
    END {
      printf "Time     Activity\n"
      for (activity in activities) {
        duration = activities[activity]
        hours = duration / 3600
        minutes = (duration % 3600) / 60
        seconds = duration % 60
        printf "%02d:%02d:%02d %s\n", hours, minutes, seconds, activity
      }
    }'
}

bar() {
  last_timestamp=$(tail -n 1 "$filename" | awk -F'\t' '{print $1}')
  now=$(date +%s)
  duration=$((now - last_timestamp))
  tail -n 1 "$filename" | awk -F'\t' '{print $3}' | tr -d '\n'
  hours=$(($duration / 3600))
  minutes=$(($duration % 3600 / 60))
  seconds=$(($duration % 60))
  printf " %02d:%02d:%02d" $hours $minutes $seconds
}

interactive() {
  activity=$({
    tail -n 1 "$filename" | awk -F'\t' '{print $3}'
    list_activities
  } | rofi -dmenu -p "Select Activity")
  if [ -n "$activity" ]; then
    add_activity "$activity"
  fi
}

categories() {
  process_file | awk -F'\t' '
  {
    activity = $1
    category = split(activity, parts, ".") > 0 ? parts[1] : "Uncategorized"
    duration = $2
    categories[category] += duration
  }
  END {
    printf "Time     Category\n"
    for (category in categories) {
      duration = categories[category]
      hours = duration / 3600
      minutes = (duration % 3600) / 60
      seconds = duration % 60
      printf "%02d:%02d:%02d %s\n", hours, minutes, seconds, category
    }
  }'
}

case "$cmd" in
  "add")
    activity="$2"
    add_activity "$activity"
    ;;
  *)
    echo "Usage: $0 <command>"
    echo
    echo "Commands:"
    echo "  add <activity>    Add a new activity"
    exit 1
    ;;
esac
