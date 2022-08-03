#!/bin/bash

if [ -z "$BASH_SOURCE" ]; then
    ME=$(basename -- "$0")
else
    ME=$(basename -- "$BASH_SOURCE")
fi

USAGE=$(cat <<-EOM

  Usage: $ME config/sync/views.view.content.yml

  Attempts to re-perform a git merge on a Drupal configuration file by first
  performing a simple recursive key sort onto the base, common and ours yaml
  files.
  
  This works quite well, but sadly some configuration in Drupal depends on
  the ordering of keys (e.g. order of fields, filters in views. Order of 
  fields on a content type).
  
  Running this script, importing the merged config back into the site, fixing
  the ordering issues in the UI, then re-exporting the config (to restore it
  to natural ordering) does a half-decent job at merging configuration.
  
  This command does nothing if not run from within a git repository in a 
  
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
    echo "The passed file is not in a git repository that is involved in a merge conflict. This command did nothing."
    exit 1
fi

if ! command -v yq -V &> /dev/null
then
    echo "The yq command must be installed and available to use this script."
    echo "See: https://github.com/mikefarah/yq"
    exit 1
fi

COMMONFILE="$DIRECTORY/$BASENAME.common.$EXTENSION"
OURSFILE="$DIRECTORY/$BASENAME.ours.$EXTENSION"
THEIRSFILE="$DIRECTORY/$BASENAME.theirs.$EXTENSION"

set -o xtrace

git show :1:$FILEPATH > "$COMMONFILE"
git show :2:$FILEPATH > "$OURSFILE"
git show :3:$FILEPATH > "$THEIRSFILE"

yq -i -P 'sort_keys(..)' "$COMMONFILE"
yq -i -P 'sort_keys(..)' "$OURSFILE"
yq -i -P 'sort_keys(..)' "$THEIRSFILE"

git merge-file -p "$OURSFILE" "$COMMONFILE" "$THEIRSFILE" > "$FILEPATH"

# rm "$COMMONFILE"
# rm "$OURSFILE"
# rm "$THEIRSFILE"

set +o xtrace
