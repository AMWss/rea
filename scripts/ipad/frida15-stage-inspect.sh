#!/bin/sh
# Shengsheng iPad / Dopamine Rootless: inspect upstream Frida 15.1.24 Debian package.
# Safety: download and extract ONLY. Do NOT install, relink, sign, execute or stop server.
set -eu
umask 077
VERSION=15.1.24
EXPECTED_BYTES=15946768
URL="https://github.com/frida/frida/releases/download/${VERSION}/frida_${VERSION}_iphoneos-arm.deb"
BASE="${HOME:-/var/mobile}/frida15-compat-inspection"
DEB="$BASE/frida_${VERSION}_iphoneos-arm.deb"
OUT="$BASE/extracted"
say() { printf '\n=== %s ===\n' "$1"; }
fail() { printf 'ERROR: %s\n' "$1" >&2; exit 1; }
for t in curl dpkg-deb wc find; do command -v "$t" >/dev/null 2>&1 || fail "$t unavailable"; done
[ "$(id -u)" = 0 ] || fail "Run from your root NewTerm session (sudo sh script.sh)."
mkdir -p "$BASE"
say "Package metadata (official Frida GitHub release)"
printf 'Version: %s\nURL: %s\nExpected bytes: %s\n' "$VERSION" "$URL" "$EXPECTED_BYTES"
printf 'Workspace: %s\n' "$BASE"
if [ -f "$DEB" ]; then
  size=$(wc -c < "$DEB" | tr -d ' ')
  if [ "$size" != "$EXPECTED_BYTES" ]; then
    printf 'Previously downloaded file has wrong size (%s), will re-download.\n' "$size"
    rm -f "$DEB"
  fi
fi
if [ ! -f "$DEB" ]; then
  tmp="$BASE/frida-download-$$.part"
  trap 'rm -f "$tmp"' EXIT HUP INT TERM
  curl -fL --retry 2 --connect-timeout 15 --max-time 240 "$URL" -o "$tmp"
  size=$(wc -c < "$tmp" | tr -d ' ')
  [ "$size" = "$EXPECTED_BYTES" ] || fail "Downloaded file size mismatch: $size"
  mv "$tmp" "$DEB"
  trap - EXIT HUP INT TERM
fi
say "Downloaded package checks"
dpkg-deb -f "$DEB" Package Version Architecture 2>&1 || fail "Not a valid Debian package"
arch=$(dpkg-deb -f "$DEB" Architecture 2>/dev/null || true)
[ "$arch" = "iphoneos-arm" ] || fail "Unexpected architecture: $arch"
if command -v shasum >/dev/null 2>&1; then
  shasum -a 256 "$DEB" 2>/dev/null || true
fi
say "Extracting to isolated workspace (NOT installing)"
mkdir -p "$OUT"
dpkg-deb -x "$DEB" "$OUT"
say "Server and agent files"
find "$OUT" -type f \( -name 'frida-server' -o -name 'frida-agent.dylib' -o -name '*frida*.dylib' \) -print
say "Inspecting the server binary (do NOT execute)"
find "$OUT" -type f -name 'frida-server' | while IFS= read -r f; do
  ls -lh "$f"
  if command -v file >/dev/null 2>&1; then file "$f" 2>&1 || true; fi
  if command -v otool >/dev/null 2>&1; then otool -L "$f" 2>&1 || true; fi
  if command -v ldid >/dev/null 2>&1; then
    printf '%s\n' 'Code-sign entitlements, if inspectable:'
    ldid -e "$f" 2>&1 || true
  fi
done
say "Current FridaManager server - untouched"
if command -v frida-server >/dev/null 2>&1; then
  frida-server --version 2>&1 || true
fi
ps -A 2>&1 | grep '[f]rida-server' || true
say "Finished"
printf '%s\n' "Only downloaded and extracted files inside: $BASE"
printf '%s\n' "No package installed. No signature changes. Existing frida-server untouched."
printf '%s\n' "Please send output from Package checks, Server and agent files, and Inspecting the server binary."
