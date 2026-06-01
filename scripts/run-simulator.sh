#!/usr/bin/env bash
set -euo pipefail

SCHEME="${SCHEME:-OccultSuccess}"
SIMULATOR_NAME="${SIMULATOR_NAME:-iPhone 17}"
BUNDLE_ID="${BUNDLE_ID:-occultsuccess.OccultSuccess}"
DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-.build/XcodeDerived}"
APP_BUNDLE="${APP_BUNDLE:-.build/OccultSuccess.app}"

cd "$(dirname "$0")/.."

xcrun simctl runtime scan-and-mount >/dev/null

SIMULATOR_ID="$(
  xcrun simctl list devices available |
    grep -E "^[[:space:]]+${SIMULATOR_NAME} \\(" |
    head -1 |
    sed -E 's/.*\(([A-F0-9-]+)\).*/\1/'
)"

if [[ -z "${SIMULATOR_ID}" ]]; then
  echo "Simulator '${SIMULATOR_NAME}' not found. Install an iOS Simulator runtime in Xcode > Settings > Components." >&2
  exit 1
fi

xcodebuild \
  -scheme "${SCHEME}" \
  -destination "platform=iOS Simulator,id=${SIMULATOR_ID}" \
  -derivedDataPath "${DERIVED_DATA_PATH}" \
  build

PRODUCT_DIR="${DERIVED_DATA_PATH}/Build/Products/Debug-iphonesimulator"
EXECUTABLE="${PRODUCT_DIR}/${SCHEME}"

rm -rf "${APP_BUNDLE}"
mkdir -p "${APP_BUNDLE}"
cp "${EXECUTABLE}" "${APP_BUNDLE}/${SCHEME}"

cat > "${APP_BUNDLE}/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>ru</string>
  <key>CFBundleExecutable</key>
  <string>${SCHEME}</string>
  <key>CFBundleIdentifier</key>
  <string>${BUNDLE_ID}</string>
  <key>CFBundleName</key>
  <string>${SCHEME}</string>
  <key>CFBundleDisplayName</key>
  <string>Occult Success</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>1.0</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>LSRequiresIPhoneOS</key>
  <true/>
  <key>MinimumOSVersion</key>
  <string>17.0</string>
  <key>UIApplicationSceneManifest</key>
  <dict>
    <key>UIApplicationSupportsMultipleScenes</key>
    <false/>
  </dict>
  <key>UILaunchScreen</key>
  <dict/>
  <key>UIDeviceFamily</key>
  <array>
    <integer>1</integer>
    <integer>2</integer>
  </array>
</dict>
</plist>
EOF

codesign --force --sign - "${APP_BUNDLE}"

xcrun simctl boot "${SIMULATOR_ID}" 2>/dev/null || true
xcrun simctl bootstatus "${SIMULATOR_ID}" -b
open -a Simulator
xcrun simctl install "${SIMULATOR_ID}" "${APP_BUNDLE}"
xcrun simctl launch "${SIMULATOR_ID}" "${BUNDLE_ID}"

echo "Launched ${BUNDLE_ID} on ${SIMULATOR_NAME} (${SIMULATOR_ID})."
