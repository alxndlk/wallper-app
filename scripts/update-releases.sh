#!/bin/bash
# =============================================================================
# Update Release Descriptions Script
# =============================================================================
# This script updates all release descriptions in the alxndlk/wallper-app
# repository to match the template used in the last 5 releases (v1.7.1–v1.6.4).
#
# Template format:
#   # Wallper v{version}
#   
#   > {Short tagline}
#   
#   ## {Section}
#   
#   ### {Subsection}
#   
#   - Bullet points
#
# Usage:
#   1. Make sure you have `gh` CLI installed and authenticated:
#      gh auth login
#   2. Run this script:
#      bash scripts/update-releases.sh
#   3. To do a dry run first (just print, don't update):
#      DRY_RUN=1 bash scripts/update-releases.sh
# =============================================================================

set -euo pipefail

REPO="alxndlk/wallper-app"
DRY_RUN="${DRY_RUN:-0}"

update_release() {
  local tag="$1"
  local body="$2"

  if [ "$DRY_RUN" = "1" ]; then
    echo "=============================="
    echo "[DRY RUN] Would update release: $tag"
    echo "=============================="
    echo "$body"
    echo ""
    return
  fi

  echo "Updating release: $tag ..."
  gh release edit "$tag" --repo "$REPO" --notes "$body"
  echo "  Done."
}

# ---------------------------------------------------------------------------
# Release 1.6.2
# ---------------------------------------------------------------------------
update_release "1.6.2" '# Wallper v1.6.2

> Performance & Polish

## Performance

### CPU Optimization

- Mesh gradient timer reduced from 30 fps to 20 fps — visually identical, 33% less CPU
- Removed per-frame GradientTheme allocation — colors computed directly without intermediate struct
- Cached blended colors in MusicThemeHolder — no heap allocations when not transitioning between tracks
- Replaced global + local NSEvent monitors with direct `NSEvent.mouseLocation` polling in the existing timer — zero additional callbacks

### Fullscreen Detection

- Replaced 2-second `CGWindowListCopyWindowInfo` polling with workspace notifications (`didActivateApplication`, `activeSpaceDidChange`)
- Fullscreen check now triggers only on app switch, not continuously

### Settings Observer

- Replaced broad `UserDefaults.didChangeNotification` with KVO on 7 specific keys
- Previously fired on every UserDefaults write system-wide — now only on actual setting changes

### Video Rendering

- Removed `shouldRasterize` from AVPlayerLayer quality reduction — was creating unnecessary VRAM bitmap cache per screen
- Quality scaling now uses `contentsScale` directly, letting `preferredMaximumResolution` handle the decoder side

## Bug Fixes

### Lockscreen Restore on Music Pause

- Fixed lockscreen not reverting to the previous wallpaper when music is paused or stopped
- Now restores both desktop wallpaper and lockscreen from the saved state

### Smooth Mouse Tracking

- Added lerp interpolation for cursor-reactive gradients — mesh follows mouse with smooth easing instead of snapping to position each tick'

# ---------------------------------------------------------------------------
# Release 1.6.1
# ---------------------------------------------------------------------------
update_release "1.6.1" '# Wallper v1.6.1

> Music Sync & 4x Optimization

## New Features

### Music-Reactive Wallpapers

- Wallpaper colors automatically change to match the album artwork of the currently playing track
- Supports both Apple Music and Spotify
- Smooth animated mesh gradient with organic blob motion reacts to your cursor
- Colors extracted from artwork using advanced k-means++ clustering for accurate palette
- Spatial color arrangement preserves the visual structure of the album cover

### Lockscreen Sync

- Lockscreen wallpaper updates to match the current track (macOS 26+)
- Seamlessly looping gradient video rendered in HEVC
- Toggle lockscreen sync on/off in Settings → Music Sync

### Playback Controls

- Play/pause, next and previous track controls in the dock and menubar
- Track title and artist name displayed alongside controls

## Improvements

### Performance

- New "Retina Rendering" toggle in Settings → Playback — reduces GPU load when off
- Artwork cached in memory — returning to a previously played album skips the download
- Lockscreen video rendered at optimized 720p/24fps — visually identical, much faster
- Eliminated redundant color conversions in the rendering pipeline
- Resuming a paused track skips lockscreen re-render'

