#!/bin/bash
# Build sheepct.dylib cho iOS (arm64) — CHAY TREN MACOS CO XCODE, KHONG CHAY TREN LINUX
# Yeu cau: macOS + Xcode + Command Line Tools, iPhoneOS SDK.
set -euo pipefail
cd "$(dirname "$0")"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "Loi: script nay can chay tren macOS (uname = $(uname -s))."
  echo "May Linux khong co Xcode / iPhoneOS SDK nen khong build duoc file Mach-O arm64 that."
  exit 1
fi

if ! command -v xcrun >/dev/null 2>&1; then
  echo "Loi: khong tim thay xcrun. Cai Xcode va Command Line Tools truoc."
  exit 1
fi

SDK_PATH="$(xcrun --sdk iphoneos --show-sdk-path)"
echo "SDK: $SDK_PATH"

xcrun --sdk iphoneos clang++ \
  -arch arm64 \
  -miphoneos-version-min=14.0 \
  -std=c++17 \
  -O2 \
  -fPIC \
  -dynamiclib \
  -isysroot "$SDK_PATH" \
  mod.cpp \
  -o sheepct.dylib

echo "Build xong: sheepct.dylib"
file sheepct.dylib
lipo -info sheepct.dylib || true
otool -L sheepct.dylib || true
echo "Luu y: ky / inject tuy theo moi truong cua anh (jailbreak, TrollStore, sideload...). Script nay chi build file .dylib."
