<img width="256" height="256" alt="w" src="https://github.com/user-attachments/assets/dcb8d175-408b-448d-9f85-6b8c04746eb0" />

<p align="left">
<br />
  <a href="https://www.wallper.app/">
    <img src="https://img.shields.io/badge/Download-macOS-000000?style=for-the-badge">
  </a>
  <br />
  <a href="https://github.com/alxndlk/wallper-app">
    <img src="https://img.shields.io/github/stars/alxndlk/wallper-app?style=for-the-badge">
  </a>
<br />
  <a href="https://discord.gg/ksxrdnETuc">
    <img src="https://img.shields.io/badge/Join-Discord-7289da?style=for-the-badge">
  </a>
</p>

## Overview

- 4K/60fps H.264/H.265 video wallpapers (MP4)  
- Built with SwiftUI, AVKit, Combine, CoreAnimation, CoreGraphics, CoreImage  
- Metal-optimized rendering, low-latency decoding  
- Smart filters: resolution, duration, size, category, created date  
- Daily Shuffle, multi-device sync, license validation  
- AWS Lambda (Node.js runtime), API Gateway, S3/MinIO storage  
- CloudFront CDN delivery, DynamoDB for likes/metadata  
- Secure with macOS App Sandbox, Hardened Runtime, Code Signing, Notarization  
- Efficient caching with NSCache + URLSession background downloads  
- JSON-based API communication, GZIP compression, CORS enabled

## Tech Stack

**Frontend:** SwiftUI, AVKit, Combine, CoreAnimation, Metal, CoreImage  
**Backend:** AWS Lambda, API Gateway, S3, MinIO, DynamoDB, CloudFront  
**Build Tools:** Xcode, SwiftPM, Shell scripts  
**Infra:** HTTPS, JSON APIs, GZIP, CORS  
**DevOps:** GitHub Actions, macOS code signing & notarization

## Installation

```bash
git clone https://github.com/alxndlk/wallper-app.git
cd wallper-app
open Wallper.xcodeproj
```
Requires macOS 14.0+, Xcode 14+, Swift 5.7+.

## Project Structure

```
App/      — App entry & environment
Core/     — Playback controllers & caching
Network/  — API communication & device sync
Shared/   — UI utilities & modifiers
Store/    — State management (filters, library, likes)
UI/       — SwiftUI views by feature
```

## License

Private project for educational and experimental purposes.
