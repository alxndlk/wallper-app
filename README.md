# [www.wallper.app](https://www.wallper.app) — Support the Project

Wallper is an independent macOS app built with care. If you want to see steady updates and more features, consider supporting the project at [wallper.app](https://www.wallper.app).

<p align="left">
  <a href="https://www.wallper.app/">
    <img alt="Download for macOS" src="https://img.shields.io/badge/Download-macOS-000000?style=for-the-badge">
  </a>
  <a href="https://github.com/alxndlk/wallper-app">
    <img alt="Star on GitHub" src="https://img.shields.io/github/stars/alxndlk/wallper-app?style=for-the-badge">
  </a>
  <a href="https://discord.gg/ksxrdnETuc">
    <img alt="Join Discord" src="https://img.shields.io/badge/Join-Discord-7289da?style=for-the-badge">
  </a>
</p>

---

# Wallper — 4K Live Wallpapers for macOS

Wallper brings your desktop to life with clean, looping 4K videos. Simple to use, fast in practice, and built to feel native on macOS.

---

## Features

- Live video wallpapers in 4K
- Smart filters: resolution, duration, size, category, age
- Daily Shuffle: automatically apply a new wallpaper each day
- Device sync: track active devices and license status
- Cloud-backed metadata and likes (AWS Lambda + S3/MinIO)
- Community uploads (manual review before publishing)

---

## Built With

- SwiftUI for the macOS interface
- AVKit for video playback
- AWS Lambda for dynamic metadata, likes, and licensing
- S3/MinIO for storage and streaming

---

## Getting Started

Requirements:
- macOS 14.0+
- Xcode 14+
- Swift 5.7+

Install:
```bash
git clone https://github.com/alxndlk/wallper-app.git
cd wallper-app
open Wallper.xcodeproj
```

---

## Project Structure

```
Wallper/
├── App/              # App entry point & environment handling
├── Core/             # Reusable controllers and playback components
├── Network/          # AWS Lambda interactions and device tracking
├── Shared/           # View modifiers and reusable UI components
├── Store/            # App state: video filters, library, likes
├── UI/               # SwiftUI views grouped by feature
```

---

## License

This project is private and intended for educational or experimental use.

---

## Credits

Developed by [@alxndlk](https://github.com/alxndlk). Inspired by Wallpaper Engine and the macOS aesthetic.

---

## Contribute

Ideas, issues, or feedback are welcome. Open an issue or reach out:
- Issues: https://github.com/alxndlk/wallper-app/issues
- Email: support@wallper.app
- Telegram: https://t.me/alxndlk
