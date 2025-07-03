#!/bin/bash

# MKS Build Script for arm64
# Run this script on a macOS system with Xcode installed

set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_NAME="MKS"
SCHEME="MKS"
CONFIGURATION="Release"
ARCH="arm64"
BUILD_DIR="$PROJECT_DIR/build"

echo "Building $PROJECT_NAME for $ARCH..."

# Clean previous builds
if [ -d "$BUILD_DIR" ]; then
    echo "Marking $BUILD_DIR as created by build system..."
    xattr -w com.apple.xcode.CreatedByBuildSystem true "$BUILD_DIR" || true
fi

echo "Cleaning previous builds..."
rm -rf "$BUILD_DIR"

# Build the project (disable code signing for local builds)
echo "Building project..."
xcodebuild \
    -project "$PROJECT_DIR/$PROJECT_NAME.xcodeproj" \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -arch "$ARCH" \
    -derivedDataPath "$BUILD_DIR/DerivedData" \
    CONFIGURATION_BUILD_DIR="$BUILD_DIR" \
    CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO \
    clean build

echo "Build completed successfully!"
echo "Built app location: $BUILD_DIR/$PROJECT_NAME.app"

# Verify the architecture
echo "Verifying architecture..."
lipo -info "$BUILD_DIR/$PROJECT_NAME.app/Contents/MacOS/$PROJECT_NAME"

echo "Build script completed!"
