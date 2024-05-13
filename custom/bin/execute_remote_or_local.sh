#!/bin/zsh

timeout=$1
if [ -z "${timeout##*[!0-9]*}" ]; then
    timeout=5
else
    shift
fi

basedir="$(dirname $0)"

# Check if the current connection is metered
if "$basedir/is_on_metered.sh"; then
  if "$basedir/is_cloudy_backup_online.sh" $timeout; then
      echo "We are home...executing on cloudy"
      "$@"
  elif "$basedir/is_online.sh" servyy.duckdns.org $timeout; then
      echo "We are remote...executing on servyy"
      "$@" -s
  else
      echo "We are offline...executing local"
      "$@" -l
  fi
else
    echo "We are metered...executing local"
    "$@" -l
fi
