# PitchCircle

PitchCircle is a native iOS app that listens to live microphone input, detects monophonic pitch in real time, and maps the detected note to a dual-ring Circle of Fifths.

The app is built with SwiftUI and AVFoundation, with on-device pitch analysis and no network dependency.

## Features

- Real-time microphone input using `AVAudioEngine`
- On-device pitch estimation with a Swift pYIN-style processor
- Dual-ring Circle of Fifths visualization
- Major and relative minor highlighting for the active pitch class
- Note display with octave, frequency, and key pills
- Reference pitch setting with `A440` and `A432`
- Settings persistence with `UserDefaults`
- Permission prompt and denied-permission fallback with deep link to iOS Settings
- Audio interruption handling for events like calls or Siri

## Tech Stack

- Platform: iOS 16+
- Language: Swift
- UI: SwiftUI
- Audio: AVFoundation
- DSP: Accelerate
- Storage: UserDefaults

## Project Structure

```text
PitchCircle/
├── App/
├── Core/
│   ├── Audio/
│   ├── Extensions/
│   └── Music/
├── Features/
│   ├── Audio/
│   ├── CircleOfFifths/
│   └── Settings/
└── PitchCircle/
    ├── Assets.xcassets
    └── Info.plist
```

## Current Architecture

The current codebase is organized by feature with lightweight shared core modules:

- `App/` contains app launch and top-level shared UI state.
- `Features/Audio/` owns microphone capture orchestration and pitch publishing.
- `Core/Audio/` contains the pitch processing logic.
- `Core/Music/` contains note conversion and Circle of Fifths mapping.
- `Features/CircleOfFifths/` renders the wheel UI.
- `Features/Settings/` manages reference pitch settings and persistence.

## Getting Started

### Requirements

- macOS with Xcode 15 or newer
- iOS 16+ deployment target
- A physical iPhone for meaningful microphone testing

### Run Locally

1. Clone the repository.
2. Open `PitchCircle.xcodeproj` in Xcode.
3. Select an iPhone target or a connected device.
4. Build and run.
5. Grant microphone access when prompted.

### Notes

- The audio pipeline is intended for real-device testing. The simulator is not a reliable environment for microphone-driven pitch detection.
- The app is portrait-first.

## Privacy

PitchCircle processes audio entirely on-device.

- No audio is uploaded
- No network access is required
- No personal data is collected
- The only persisted data is the selected reference pitch in `UserDefaults`

## Permission Behavior

- On first launch, the app shows an in-app explanation before requesting microphone access.
- If access is denied, the app shows a banner with a deep link to `Settings.app`.
- If audio is interrupted, the app attempts to resume listening automatically when possible.

## Development Status

The project currently has a stable v1.1 foundation in place:

- Shared app state and settings flow are implemented
- Core audio capture and pitch detection are wired to the UI
- The dual-ring Circle of Fifths is rendered and reacts to detected pitch
- Settings and permission states are integrated into the main experience

Areas still worth expanding:

- Automated tests
- Accessibility support
- Additional UI polish and performance profiling on device
- CI and release automation

## Roadmap

- Add unit and UI test coverage
- Improve pitch stability and smoothing
- Refine visual layout and animation behavior
- Prepare TestFlight distribution

## Contributing

Issues and pull requests are welcome, but this project is currently optimized for fast iteration on the core pitch-detection experience. Keep changes focused and avoid unrelated refactors.

## License

No license has been added yet. Until one is provided, all rights are reserved by the repository owner.
