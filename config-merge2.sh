#!/bin/bash

if [ -z "$BASH_SOURCE" ]; then
    ME=$(basename -- "$0")
else
    ME=$(basename -- "$BASH_SOURCE")
fi

USAGE=$(cat <<-EOM

  Usage: $ME config/sync/views.view.content.yml  

  Attempts to re-perform a git merge on a Drupal configuration file by converting
  the "theirs" and "ours" changes into an array of RFC6902 patch operations and
  attempting to apply both sets of changes onto the common ancestor.

  This approach doesn't work to be honest.

  See:
   - https://www.npmjs.com/package/yaml-diff-patch
   - https://github.com/mikefarah/yq
  
EOM
)

FILEPATH=$1

if [ -z "$FILEPATH" ]; then
      echo "$USAGE"
      exit 0
fi

DIRECTORY=$(dirname -- "$FILEPATH")
FILENAME=$(basename -- "$FILEPATH")
EXTENSION="${FILENAME##*.}"
BASENAME="${FILENAME%.*}"

if [ "$EXTENSION" != "yml" ]; then
    echo "This command expects a file with an extension of 'yml', '$EXTENSION' given."
    exit 1
fi

CONFLICTS=$(cd "$DIRECTORY" && git ls-files -u | wc -l)
if [ "$CONFLICTS" -eq 0 ] ; then
    echo "The passed file is not in a git repository that is in a merge conflict."
    exit 1
fi

if ! command -v yq -V &> /dev/null
then
    echo "The yq command must be installed and available to use this script."
    echo "See: https://github.com/mikefarah/yq"
    exit 1
fi

if ! command -v yaml-diff-patch -V &> /dev/null
then
    echo "The yaml-diff-patch command must be installed globally and available to use this"
    echo "script."
    echo "See: https://www.npmjs.com/package/yaml-diff-patch"
    exit 1
fi

COMMONFILE="$DIRECTORY/$BASENAME.common.$EXTENSION"
OURSFILE="$DIRECTORY/$BASENAME.ours.$EXTENSION"
THEIRSFILE="$DIRECTORY/$BASENAME.theirs.$EXTENSION"

COMMONJSONFILE="$DIRECTORY/$BASENAME.common.json"
THEIRSJSONFILE="$DIRECTORY/$BASENAME.theirs.json"

set -o xtrace

git show :1:$FILEPATH > "$COMMONFILE"
git show :2:$FILEPATH > "$OURSFILE"
git show :3:$FILEPATH > "$THEIRSFILE"

# Convert the theirs file to JSON.
yq -o=json '.' "$COMMONFILE" > "$COMMONJSONFILE"
yq -o=json '.' "$THEIRSFILE" > "$THEIRSJSONFILE"

# Patch
yaml-diff-patch "$OURSFILE" "$COMMONJSONFILE" "$THEIRSJSONFILE" > "$FILEPATH"

# Clean up.
# rm "$COMMONFILE"
# rm "$OURSFILE"
# rm "$THEIRSFILE"
# rm "$COMMONJSONFILE"
# rm "$THEIRSJSONFILE"

set +o xtrace