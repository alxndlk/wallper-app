<div align="center">
<img width="156" height="156" alt="image" src="https://github.com/user-attachments/assets/ba9fd97a-3798-4d1a-bd6e-07f13555efa6" />

  <h1>Wallper App</h1>

<a href="https://github.com/alxndlk"><img alt="Vercel logo" src="https://img.shields.io/badge/MADE%20BY%20alxndlk-000000.svg?style=for-the-badge&logo=Github&labelColor=000"></a>
<a href="https://github.com/alxndlk/wallper-app"><img alt="Star on GitHub" src="https://img.shields.io/github/stars/alxndlk/wallper-app?style=for-the-badge&logo=Github&labelColor=000"></a>
<a><img alt="License" src="https://img.shields.io/npm/l/next.svg?style=for-the-badge&labelColor=000000"></a>
<a href="https://discord.gg/ksxrdnETuc"><img alt="Join the community on Discord" src="https://img.shields.io/badge/Join%20the%20community-7289da.svg?style=for-the-badge&logo=Discord&labelColor=000000&logoWidth=20"></a>

</div>


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
