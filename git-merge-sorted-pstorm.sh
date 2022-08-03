#!/bin/bash

LOCAL=$1
REMOTE=$2
BASE=$3
MERGED=$4

if [ -z "$LOCAL" ] || [ -z "$REMOTE" ] || [ -z "$BASE" ] || [ -z "$MERGED" ]; then
      cat <<-EOM

This script must be set up as a mergetool in git config. For example:

    [mergetool "sorted-pstorm"]
        cmd = $0 "\$LOCAL" "\$REMOTE" "\$BASE" "\$MERGED"
        trustExitCode = true

And then executed during a git merge like:

    git mergetool --tool=sorted-pstorm config/sync

EOM
      exit 1
fi

if ! command -v yq -V &> /dev/null
then
    echo "The yq command must be installed and available to use this mergetool."
    echo "See: https://github.com/mikefarah/yq"
    exit 1
fi

verify_yaml_file() {
    local EXTENSION="${1##*.}"

    if [ "$EXTENSION" != "yml" ]; then
        return 1
    fi

    return 0
}

if verify_yaml_file "$LOCAL"; then
    yq -i -P 'sort_keys(..)' "$LOCAL"
fi

if verify_yaml_file "$REMOTE"; then
    yq -i -P 'sort_keys(..)' "$REMOTE"
fi

if verify_yaml_file "$BASE"; then
    yq -i -P 'sort_keys(..)' "$BASE"
fi

if verify_yaml_file "$MERGED"; then
    git merge-file -p "$LOCAL" "$BASE" "$REMOTE" > "$MERGED"
fi

/usr/local/bin/pstorm merge "$LOCAL" "$REMOTE" "$BASE" "$MERGED"
