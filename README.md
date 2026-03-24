# Apple TV Situation Room

A 9-screen auto-rotating intelligence dashboard for Apple TV, built with SwiftUI and tvOS. Pulls live data from 15+ free public APIs — no API keys required.

Built initially to explore Claude Code's ability to create software for niche platforms such as the Apple TV. Also useful as a background for video calls.

## What It Does

The app cycles through 9 full-screen dashboards every 30 seconds (60s for Air Traffic and Gulf Command), displaying real-time data across global events, markets, energy, space weather, cyber threats, aviation, and military activity.

| # | Screen | Highlights |
|---|--------|------------|
| 1 | **Global Situation** | World map with earthquake pins + expanding rings, market sidebar, crypto, fear/greed gauge |
| 2 | **Live Intel** | Embedded live news streams (DW, ABC, Al Jazeera, France 24) |
| 3 | **Markets & Economy** | US indices, commodities, crypto, VIX, S&P 500 heatmap |
| 4 | **Energy & Oil Portfolio** | WTI/Brent 30-day price charts, 13-stock energy portfolio, 5-stock high-oil portfolio with sparklines |
| 5 | **Natural Threats** | Earthquakes (M4.5+) with seismic radar, severe weather alerts, NASA EONET natural events |
| 6 | **Space & Geophysical** | SUVI 195Å solar imagery, DONKI flare/CME events, 3-day forecast, ISS tracker, asteroids, aurora oval, satellite constellations |
| 7 | **Cyber & Infrastructure** | NVD CVE feed, infrastructure status monitoring |
| 8 | **Air Traffic Monitor** | Dual-phase: local satellite view (250nm) → worldwide view (~500 aircraft), nearby aircraft table, military flagging |
| 9 | **Persian Gulf Command** | Dual-phase: Gulf zone → ME theater view, conflict events (GDELT), military flights, satellite tracking |

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
| Yahoo Finance | Market quotes, oil benchmarks, energy/oil portfolios, sparklines |
| CoinGecko | Crypto prices |
| Alternative.me | Fear & Greed Index |
| NOAA SWPC | Solar weather, SUVI imagery, aurora, X-ray flux, DONKI events, 3-day forecast |
| Where The ISS At | ISS position |
| JPL SBDB | Asteroid approaches |
| NASA EONET | Natural events |
| NWS | Severe weather alerts |
| NVD/NIST | Recent CVEs |
| CelesTrak | Satellite positions (Starlink, GPS, military) |
| ADSB.lol | Flight tracking (local, global, Gulf region) |
| GDELT | Conflict events and geopolitical data |
| BBC/CNBC/NPR/Guardian/NYT/Reuters | News headlines (RSS) |

## Architecture

```
SituationRoom/Sources/
├── App/          — App entry point
├── Config/       — Hotspots, live stream URLs
├── Models/       — Data types (market, cyber, space, news)
├── Services/     — APIService (actor-based), DashboardState, LocationManager, RSSParser
└── Views/        — 9 screen views + dashboard container + overlays
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
