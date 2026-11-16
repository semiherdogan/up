# Roadmap

Up keeps the Mac awake by running `caffeinate -dims`, either for a manual session or during a weekly schedule. Everything below is deliberately left out of v1.

## Stay awake with the lid closed

Not needed today. Closing the lid puts the Mac to sleep regardless of `caffeinate` or any power assertion. The only built-in exception is clamshell mode: power adapter connected and an external display attached.

Supporting it would mean `pmset disablesleep 1` (undocumented, needs root), which brings:

- a privileged helper, or an admin prompt on every toggle
- restoring `disablesleep 0` on session end, quit and crash, otherwise the Mac never sleeps again
- a heat and battery warning, because the Mac keeps running inside a bag

Revisit only when a real need shows up.

## Smaller ideas

- Custom session duration
- Choice of `caffeinate` flags, for example allowing display sleep
- Quick start with a right click on the menu bar icon
- Start a session while a given app is running
- Global hotkey for start and end
