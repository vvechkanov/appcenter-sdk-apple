#!/bin/sh

# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

# Work dir is directory where all XCFramework artifacts is stored.
BUILD_DIR=build
WORK_DIR="${SRCROOT}/../AppCenter-SDK-Apple/xcframework"

# Work dir will be the final output to the framework.
XC_FRAMEWORK_PATH="${WORK_DIR}/Output/${PROJECT_NAME}.xcframework"

# Clean previus XCFramework build.
rm -rf ${PROJECT_NAME}.xcframework/

# Build and move mac catalyst framework
xcodebuild -project "${SRCROOT}/${PROJECT_NAME}.xcodeproj" -configuration "${CONFIGURATION}" -scheme "${PROJECT_NAME} iOS Framework" -destination 'platform=macOS,variant=Mac Catalyst'

# Create a command to build XCFramework.
for SDK in iphoneos iphonesimulator appletvos appletvsimulator macOS maccatalyst; do
    FRAMEWORK_PATH="${BUILD_DIR}/${CONFIGURATION}-${SDK}/${PROJECT_NAME}.framework"
    [ -e "${FRAMEWORK_PATH}" ] && XC_BUILD_COMMAND="${XC_BUILD_COMMAND} -framework ${FRAMEWORK_PATH}";
done
XC_BUILD_COMMAND="xcodebuild -create-xcframework ${XC_BUILD_COMMAND} -output ${XC_FRAMEWORK_PATH}"

#Build XCFramework
eval "$XC_BUILD_COMMAND"

RES_FILE_PATH="${BUILD_DIR}/${CONFIGURATION}-iphoneos/AppCenterDistributeResources.bundle"
if [[ ${PROJECT_NAME} == "AppCenterDistribute" ]] && [ -e "${RES_FILE_PATH}" ]; then
    mv "${RES_FILE_PATH}" "${XC_FRAMEWORK_PATH}"
fi

rm -rf "$XC_FRAMEWORK_PATH"

