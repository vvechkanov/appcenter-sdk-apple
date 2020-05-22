#!/bin/sh

# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.
set -e

# Sets the target folders and the final framework product.
TARGET_NAME="${PROJECT_NAME} macOS Framework"

echo "Building ${TARGET_NAME}."

# Install dir will be the final output to the framework.
# The following line create it in the root folder of the current project.
BUILD_DIR="${SRCROOT}/../AppCenter-SDK-Apple/${CONFIGURATION}-macOS"

# Working dir will be deleted after the framework creation.

# Make sure we're inside $SRCROOT.
cd "${SRCROOT}"

# Creates and renews the final product folder.
if [ -d "${BUILD_DIR}" ]; then rm -Rf "${BUILD_DIR}"; fi

# Creates and renews the final product folder.
mkdir -p "${BUILD_DIR}"

# Building both architectures.
xcodebuild -project "${PROJECT_NAME}.xcodeproj" -configuration "${CONFIGURATION}" -target "${TARGET_NAME}" clean
xcodebuild -project "${PROJECT_NAME}.xcodeproj" -configuration "${CONFIGURATION}" -target "${TARGET_NAME}" CONFIGURATION_BUILD_DIR="${BUILD_DIR}"


