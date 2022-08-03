#!/bin/bash

if [ -z "$BASH_SOURCE" ]; then
    ME=$(basename -- "$0")
else
    ME=$(basename -- "$BASH_SOURCE")
fi

USAGE=$(cat <<-EOM

  Usage: $ME config/sync

  Sorts all yaml files in the given directory.
  
EOM
)

DIRECTORY=$1

if [ -z "$DIRECTORY" ]; then
      echo "$USAGE"
      exit 0
fi

if [ ! -d "$DIRECTORY" ]; then
      echo "$DIRECTORY is not a directory or does not exist."
      exit 1
fi


if ! command -v yq -V &> /dev/null
then
    echo "The yq command must be installed and available to use this script."
    echo "See: https://github.com/mikefarah/yq"
    exit 1
fi

find "$DIRECTORY" -maxdepth 1 -type f -name '*.yml' -exec yq -i -P 'sort_keys(..)' {} \;
