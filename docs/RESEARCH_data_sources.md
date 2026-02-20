# Situation Room Data Sources Research

## Date: 2026-02-19

Research into available data sources for a tvOS "Situation Room" app, combining World Monitor's proven sources with additional tvOS-friendly content.

---

## 1. LIVE NEWS VIDEO STREAMS (YouTube Live)

These are 24/7 YouTube Live streams. On tvOS, they'd be played via AVPlayer using extracted HLS/DASH URLs (via `youtubei.js` or a backend proxy). YouTube embeds won't work natively on tvOS — we need direct stream URLs.

| Channel | YouTube Handle | Fallback Video ID | Visual Appeal |
|---------|---------------|-------------------|---------------|
| Bloomberg | @Bloomberg | iEpJwprxDdk | HIGH - financial data overlays |
| Sky News | @SkyNews | YDvsBbKfLPA | HIGH - breaking news |
| Euronews | @euronews | pykpO5kQJ98 | HIGH - European focus |
| DW News | @DWNews | LuKwFajn37U | HIGH - international |
| CNBC | @CNBC | 9NyxcX3rhQs | HIGH - market data |
| France24 EN | @FRANCE24English | Ap-UM1O9RBU | MEDIUM |
| Al Arabiya | @AlArabiya | n7eQejkXbnM | MEDIUM - Arabic/English |
| Al Jazeera EN | @AlJazeeraEnglish | gCNeDWCI0vo | HIGH - conflict coverage |
| NASA TV | @NASA | fO9e9jnhYK8 | HIGH - space visuals |

**tvOS approach:** Backend service extracts HLS stream URLs from YouTube video IDs using `youtubei.js`. AVPlayer plays HLS natively. Rotate channels on a timer or let user navigate with Siri Remote.

**Apple TV App Store risk:** YouTube ToS technically prohibit extracting streams outside their player. Mitigations: use as "personal use" dashboard, don't distribute on App Store, or use YouTube's official TV API (limited).

---

## 2. LIVE WEBCAMS (YouTube)

From World Monitor's verified webcam feeds — all YouTube-based:

### Middle East (Conflict Hotspots)
| City | Channel | Fallback ID | Appeal |
|------|---------|-------------|--------|
| Jerusalem | @TheWesternWall | UyduhBUpO7Q | HIGH |
| Tehran | @IranHDCams | -zGuR1qVKrU | HIGH |
| Tel Aviv | @IsraelLiveCam | -VLcYT5QBrY | MEDIUM |
| Mecca | @MakkahLive | DEcpmPUbkDQ | MEDIUM |

### Europe
| City | Channel | Fallback ID | Appeal |
|------|---------|-------------|--------|
| Kyiv | @DWNews | -Q7FuPINDjA | HIGH - war zone |
| Odessa | @UkraineLiveCam | e2gC37ILQmk | HIGH |
| Paris | @PalaisIena | OzYp4NRZlwQ | MEDIUM |
| St. Petersburg | @SPBLiveCam | CjtIYbmVfck | MEDIUM |
| London | @EarthCam | Lxqcg1qt0XU | MEDIUM |

### Americas
| City | Channel | Fallback ID | Appeal |
|------|---------|-------------|--------|
| Washington DC | @AxisCommunications | 1wV9lLe14aU | HIGH |
| New York | @EarthCam | 4qyZLflp-sI | HIGH |
| Los Angeles | @VeniceVHotel | EO_1LWqsCNE | MEDIUM |
| Miami | @FloridaLiveCams | 5YCajRjvWCg | MEDIUM |

### Asia-Pacific
| City | Channel | Fallback ID | Appeal |
|------|---------|-------------|--------|
| Taipei | @JackyWuTaipei | z_fY1pj1VBw | HIGH - strait hotspot |
| Shanghai | @SkylineWebcams | 76EwqI5XZIc | HIGH |
| Tokyo | @TokyoLiveCam4K | 4pu9sF5Qssw | HIGH - 4K |
| Seoul | @UNvillage_live | -JhoMGoAfFc | MEDIUM |
| Sydney | @WebcamSydney | 7pcL-0Wo77U | MEDIUM |

**tvOS approach:** 2x2 or 3x3 grid of live webcam feeds, cycling by region. Use AVPlayer for each cell. Auto-rotate regions every 60 seconds.

