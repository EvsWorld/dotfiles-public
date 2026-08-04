#!/usr/bin/env bash

set -euo pipefail

# Turn terminal-grid text into paste-friendly prose:
# - discard width-dependent horizontal padding
# - join adjacent screen rows with one space
# - retain blank lines as paragraph separators
perl -0pe '
    s/\r\n?/\n/g;
    s/[ \t]*\n(?:[ \t]*\n)+[ \t]*/\x00/g;
    s/[ \t]*\n[ \t]*/ /g;
    s/[ \t]+/ /g;
    s/\x00/\n\n/g;
    s/\A[ \t\n]+|[ \t\n]+\z//g;
'
