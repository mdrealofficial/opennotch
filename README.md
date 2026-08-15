# 🏝️ OpenNotch

> **The Ultimate Open-Source macOS Notch & Dynamic Island Hub.**  
> Built with **Swift 6**, **SwiftUI**, and **AppKit** for macOS Sonoma (14.0+) & Sequoia (15.0+).

[![Release](https://img.shields.io/github/v/release/mdrealofficial/opennotch?color=purple)](https://github.com/mdrealofficial/opennotch/releases/latest)
[![Platform](https://img.shields.io/badge/platform-macOS%2014.0%2B-blue.svg)](https://apple.com/macos)
[![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)

---

## ✨ Features (100% Feature Parity & Beyond)

| Feature | Description |
| :--- | :--- |
| 🪄 **Hardware Notch Snapping** | Auto-detects physical MacBook notch insets and blends seamlessly. |
| 🏝️ **Dynamic Floating Island** | Elegant floating capsule fallback for external monitors and notch-less Macs. |
| 🎵 **Media Player & Visualizer** | Live status for **Apple Music** & **Spotify**, animated equalizer, and scrubbing. |
| 📦 **Drop Shelf (AirDrop & Stash)** | Stash files, view sizes, copy paths, reveal in Finder, or drag out to apps. |
| 🪞 **Camera Mirror Widget** | Instant webcam preview directly in the notch before video meetings. |
| ⏱️ **Timer & Stopwatch** | Live Pomodoro & countdown timers with real-time countdown badge in the compact notch. |
| 🎧 **Bluetooth Accessories Hub** | Live battery levels for AirPods, Magic Mouse, Magic Keyboard, and headphones. |
| ⚡️ **Pipelines & Shortcuts Runner** | 1-click execution for macOS Shortcuts, screenshot capture, appearance toggle, and scripts. |
| 💻 **Developer HUD (CPU, RAM, Uptime)** | Live CPU load, RAM usage, Battery health, Terminal launcher, and Unix timestamps. |
| 📅 **Calendar & Scratchpad** | Daily meeting glance and persistent temporary notes scratchpad. |
| 🧩 **Open-Source NotchWidget Plugin API** | Easily build custom widgets with the open `NotchWidget` Swift protocol. |

---

## 📊 OpenNotch vs. NotchNook Comparison

| Feature | NotchNook (Closed Source) | OpenNotch (Open Source) |
| :--- | :---: | :---: |
| **Physical Notch & Floating Island Snapping** | ✅ | ✅ |
| **Media Player & Live Spectrum Visualizer** | ✅ | ✅ |
| **Drop Shelf & File Stashing** | ✅ | ✅ |
| **Camera Mirror Check** | ✅ | ✅ |
| **Live Timers & Pomodoro** | ✅ | ✅ |
| **Connected Bluetooth Devices & Battery** | ✅ | ✅ |
| **Shortcuts & Pipelines Runner** | ✅ | ✅ |
| **Calendar Glance & Notes Scratchpad** | ✅ | ✅ |
| **💻 Developer HUD (CPU, RAM, Uptime)** | ❌ | **✅ (Exclusive)** |
| **🧩 Open-Source `NotchWidget` Plugin API** | ❌ | **✅ (Exclusive)** |
| **100% Free & Open Source (MIT)** | ❌ *(Paid)* | **✅ (Free / MIT)** |

---

## 🛠️ Architecture

```mermaid
flowchart TD
    App["OpenNotch App"] --> WindowManager["NotchWindowManager"]
    WindowManager --> ScreenDetector["ScreenGeometryHelper"]
    WindowManager --> Panel["NotchPanel (NSPanel)"]
    Panel --> Container["NotchContainerView (SwiftUI)"]
    
    Container --> CompactView["Compact Notch Capsule"]
    Container --> ExpandedView["Expanded Glass Hub"]
    
    ExpandedView --> TabMedia["🎵 Media Hub"]
    ExpandedView --> TabShelf["📦 Drop Shelf"]
    ExpandedView --> TabMirror["🪞 Camera Mirror"]
    ExpandedView --> TabTimer["⏱️ Timers & Pomodoro"]
    ExpandedView --> TabBT["🎧 Bluetooth Gear"]
    ExpandedView --> TabPipe["⚡️ Shortcuts / Pipelines"]
    ExpandedView --> TabDev["💻 Dev HUD"]
    ExpandedView --> TabCal["📅 Calendar & Notes"]
    ExpandedView --> TabSettings["⚙️ Preferences"]
```

---

## 🚀 Building and Running Locally

### Prerequisites
- macOS 14.0 (Sonoma) or newer
- Xcode 15.0+ / Swift 6 toolchain

### Quick Start
```bash
# Clone the repository
git clone https://github.com/mdrealofficial/opennotch.git
cd OpenNotch

# Build the project
swift build

# Run unit tests
swift test

# Launch OpenNotch
swift run
```

---

## ⌨️ Shortcuts & Controls

- **Hover:** Hover cursor over the notch for 0.15s to expand the hub.
- **Click:** Click the compact notch pill to toggle expansion.
- **Global Hotkey:** Press `⌥ + ⌘ + N` to expand / collapse from anywhere.
- **Menu Bar Icon:** Click the menu bar item (`✨`) to access tabs, settings, or quit.

---

## 🧩 Creating a Custom Community Widget

Adding a new widget to OpenNotch is straightforward:

```swift
import SwiftUI

struct MyCustomWidget: NotchWidget {
    var id: String = "my.custom.widget"
    var title: String = "My Tool"
    var iconName: String = "wrench.and.screwdriver"
    var order: Int = 10
    
    func makeCompactView() -> some View {
        HStack {
            Image(systemName: iconName)
            Text("Ready")
        }
    }
    
    func makeExpandedView() -> some View {
        VStack {
            Text("My Custom Hub Widget")
                .font(.headline)
        }
    }
}
```

---

## 📄 License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.