# ---------------------------------------------------------------------------
# Release 1.6.0
# ---------------------------------------------------------------------------
update_release "1.6.0" '# Wallper v1.6.0

> 50K Users Milestone & All Major Bug Fixes

## What'\''s New

### Lock Screen & Screensaver

- Fixed black screen on lock screen after unlock and re-lock
- Screensaver video now plays correctly every time, not just on the first lock

### Offline Startup

- Downloaded wallpapers now load instantly on boot — no internet needed
- Fixed wallpapers not appearing after reboot without Wi-Fi

### Auto-Reconnect

- Video library automatically reloads when you open the app or menubar after going online
- No need to restart the app manually

### Stability & Performance

- Overall performance and optimization improvements
- Fixed excessive background activity when changing settings
- Improved diagnostic logging for troubleshooting

### Trials Reset

- All trials have been reset as a gift for reaching 50K users'

# ---------------------------------------------------------------------------
# Release 1.5.3.1
# ---------------------------------------------------------------------------
update_release "1.5.3.1" '# Wallper v1.5.3.1

> Hotfix: Offline Startup & Stability

## Bug Fixes

### Offline Startup

- Downloaded wallpapers now load instantly on boot — no internet needed
- Fixed wallpapers not appearing after reboot without Wi-Fi

### Auto-Reconnect

- Video library automatically reloads when you open the app or menubar after going online
- No need to restart the app manually

### Stability

- Fixed excessive background activity when changing settings
- Improved diagnostic logging for troubleshooting'

# ---------------------------------------------------------------------------
# Release 1.5.3
# ---------------------------------------------------------------------------
update_release "1.5.3" '# Wallper v1.5.3

> Offline Resilience & Boot Recovery

## Improvements

### Offline Boot Recovery

- Wallpapers now play correctly after system reboot without internet
- App uses locally cached video files instead of streaming from CDN
- No more black screens when Wi-Fi hasn'\''t connected yet

### Seamless Online Transition

- Stalled video players are automatically detected and re-applied when internet returns
- Video library loads automatically once connection is restored
- Smooth transition from offline to online mode without manual restart

### Shuffle Fix

- Fixed shuffle not working when cached video couldn'\''t be streamed
- Shuffle now correctly uses local files for uninterrupted rotation

### Playback Reliability

- Improved local cache resolution across all wallpaper apply paths
- Monitor selection view now prefers cached files for instant playback
- Wallpaper restore on wake and screen changes uses local files first

### App Icon Update

- Fixed white corners for macOS <26.0'

# ---------------------------------------------------------------------------
# Release 1.5.2
# ---------------------------------------------------------------------------
update_release "1.5.2" '# Wallper v1.5.2

> Performance, Stability & Global Update

## New Features

### Sorting

- Added video sorting options
- Organize wallpapers by your preferred order

### Video Speed Control

- Added playback speed adjustment
- Applies instantly without reload
- Independent speed per display

### Menu Bar Version

- Added app version display in the menu bar view

### Localization

- Full localization added for: English, Chinese, Russian, French, Italian, Spanish, Ukrainian, Japanese, Korean, German

## Improvements

### Video Playback

- Optimized video rendering performance
- Fixed unexpected pauses during playback
- Improved overall playback stability
- Smoother experience on all supported Macs

### Preview System

- Fixed backend preview generation issues
- Improved preview loading inside the app
- Official wallpapers now display correctly
- More reliable preview caching behavior

### Stability

- Fixed issue where official wallpapers were not visible
- Improved consistency between backend and client preview handling
- General reliability improvements across the app

### App Icon

- Updated application icon
- Cleaner and more refined visual identity'

# ---------------------------------------------------------------------------
# Release 1.5.1
# ---------------------------------------------------------------------------
update_release "1.5.1" '# Wallper v1.5.1

> Bug Fixes & UI Improvements

## Bug Fixes

### Launch at Login

- Fixed Launch at Login not working correctly
- Improved reliability of startup behavior

### Preview Loading

- Fixed empty previews issue
- Previews now load consistently without blank states

