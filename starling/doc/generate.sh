#!/bin/bash

# This script creates the API reference documentation for the Starling source.
# It uses the "ASDoc" tool that comes with the AIR SDK.
# Adapt the ASDOC variable below so that it points to the correct path.

if [ $# -ne 1 ]
then
  echo "Usage: `basename $0` [version]"
  echo "  (version like '1.0')"
  exit 1
fi

ASDOC="/Users/redge/Dropbox/Development/library/flash/air/air-20/bin/asdoc"

"${ASDOC}" \
  -doc-sources ../src \
  -exclude-classes com.adobe.utils.AGALMiniAssembler \
  -main-title "Starling Framework Reference (v$version)" \
  -window-title "Starling Framework Reference" \
  -package-description-file "package-descriptions.xml" \
  -strict=false \
  -output html
