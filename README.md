# Apple TV Situation Room

A 9-screen auto-rotating intelligence dashboard for Apple TV, built with SwiftUI and tvOS. Pulls live data from 15+ free public APIs — no API keys required.

Built initially to explore Claude Code's ability to create software for niche platforms such as the Apple TV. Also useful as a background for video calls.

## What It Does

The app cycles through 9 full-screen dashboards every 30 seconds (60s for air traffic), displaying real-time data across global events, markets, space weather, cyber threats, and aviation.

| # | Screen | Highlights |
|---|--------|------------|
| 1 | **Global Situation** | World map with earthquake pins + expanding rings, market sidebar, crypto, fear/greed gauge |
| 2 | **Live Intel** | Embedded live news streams (DW, ABC, Al Jazeera, France 24) |
| 3 | **Markets & Economy** | US indices, commodities, crypto, VIX, S&P 500 heatmap |
| 4 | **Threat Assessment** | Earthquake list with pulse indicators, strategic theater posture, seismic radar sweep |
| 5 | **Space & Geophysical** | Solar weather, ISS tracker, asteroids, aurora oval map, solar flare X-ray chart, satellite constellation tracker |
| 6 | **Cyber & Infrastructure** | NWS severe weather alerts, NVD CVE feed, NEXRAD weather radar, lightning activity map |
| 7 | **Deep Markets** | 28-stock watchlist with sparklines, 12-sector ETF grid, crypto panel |
| 8 | **Global Threat Matrix** | DEFCON estimator, multi-hazard feed, global risk gauges, Doomsday Clock, flight tracking map |
| 9 | **Air Traffic Monitor** | Dual-phase: local satellite view (250nm) → worldwide view (~500 aircraft), nearby aircraft table, military flagging |

## Visual Design

- Near-black background with cyan/teal accents
- CRT scan line overlay across all screens
- Animated rolling number counters
- Radar sweep, expanding earthquake rings, pulsing indicators
- Dual scrolling ticker bars (markets + news headlines)
- Status bar with DEFCON level, countdown timers, and UTC clock

## Data Sources

All free, no API keys needed:

| Source | Data |
|--------|------|
| USGS | Earthquakes |
| Yahoo Finance | Market quotes, watchlist, sector ETFs, sparklines |
| CoinGecko | Crypto prices |
| Alternative.me | Fear & Greed Index |
| NOAA SWPC | Solar weather, aurora, X-ray flux |
| Open Notify | ISS position |
| JPL SBDB | Asteroid approaches |
| NASA EONET | Natural events |
| NWS | Severe weather alerts |
| NVD/NIST | Recent CVEs |
| CelesTrak | Satellite positions |
| ADSB.lol | Flight tracking |
| Iowa Mesonet | NEXRAD weather radar |
| BBC/CNBC/NPR/Guardian/NYT/Reuters | News headlines (RSS) |

## Architecture

```
SituationRoom/Sources/
├── App/          — App entry point
├── Config/       — Hotspots, live stream URLs
├── Models/       — Data types (market, cyber, space, news)
├── Services/     — APIService (actor-based), DashboardState, LocationManager, RSSParser
└── Views/        — 9 screen views + main dashboard + overlays
```

- **DashboardState** — Central `@MainActor ObservableObject` managing all data + auto-rotation
- **APIService** — Actor-based, fetches 15+ APIs in parallel every 120s
- **LocationManager** — CoreLocation for flight proximity (IP-based on tvOS)

## Requirements

- Apple TV 4K (tvOS 17+)
- Xcode 15+
- Free Apple Developer account (signing expires every 7 days)

## Build & Deploy

```bash
xcodebuild -project SituationRoom.xcodeproj \
  -scheme SituationRoom \
  -destination 'platform=tvOS,name=Apple TV' \
  -allowProvisioningUpdates build
```

## Built With

Swift, SwiftUI, MapKit, CoreLocation, and Claude Code.
