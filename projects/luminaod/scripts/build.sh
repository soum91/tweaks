#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
: "${SDKROOT:?Set SDKROOT to an iPhoneOS SDK}"
: "${CC:?Set CC to iOS clang}"
: "${LDID:?Set LDID to ldid}"
: "${LIPO:?Set LIPO to lipo}"
mkdir -p build dist
stage="$PWD/build/stage"
rm -rf "$stage"
app="$stage/var/jb/Applications/LuminAOD.app"
tweak="$stage/var/jb/Library/MobileSubstrate/DynamicLibraries"
mkdir -p "$stage/DEBIAN" "$app" "$tweak"
flags=(-isysroot "$SDKROOT" -fobjc-arc -fblocks -Os -Wall -Wextra -Wno-unused-parameter -Wno-unused-function -Wno-incompatible-pointer-types -Werror=implicit-function-declaration -Wl,-headerpad,0x1000)
for arch in arm64 arm64e; do
  "$CC" -target "$arch-apple-ios16.1" "${flags[@]}" -dynamiclib -install_name /var/jb/Library/MobileSubstrate/DynamicLibraries/LuminAOD.dylib -framework UIKit -framework Foundation -framework CoreFoundation -framework CoreMotion src/Tweak.m -o "build/LuminAOD.$arch.dylib"
done
"$LIPO" -create build/LuminAOD.arm64.dylib build/LuminAOD.arm64e.dylib -output "$tweak/LuminAOD.dylib"
"$CC" -target arm64-apple-ios16.1 "${flags[@]}" -framework UIKit -framework Foundation -framework CoreFoundation src/App.m -o "$app/LuminAOD"
"$LDID" -S "$tweak/LuminAOD.dylib"
"$LDID" -Spackaging/entitlements.plist "$app/LuminAOD"
cp packaging/LuminAOD.plist "$tweak/"
cp packaging/control packaging/postinst packaging/postrm "$stage/DEBIAN/"
chmod 0755 "$stage/DEBIAN/postinst" "$stage/DEBIAN/postrm"
python3 scripts/metadata.py "$app"
dpkg-deb --root-owner-group -Zxz --build "$stage" dist/com.soum91.luminaod_0.1.0_iphoneos-arm64.deb
python3 scripts/validate.py dist/com.soum91.luminaod_0.1.0_iphoneos-arm64.deb
