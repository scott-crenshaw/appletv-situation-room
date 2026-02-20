# Situation Room Feature Research — Feb 2026

## POC Status (What We Have)

**4 screens:** Threat Assessment, Markets & Economy, Global Situation, Live Intel
**Live data:** USGS earthquakes, Yahoo Finance (6 symbols), CoinGecko (3 coins), Fear & Greed, 4 RSS feeds, 3 working HLS streams
**UI:** Auto-rotation, dual ticker (markets + news), DEFCON badge (hardcoded), satellite map with 21 hotspot annotations, 8 auto-pan regions

---

## Tier 1 — High Impact, Easy-Medium Effort, Free APIs (No Keys Required)

| # | Feature | Data Source | Effort | Notes |
|---|---|---|---|---|
| 1 | **NOAA Space Weather panel** — Kp index, solar wind speed, aurora forecast | `services.swpc.noaa.gov` (free JSON, no key) | Easy | Kp gauge + solar wind sparkline. Dramatic during geomagnetic storms |
| 2 | **ISS position tracker** on globe | `api.open-notify.org/iss-now.json` (no key) | Easy | Moving dot on MapKit, poll every 10s |
| 3 | **Asteroid close approaches** | `ssd-api.jpl.nasa.gov/cad.api` (no key) | Easy | "2024 YR4 passes at 0.6 lunar distances" — list of upcoming close approaches |
| 4 | **NASA EONET natural events** — volcanoes, storms, wildfires | `eonet.gsfc.nasa.gov/api/v3/events` (no key) | Easy | Extend disaster panel beyond just earthquakes |
| 5 | **GDACS multi-hazard alerts** — cyclones, floods, tsunamis | `gdacs.org` RSS (no key) | Medium | RSS parsing, add to Threat Assessment screen |
| 6 | **US severe weather alerts** | `api.weather.gov/alerts/active` (no key) | Easy | Tornado/hurricane warnings in real-time |
| 7 | **Full stock watchlist** — expand from 6 to 28+ symbols | Yahoo Finance v8 (no key) | Easy | Add AAPL, MSFT, NVDA, GOOGL, AMZN, META, TSLA, etc. |
| 8 | **Sector ETF heatmap** — 12 sectors color-coded | Yahoo Finance v8 (no key) | Medium | XLK, XLF, XLE, XLV, etc. — signature visual |
| 9 | **More RSS feeds** — expand from 4 to 30+ | Direct RSS (no key) | Easy | Reuters, AP, Al Jazeera, Guardian, The Diplomat, Nikkei Asia, etc. |
| 10 | **Doomsday Clock display** — currently 85 seconds to midnight | Static (Bulletin of Atomic Scientists) | Easy | Permanent visceral indicator |
| 11 | **More static map layers** — nuclear sites, submarine cables, military bases, pipelines | Static GeoJSON datasets | Medium | MKAnnotation + MKPolyline overlays |

---

## Tier 2 — High Impact, Medium Effort, Free API Key Required

| # | Feature | Data Source | Key | Effort | Notes |
|---|---|---|---|---|---|
| 12 | **NASA FIRMS wildfire hotspots** | `firms.modaps.eosdis.nasa.gov` | Free MAP_KEY | Medium | Global fire detections on map — visually striking |
| 13 | **Cloudflare Radar internet outages** | `api.cloudflare.com/client/v4/radar` | Free token | Medium | "Internet down in Iran" — first signal of coups/conflicts |
| 14 | **FRED economic indicators** — yield curve, CPI, unemployment | `api.stlouisfed.org/fred` | Free key | Medium | Yield curve shape visualization is a signature feature |
| 15 | **Polymarket prediction markets** | `polymarket.com` API | No key | Medium | Geopolitical event probabilities — unique data |
| 16 | **OpenSky flight tracking** | `opensky-network.org` | Optional (higher limits) | Hard | Live aircraft positions on globe — visually stunning |
| 17 | **NIST NVD critical CVEs** | `services.nvd.nist.gov` | Optional (faster) | Easy | Cyber threat ticker — "Critical CVE disclosed" |
| 18 | **EIA US power grid** | `api.eia.gov` | Free key | Medium | Real-time energy mix chart (nuclear/gas/wind/solar) |

