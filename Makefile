APP := build/Up.app
RUN_ARGS ?=
ICON := Support/AppIcon.icns
ICONSET := build/AppIcon.iconset
# Info.plist owns the default version; a release overrides it with VERSION=x.y.z.
VERSION ?= $(shell plutil -extract CFBundleShortVersionString raw Support/Info.plist)
# For example "--arch arm64 --arch x86_64" for a universal binary.
SWIFT_BUILD_FLAGS ?=
DIST := build/Up-$(VERSION).zip

.PHONY: build test icon app dist run install clean

build:
	swift build -c release $(SWIFT_BUILD_FLAGS)

test:
	swift test

icon:
	swift Scripts/make-icon.swift $(ICONSET)
	iconutil -c icns -o $(ICON) $(ICONSET)
	cp $(ICONSET)/icon_128x128@2x.png docs/icon.png

app: build
	rm -rf $(APP)
	mkdir -p $(APP)/Contents/MacOS $(APP)/Contents/Resources
	cp "$$(swift build -c release $(SWIFT_BUILD_FLAGS) --show-bin-path)/Up" $(APP)/Contents/MacOS/Up
	cp Support/Info.plist $(APP)/Contents/Info.plist
	plutil -replace CFBundleShortVersionString -string "$(VERSION)" $(APP)/Contents/Info.plist
	cp $(ICON) $(APP)/Contents/Resources/AppIcon.icns
	codesign --force --sign - $(APP)

dist: app
	# ditto keeps the bundle's signature and metadata intact inside the zip.
	ditto -c -k --keepParent $(APP) $(DIST)

run: app
	# open reuses a running instance and drops --args, so quit it and force a new one.
	-pkill -x Up
	open -n $(APP) --args $(RUN_ARGS)

install: app
	rm -rf /Applications/Up.app
	cp -R $(APP) /Applications/Up.app

clean:
	rm -rf .build build
