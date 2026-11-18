#!/bin/sh
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd -P)
cd "$root"
version=$(cat VERSION)
printf '%s\n' "$version" | grep -Eq '^(0|[1-9][0-9]{0,8})\.(0|[1-9][0-9]{0,8})\.(0|[1-9][0-9]{0,8})$'
case "$(uname -s)-$(uname -m)" in
    Darwin-arm64) platform=macos-arm64; ${MAKE:-make} studio-macos ;;
    Linux-x86_64) platform=linux-x64 ;;
    *) echo 'Unsupported release platform' >&2; exit 1 ;;
esac
work=$(mktemp -d "${TMPDIR:-/tmp}/vdb-release.XXXXXXXX")
trap 'rm -rf "$work"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
name="vdb-$platform"
package="$work/$name"
payload="$package/payload"
mkdir -p "$payload" dist
cp distribution/install.sh "$package/"
cp distribution/vdb-setup VERSION "$payload/"
printf '%s\n' "$platform" > "$payload/PLATFORM"
cp README.md "$package/"
cp studio/LICENSE-VPP "$package/"
cp studio/LICENSE-VPP "$payload/"
if [ "$platform" = macos-arm64 ]; then
    cp -R 'build/VDB Studio.app' "$payload/"
    clang -arch arm64 -fobjc-arc -framework Cocoa distribution/setup.m -o "$work/setup"
    for app in "$package/VDB Setup.app" "$payload/VDB Update.app"; do
        app_name=$(basename "$app" .app)
        case "$app_name" in
            'VDB Setup') mode=setup; update=false ;;
            'VDB Update') mode=update; update=true ;;
        esac
        mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
        cp "$work/setup" "$app/Contents/MacOS/setup"
        cp studio/VDB.icns "$app/Contents/Resources/"
        cat > "$app/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleIdentifier</key><string>vn.vdb.$mode</string>
<key>CFBundleName</key><string>$app_name</string>
<key>CFBundleExecutable</key><string>setup</string>
<key>CFBundleIconFile</key><string>VDB.icns</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>$version</string>
<key>CFBundleVersion</key><string>$version</string>
<key>LSMinimumSystemVersion</key><string>11.0</string>
<key>VDBUpdate</key><$update/>
</dict></plist>
PLIST
        plutil -lint "$app/Contents/Info.plist"
        codesign --force --sign - "$app"
    done
else
    mkdir -p "$payload/build" "$payload/studio"
    cp vdb VERSION "$payload/"
    touch "$payload/VDB_RELEASE"
    cp build/vdb-engine build/vdb-studio "$payload/build/"
    cp studio/index.html studio/serve "$payload/studio/"
fi
# Exclude extended attributes on macOS; no catalog or source cache enters the package.
COPYFILE_DISABLE=1 tar -C "$work" -czf "$work/$name.tar.gz" "$name"
(cd "$work" && if command -v sha256sum >/dev/null 2>&1; then sha256sum "$name.tar.gz"; else shasum -a 256 "$name.tar.gz"; fi > "$name.tar.gz.sha256")
mv "$work/$name.tar.gz" "$work/$name.tar.gz.sha256" dist/
printf 'Release %s: dist/%s.tar.gz\n' "$version" "$name"
