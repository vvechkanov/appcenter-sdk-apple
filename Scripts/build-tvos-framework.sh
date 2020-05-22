#!/bin/sh

# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.
set -e

# Sets the target folders and the final framework product.
TARGET_NAME="${PROJECT_NAME} tvOS Framework"

echo "Building ${TARGET_NAME}."

# Install dir will be the final output to the framework.
# The following line create it in the root folder of the current project.
WORK_DIR=build
BUILD_DIR="${SRCROOT}/../AppCenter-SDK-Apple/tvOS"
TEMP_DIR="${SRCROOT}/../AppCenter-SDK-Apple/temp"

# Working dir will be deleted after the framework creation.
TEMP_DEVICE_DIR="${TEMP_DIR}/${CONFIGURATION}-appletvos/"
TEMP_SIMULATOR_DIR="${TEMP_DIR}/${CONFIGURATION}-appletvsimulator/"

# Make sure we're inside $SRCROOT.
cd "${SRCROOT}"

# Cleaning the previous build.
if [ -d "${BUILD_DIR}" ]; then rm -rf "${BUILD_DIR}"; fi
if [ -d "${TEMP_DEVICE_DIR}" ]; then rm -Rf "${TEMP_DEVICE_DIR}"; fi
if [ -d "${TEMP_SIMULATOR_DIR}" ]; then rm -Rf "${TEMP_SIMULATOR_DIR}"; fi

# Create temp directories.
mkdir -p "${BUILD_DIR}"
mkdir -p "${TEMP_DEVICE_DIR}"
mkdir -p "${TEMP_SIMULATOR_DIR}"

# Building both architectures.
xcodebuild -project "${PROJECT_NAME}.xcodeproj" -configuration "${CONFIGURATION}" -target "${TARGET_NAME}" clean

xcodebuild -project "${PROJECT_NAME}.xcodeproj" -configuration "${CONFIGURATION}" -target "${TARGET_NAME}" -sdk appletvos CONFIGURATION_BUILD_DIR="${TEMP_DEVICE_DIR}"
xcodebuild -project "${PROJECT_NAME}.xcodeproj" -configuration "${CONFIGURATION}" -target "${TARGET_NAME}" -sdk appletvsimulator CONFIGURATION_BUILD_DIR="${TEMP_SIMULATOR_DIR}"

# Copy framework.
cp -R "${TEMP_DEVICE_DIR}/${PROJECT_NAME}.framework" "${BUILD_DIR}"

# # Uses the Lipo Tool to merge both binary files (i386/x86_64 + armv7/armv7s/arm64) into one Universal final product.
lipo -create "${TEMP_DEVICE_DIR}/${PROJECT_NAME}.framework/${PROJECT_NAME}" "${TEMP_SIMULATOR_DIR}/${PROJECT_NAME}.framework/${PROJECT_NAME}" -output "${BUILD_DIR}/${PROJECT_NAME}.framework/${PROJECT_NAME}"