# <img src="docs/klamap-icon.png" alt="klamap icon" width="32" align="top"> klamap # klamap

Native iOS/macOS app to design cinematic map routes and camera paths, exporting high-quality videos and image sequences between points A and B — an Apple-centric alternative to Google Earth Studio.

> ⚠️ Work in progress – API, UI and file formats may change at any time.

---

## Features

- 🎯 **A/B points on Apple Maps**
  - Set point **A** and **B** with a crosshair at the center of the map
  - Live preview of the camera path between A and B

- 🗺️ **Camera & path control**
  - Adjustable **pitch**, heading and distance
  - Option to **keep the route centered** (CarPlay-like framing)
  - **Curved path** with configurable curvature (spline)
  - Optional **real route following** (car / walk / transit)

- ⏱️ **Timing & motion**
  - Global **duration in seconds** with human-readable breakdown (d/h/min/s)
  - Multiple **easing presets** (linear, ease-in/out, smoothstep, cubic-bezier)
  - Separate **intro / outro** percentages with live clamps
  - Optional **traffic simulation**: stops, speed jitter, variability

- 🎬 **Export modes**
  - **Single still image** at any point in the animation
  - **Video export** (H.264 / HEVC containers) with:
    - FPS from 1–120
    - Adjustable bitrate (Mb/s)
    - Frame count based on `duration × FPS` or **fixed number of frames**
  - **Uncompressed PNG sequence**:
    - Frames written to a temp folder
    - Archived as a `.zip` for import in other tools (e.g. compositing apps)

- 🧱 **Resolution & aspect**
  - Presets: **Native**, **1080p**, **4K**
  - Aspect ratios: **Device**, 16:9, 4:3, 1:1, **Custom**
  - Portrait / landscape toggle (when aspect is not “device”)
  - **Oversampling slider** (×1.0 → ×5.0) to reduce aliasing

- 🖼️ **Image formats**
  - **PNG** (with compression level 0–9)
  - **JPEG** (quality slider)
  - **HEIC** (quality slider)
  - **TIFF**

- 🧭 **Map styles & labels**
  - Standard / muted / hybrid styles
  - Optional realistic elevation when pitch > 1°
  - Toggle for **road labels / POI visibility**
  - Optional **route polyline** overlay (CarPlay-style blue line)

- 📂 **Preset & data export**
  - Export/import of presets as custom `.klav` text files:
    - Points A/B
    - Resolution / aspect / orientation
    - Timing, easing, oversampling
    - Image/video formats, frame counts
    - Route & traffic options
  - Export **tracking data** as:
    - `tracking-…​.json`
    - `tracking-…​.csv` (simple lat/lon listing for A/B)

- 🧪 **Onboarding & overlays**
  - Boot overlay with short progress animation
  - First-launch onboarding with:
    - App logo
    - Short description
    - Links to GitHub / Instagram / Discord
  - Full-screen render overlay:
    - Progress text + percentage
    - Cancel button
    - Success / error states
    - Special UI when exporting image sequences (ZIP)

---

## Requirements

- **Xcode**: 15+ (recommended)
- **Platforms**:
  - iOS 17+ (iPhone, iPad)
  - macOS (via Mac Catalyst / SwiftUI, depending on your target)
- Uses:
  - `MapKit`
  - `CoreLocation`
  - `AVFoundation`
  - `Photos` / `PhotosUI`
  - `UniformTypeIdentifiers`
  - `ZIPFoundation` (optional, for ZIP creation)

---

## Getting started

1. **Clone the repository**:

   ```bash
   git clone https://github.com/0klavair/klamap.git
   cd klamap
