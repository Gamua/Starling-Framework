#!/bin/bash
#
# Builds the unit tests and runs them in the AIR Debug Launcher, without IDE or visible window.
# The exit code is 0 if all tests passed. Requires the AIR SDK: set AIR_HOME to its
# root folder, or put its 'bin' folder on the PATH.
#
# The tests run once per Stage3D profile, because Starling's code paths differ between them.
# Pass '--profile=<name>[,<name>...]' to pick the profiles (e.g. '--profile=standard' for a quick run).
#
# Pass '--record' to (re)write the golden images in 'fixtures/golden' instead of comparing them.

set -e
cd "$(dirname "$0")"

BIN="${AIR_HOME:+$AIR_HOME/bin/}"
OUT=out

# AGAL 2, AGAL 1, and AGAL 1 with power-of-two textures and the tightest shader limits
PROFILES="standard,baseline,baselineConstrained"
RECORD=""

for arg in "$@"; do
    case "$arg" in
        --profile=*) PROFILES="${arg#--profile=}" ;;
        --record)    RECORD="--record" ;;
        *)           echo "Unknown argument: $arg" >&2; exit 1 ;;
    esac
done

mkdir -p "$OUT"
rm -rf "$OUT/fixtures" "$OUT/golden-failures"
cp -R fixtures "$OUT/fixtures"
# the window stays hidden; Starling still gets its Stage3D context
sed -e 's|<content>.*</content>|<content>tests.swf</content>|' \
    -e 's|<visible>true</visible>|<visible>false</visible>|' \
    src/UnitTest-app.xml > "$OUT/UnitTest-app.xml"

# a debug build is required; otherwise, 'trace' output (i.e. the test log) is not shown
"${BIN}mxmlc" +configname=air -debug=true -source-path+=src -source-path+=../starling/src \
    -output="$OUT/tests.swf" src/Startup.as > /dev/null  # errors still show up via stderr

STATUS=0
PROFILE_LIST=(${PROFILES//,/ })

for i in "${!PROFILE_LIST[@]}"; do
    profile="${PROFILE_LIST[$i]}"
    echo -e "\nRun $((i + 1))/${#PROFILE_LIST[@]}: $profile"

    # hides a macOS font notice that AIR triggers on startup
    "${BIN}adl" "$OUT/UnitTest-app.xml" "$OUT" -- --profile="$profile" $RECORD \
        2> >(grep -v 'CoreText registered' >&2) || STATUS=1

    # all profiles must match the same goldens, so recording them once is enough
    RECORD=""
done

exit $STATUS
