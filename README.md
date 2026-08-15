# 🏝️ OpenNotch

> **The Ultimate Open-Source macOS Notch & Dynamic Island Hub.**  
> Built with **Swift 6**, **SwiftUI**, and **AppKit** for macOS Sonoma (14.0+) & Sequoia (15.0+).

[![Release](https://img.shields.io/github/v/release/mdrealofficial/opennotch?color=purple)](https://github.com/mdrealofficial/opennotch/releases/latest)
[![Platform](https://img.shields.io/badge/platform-macOS%2014.0%2B-blue.svg)](https://apple.com/macos)
[![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

---

## 📥 Installation

1. Download the latest release: [**`OpenNotch-v1.2.0-macOS.dmg`**](https://github.com/mdrealofficial/opennotch/releases/latest) or [**`OpenNotch-v1.2.0-macOS.zip`**](https://github.com/mdrealofficial/opennotch/releases/latest).
2. Move **`OpenNotch.app`** into your **`/Applications`** folder.
3. If macOS displays *"OpenNotch is damaged and can’t be opened"* (due to macOS Gatekeeper for open-source apps), simply open **Terminal** and run:
   ```bash
   xattr -cr /Applications/OpenNotch.app
   ```
   *(Or right-click `OpenNotch.app` -> select **Open** -> click **Open**).*

---

## ✨ Features

| Feature | Description |
| :--- | :--- |
| 🪄 **Hardware Notch Snapping** | Auto-detects physical MacBook notch insets and blends seamlessly. |
| 🏝️ **Dynamic Floating Island** | Elegant floating capsule fallback for external monitors and notch-less Macs. |
| 📦 **Dynamic Drop Shelf & AirDrop** | Drag any file towards the notch to reveal the 2-zone drop target (Files Tray & AirDrop). |
| 🎵 **Media Player & Visualizer** | Live status for Apple Music, Spotify, and browser audio with animated 4-bar equalizer. |
| 🎧 **Bluetooth Accessories Hub** | Paired device monitoring with live battery % and instant connect/disconnect toggles. |
| ⚙️ **Configurable Hover Styles** | Customize hover peek content (Live Activities, Clock/Date, CPU/Battery Stats, Shortcuts). |
| 🪞 **Camera Mirror Widget** | Instant webcam preview directly in the notch. |
| ⏱️ **Timer & Stopwatch** | Live Pomodoro & countdown timers. |
| 💻 **Developer HUD** | Live CPU load, RAM usage, Battery health, and Terminal quick actions. |

---

## 🚀 Building From Source

```bash
git clone https://github.com/mdrealofficial/opennotch.git
cd opennotch
swift build -c release
swift run
```

---

## 📄 License
MIT License © Md Real