## Improvements

### Lock Screen Setup

- Added more steps to the lock screen installation process
- Clearer guidance through each installation stage
- Improved user experience with step-by-step flow'

# ---------------------------------------------------------------------------
# Release 1.5.0
# ---------------------------------------------------------------------------
update_release "1.5.0" '# Wallper v1.5.0

> Performance & Settings Update

## What'\''s New

### Trial Reset

- Trial period has been reset for all users
- Enjoy a fresh start with all new features

### New Playback Settings Tab

- Video Quality Preset selector (Auto, High, Balanced, Performance)
- Maximum Resolution limit
- Frame Rate limit
- Video Volume slider with real-time preview
- Transition Duration control
- Start Delay before wallpaper plays

### Smart Power Management

- Pause wallpapers when any app goes fullscreen
- Pause wallpapers on high CPU usage (80%+ threshold)
- Reduce quality automatically on battery
- Improved Pause on Battery with state persistence
- Wallpapers auto-resume when conditions change

### Real-Time Settings

- All playback settings apply instantly without reload
- No more video flickering when changing settings
- Volume changes apply to all active wallpapers immediately

### Fullscreen & CPU Monitors

- FullscreenMonitor detects fullscreen apps and pauses wallpapers
- CPUMonitor monitors system load and pauses when CPU > 80%
- Both monitors start/stop based on user settings
- Smart debouncing to prevent false triggers

## Improvements

### Memory & Performance

- Fixed memory leaks in ExploreView when scrolling
- Removed unnecessary @ObservedObject usage across preview components
- Added proper cleanup on view disappear
- Reduced URLCache memory footprint
- Fixed priority inversion in ScreenSaverManager

### Menu Bar

- Fixed video flickering when pressing play/pause
- Fixed preview not updating when switching wallpapers
- Wallpaper preview now updates instantly on change
- Improved player identity check to prevent unnecessary updates

### Launch at Login

- Improved SMAppService synchronization
- Better handling of .requiresApproval state
- Added error alerts with "Open System Settings" option
- Fixed setting turning back on unexpectedly

### Pause on Battery

- State now persists across app restarts
- Tracks manual pause vs automatic pause
- Won'\''t auto-resume if user manually paused
- Proper state reset when toggling setting'

# ---------------------------------------------------------------------------
# Release 1.4.0.1
# ---------------------------------------------------------------------------
update_release "1.4.0.1" '# Wallper v1.4.0.1

> Hotfix

## Bug Fixes

### Instruments Compatibility

- Fixed an issue where the Allocations instrument sometimes failed to report reference counting operations for native Swift types'

# ---------------------------------------------------------------------------
# Release 1.4.0
# ---------------------------------------------------------------------------
update_release "1.4.0" '# Wallper v1.4.0

> Massive UI & Architecture Update

## New Features

### Menu Bar & Shuffle

- Fully redesigned Menu Bar
- Like wallpapers directly from the Menu Bar
- Open Shuffle from the Menu Bar
- Shuffle now includes liked and downloaded wallpapers
- Shuffle filtering by switch interval (optional)
- Seamless wallpaper switching in Shuffle mode
- Optional Lock Screen wallpaper in Shuffle (macOS 26+)
- Per-display pause and video switching from the Menu Bar

### Bottom Control Panel

- New control panel for current wallpapers
- Pause / switch wallpapers instantly
- Set wallpapers per display
- Toggle Lock Screen wallpaper (advanced controls)
- Like wallpapers directly from the panel

### Settings

- Settings moved to system-style section
- Restore default macOS live wallpapers
- Reopen Welcome Screen anytime
- App version display
- Generate and export logs
- Advanced cache management: preview cache, video cache, Lock Screen cache
- Cache size limits
- Open system cache folder
- Installed wallpapers list with delete option
- Display overview with per-display controls
- Pause / disable wallpapers per display
- Improved display and device loading speed
- Device-specific icons
- Improved license information and protection
- Fixed incorrect license data display
- New Support tab

### Lock Screen (macOS 26+)

- No need to manually reselect wallpapers when switching
- Fixed Lock Screen preview issues
- Added Lock Screen caching
- New Lock Screen setup overlay in main app view

