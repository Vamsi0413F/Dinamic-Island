# MacDynamicIsland

**MacDynamicIsland** is a complete, native macOS Dynamic Island application designed for the **MacBook Air M5** and Apple Silicon architecture, with full compatibility across all notch-equipped Apple Silicon Macs (M1, M2, M3, M4, M5, MacBook Air & MacBook Pro) and intelligent automatic fallback for external monitors and non-notch Macs.

Built with **Swift 6**, **SwiftUI**, **AppKit**, and native macOS system frameworks (`IOKit`, `EventKit`, `Vision`, `AVFoundation`).

---

## 🌟 Features Overview

### 1. Dynamic Island Interface & Hardware Notch Detection
- **Runtime Notch Geometry Detection**: Dynamically calculates the exact camera notch cutout at runtime using macOS `NSScreen.auxiliaryTopLeftArea`, `auxiliaryTopRightArea`, `safeAreaInsets.top`, and `backingScaleFactor`. Never hardcodes fixed dimensions, ensuring pixel-perfect alignment across MacBook Air M5, MacBook Pro models, and different display scaling settings.
- **Three Presentation States**:
  - **Compact State**: Hugs the notch with minimal footprint. Displays media status, battery %, CPU load, active Pomodoro timer, or Caps Lock indicator. Spacer wings dynamically adapt to the physical hardware notch cutout.
  - **Expanded State**: Smooth spring animation drops down on hover or click, showing track details, quick transport controls, and widget quick-switches.
  - **Detailed State**: Full multi-tab interactive surface providing deep controls for all modules.
- **Click-Through Non-Blocking Architecture**: The underlying `IslandPanel` dynamically resizes to match the rendered island bounds, guaranteeing that menu bar controls and background windows are never blocked.
- **Hardware Fallback**: Automatically senses non-notch Macs or external monitors and renders a floating pill with a 10pt offset and unified compact content.
- **Multi-Monitor & Space Support**: Can anchor to the built-in notch display or follow active displays; joins all spaces and full-screen apps (`.canJoinAllSpaces`, `.fullScreenAuxiliary`).

### 2. Music & Media
- **Real-Time Integration**: Seamless AppleScript & DistributedNotification listeners for **Apple Music** and **Spotify**.
- **Transport Controls**: Play/pause, previous track, next track, and position scrubbing.
- **Energy-Optimized Visualizer**: Animated waveform runs only while playback is active, consuming zero CPU cycles when idle.

### 3. System Monitoring
- **Hardware-Aware Information**: Dynamically detects the Mac model family, chip identifier (e.g. `Apple M5`), and core count at runtime.
- **Real CPU Load**: Host Mach statistics (`host_cpu_load_info`) measuring real kernel/user/idle tick deltas.
- **Real Memory (RAM)**: `host_statistics64` measuring active, wired, and compressed memory against physical `hw.memsize`.
- **Disk Storage**: `statvfs` measuring real available and total storage.
- **Network Bandwidth**: `getifaddrs` measuring real-time download and upload bytes per second.
- **Battery Status**: Native IOKit Power Sources API (`IOPSCopyPowerSourcesInfo`) reporting exact battery level, AC/charging state, and time remaining.
- **Caps Lock Indicator**: Real-time modifier flag detection.

### 4. File Shelf
- **Drag & Drop Target**: Drop any files or folders directly onto the notch island.
- **Persistent Tray**: Holds items across application switches and macOS spaces.
- **Actions**:
  - Open in default app
  - Reveal in Finder
  - Compress to ZIP (using native `ditto`)
  - Remove / Clear shelf

### 5. Clipboard History
- **Opt-in Monitoring**: Tracks pasteboard changes locally without cloud transmission.
- **Sensitive Data Detection**: Filters out passwords, private keys, and transient password manager clippings.
- **Search & Pin**: Instant search, pin essential snippets, and one-click copy back to clipboard.
- **Vision OCR**: Built-in Vision framework (`VNRecognizeTextRequest`) to extract text from images.

### 6. Productivity & Timers
- **Pomodoro Timer**: Work (25m), Short Break (5m), and Long Break (15m) cycles with automated transitions and sound alerts.
- **Stopwatch**: High-precision stopwatch with lap times.
- **Custom Countdown**: Quick presets (1m, 5m, 10m, 15m, 25m).
- **Idle Power Efficiency**: Ticker timers activate lazily on demand and stop completely when idle, maximizing Apple Silicon battery life.
- **Keep-Awake (Caffeinate)**: Native IOKit power assertion (`IOPMAssertionCreateWithName`) prevents display and system sleep with a single toggle.
- **Quick Notes**: Instant scratchpad notepad that persists locally.
- **Calendar & Reminders**: Authorized EventKit integration showing today's events, time ranges, and meeting links.

### 7. Camera & Visual Tools
- **Camera Mirror**: Instant webcam preview right under your notch using `AVCaptureSession`.
- **Color Picker**: Native `NSColorSampler` to sample any screen pixel, providing HEX and RGB values copied directly to the clipboard.
- **Screen Capture**: Quick region screen capture to clipboard.
- **Teleprompter**: Adjustable speed scrolling prompter positioned right under your camera.