---

## Tier 3 — Differentiating, Complex, May Need Backend

| # | Feature | Data Source | Effort | Notes |
|---|---|---|---|---|
| 19 | **AIS vessel tracking** — live ship positions | aisstream.io WebSocket | Hard | Needs backend WebSocket relay. Chokepoint traffic monitoring |
| 20 | **ACLED conflict events** — live, georeferenced | acleddata.com | Hard | Free academic key. Weekly updates. Protest/battle/riot events on map |
| 21 | **GDELT real-time events** — global event stream | gdeltproject.org | Hard | 15-min updates. Requires CSV parsing and CAMEO code filtering |
| 22 | **AI situation briefing** — LLM-generated summary | Groq API (free 14.4k req/day) | Hard | Needs backend. "AI analysts assess..." paragraph per region |
| 23 | **Country Instability Index** — composite risk score | Multiple sources | Hard | Custom algorithm combining ACLED + USGS + news + markets |
| 24 | **Information Blackout Detector** | Cloudflare + RSS + social silence | Hard | Novel. "When internet goes dark AND news stops = something is happening" |
| 25 | **Convergence Alert** | All above sources correlated | Hard | Multiple independent signals spiking for same region simultaneously |

---

## New Screen Concepts

### Space & Geophysical Intelligence
- Solar wind gauge + Kp meter + aurora probability
- ISS ground track on globe
- Asteroid close approach list
- Satellite fire count by region
- Active volcano/cyclone count

### Cyber & Infrastructure
- Internet outage map (Cloudflare Radar)
- Critical CVE ticker
- Submarine cable map
- Power grid fuel mix
- BGP anomaly alerts

### Deep Markets
- 28-stock watchlist scrolling
- Sector ETF heatmap (12 cells)
- Yield curve shape
- Prediction market odds
- Central bank rate decisions
- BTC ETF flows

### Enhanced Threat Assessment
- GDACS multi-hazard (not just earthquakes)
- NASA FIRMS fire hotspots by conflict region
- ACLED conflict event timeline
- DEFCON estimator (from defconlevel.com)
- Doomsday Clock (85 seconds)

---

## Zero-Friction Quick Wins (No API Key, No Backend)

These can be added with just a new `async` fetch function and a UI view:

1. `services.swpc.noaa.gov/products/noaa-planetary-k-index.json` — Kp index
2. `api.open-notify.org/iss-now.json` — ISS position
3. `ssd-api.jpl.nasa.gov/cad.api?dist-max=0.05&date-min=now` — asteroids
4. `eonet.gsfc.nasa.gov/api/v3/events?status=open` — NASA natural events
5. `api.weather.gov/alerts/active?severity=Extreme` — US severe weather
6. `disease.sh/v3/covid-19/all` — global health stats
7. `api.ooni.io/api/v1/measurements?limit=50` — censorship detection
8. More Yahoo Finance symbols — just add to the array

---

## Design Principles for TV at Distance

- **Minimum font: 36pt** at 1080p for glanceable data (28pt absolute minimum)
- **Dark background always** — pure black or deep navy (#0a0f1a)
- **Color semantics are strict**: Green=nominal, Yellow=watch, Red=action, Blue=info
- **Every feed shows freshness** — "Updated 2m ago" or stale indicator
- **Hero numbers big** — single KPI should be 60-80pt
- **Motion = signal** — animate only for state changes (new alert, market move)
- **Max 4 columns** on any screen at 1080p
- **No pie charts > 4 slices**, no dense tables > 4 columns

---

## What Makes This Different From a News Aggregator

A news aggregator shows **headlines**. A situation room shows **state** — the current condition of the world along multiple dimensions simultaneously.

Key differentiators:
1. **Multi-domain correlation** — markets + military + weather + cyber on one screen
2. **Threat posture visualization** — DEFCON, Doomsday Clock, theater readiness
3. **Live video + data fusion** — not just text, actual live feeds alongside data
4. **Geographic intelligence** — everything tied to a map with overlays
5. **Convergence detection** — when multiple independent signals spike together
6. **Space/geophysical layer** — solar weather, ISS tracking, asteroid approaches
7. **Infrastructure awareness** — internet outages, cable cuts, power grid status
