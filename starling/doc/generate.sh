#!/bin/bash

# This script creates a nice API reference documentation for the Starling source.
# It uses the "ASDoc" tool that comes with the Flex SDK.
# Adapt the ASDOC variable below so that it points to the correct path.

if [ $# -ne 1 ]
then
  echo "Usage: `basename $0` [version]"
  echo "  (version like '1.0')"
  exit 1
fi

version=$1
ASDOC="/Applications/Adobe Flash Builder 4.7/sdks/4.6.0/bin/asdoc"

"${ASDOC}" \
  -doc-sources ../src \
  -exclude-classes com.adobe.utils.AGALMiniAssembler \
  -main-title "Starling Framework Reference (v$version)" \
  -window-title "Starling Framework Reference" \
  -package starling.animation "The components of Starlings animation system." \
  -package starling.core "Contains the core class of the framework and a rendering utility class." \
  -package starling.display "The main classes from which to build anything that is displayed on the screen." \
  -package starling.errors "A set of commonly used error classes." \
  -package starling.events "A simplified version of Flash's DOM event model, including an alternative EventDispatcher base class." \
  -package starling.text "Classes for working with text fields and bitmap fonts." \
  -package starling.textures "Classes to create and work with GPU texture data." \
  -package starling.utils "Utility classes and helper methods." \
  -package starling.filters "Post processing filters for special effects." \
  -output html