### New UI

- Redesigned My Library
- Rename wallpapers in your library
- Share wallpapers via public link during installation
- New full-screen wallpaper installation overlay

### Global Search

- Search across wallpapers, tags and colors
- Optimized async preview loading
- Install wallpapers directly from search results

### Loading & Startup

- Significantly faster app startup
- Asynchronous license connection
- Parallel loading of user and app data

### Video Publishing

- Video publishing moved to the website
- Automatic detection of video color and type
- Support for publishing multiple videos at once

## Improvements

### Performance

- UI loading migrated to a new backend architecture
- Entire UI rewritten for faster loading, better async handling, and multithreading support

### Onboarding

- New onboarding flow
- New license key modal'

# ---------------------------------------------------------------------------
# Release 1.3.6
# ---------------------------------------------------------------------------
update_release "1.3.6" '# Wallper v1.3.6

> Black Screen Fix & Client Optimization

## Improvements

### Smarter Video Library Loading

- Reworked how Wallper loads the video library
- Previously, the app scanned and built the list of videos locally, which put extra load on the Mac and stopped working reliably around 1,000 videos
- Now the video list is generated on the backend and sent to the app in a ready-to-use format
- Removes the old 1,000-video ceiling and keeps large libraries in sync

## Bug Fixes

### Black Screen After Wake

- Fixed an issue where the desktop could stay black instead of showing the wallpaper after waking the Mac from sleep
- Switched to a more reliable wake-up behavior
- Removed the old setting that could trigger this behavior
- Enabled the safe default for everyone'

# ---------------------------------------------------------------------------
# Release 1.3.5.1
# ---------------------------------------------------------------------------
update_release "1.3.5.1" '# Wallper v1.3.5.1

> Lock Screen & Screen Saver Policy Update

## Changes

### macOS Below 26.0

- Lock Screen and Screen Saver playback is no longer supported on macOS versions earlier than 26.0
- Older macOS versions have system-level issues that make reliable video wallpapers on the lock screen impossible without heavy workarounds
- These workarounds are fragile, can conflict with system security, and do not meet quality or stability standards

### macOS 26.0 and Later

- Lock Screen and Screen Saver are supported natively on macOS 26.0 and newer
- Apple fixed the underlying issues, allowing clean, stable, and officially supported integration
- Strongly recommend updating to macOS 26.0 or later for the full experience'

# ---------------------------------------------------------------------------
# Release 1.3.5
# ---------------------------------------------------------------------------
update_release "1.3.5" '# Wallper v1.3.5

> Lock Screen & Big QoL Update

## New Features

### Autostart & Power

- Launch at login support — Wallper can now start automatically when you log in to macOS
- Ask for autostart on first launch — the app now clearly asks whether you want it to start with the system
- Hide main window after autostart — the main window stays hidden during the first ~60 seconds to avoid getting in your way
- Default screen saver setup configured for a smoother first-time experience
- Power-aware wallpapers — wallpapers are disabled by default when external power is disconnected to save battery
- Automatic settings opening for wallpaper setup

### Download Button

- A dedicated Download button was added instead of relying only on "Set as Wallpaper"

### Trial Extension

- All users whose trial has already expired get another 7 days to try Wallper again

## Improvements

### Wallpaper Installation

- Optimized wallpaper installation — the process is faster and more reliable
- No more main-thread blocking — applying wallpapers no longer blocks the main app thread
- Asynchronous wallpaper application — wallpapers are set in the background so the UI stays responsive

### Screen Saver

- Fully fixed for macOS 26
- Partially improved for macOS < 26

### Preview System

- Reworked preview loading logic for more robust behavior
- Preview images are now created server-side and then fetched by the app

### Uploads & Publishing

- Fixed wallpaper publishing flow — upload and publish pipeline repaired
- Backend-driven previews for uploads — preview generated and stored on the backend

### UI & UX

- Explore tab redesign with clearer navigation and a more modern look
- New animations in Explore for smoother browsing
- Reworked card logic for more predictable behavior and better state handling
- Fixed toggles in Settings

### Performance & Network

