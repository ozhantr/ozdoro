# OzDoro

A minimal Pomodoro timer for the macOS menu bar, built with SwiftUI and AppKit. No Dock icon, external dependencies, or network requests.

## Features

- Four 25-minute focus sessions per cycle.
- Five-minute breaks after the first three sessions, followed by a long break of 15, 20, 25, or 30 minutes.
- Breaks start automatically; focus sessions start when you're ready.
- Pause, resume, restart a session, skip a break, or reset the cycle.
- Live menu bar countdown and an instantly opening popover.
- Selectable macOS alert sounds, including a silent option.
- English, German, and Turkish, selected from your macOS language preferences.

Sound and break settings are saved between launches. Timer progress resets when you quit. If a focus session expires while your Mac sleeps, a full break starts on wake; an expired break leaves the next focus session ready to start.

## Build and run

Requires macOS 13 or later and Xcode 15 or later. Supports Apple Silicon and Intel Macs.

```sh
git clone https://github.com/ozhantr/ozdoro.git
cd ozdoro
make run
```

To install your build in `~/Applications`:

```sh
make install
```

Alternatively, open `OzDoro.xcodeproj` in Xcode, select **My Mac**, and press **⌘R**.

Signed downloads and Homebrew installation are not available yet. Building from source requires no paid Apple Developer membership.

## Language

OzDoro follows your macOS language preferences, with English as the fallback. To choose a language for this app, use **System Settings → General → Language & Region → Applications**, then restart OzDoro.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for setup, tests, and translation guidance. Technical details are in [Architecture](Docs/ARCHITECTURE.md); maintainer instructions are in [Releasing](Docs/RELEASING.md).

## License

[MIT](LICENSE)
