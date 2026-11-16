APP := build/Up.app
RUN_ARGS ?=
ICON := Support/AppIcon.icns
ICONSET := build/AppIcon.iconset

.PHONY: build test icon app run install clean

build:
	swift build -c release

test:
	swift test

icon:
	swift Scripts/make-icon.swift $(ICONSET)
	iconutil -c icns -o $(ICON) $(ICONSET)

app: build
	rm -rf $(APP)
	mkdir -p $(APP)/Contents/MacOS $(APP)/Contents/Resources
	cp "$$(swift build -c release --show-bin-path)/Up" $(APP)/Contents/MacOS/Up
	cp Support/Info.plist $(APP)/Contents/Info.plist
	cp $(ICON) $(APP)/Contents/Resources/AppIcon.icns
	codesign --force --sign - $(APP)

run: app
	# open reuses a running instance and drops --args, so quit it and force a new one.
	-pkill -x Up
	open -n $(APP) --args $(RUN_ARGS)

install: app
	rm -rf /Applications/Up.app
	cp -R $(APP) /Applications/Up.app

clean:
	rm -rf .build build