- Fixed heavy settings sync bug — synchronization stabilized and made more reliable
- Improved network and internet usage — cleaned up and made more efficient
- Faster overall app performance
- Auto-update made invisible — updates happen more quietly with minimal disruption'

# ---------------------------------------------------------------------------
# Release 1.3.4.1
# ---------------------------------------------------------------------------
update_release "1.3.4.1" '# Wallper v1.3.4.1

> Routing Links Update

## Changes

### Links

- Updated links in the application'

# ---------------------------------------------------------------------------
# Release 1.3.4
# ---------------------------------------------------------------------------
update_release "1.3.4" '# Wallper v1.3.4

> Mini Patch — Bugfix & Upload Fix

## Bug Fixes

### Upload

- Fixed the Publish button in Uploads — UI now responds correctly

### UI

- Arrow clickable area scaled in Home View
- Fixed This Week Uploads section
- Fixed Empty Setting Application issue

### Content

- Halloween wallpaper ended

## Improvements

### App Size

- Application size reduced from 50mb to 27mb'

# ---------------------------------------------------------------------------
# Release 1.3.3
# ---------------------------------------------------------------------------
update_release "1.3.3" '# Wallper v1.3.3

> Mini Patch — Bugfix & UX

## Improvements

### Apply Button

- Apply button now shows a spinner with fade/scale animation
- Busy state propagated through the UI
- Button disables while busy to prevent duplicate actions
- Auto-apply runs immediately after download completes
- Minor transition tweaks for smoother, clearer feedback'

# ---------------------------------------------------------------------------
# Release 1.3.2
# ---------------------------------------------------------------------------
update_release "1.3.2" '# Wallper v1.3.2

> Preview Bugfix

## Bug Fixes

### Preview Thumbnails

- Fixed async preview loading and caching for video cards
- Auto-preload on appear, hover-triggered generation and S3 path resolution
- Consistent thumbnails across all sections'

# ---------------------------------------------------------------------------
# Release 1.3.1
# ---------------------------------------------------------------------------
update_release "1.3.1" '# Wallper v1.3.1

> Maintenance Update

## Bug Fixes

### macOS 14 Sonoma Compatibility

- Corrected integration and behavior on Sonoma
- Improved stability across all supported versions

### Uploads

- Fixed video publishing via Uploads — metadata validation, status propagation, and storage path resolution

### Links Handling

- Corrected opening and routing of links inside the app — menu bar, guides, and support

### State Managers

- Fixed state synchronization issues leading to occasional UI desyncs after background updates or license changes'

# ---------------------------------------------------------------------------
# Release 1.3.0
# ---------------------------------------------------------------------------
update_release "1.3.0" '# Wallper v1.3.0

> Screen Saver, macOS 26 Support & New UI

## New Features

### macOS 26 Support

- Full support for macOS 26 "Tahoe"
- Fully redesigned interface for macOS 26
- Native screensaver available for macOS 26
- Planned native lock screen support for macOS <26 (in ~2 months)

### UI & UX

- App launches and updates silently in the background
- Default window behavior changed to background mode
- Fixed Dock launch and window resizing
- Fixed wallpaper restoration after downloads or sleep mode
- Optional static wallpaper installation fixed and stabilized
- Expanded menu bar functionality
- Cache can now be cleared directly from the menu bar
- Resource viewer removed — key features moved to the menu bar
- Improved system tray icon responsiveness and state tracking
- Improved responsiveness of UI under heavy usage
- Slightly improved preview loading speed

### Features & Content

- Filter and category states are now saved and synced between sessions
- Strict video naming enforced during publication
- Added recommendation blocks for promoting user videos

### Payments & Plans

- Removed free plan — replaced with a 7-day trial
- Automatic refunds for purchases within 14 days
- Option to download purchase receipt
- Updated purchase confirmation email
- 10% discount for joining the Discord community

### Documentation & Legal

- Added detailed usage documentation
- Updated Terms of Use, Privacy Policy, Cookies Policy, and Subprocessors
- Added Mac Compatibility Support, Displays Compatibility Support, Lock Screen Guide, and Uploads Guide
- Completely redesigned website

## Improvements

### Core & Architecture

