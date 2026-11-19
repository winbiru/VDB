VPP ?= $(or $(shell command -v vpp 2>/dev/null),$(HOME)/V++/VPP)
BUILD := build/vdb-engine
SOURCES := $(shell find src -type f -name '*.vi')
MAC_APP := build/VDB Studio.app
MAC_BIN := build/VDB\ Studio.app/Contents/MacOS/vdb-studio-macos

.PHONY: all test test-constants studio clean
all: $(BUILD)

$(BUILD): $(SOURCES)
	mkdir -p build
	"$(VPP)" build src/chinh.vi -o "$@"

build/vdb-studio: studio/server.vi
	mkdir -p build
	"$(VPP)" build studio/server.vi -o "$@"

$(MAC_BIN): studio/macos_arm64.S studio/Info.plist VERSION
	mkdir -p "$(MAC_APP)/Contents/MacOS"
	cp studio/Info.plist "$(MAC_APP)/Contents/Info.plist"
	/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $$(cat VERSION)" "$(MAC_APP)/Contents/Info.plist"
	/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $$(cat VERSION)" "$(MAC_APP)/Contents/Info.plist"
	clang -arch arm64 studio/macos_arm64.S -framework Cocoa -framework WebKit -o "$@"

.PHONY: studio-macos
studio-macos: $(MAC_BIN) $(BUILD) build/vdb-studio studio/launch-macos studio/index.html studio/serve studio/VDB.icns studio/LICENSE-VPP vdb VERSION
	mkdir -p "$(MAC_APP)/Contents/Resources/build" "$(MAC_APP)/Contents/Resources/studio"
	cp studio/VDB.icns studio/LICENSE-VPP "$(MAC_APP)/Contents/Resources/"
	cp vdb VERSION "$(MAC_APP)/Contents/Resources/"
	cp $(BUILD) build/vdb-studio "$(MAC_APP)/Contents/Resources/build/"
	cp studio/index.html studio/serve "$(MAC_APP)/Contents/Resources/studio/"
	cp studio/launch-macos "$(MAC_APP)/Contents/MacOS/launch-vdb-studio"
	chmod +x "$(MAC_APP)/Contents/MacOS/launch-vdb-studio"

studio: all build/vdb-studio
	./vdb studio

test-constants:
	python3 tests/check_constants.py

test: test-constants all
	./tests/test.sh

.PHONY: benchmark-joins
build/vdb-benchmark-join: $(SOURCES)
	mkdir -p build
	"$(VPP)" build src/benchmark_join.vi -o "$@"

benchmark-joins: build/vdb-benchmark-join
	python3 tests/benchmark_joins.py "$<"

.PHONY: test-studio test-studio-state
test-studio: all build/vdb-studio
	python3 tests/studio_api.py

test-studio-state:
	node tests/studio_state.js

clean:
	rm -f "$(BUILD)" build/vdb-studio
	rm -rf "$(MAC_APP)"

.PHONY: release test-release
release: all build/vdb-studio
	./distribution/package.sh
test-release: release
	./tests/distribution.sh
