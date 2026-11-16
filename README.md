<p align="center">
  <img src="docs/icon.png" width="128" alt="Up icon">
</p>

# Up

A tiny macOS menu bar app that keeps your Mac awake. It runs the built-in `caffeinate -dims` for you, either for a fixed time or automatically on a weekly schedule.

## Features

- **One click sessions:** 15 minutes, 30 minutes, 1, 2 or 4 hours, or indefinitely.
- **Schedules:** pick weekdays and a time range, for example Monday to Friday, 08:30 to 19:00. Ranges may cross midnight.
- **Notifications:** when a schedule starts and when a session ends by itself.
- **Launch at login.**
- **No leftovers:** `caffeinate` is tied to the app, so it stops when Up quits or crashes.

## Install

1. Download `Up-x.y.z.zip` from the [latest release](../../releases/latest) and unzip it.
2. Move `Up.app` to `/Applications`.
3. Open it. Up is not notarized, so macOS blocks the first launch. Go to **System Settings > Privacy & Security**, scroll down and click **Open Anyway**.

If you prefer the terminal, this removes the download quarantine instead of step 3:

```sh
xattr -dr com.apple.quarantine /Applications/Up.app
```

Requires macOS 15 or later. Developed and tested on macOS 27.

## Usage

Click the cup in the menu bar.

- Pick a duration under **Keep Awake For** to start a session. The first line shows until when your Mac stays awake.
- **End Session** stops it. Inside a schedule, that schedule stays quiet until its current time range is over. Turn the schedule off and on to resume it earlier.
- **Schedules…** opens the schedule editor.

Up sends a notification when a schedule starts, when a session ends by itself, and when `caffeinate` fails. It stays silent for things you just did yourself.

## How it works

Up starts `/usr/bin/caffeinate -dims -w <pid of Up>` while a session or schedule is active and stops it otherwise. You can see it at work with:

```sh
pmset -g assertions | grep caffeinate
```

The flags prevent display sleep (`d`), idle sleep (`i`), disk sleep (`m`) and system sleep on AC power (`s`).

Closing the lid still puts the Mac to sleep. See [docs/roadmap.md](docs/roadmap.md) for that and other ideas that were left out on purpose.

## Build from source

Requires Xcode 16 or later.

```sh
make run      # build build/Up.app and launch it
make install  # copy it to /Applications
make test     # run the unit tests
```

## Releasing

Push a tag such as `v0.2.0`, or run the **Release** workflow manually with the tag as input. The workflow runs the tests, builds a universal app and attaches `Up-0.2.0.zip` to a new GitHub release.

## License

[MIT](LICENSE)