- Completely new backend architecture — faster data access, higher reliability
- Extended backend performance under high load
- Updated internal APIs for faster response
- Improved error handling in background updates
- Optimized caching logic for media content
- Added secure data channels for video publishing

### Performance

- Reduced CPU and network load during video preview rendering
- Optimized network usage when hovering over many video cards
- Optimized menu bar resource calculations

### Integrations

- Improved collaboration and sponsor program integration'

# ---------------------------------------------------------------------------
# Release 1.2.1
# ---------------------------------------------------------------------------
update_release "1.2.1" '# Wallper v1.2.1

> Screen Saver Update

## New Features

### System Screen Saver

- You can now set Wallper videos as a system screen saver
- Videos are automatically converted to .mov and the original file is safely backed up
- Wallper replaces the Dubai Skyline screen saver — just select it in your Mac'\''s Screen Saver settings
- The system may ask for your Mac password once to allow installation in the protected folder
- Performance is fully optimized and wallpapers stay active even when your Mac is locked'

# ---------------------------------------------------------------------------
# Release 1.2.0
# ---------------------------------------------------------------------------
update_release "1.2.0" '# Wallper v1.2.0

> Native macOS Screen Saver (Alpha)

## New Features

### Native Screen Saver

- First truly native video screen saver for macOS
- Apple notarized for security and compatibility
- No administrator rights required
- Extremely low resource usage
- Can run without Wallper installed

## Notes

### Alpha Notice

- This is an early alpha release — core functionality is in place but there may still be bugs or rough edges
- Feedback and issue reports are welcome to help improve future versions'

# ---------------------------------------------------------------------------
# Release 1.1.1
# ---------------------------------------------------------------------------
update_release "1.1.1" '# Wallper v1.1.1

> Menu Bar, Positioning & Polish

## Improvements

### Menu Bar Integration

- Fixed a glitch where the menu bar color didn'\''t always adapt correctly
- Now updates immediately, stays in sync across Spaces

### Video Positioning

- Wallpapers now auto-center on each screen, which looks much cleaner — especially on ultrawide monitors or multiple displays
- You can still adjust positioning manually in Display Manager

### Launch Window

- The main app window now opens cleanly in the center of your screen

### New Badge Logic

- The green "new" dot now fades away after a few seconds
- It won'\''t reappear after restart — no clutter, no noise

## Bug Fixes

### Playback

- Wallpapers now reliably resume after waking from sleep or unlocking your Mac
- Better handling of fast video switches — fewer stutters, smoother feel
- Memory usage has been optimized when generating previews'

# ---------------------------------------------------------------------------
# Release 1.1.0
# ---------------------------------------------------------------------------
update_release "1.1.0" '# Wallper v1.1.0

> Major Stability & Control Update

## New Features

### Battery-Aware Mode

- Wallpapers automatically pause when on battery
- Resume instantly when plugged in
- Perfect for saving energy without sacrificing aesthetics

### Display Manager

- Adjust wallpaper scale
- Control position (X/Y offset)
- Disable wallpapers per monitor

### More Free Features

- More wallpapers and features available in the free version

## Bug Fixes

### Sleep & Login

- Wallpapers now restore properly after sleep
- Fixed issues with restoration after system login
- Solved a rare bug where the app would hang if internet wasn'\''t yet available during startup

### Faster Launch

- Wallpapers now load instantly at launch — no more delays or flicker

### Flicker & Transitions

- Fixed flickering when switching between videos
- Improved stability when monitors sleep/wake or change resolution/state'

# ---------------------------------------------------------------------------
# Release 1.0.9
# ---------------------------------------------------------------------------
update_release "1.0.9" '# Wallper v1.0.9

> Smarter Startup

## New Features

### Start on Login

- Wallper now launches automatically when you log in to your Mac
- Just enable the option in Settings — and your wallpapers are ready from the moment you start'

# ---------------------------------------------------------------------------
# Release 1.0.8
# ---------------------------------------------------------------------------
update_release "1.0.8" '# Wallper v1.0.8

> Reinvented from the Core

## What'\''s New

### Fully Rewritten Core

- Rebuilt the entire video playback engine from scratch — faster, leaner, and much more stable
- Smoother performance and instant responsiveness throughout the app

