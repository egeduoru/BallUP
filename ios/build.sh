#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
if [[ "$(uname -s)" != Darwin ]]; then echo 'This build requires macOS with Xcode.' >&2; exit 1; fi
BUILD="$(mktemp -d "$PWD/build.XXXXXX")"
APP="$BUILD/Payload/BallUP.app"
mkdir -p "$APP" dist
IPA="$PWD/dist/BallUP-1.0.0.ipa"
SDK="$(xcrun --sdk iphoneos --show-sdk-path)"
xcrun --sdk iphoneos swiftc -parse-as-library -swift-version 5 -O -target arm64-apple-ios15.0 -sdk "$SDK" -framework UIKit -framework WebKit App/Main.swift -o "$APP/BallUP"
cp App/index.html "$APP/index.html"
cp App/Info.plist "$APP/Info.plist"
xcrun actool App/Assets.xcassets --compile "$APP" --platform iphoneos --minimum-deployment-target 15.0 --target-device iphone --app-icon AppIcon --output-partial-info-plist "$BUILD/icons.plist"
/usr/libexec/PlistBuddy -c "Merge $BUILD/icons.plist" "$APP/Info.plist"
plutil -lint "$APP/Info.plist"
codesign --force --sign - "$APP"
codesign --verify --deep --strict "$APP"
(cd "$BUILD" && /usr/bin/zip -qr "$IPA" Payload)
unzip -t dist/BallUP-1.0.0.ipa
shasum -a 256 dist/BallUP-1.0.0.ipa
echo 'IPA built. Install and re-sign with your own Apple Account using AltStore Classic.'
