#!/bin/bash

set -o xtrace
dyff \
    --color on \
    between \
        --omit-header \
        --no-table-style \
        "$2" \
        "$5"