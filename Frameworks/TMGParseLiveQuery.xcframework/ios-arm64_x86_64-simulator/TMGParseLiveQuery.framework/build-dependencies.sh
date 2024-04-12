#!/bin/bash

rm -rf "Frameworks"
mkdir "Frameworks"

Bolts_Version="1.9.1"
BoltsSwift_Version="1.5.0"
Parse_Version="1.19.4"
Starscream_Version="4.0.6"

# Git

# Build Starscream
echo "Building Starscream (${Starscream_Version}) from git"
./build-xcframework-from-git.sh \
    "https://github.com/daltoniam/Starscream.git" \
    "${Starscream_Version}" \
    "Starscream" \
    "Starscream" \
    "Starscream"

# Pod

# Build Bolts-Swift
echo "Building Bolts-Swift (${BoltsSwift_Version}) from pod"
./build-xcframework-from-pod.sh \
    "Bolts-Swift" \
    "Bolts-Swift" \
    "BoltsSwift" \
    "Bolts-Swift" \
    "${BoltsSwift_Version}"

# Build Bolts
echo "Building Bolts (${Bolts_Version}) from pod"
./build-xcframework-from-pod.sh \
    "Bolts" \
    "Bolts" \
    "Bolts" \
    "Bolts" \
    "${Bolts_Version}"

./build-parse.sh "${Parse_Version}"
