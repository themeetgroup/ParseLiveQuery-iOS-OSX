#!/bin/bash

TMGCOMMON_SHARED=$(pwd)
DEPENDENCIES="${TMGCOMMON_SHARED}/Dependencies"
# Get framework locations
PARSE_LOCATION="${DEPENDENCIES}/ParseCore.xcframework"
SHARED_PARSE_LQ_LOCATION="${DEPENDENCIES}/TMGParseLiveQuery.xcframework"
# Delete the old version
rm -rf ${SHARED_PARSE_LQ_LOCATION}
# Currently assume the ParseLiveQuery-iOS-OSX repo is up one dir
cd "../ParseLiveQuery-iOS-OSX"

# Delete old version of frameworks
rm -rf "Dependencies/TMGParseLiveQuery.xcframework"

# Copy the needed ParseCore framework
cp -r ${PARSE_LOCATION} "Dependencies/ParseCore.xcframework"

# Delete the old version of TMGParseLiveQuery
PARSE_LIVE_QUERY_LOCATION="Dependencies/TMGParseLiveQuery.xcframework"
rm -rf ${PARSE_LIVE_QUERY_LOCATION}

# Build TMGParseLiveQuery
./build-framework.sh

# Move final output back to TMGCommonShared
cp -r ${PARSE_LIVE_QUERY_LOCATION} ${SHARED_PARSE_LQ_LOCATION}
