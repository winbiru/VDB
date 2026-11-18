#!/bin/sh
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd -P)
case "$(uname -s)-$(uname -m)" in
    Darwin-arm64) platform=macos-arm64; cli='VDB Studio.app/Contents/Resources/vdb' ;;
    Linux-x86_64) platform=linux-x64; cli=vdb ;;
    *) exit 1 ;;
esac
asset="vdb-$platform.tar.gz"
checksum() {
    if command -v sha256sum >/dev/null 2>&1; then sha256sum "$@"; else shasum -a 256 "$@"; fi
}
(cd "$root/dist" && checksum -c "$asset.sha256")
work=$(mktemp -d "${TMPDIR:-/tmp}/vdb-install-test.XXXXXXXX")
trap 'rm -rf "$work"' EXIT
export HOME="$work/home"
export XDG_DATA_HOME="$HOME/data"
export VDB_STUDIO_DATA_DIR="$HOME/studio-data"
export VDB_INSTALL_ROOT="$HOME/program có dấu nháy ' và khoảng trắng"
export VDB_BIN_DIR="$HOME/bin"
export VDB_APPLICATIONS_DIR="$HOME/Applications"
mkdir -p "$HOME"
tar -C "$work" -xzf "$root/dist/$asset"
pkg="$work/vdb-$platform"
version=$(cat "$root/VERSION")
# Refuse to replace an unrelated launcher.
mkdir -p "$VDB_BIN_DIR"
printf 'unrelated\n' > "$VDB_BIN_DIR/vdb"
if "$pkg/install.sh" --yes; then exit 1; fi
[ "$(cat "$VDB_BIN_DIR/vdb")" = unrelated ]
rm "$VDB_BIN_DIR/vdb"
"$pkg/install.sh" --yes
[ "$("$VDB_BIN_DIR/vdb" --version)" = "VDB $version" ]
[ "$(readlink "$VDB_INSTALL_ROOT/current")" = "versions/$version" ]
"$VDB_BIN_DIR/vdb" -e 'CREATE TABLE demo (id INT); INSERT INTO demo VALUES (42);'
case "$platform" in
    macos-arm64)
        catalog="$VDB_STUDIO_DATA_DIR/vdb.json"
        [ -L "$VDB_APPLICATIONS_DIR/VDB Studio.app" ]
        [ -L "$VDB_APPLICATIONS_DIR/VDB Update.app" ]
        "$pkg/VDB Setup.app/Contents/MacOS/setup" --check
        "$VDB_APPLICATIONS_DIR/VDB Update.app/Contents/MacOS/setup" --check
        plutil -lint "$VDB_INSTALL_ROOT/current/VDB Studio.app/Contents/Info.plist"
        codesign --verify "$pkg/VDB Setup.app"
        codesign --verify "$VDB_INSTALL_ROOT/current/VDB Update.app"
        ;;
    linux-x64) catalog="$XDG_DATA_HOME/vdb/vdb.json" ;;
esac
before=$(checksum "$catalog")
# Same-version installation repairs a missing launcher. Upgrade through the actual update flow using a local
# curl fixture; do not contact GitHub or mutate the user's installation.
rm "$VDB_BIN_DIR/vdb"
"$pkg/install.sh" --yes
[ "$("$VDB_BIN_DIR/vdb" --version)" = "VDB $version" ]
next=$(printf '%s\n' "$version" | awk -F. '{printf "%d.%d.%d",$1,$2,$3+1}')
printf '%s\n' "$next" > "$pkg/payload/VERSION"
printf '%s\n' "$next" > "$(dirname "$pkg/payload/$cli")/VERSION"
mkdir -p "$work/mock" "$work/download"
COPYFILE_DISABLE=1 tar -C "$work" -czf "$work/download/$asset" "vdb-$platform"
(cd "$work/download" && checksum "$asset" > "$asset.sha256")
cat > "$work/mock/curl" <<'MOCK'
#!/bin/sh
set -eu
out=''
while [ "$#" -gt 1 ]; do
    case "$1" in -o) out=$2; shift 2 ;; *) shift ;; esac
done
case "$1" in
    */releases/latest) printf 'https://github.com/winbiru/VDB/releases/tag/v%s' "$TEST_NEXT" ;;
    */releases/download/*) cp "$TEST_DOWNLOAD/${1##*/}" "$out" ;;
    *) exit 1 ;;
esac
MOCK
chmod +x "$work/mock/curl"
export TEST_NEXT="$next" TEST_DOWNLOAD="$work/download"
export PATH="$work/mock:$PATH"
# Corrupt checksum must leave the active release intact.
cp "$work/download/$asset.sha256" "$work/checksum"
printf 'bad\n' > "$work/download/$asset.sha256"
if "$VDB_BIN_DIR/vdb" update --yes; then exit 1; fi
[ "$("$VDB_BIN_DIR/vdb" --version)" = "VDB $version" ]
cp "$work/checksum" "$work/download/$asset.sha256"
# Even with a valid digest, reject an archive containing links.
cp "$work/download/$asset" "$work/valid.tar.gz"
ln -s /tmp "$pkg/payload/unsafe-link"
COPYFILE_DISABLE=1 tar -C "$work" -czf "$work/download/$asset" "vdb-$platform"
(cd "$work/download" && checksum "$asset" > "$asset.sha256")
if "$VDB_BIN_DIR/vdb" update --yes; then exit 1; fi
[ "$("$VDB_BIN_DIR/vdb" --version)" = "VDB $version" ]
rm "$pkg/payload/unsafe-link"
mv "$work/valid.tar.gz" "$work/download/$asset"
cp "$work/checksum" "$work/download/$asset.sha256"
# An active Studio state lock must prevent publication.
(
    exec 8>>"$(dirname "$catalog")/studio-state.json.lock"
    case "$platform" in
        macos-arm64) lockf -s -t 0 8 ;;
        linux-x64) flock -n 8 ;;
    esac
    if "$VDB_BIN_DIR/vdb" update --yes; then exit 1; fi
    [ "$("$VDB_BIN_DIR/vdb" --version)" = "VDB $version" ]
)
"$VDB_BIN_DIR/vdb" update --yes
[ "$("$VDB_BIN_DIR/vdb" --version)" = "VDB $next" ]
[ -d "$VDB_INSTALL_ROOT/versions/$version" ]
[ "$before" = "$(checksum "$catalog")" ]
"$VDB_BIN_DIR/vdb" -e 'SELECT * FROM demo;' | grep -Fq '"rows":[[42]]'
"$VDB_BIN_DIR/vdb" update --yes
# Local older package must not replace newer active version.
tar -C "$work" -xzf "$root/dist/$asset"
if "$pkg/install.sh" --yes; then exit 1; fi
[ "$("$VDB_BIN_DIR/vdb" --version)" = "VDB $next" ]
printf 'VDB distribution tests: PASS\n'