---

## 3. MAPS & GLOBE (tvOS-native)

tvOS cannot use WebGL/deck.gl. Options:

### MapKit (Native tvOS)
- **Available on tvOS:** Yes
- **Capabilities:** Satellite/standard/hybrid tiles, annotations, overlays, polylines
- **Limitations:** No custom WebGL layers, no deck.gl aggregation
- **Best for:** Plotting conflict zones, bases, hotspots as annotations
- **Visual appeal:** HIGH (Apple's satellite imagery is excellent on big screens)

### SceneKit 3D Globe
- **Available on tvOS:** Yes
- **Approach:** Render a 3D globe with SceneKit, overlay data points
- **Visual appeal:** VERY HIGH for a situation room feel
- **Complexity:** Medium-high

### Pre-rendered Map Tiles
- **Approach:** Backend renders map frames with data overlays, sends as images
- **Visual appeal:** HIGH (can replicate deck.gl look)
- **Complexity:** High (need server-side rendering)

### Recommended: MapKit + Annotations
- Plot ~200 military bases, nuclear sites, conflict zones as map annotations
- Use MKOverlay for conflict region polygons
- Color-code by threat level (red/orange/yellow)
- Auto-pan between regional presets every 30 seconds

---

## 4. FINANCIAL MARKETS (Free APIs)

### Direct APIs (no proxy needed)
| Source | API | Free Tier | Data | Auth |
|--------|-----|-----------|------|------|
| Yahoo Finance | Unofficial REST | Unlimited* | Stocks, indices, crypto, commodities | None |
| CoinGecko | api.coingecko.com | 10-50 req/min | Crypto prices, volumes | None |
| Finnhub | finnhub.io/api/v1 | 60 req/min | Stock quotes, news | API key (free) |
| Alpha Vantage | alphavantage.co | 25 req/day | Stocks, forex, crypto | API key (free) |
| FRED | api.stlouisfed.org | 120 req/min | Economic indicators | API key (free) |
| EIA | api.eia.gov | 1000 req/hr | Energy data | API key (free) |
| Alternative.me | alternative.me/crypto | Unlimited | Fear & Greed Index | None |
| Mempool.space | mempool.space/api | Unlimited | Bitcoin hashrate, fees | None |

### World Monitor's Market Config
- **Indices:** S&P 500, Dow Jones, NASDAQ
- **Top Stocks:** AAPL, MSFT, NVDA, GOOGL, AMZN, META, TSLA, etc. (28 symbols)
- **Commodities:** VIX, Gold, Crude Oil, Natural Gas, Silver, Copper
- **Crypto:** Bitcoin, Ethereum, Solana
- **Sectors:** XLK, XLF, XLE, XLV, XLY, XLI, XLP, XLU, XLB, XLRE, XLC, SMH

**tvOS display:** Large-format ticker board, color-coded green/red. Sector heatmap using colored grid cells. Update every 60 seconds.

---

## 5. MILITARY/AVIATION TRACKING

| Source | API | Free Tier | Auth |
|--------|-----|-----------|------|
| OpenSky Network | opensky-network.org/api | 400 req/10s (anon) | Optional (higher limits) |
| ADS-B Exchange | adsbexchange.com | Public API | API key |
| ADSB.fi | api.adsb.fi | Public | None |
| Wingbits | wingbits.com | Commercial | API key |

**World Monitor approach:** Uses OpenSky Network + AISStream via WebSocket relay (Railway). Military aircraft identified by ICAO hex ranges (config in `/src/config/military.ts`).

**tvOS approach:** Periodic REST polling (every 30-60s) instead of WebSocket. Plot aircraft positions on MapKit. Filter for military-only using ICAO prefixes.

---

## 6. MARITIME/VESSEL TRACKING

| Source | API | Free Tier | Auth |
|--------|-----|-----------|------|
| AISStream | aisstream.io | WebSocket | API key (free tier) |
| MarineTraffic | marinetraffic.com | Limited | API key (paid) |

**World Monitor approach:** WebSocket connection to AISStream via Railway relay server.

**tvOS approach:** Backend polls AIS data periodically, serves snapshots via REST. Plot vessel positions on MapKit with ship type icons.

---

## 7. NATURAL DISASTERS

| Source | API | Free Tier | Data | Auth |
|--------|-----|-----------|------|------|
| USGS Earthquakes | earthquake.usgs.gov | Unlimited | GeoJSON, M4.5+ daily | None |
| NASA FIRMS | firms.modaps.eosdis.nasa.gov | 10 req/min | Satellite fire detection | API key (free) |
| GDACS | gdacs.org | Public RSS/API | Disasters, alerts | None |
| Open-Meteo | open-meteo.com | Unlimited | Weather, climate | None |
| NASA EONET | eonet.gsfc.nasa.gov | Public | Natural events | None |

**World Monitor's FIRMS regions:** Ukraine, Russia, Iran, Israel/Gaza, Syria, Taiwan, North Korea, Saudi Arabia, Turkey.

**tvOS display:** Earthquake dots on globe (size = magnitude), fire clusters as heat indicators, severe weather alerts as banner overlays.

---

## 8. SPACE & SATELLITE

| Source | API | Free | Data |
|--------|-----|------|------|
| NASA ISS | api.open-notify.org | Yes | ISS position |
| CelesTrak | celestrak.org | Yes | Satellite TLE data |
| Space-Track | space-track.org | Yes | Satellite catalog |
| NOAA SWPC | swpc.noaa.gov | Yes | Space weather, solar flares |
| SpaceX | api.spacexdata.com | Yes | Launch schedule |

**tvOS display:** ISS ground track on globe, solar activity indicator, next launch countdown.

---

## 9. CYBER THREATS

| Source | API | Free | Data |
|--------|-----|------|------|
| Cloudflare Radar | radar.cloudflare.com | API | Internet outages | API token |
| AbuseIPDB | abuseipdb.com | 1000 checks/day | IP reputation | API key |
| VirusTotal | virustotal.com | 4 req/min | Malware/IOC | API key |
| OTX AlienVault | otx.alienvault.com | Unlimited | Threat intel pulses | API key (free) |
| Shodan | shodan.io | Limited | Internet scanning | API key |

**World Monitor approach:** `/api/cyber-threats.js` (33KB — largest API handler) aggregates multiple IOC sources.

**tvOS display:** "Cyber Threat Level" indicator, recent IOC count, top targeted countries.

---

## 10. RSS/NEWS FEEDS (from World Monitor)

World Monitor has **372 unique RSS feed URLs** organized into categories:

### Priority feeds for Situation Room (Tier 1-2 only):
**Wire Services:** Reuters, AP, AFP, Bloomberg
**Government:** White House, State Dept, Pentagon, UN News, CISA
**Defense/Intel:** Defense One, USNI News, War Zone, Bellingcat, Janes
**Think Tanks:** CSIS, RAND, Brookings, Carnegie, Foreign Affairs
**Crisis:** CrisisWatch (ICG), IAEA, WHO, UNHCR
**Regional:** BBC World/ME/Africa/Asia, Al Jazeera, France24, Xinhua, TASS
**Markets:** CNBC, MarketWatch, Financial Times, Bloomberg

**tvOS display:** Scrolling headline ticker at bottom of screen. Category-filtered news cards. Breaking news alert overlay.

---

## 11. ADDITIONAL tvOS-FRIENDLY SOURCES

### Prediction Markets
- **Polymarket** — polymarket.com API (public, JSON)
- Display: Top prediction cards with probability bars

### Country Risk/Instability
- World Monitor computes a **Country Instability Index (CII)** across 22 tier-1 nations
- Factors: conflict events, protest frequency, sanctions, economic stress
- Display: Country risk heatmap or ranked list

### DEFCON/Threat Level
- World Monitor's composite DEFCON indicator
- Display: Large DEFCON badge (1-5) with color coding

### Strategic Theater Posture
- `/api/theater-posture.js` computes military posture for theaters (Iran, Baltic, Taiwan, etc.)
- Factors: air activity, naval presence, stability trend
- Display: Theater cards with air/sea/land indicators

---

## 12. RECOMMENDED tvOS PANEL LAYOUT

For a 1920x1080 Apple TV display, auto-cycling between these screens:

### Screen 1: "Global Situation" (Primary)
```
┌─────────────────────────┬──────────────────┐
│                         │   DEFCON BADGE    │
│     WORLD MAP           │   THREAT LEVEL    │
│  (MapKit + hotspots)    │   Date/Time UTC   │
│                         ├──────────────────┤
│                         │   MARKET TICKER   │
│                         │   SPX DOW NDX     │
│                         │   BTC ETH GOLD    │
└─────────────────────────┴──────────────────┘
│ SCROLLING NEWS TICKER ─ TOP HEADLINES      │
└────────────────────────────────────────────┘
```

### Screen 2: "Live Intel"
```
┌──────────────┬──────────────┐
│  LIVE NEWS   │  WEBCAM 1    │
│  (Bloomberg  │  (Jerusalem) │
│   stream)    │              │
├──────────────┼──────────────┤
│  WEBCAM 2    │  WEBCAM 3    │
│  (Kyiv)      │  (Taipei)    │
│              │              │
└──────────────┴──────────────┘
```

### Screen 3: "Markets & Economy"
```
┌─────────────────────────┬──────────────────┐
│   SECTOR HEATMAP        │  TOP MOVERS      │
│   (colored grid)        │  (green/red)     │
├─────────────────────────┼──────────────────┤
│   COMMODITIES           │  CRYPTO          │
│   OIL GOLD GAS          │  BTC ETH SOL     │
├─────────────────────────┴──────────────────┤
│   ECONOMIC INDICATORS (FRED data)          │
└────────────────────────────────────────────┘
```

### Screen 4: "Threat Assessment"
```
┌─────────────────────────┬──────────────────┐
│  COUNTRY INSTABILITY    │  THEATER POSTURE │
│  INDEX (top 10)         │  Iran: CRITICAL  │
│                         │  Baltic: HIGH    │
│                         │  Taiwan: ELEVATED│
├─────────────────────────┼──────────────────┤
│  RECENT EARTHQUAKES     │  PREDICTION      │
│  (last 24h, M4.5+)     │  MARKETS         │
└─────────────────────────┴──────────────────┘
```

### Screen 5: "Infrastructure"
```
┌─────────────────────────┬──────────────────┐
│  INTERNET OUTAGES       │  CYBER THREATS   │
│  (Cloudflare Radar)     │  (IOC summary)   │
├─────────────────────────┼──────────────────┤
│  SATELLITE FIRES        │  MILITARY        │
│  (NASA FIRMS)           │  FLIGHTS (count) │
└─────────────────────────┴──────────────────┘
```

---

## 13. API KEY REQUIREMENTS

### Required for core features:
- `FINNHUB_API_KEY` — Stock quotes (free at finnhub.io)
- `NASA_FIRMS_API_KEY` — Satellite fires (free at earthdata.nasa.gov)

### Required for enhanced features:
- `GROQ_API_KEY` — AI summarization (free 14.4k req/day at groq.com)
- `ACLED_ACCESS_TOKEN` — Conflict data (free academic access at acleddata.com)
- `FRED_API_KEY` — Economic data (free at fred.stlouisfed.org)
- `EIA_API_KEY` — Energy data (free at eia.gov)
- `CLOUDFLARE_API_TOKEN` — Internet outages

### Required for live tracking:
- `AISSTREAM_API_KEY` — Vessel tracking (free tier at aisstream.io)
- `OPENSKY_CLIENT_ID` / `OPENSKY_CLIENT_SECRET` — Aircraft tracking

### Not required (public APIs):
- USGS Earthquakes, CoinGecko, Yahoo Finance, Polymarket, Open-Meteo, Mempool.space, Alternative.me

---

## 14. tvOS TECHNICAL CONSIDERATIONS

### Video Playback
- AVPlayer handles HLS/DASH natively
- YouTube streams need URL extraction (backend service with `youtubei.js`)
- Multiple simultaneous AVPlayer instances supported (tested up to 4 on Apple TV 4K)

### Networking
- All data fetching should go through a backend proxy/aggregator
- tvOS apps have standard URLSession networking
- WebSocket support available via URLSessionWebSocketTask

### Focus Engine
- Siri Remote navigation: up/down/left/right/select
- Design panels as focusable containers
- Auto-rotate mode should be the default (no interaction needed)

### Background Refresh
- tvOS supports background app refresh
- Can update data while app is in "screensaver" state
- Push notifications available for breaking alerts

### Storage
- UserDefaults for settings
- Core Data or JSON files for cached data
- No localStorage equivalent — use proper persistence
