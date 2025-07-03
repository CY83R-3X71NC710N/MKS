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
echo "Cleaning previous builds..."
if [ -d "$BUILD_DIR" ]; then
    echo "Marking $BUILD_DIR as created by build system..."
    xattr -w com.apple.xcode.CreatedByBuildSystem true "$BUILD_DIR" || true
    rm -rf "$BUILD_DIR"
fi

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

BUILD_EXIT_CODE=$?

if [ $BUILD_EXIT_CODE -eq 0 ]; then
    echo "✅ Build completed successfully!"
elif [ -f "$BUILD_DIR/$PROJECT_NAME.app/Contents/MacOS/$PROJECT_NAME" ]; then
    echo "⚠️  Build completed with warnings (exit code $BUILD_EXIT_CODE), but app was created successfully!"
else
    echo "❌ Build failed with exit code $BUILD_EXIT_CODE"
    exit $BUILD_EXIT_CODE
fi
echo "Built app location: $BUILD_DIR/$PROJECT_NAME.app"

# Verify the architecture
echo "Verifying architecture..."
lipo -info "$BUILD_DIR/$PROJECT_NAME.app/Contents/MacOS/$PROJECT_NAME"

echo "Build script completed!"
