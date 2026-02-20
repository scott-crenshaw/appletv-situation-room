# Project Status — Mac Situation Room

**Last updated:** 2026-02-20 04:00 UTC

## What Was Completed

### Core App (8 Screens, All Working)
1. **Global Situation** — World map with earthquake pins, market sidebar, crypto, fear/greed gauge
2. **Live Intel** — Embedded live news streams (DW, ABC, Al Jazeera, France 24, YouTube)
3. **Markets & Economy** — US indices, commodities, crypto, VIX, fear/greed gauge
4. **Threat Assessment** — Earthquake list, strategic theater posture, active conflicts
5. **Space & Geophysical** — Solar weather (Kp, solar wind, Bz), ISS tracker, asteroids (JPL), natural events (EONET), Doomsday Clock
6. **Cyber & Infrastructure** — NWS severe weather alerts, NVD CVE feed, infrastructure status indicators, threat landscape panel
7. **Deep Markets** — 28-stock watchlist grid, 12-sector ETF heatmap, enhanced crypto panel, fear/greed
8. **Global Threat Matrix** — DEFCON estimator, multi-hazard event feed, global risk gauges (geopolitical/natural/economic/cyber), conflict tracker with 7 conflicts, Doomsday Clock, key risk indicators, threat news feed

### Architecture
- **DashboardState** — Central `@MainActor ObservableObject` managing all data + auto-rotation (30s per screen)
- **APIService** — Actor-based, fetches from 10+ free public APIs in parallel every 120s
- **Dual ticker bars** — Market strip + news headlines scrolling at bottom of every screen
- **Status bar** — DEFCON level, screen name, UTC time, auto-rotate indicator at top

### Data Sources (All Free, No API Keys)
| Source | API | Used By |
|--------|-----|---------|
| USGS GeoJSON | earthquake.usgs.gov | Earthquakes |
| Yahoo Finance v8 | query1.finance.yahoo.com | Market quotes, watchlist, sectors |
| CoinGecko | api.coingecko.com | Crypto prices |
| Alternative.me | api.alternative.me | Fear & Greed Index |
| NOAA SWPC | services.swpc.noaa.gov | Kp index, solar wind, Bz |
| Open Notify | api.open-notify.org | ISS position |
| JPL SBDB | ssd-api.jpl.nasa.gov | Asteroid approaches |
| NASA EONET | eonet.gsfc.nasa.gov | Natural events (fires, volcanoes, storms) |
| NWS | api.weather.gov | US severe weather alerts |
| NVD/NIST | services.nvd.nist.gov | Recent CVEs |
| BBC/CNBC/Diplomat RSS | Various | News headlines |

## Deployment
- **Successfully deployed to physical Apple TV** ("Living Room") on 2026-02-19
- Bundle ID: `com.scottcrenshaw.situationroom`
- Signed with: Scott Crenshaw (Personal Team) — free account, expires in 7 days
- Device ID: `00008110-001260480A51401E`

## What's Tested
- All 8 screens verified visually on Apple TV 4K (3rd gen) simulator
- App running on physical Apple TV — confirmed working
- All API endpoints tested and returning real data
- Auto-rotation working across all screens
- Market + news ticker bars scrolling correctly
- Screenshot verification workflow: `xcrun simctl io` → `sips --resampleWidth 1920` → stays under 2000px limit

## Known Issues
- "ELEVATED" text wraps in Cyber screen's threat level bar (minor cosmetic)
- Space screen: slight visual overlap with adjacent screen data during transitions (opacity animation)
- France 24 live stream shows "hostname could not be found" error (stream URL may have changed)
- Infrastructure status indicators are static (no free API for real-time internet health monitoring)
- Conflict data is hardcoded (no free conflict tracking API)
- NVD API is rate-limited without an API key (may fail on rapid refreshes)

## What's Next (Potential Enhancements)
- Add keyboard/remote navigation between screens (tvOS focus engine)
- Add GDACS disaster feed as additional hazard source
- Replace static infrastructure indicators with real monitoring (requires API keys)
- Add more RSS feeds for broader news coverage
- Persist user preferences (DEFCON level, rotation speed, favorite screens)
- Add sound alerts for significant events (M6+ earthquakes, extreme weather)
- macOS native target (currently tvOS only)

## Project Structure
```
SituationRoom/Sources/
├── App/
│   └── SituationRoomApp.swift
├── Config/
│   ├── Hotspots.swift
│   └── LiveStreams.swift
├── Models/
│   ├── CyberData.swift          — WeatherAlert, CVEEntry, InfraStatus
│   ├── MarketData.swift         — MarketQuote, CryptoPrice, FearGreedIndex
│   ├── NewsItem.swift           — NewsItem, Earthquake, USGSResponse
│   └── SpaceData.swift          — SpaceWeather, ISSPosition, AsteroidApproach, NaturalEvent
├── Services/
│   ├── APIService.swift         — All API fetching (actor-based)
│   ├── DashboardState.swift     — Central state manager + timers
│   └── RSSParser.swift          — Simple RSS XML parser
└── Views/
    ├── CyberScreenView.swift    — Screen 6: Cyber & Infrastructure
    ├── DashboardView.swift      — Main view + StatusBar + TickerBars
    ├── DeepMarketsScreenView.swift — Screen 7: Deep Markets
    ├── GlobalThreatMatrixView.swift — Screen 8: Global Threat Matrix
    ├── LiveIntelScreenView.swift — Screen 2: Live Intel
    ├── MarketsScreenView.swift  — Screen 3: Markets & Economy
    ├── SituationScreenView.swift — Screen 1: Global Situation
    ├── SpaceScreenView.swift    — Screen 5: Space & Geophysical
    └── ThreatScreenView.swift   — Screen 4: Threat Assessment
```

## Build & Run
```bash
# Build
xcodebuild -project SituationRoom.xcodeproj -scheme SituationRoom \
  -destination 'platform=tvOS Simulator,name=Apple TV 4K (3rd generation)' build

# Install & Launch
xcrun simctl install booted <path-to-built-app>
xcrun simctl launch booted com.situationroom.tvos

# Screenshot (resized for context window)
xcrun simctl io booted screenshot /tmp/screen.png
sips --resampleWidth 1920 /tmp/screen.png --out /tmp/screen_small.png
```
