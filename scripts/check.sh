#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_PATH="$ROOT_DIR/PPLAITrainer.xcodeproj"
SCHEME="PPLAITrainer"

if [[ "$(uname -s)" != "Darwin" ]] || ! command -v xcodebuild >/dev/null 2>&1; then
  echo "macOS/Xcode not available. Running cloud-safe checks..."
  exec "$ROOT_DIR/scripts/check-cloud.sh"
fi

BUILD_ROOT="$ROOT_DIR/.build"
DERIVED_DATA_PATH="$BUILD_ROOT/DerivedData"
SOURCE_PACKAGES_PATH="$BUILD_ROOT/SourcePackages"
HOME_PATH="$BUILD_ROOT/home"
TMP_PATH="$BUILD_ROOT/tmp"
CLANG_MODULE_CACHE_PATH="$BUILD_ROOT/ModuleCache.noindex"
SWIFT_MODULE_CACHE_PATH="$BUILD_ROOT/SwiftModuleCache.noindex"

mkdir -p \
  "$DERIVED_DATA_PATH" \
  "$SOURCE_PACKAGES_PATH" \
  "$HOME_PATH" \
  "$TMP_PATH" \
  "$CLANG_MODULE_CACHE_PATH" \
  "$SWIFT_MODULE_CACHE_PATH"

export HOME="$HOME_PATH"
export TMPDIR="$TMP_PATH/"
export CLANG_MODULE_CACHE_PATH
export SWIFT_MODULECACHE_PATH="$SWIFT_MODULE_CACHE_PATH"

echo "Running xcodebuild for scheme '$SCHEME'..."

xcodebuild \
  -project "$PROJECT_PATH" \
  -scheme "$SCHEME" \
  -configuration Debug \
  -destination "generic/platform=iOS" \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  -clonedSourcePackagesDirPath "$SOURCE_PACKAGES_PATH" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  build

echo "Build check completed."
