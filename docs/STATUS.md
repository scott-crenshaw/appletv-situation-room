# Project Status — Mac Situation Room

**Last updated:** 2026-02-20 18:15 UTC

## What Was Completed

### Core App (9 Screens, All Working)
1. **Global Situation** — World map with earthquake pins + expanding rings, market sidebar, crypto, fear/greed gauge
2. **Live Intel** — Embedded live news streams (DW, ABC, Al Jazeera, France 24, YouTube)
3. **Markets & Economy** — US indices, commodities, crypto, VIX, fear/greed gauge, S&P 500 heatmap
4. **Threat Assessment** — Earthquake list with pulse indicators, strategic theater posture, active conflicts, seismic radar sweep
5. **Space & Geophysical** — Solar weather, ISS tracker, asteroids, natural events, aurora oval map, solar flare X-ray chart, satellite constellation tracker
6. **Cyber & Infrastructure** — NWS severe weather alerts, NVD CVE feed, infrastructure status, NEXRAD weather radar, lightning activity map
7. **Deep Markets** — 28-stock watchlist with sparklines, 12-sector ETF grid, crypto panel, fear/greed
8. **Global Threat Matrix** — DEFCON estimator, multi-hazard feed, global risk gauges, conflict tracker, Doomsday Clock, flight tracking map
9. **Air Traffic Monitor** — 60s dual-phase: local satellite view (250nm, 30s) → worldwide view (~500 aircraft, 30s), nearby aircraft table, altitude stats, military flagging

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
6. Live flight tracking map from ADSB.lol (Global Threat Matrix, Air Traffic Monitor)
7. Severe weather activity lightning visualization (Cyber & Infrastructure)

### Air Traffic Monitor (commits 4ed04e3, 92d2bb2, 3caee6c)
- **Data source**: ADSB.lol (primary, no auth, no rate limits) with OpenSky Network fallback
- **Dual-phase display** (60s total, double other screens):
  - Phase 1 (0-30s): Local satellite view centered on user location (250nm radius)
  - Phase 2 (30-60s): Worldwide view with ~500 aircraft (sampled from 3 regional ADSB.lol queries) centered on mid-Atlantic for full world coverage
  - Animated camera transition between phases (2.5s ease-in-out)
- **Map**: MapKit satellite imagery, aircraft as heading-rotated arrows (smaller dots in global view)
- **Table**: 20 nearest aircraft sorted by distance — callsign, registration, ICAO type, distance (nm), altitude (FL), speed (kt), heading (always shows local data)
- **Stats**: Total count, altitude band breakdown (LOW/MID/HIGH), military count, top aircraft types
- **CoreLocation**: IP-based geolocation on tvOS, works in Denver and Austin
- **Military**: Flagged with red "M" badge in table, red dots on map

### Architecture
- **DashboardState** — Central `@MainActor ObservableObject` managing all data + auto-rotation (30s per screen, 60s for Air Traffic)
- **APIService** — Actor-based, fetches from 15+ free public APIs in parallel every 120s
- **LocationManager** — CoreLocation wrapper for tvOS, provides user position for flight proximity
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
| ADSB.lol | api.adsb.lol | Flight positions, registration, type, military flag |
| OpenSky Network | opensky-network.org | Flight positions (fallback) |
| Iowa Mesonet WMS | mesonet.agron.iastate.edu | NEXRAD weather radar composites |
| BBC/CNBC/NPR/Guardian/NYT/Reuters RSS | Various | News headlines |

## Deployment
- **Successfully deployed to physical Apple TV** ("Living Room") on 2026-02-20
- Bundle ID: `com.scottcrenshaw.situationroom`
- Signed with: Scott Crenshaw (Personal Team) — free account, expires in 7 days
- Device ID: `00008110-001260480A51401E`

## What's Tested
- All 9 screens verified visually on Apple TV 4K simulator + physical Apple TV
- All Tier 1 + Tier 2 features verified via screenshots
- All API endpoints tested and returning real data
- ADSB.lol returning 300+ aircraft with registration, type, military flags
- CoreLocation working on simulator (Denver) and physical Apple TV (Austin)
- Auto-rotation, remote navigation, countdown timers all working
- Ticker scrolling smooth after reducing annotation counts (500 global, 400 local)
- Sparklines, heatmap, radar sweep, flight tracker, weather radar all rendering

## Known Issues
- France 24 live stream shows "hostname could not be found" error (stream URL may have changed)
- Infrastructure status indicators are static (no free API for real-time internet health monitoring)
- Conflict data is hardcoded (no free conflict tracking API)
- NVD API is rate-limited without an API key (may fail on rapid refreshes)
- Lightning map uses weather alert count as proxy (Blitzortung API requires auth)
- ADSB.lol is community-run with no SLA (OpenSky fallback mitigates this)
- Ship tracking not feasible — no free, no-auth AIS API exists (see `docs/RESEARCH_flight_tracking_apis.md`)

## What's Next
- See `docs/FEATURE_BACKLOG.md` for remaining Tier 2 items (require API keys) and Tier 3 features
- Potential: GDACS disaster feed, sound alerts, macOS native target, user preferences persistence
- Flight enrichment: AirLabs free tier (1,000 req/mo) could add origin/destination airports

## Git History
```
f675f6a Reduce aircraft annotation counts to fix ticker stutter on Apple TV
668bd1b Center global airspace view on mid-Atlantic for full world coverage
e25cf24 Update STATUS.md with dual-phase air traffic feature
3caee6c Add 60s air traffic screen with local→global phase transition
1b3f0c3 Update STATUS.md for Screen 9 and ADSB.lol migration
92d2bb2 Switch flight feed to ADSB.lol, add satellite map overlay
4ed04e3 Add Screen 9: Air Traffic Monitor with nearby aircraft table
329dff0 Fix news ticker freezing after data refresh
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
│   ├── LocationManager.swift    — CoreLocation wrapper for tvOS
│   └── RSSParser.swift          — Simple RSS XML parser
└── Views/
    ├── AirTrafficScreenView.swift — Screen 9: Air Traffic Monitor
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
