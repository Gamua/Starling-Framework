#!/bin/bash
#
# Builds the unit tests and runs them in the AIR Debug Launcher, without IDE or visible window.
# The exit code is 0 if all tests passed. Requires the AIR SDK: set AIR_HOME to its
# root folder, or put its 'bin' folder on the PATH.

set -e
cd "$(dirname "$0")"

BIN="${AIR_HOME:+$AIR_HOME/bin/}"
OUT=out

mkdir -p "$OUT"
rm -rf "$OUT/fixtures"
cp -R fixtures "$OUT/fixtures"
# the window stays hidden; Starling still gets its Stage3D context
sed -e 's|<content>.*</content>|<content>tests.swf</content>|' \
    -e 's|<visible>true</visible>|<visible>false</visible>|' \
    src/UnitTest-app.xml > "$OUT/UnitTest-app.xml"

# a debug build is required; otherwise, 'trace' output (i.e. the test log) is not shown
"${BIN}mxmlc" +configname=air -debug=true -source-path+=src -source-path+=../starling/src \
    -output="$OUT/tests.swf" src/Startup.as > /dev/null  # errors still show up via stderr

# hides a macOS font notice that AIR triggers on startup
"${BIN}adl" "$OUT/UnitTest-app.xml" "$OUT" 2> >(grep -v 'CoreText registered' >&2)
