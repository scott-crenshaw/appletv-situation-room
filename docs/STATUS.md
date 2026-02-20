# Project Status — Mac Situation Room

**Last updated:** 2026-02-20 09:45 UTC

## What Was Completed

### Core App (8 Screens, All Working)
1. **Global Situation** — World map with earthquake pins + expanding rings, market sidebar, crypto, fear/greed gauge
2. **Live Intel** — Embedded live news streams (DW, ABC, Al Jazeera, France 24, YouTube)
3. **Markets & Economy** — US indices, commodities, crypto, VIX, fear/greed gauge, S&P 500 heatmap
4. **Threat Assessment** — Earthquake list with pulse indicators, strategic theater posture, active conflicts, seismic radar sweep
5. **Space & Geophysical** — Solar weather, ISS tracker, asteroids, natural events, aurora oval map, solar flare X-ray chart, satellite constellation tracker
6. **Cyber & Infrastructure** — NWS severe weather alerts, NVD CVE feed, infrastructure status, NEXRAD weather radar, lightning activity map
7. **Deep Markets** — 28-stock watchlist with sparklines, 12-sector ETF grid, crypto panel, fear/greed
8. **Global Threat Matrix** — DEFCON estimator, multi-hazard feed, global risk gauges, conflict tracker, Doomsday Clock, flight tracking map

### Visual Enhancements (Tier 1 — commit 567bf88)
1. Animated rolling number counters (`.contentTransition(.numericText())`)
2. Earthquake expanding rings on map + pulse indicators on threat list
3. CRT scan line overlay on entire dashboard
4. Aurora probability polar map (SWPC OVATION data)
5. Countdown timers in status bar (NYSE hours, data refresh, screen rotation)
6. Additional RSS feeds (NPR, Guardian, NY Times, Reuters)
7. Sparklines in Deep Markets stock tiles (Yahoo Finance v8 chart)

### Visual Enhancements (Tier 2 — commit 3e7d636)
1. Solar flare X-ray flux chart with GOES data and flare classification (Space)
2. S&P 500 heatmap grid color-coded by daily % change (Markets)
3. Animated radar sweep with seismic blips (Threat Assessment)
4. NEXRAD weather radar composite overlay (Cyber & Infrastructure)
5. Satellite constellation tracker from CelesTrak data (Space)
6. Live flight tracking map from OpenSky Network (Global Threat Matrix)
7. Severe weather activity lightning visualization (Cyber & Infrastructure)

### Architecture
- **DashboardState** — Central `@MainActor ObservableObject` managing all data + auto-rotation (30s per screen)
- **APIService** — Actor-based, fetches from 15+ free public APIs in parallel every 120s
- **Dual ticker bars** — Market strip + news headlines scrolling at bottom of every screen
- **Status bar** — DEFCON level, screen name, countdown timers, UTC time at top
- **CRT overlay** — Subtle scan lines + gradient sweep across all screens

### Data Sources (All Free, No API Keys)
| Source | API | Used By |
|--------|-----|---------|
| USGS GeoJSON | earthquake.usgs.gov | Earthquakes |
| Yahoo Finance v8 | query1.finance.yahoo.com | Market quotes, watchlist, sectors, sparklines |
| CoinGecko | api.coingecko.com | Crypto prices |
| Alternative.me | api.alternative.me | Fear & Greed Index |
| NOAA SWPC | services.swpc.noaa.gov | Kp index, solar wind, Bz, aurora, solar X-ray flux |
| Open Notify | api.open-notify.org | ISS position |
| JPL SBDB | ssd-api.jpl.nasa.gov | Asteroid approaches |
| NASA EONET | eonet.gsfc.nasa.gov | Natural events (fires, volcanoes, storms) |
| NWS | api.weather.gov | US severe weather alerts |
| NVD/NIST | services.nvd.nist.gov | Recent CVEs |
| CelesTrak | celestrak.org | Satellite positions (Starlink) |
| OpenSky Network | opensky-network.org | Live flight positions |
| Iowa Mesonet WMS | mesonet.agron.iastate.edu | NEXRAD weather radar composites |
| BBC/CNBC/NPR/Guardian/NYT/Reuters RSS | Various | News headlines |

## Deployment
- **Successfully deployed to physical Apple TV** ("Living Room") on 2026-02-20
- Bundle ID: `com.scottcrenshaw.situationroom`
- Signed with: Scott Crenshaw (Personal Team) — free account, expires in 7 days
- Device ID: `00008110-001260480A51401E`

## What's Tested
- All 8 screens verified visually on Apple TV 4K simulator + physical Apple TV
- All Tier 1 + Tier 2 features verified via screenshots
- All API endpoints tested and returning real data
- Auto-rotation, remote navigation, countdown timers all working
- Sparklines, heatmap, radar sweep, flight tracker, weather radar all rendering

## Known Issues
- France 24 live stream shows "hostname could not be found" error (stream URL may have changed)
- Infrastructure status indicators are static (no free API for real-time internet health monitoring)
- Conflict data is hardcoded (no free conflict tracking API)
- NVD API is rate-limited without an API key (may fail on rapid refreshes)
- Lightning map uses weather alert count as proxy (Blitzortung API requires auth)

## What's Next
- See `docs/FEATURE_BACKLOG.md` for remaining Tier 2 items (require API keys) and Tier 3 features
- Potential: GDACS disaster feed, sound alerts, macOS native target, user preferences persistence

## Git History
```
3e7d636 Tier 2 visual enhancements: 7 features adding live data visualizations
567bf88 Tier 1 visual enhancements: 7 features to elevate dashboard aesthetics
f389a8e Release 1.0: fix news ticker, upgrade video feeds, add remote navigation
432c9b3 First POC to AppleTV
```

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
    ├── DashboardView.swift      — Main view + StatusBar + TickerBars + CRT overlay
    ├── DeepMarketsScreenView.swift — Screen 7: Deep Markets
    ├── GlobalThreatMatrixView.swift — Screen 8: Global Threat Matrix
    ├── LiveIntelScreenView.swift — Screen 2: Live Intel
    ├── MarketsScreenView.swift  — Screen 3: Markets & Economy
    ├── SituationScreenView.swift — Screen 1: Global Situation
    ├── SpaceScreenView.swift    — Screen 5: Space & Geophysical
    └── ThreatScreenView.swift   — Screen 4: Threat Assessment
```
