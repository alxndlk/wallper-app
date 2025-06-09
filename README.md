# 🌐 [www.wallper.app](https://www.wallper.app/) — Support the Project

Wallper is an indie macOS app built with care. If you like it — [consider supporting us](https://www.wallper.app/) to keep the updates coming 💙

---

# Wallper — Stunning 4K Live Wallpapers for macOS

**Wallper** is a beautifully designed macOS application that brings your desktop to life with dynamic, 4K live wallpapers. With a curated video library, smart filtering, and a polished SwiftUI interface, Wallper is more than just a wallpaper app — it’s a creative desktop experience.

---

## ✨ Features

- 🎥 **Live Video Wallpapers** — Apply gorgeous 4K video loops directly to your desktop.
- 🔍 **Smart Filters** — Search and filter wallpapers by resolution, duration, size, category, and age.
- 📁 **Daily Shuffle** — Automatically set a new wallpaper each day from your library.
- ⚙️ **Device Sync** — Track active devices and license status.
- ☁️ **Cloud-Powered Metadata** — Video data is fetched and updated through AWS Lambda + S3/MinIO.
- 📤 **User Submissions** — Upload your own creations to share with the community.

---

## 🛠 Built With

- `SwiftUI` — for declarative, responsive macOS UI
- `AVKit` — for smooth video rendering
- `AWS Lambda` — for dynamic metadata, likes, and licensing
- `S3` — for storage and video streaming

---

## 🚀 Getting Started

### Prerequisites

- macOS 14.0+
- Xcode 14+
- Swift 5.7+

### Installation

```bash
git clone https://github.com/alxndlk/wallper-app.git
cd wallper-app
open Wallper.xcodeproj
```


---

## 📁 Project Structure

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

## 🔒 License

This project is currently **private** and intended for educational or experimental use.

---

## 💡 Credits

Developed with ❤️ by [@alxndlk](https://github.com/alxndlk).  
Inspired by Wallpaper Engine and the macOS aesthetic.

---

## 📬 Want to Contribute?

Feature suggestions, bug reports, and pull requests are always welcome.  
Just open an [issue](https://github.com/alxndlk/wallper-app/issues) or start a discussion.

Contact: support@wallper.app | [Telegram](https://t.me/alxndlk)