### 8. Customization & Settings
- **Display & Notch Calibration**: Live readout of the connected screen resolution, scale factor, and hardware-detected notch dimensions. Fine-tune width, height, corner radius, and top offset with relative sliders.
- **Interaction Controls**: Toggle hover-to-expand, configure delay, auto-collapse timeout, and reduce-motion mode.
- **Launch at Login**: Optional `SMAppService` startup registration.
- **Reset to Defaults**: One-click restore to hardware-calibrated baseline values.

---

## 🛠 Prerequisites & Requirements

- **Target Hardware**: MacBook Air M5 (also compatible with MacBook Air M2/M3/M4, MacBook Pro 14"/16", and all Apple Silicon Macs)
- **Operating System**: macOS Sonoma (14.0) or macOS Sequoia (15.0+)
- **Build Tools**: Apple Xcode 15+ command line tools (`xcode-select --install` or Xcode.app)
- **Swift Version**: Swift 6.0+

---

## 🚀 Build & Run Instructions

### Option 1: One-Click Build & Package Script
Run the automated build script to compile the release binary and bundle it into `MacDynamicIsland.app`:

```bash
./scripts/build_app.sh
```

Then open the application:
```bash
open build/MacDynamicIsland.app
```

### Option 2: Swift Package Manager (Direct Run)
```bash
# Debug build and run
swift run MacDynamicIsland
```

### Option 3: Xcode
You can open the package directly in Xcode:
```bash
open Package.swift
```
Select the `MacDynamicIsland` scheme and press `Cmd + R` to run.

---

## 🔐 Permissions Guide

MacDynamicIsland requests only the permissions required for optional features:
1. **Camera**: Required only when launching the Camera Mirror preview (`NSCameraUsageDescription`).
2. **Calendar**: Required only to display today's events in the Calendar widget (`NSCalendarsUsageDescription`).
3. **Apple Events / Automation**: Required when controlling Apple Music or Spotify playback.
4. **Accessibility**: Optional, for global shortcuts.

---

## 📋 Feature Verification Status

| Feature Group | Component | Status | Notes |
| :--- | :--- | :---: | :--- |
| **1. Dynamic Island Interface** | Runtime notch detection & positioning | **WORKING** | Tested on Apple Silicon M5 (safeAreaTop: 37.5pt, cutout: 208pt × 37.5pt, scale: 2.0x) |
| | Compact, Expanded, Detailed states | **WORKING** | Smooth animations & transitions |
| | Hover-to-expand & Auto-collapse | **WORKING** | Configurable timeouts |
| | Non-blocking window click-through | **WORKING** | NSPanel tightly bounds content |
| | External display fallback | **WORKING** | Floating pill with 10pt offset and cohesive compact layout |
| | Menu bar status item | **WORKING** | Quick access menu & quit action |
| **2. Music & Media** | Now Playing metadata & scrubber | **WORKING** | Apple Music & Spotify |
| | Play / Pause / Next / Prev | **WORKING** | Asynchronous AppleScript controls |
| | Music visualizer waveform | **WORKING** | Pauses timer when not playing to eliminate idle CPU usage |
| **3. System Monitoring** | Real CPU usage % | **WORKING** | Mach host load delta calculations |
| | Real RAM & Disk usage | **WORKING** | Mach VM statistics & statvfs |
| | Real Network upload / download | **WORKING** | Network interface byte rate diffs |
| | Real Battery % & Charging state | **WORKING** | IOKit Power Sources API |
| | Hardware Chip & Model Detection | **WORKING** | Dynamically detects Apple M5 / Mac model via sysctl |
| | Caps Lock status | **WORKING** | Real-time modifier flags |
| **4. Clipboard History** | Clipboard polling & local history | **WORKING** | NSPasteboard changeCount |
| | Sensitive data protection | **WORKING** | Key/token detection & exclusion |
| | Search & Pinning | **WORKING** | Instant search filter |
| | Vision OCR | **WORKING** | Apple Vision framework |
| **5. File Shelf** | Drag & Drop files onto island | **WORKING** | SwiftUI onDrop `.fileURL` |
| | Shelf list & file actions | **WORKING** | Open, Reveal, ZIP compression |
| **6. Productivity** | Pomodoro timer & cycles | **WORKING** | Focus, Short Break, Long Break |
| | Stopwatch & Laps | **WORKING** | Sub-second accuracy |
| | Countdown presets | **WORKING** | 1m, 5m, 10m, 15m, 25m |
| | Idle Power Efficiency | **WORKING** | Ticker disabled when idle to preserve battery |
| | Keep-Awake (Caffeinate) | **WORKING** | IOPMAssertion power assertions |
| | Quick Scratchpad Notes | **WORKING** | Persistent notes with word count |
| | Calendar Today's Events | **WORKING** | EventKit authorization & fetch |
| **7. Visual Tools** | Camera Mirror preview | **WORKING** | AVFoundation AVCaptureSession |
| | Color Picker (HEX & RGB) | **WORKING** | NSColorSampler |
| | Screen Region Capture | **WORKING** | Native screencapture helper |
| | Teleprompter | **WORKING** | Speed & font controls |
| **8. Settings & Customization** | Sizing calibration sliders | **WORKING** | Relative offset sliders based on detected hardware |
| | Behavioral toggles | **WORKING** | Hover, reduce motion, visualizer, display preference |
| | Reset to defaults | **WORKING** | Reset confirmation alert |

---

## 📄 License
MIT License. Built with Apple Swift & SwiftUI.
