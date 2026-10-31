#!/usr/bin/env bash
set -euo pipefail
: "${GITHUB_WORKSPACE:?Must run in GitHub Actions workspace}"
: "${THEOS:?Theos not configured}"
UPSTREAM="$GITHUB_WORKSPACE/upstream"
PROJECT="$UPSTREAM/pluginDemo/h5frida15.1.24"
FRIDA_VERSION=17.25.0
DEVKIT_DIR="$RUNNER_TEMP/frida-core-devkit-$FRIDA_VERSION"
mkdir -p "$DEVKIT_DIR" "$GITHUB_WORKSPACE/build-results"

echo "::group::Download official Frida Core SDK for iOS arm64"
URL="https://github.com/frida/frida/releases/download/$FRIDA_VERSION/frida-core-devkit-$FRIDA_VERSION-ios-arm64.tar.xz"
curl --fail --location --retry 3 --connect-timeout 20 --max-time 900 "$URL" -o "$RUNNER_TEMP/frida-devkit.tar.xz"
tar -xJf "$RUNNER_TEMP/frida-devkit.tar.xz" -C "$DEVKIT_DIR"
find "$DEVKIT_DIR" -maxdepth 3 -type f | head -50
echo "::endgroup::"

CORE_HEADER=$(find "$DEVKIT_DIR" -name 'frida-core.h' -type f -print -quit)
CORE_LIB=$(find "$DEVKIT_DIR" -name 'libfrida-core.a' -type f -print -quit)
test -n "$CORE_HEADER" && test -n "$CORE_LIB" || {
  echo "Frida 17 devkit did not contain expected frida-core.h and libfrida-core.a" >&2
  exit 1
}
cp "$CORE_HEADER" "$PROJECT/frida-core-15.1.24.h"
cp "$CORE_LIB" "$PROJECT/libfrida-core-15.1.24.a"
/usr/bin/sed -i '' 's/FRIDA_CORE_VERSION  "15.1.24"/FRIDA_CORE_VERSION  "17.25.0"/' "$PROJECT/version.h"

echo "::group::Source and toolchain verification"
echo "THEOS=$THEOS"
xcodebuild -version
xcrun --sdk iphoneos --show-sdk-path
ls -lh "$PROJECT/libfrida-core-15.1.24.a" "$PROJECT/libdobby_fixed.a"
file "$PROJECT/libfrida-core-15.1.24.a" || true
grep 'FRIDA_CORE_VERSION' "$PROJECT/version.h"
echo "::endgroup::"

echo "::group::Theos compile for arm64 rootless"
# Diagnostic first attempt: original plugin source + Frida 17 SDK. 
# A source-level API port may be required after observing compiler errors.
make -C "$PROJECT" clean THEOS_PACKAGE_SCHEME=rootless \
    TARGET=iphone:clang:latest:15.0 ARCHS=arm64
make -C "$PROJECT" -j2 THEOS_PACKAGE_SCHEME=rootless \
    TARGET=iphone:clang:latest:15.0 ARCHS=arm64 \
    h5frida_FRAMEWORKS="Foundation UIKit JavaScriptCore" \
    2>&1 | tee "$GITHUB_WORKSPACE/build-results/build.log"
echo "::endgroup::"

echo "::group::Collect dylib, if built"
find "$PROJECT/.theos" -type f -name 'h5frida.dylib' -print | while read -r dylib; do
  cp "$dylib" "$GITHUB_WORKSPACE/build-results/h5frida17-rootless-UNSIGNED.dylib"
done
if [ -f "$GITHUB_WORKSPACE/build-results/h5frida17-rootless-UNSIGNED.dylib" ]; then
  file "$GITHUB_WORKSPACE/build-results/h5frida17-rootless-UNSIGNED.dylib"
  otool -L "$GITHUB_WORKSPACE/build-results/h5frida17-rootless-UNSIGNED.dylib" || true
else
  echo "No compiled dylib located; see build.log" >&2
  exit 1
fi
echo "::endgroup::"
