#!/bin/bash
# =============================================================================
# OTA Update Publishing Script
# =============================================================================
# This script generates the release_manifest.json for a new APK release and
# uploads it to the update server along with the APK file.
#
# Usage:
#   ./publish_update.sh <version> <build_number> <apk_path>
#
# Example:
#   ./publish_update.sh 1.0.56 806 build/app/outputs/flutter-apk/app-release.apk
#
# Prerequisites:
#   - sha256sum (Linux) or shasum (macOS) must be available
#   - SSH access to the update server (or adjust UPLOAD_CMD below)
# =============================================================================

set -euo pipefail

VERSION="${1:?Usage: $0 <version> <build_number> <apk_path>}"
BUILD_NUMBER="${2:?Usage: $0 <version> <build_number> <apk_path>}"
APK_PATH="${3:?Usage: $0 <version> <build_number> <apk_path>}"
MIN_SUPPORTED_BUILD=800

# Server configuration — adjust these to match your hosting setup
SERVER_HOST="aldhakereen.com"
SERVER_USER="deploy"
SERVER_PATH="/var/www/update"

if [ ! -f "$APK_PATH" ]; then
    echo "Error: APK file not found at $APK_PATH"
    exit 1
fi

# Calculate SHA-256 checksum
if command -v sha256sum &> /dev/null; then
    SHA256=$(sha256sum "$APK_PATH" | awk '{print $1}')
elif command -v shasum &> /dev/null; then
    SHA256=$(shasum -a 256 "$APK_PATH" | awk '{print $1}')
else
    echo "Error: Neither sha256sum nor shasum found"
    exit 1
fi

APK_FILENAME="aldhakereen.apk"
APK_URL="https://${SERVER_HOST}/api/update/${APK_FILENAME}"

# Generate manifest
MANIFEST=$(cat <<EOF
{
  "version": "${VERSION}",
  "build_number": ${BUILD_NUMBER},
  "min_supported_build": ${MIN_SUPPORTED_BUILD},
  "apk_url": "${APK_URL}",
  "sha256": "${SHA256}"
}
EOF
)

echo "$MANIFEST"
echo ""
echo "Manifest generated successfully."
echo "APK SHA-256: $SHA256"
echo ""

# Save manifest locally
echo "$MANIFEST" > release_manifest.json
echo "Saved release_manifest.json"

# Upload to server
echo ""
echo "Uploading to ${SERVER_HOST}:${SERVER_PATH}/ ..."
scp "$APK_PATH" "${SERVER_USER}@${SERVER_HOST}:${SERVER_PATH}/${APK_FILENAME}"
scp release_manifest.json "${SERVER_USER}@${SERVER_HOST}:${SERVER_PATH}/release_manifest.json"

echo "Done! Update is now live."