### Menu Bar Mode

- Wallper now lives in the menu bar and runs silently in the background
- RAM and CPU usage is dramatically reduced — even with live wallpapers enabled

### Smart Window Memory

- The app remembers your window positions and states
- Reopen Wallper and it'\''s exactly where you left it

### Live Usage Graph

- New interactive chart shows your real-time CPU usage directly in-app

### System Stats in Menu Bar

- Monitor your CPU and RAM consumption live from the menu — no extra tools needed'

# ---------------------------------------------------------------------------
# Release 1.0.7
# ---------------------------------------------------------------------------
update_release "1.0.7" '# Wallper v1.0.7

> Smarter Authors & Smarter Control

## New Features

### Creator Name Support

- Authors can now add their name to uploaded videos
- Shown directly in the preview and dynamically filterable from the bottom bar

### ESC to Cancel Downloads

- You can now press the Escape key while downloading a wallpaper to cancel it immediately'

# ---------------------------------------------------------------------------
# Release 1.0.6
# ---------------------------------------------------------------------------
update_release "1.0.6" '# Wallper v1.0.6

> Lighter, Cleaner, More Compatible

## Improvements

### Memory Optimization

- Wallper now uses just 83 MB of RAM on average
- Faster startup and smoother performance, especially on older Macs

### File Size Display

- Each wallpaper card now shows the file size
- Helps you pick the perfect one for your bandwidth or storage needs

### Filter Bar

- Filters now display correctly and apply instantly
- Clearing filters works as expected with one click
- Better responsiveness and more accurate search results

## Changes

### UI Simplification

- Removed the loop button to simplify the experience — most users didn'\''t need it
- Cleaner interface, fewer distractions

## Bug Fixes

### macOS 14 Compatibility

- Resolved critical startup issues on macOS 14
- The app now launches properly on all supported versions'

# ---------------------------------------------------------------------------
# Release 1.0.5
# ---------------------------------------------------------------------------
update_release "1.0.5" '# Wallper v1.0.5

> Realtime Likes & Better UX

## New Features

### Likes with Instant Feedback

- You can now like and unlike wallpapers directly from the grid view
- The UI updates immediately with smooth visual feedback — no delays, no reloads

## Improvements

### Auto Scroll to Top

- When switching between pages, the wallpaper feed now scrolls back to the top automatically
- Makes browsing faster and smoother'

# ---------------------------------------------------------------------------
# Release 1.0.4
# ---------------------------------------------------------------------------
update_release "1.0.4" '# Wallper v1.0.4

> Private Video Fix

## Bug Fixes

### Local Video Playback

- Fixed missing playback for user-imported videos after restart
- Previously, videos added via Import Local Video were no longer recognized after restarting the app
- Local videos are now persisted correctly by reinjecting them into the main video list during app startup

## Improvements

### Local Video Recovery

- All local videos stored in the Application Support/Wallper/Videos directory are re-scanned on launch
- If a matching VideoData doesn'\''t already exist, the app reconstructs it and adds it back'

# ---------------------------------------------------------------------------
# Release 1.0.3
# ---------------------------------------------------------------------------
update_release "1.0.3" '# Wallper v1.0.3

> Improved Video Loading Experience

## Bug Fixes

### Video Loading

- Fixed an issue where the screen appeared frozen while downloading videos
- Progress bar now updates in real-time and uses a clean white style to match the dark UI

## Improvements

### Playback

- Videos start playing immediately after download with no noticeable delay
- Previously downloaded videos now launch instantly thanks to better caching
- Visual transitions and animations are smoother for a more polished fullscreen experience'

# ---------------------------------------------------------------------------
# Release 1.0.0 (tag: Release)
# ---------------------------------------------------------------------------
update_release "Release" '# Wallper v1.0.0

> First Official Release

## New Features

### Live Wallpapers

- Live wallpapers with smooth performance
- Easy and intuitive UI for choosing wallpapers
- Dynamic customization options
- Lightweight and secure

## Notes

### Installation

- Download the binary and run it — no installation needed
- macOS supported
- Internet connection required for online wallpapers'

echo ""
echo "All releases updated successfully!"
