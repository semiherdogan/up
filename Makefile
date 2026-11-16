APP := build/Up.app

.PHONY: build test app run install clean

build:
	swift build -c release

test:
	swift test

app: build
	rm -rf $(APP)
	mkdir -p $(APP)/Contents/MacOS
	cp "$$(swift build -c release --show-bin-path)/Up" $(APP)/Contents/MacOS/Up
	cp Support/Info.plist $(APP)/Contents/Info.plist
	codesign --force --sign - $(APP)

run: app
	open $(APP)

install: app
	rm -rf /Applications/Up.app
	cp -R $(APP) /Applications/Up.app

clean:
	rm -rf .build build
