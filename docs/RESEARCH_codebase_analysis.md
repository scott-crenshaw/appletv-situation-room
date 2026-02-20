# World Monitor Codebase Analysis

## Date: 2026-02-19
## Source: https://github.com/koala73/worldmonitor (AGPL-3.0)

---

## Architecture Overview

World Monitor is a Vue 3 + TypeScript + Vite web app deployed on Vercel Edge Functions, with a Tauri desktop wrapper. It has 3 build variants (full/tech/finance) sharing one codebase.

### Key Numbers
- **181KB** App.ts (main orchestrator)
- **60+** API edge function handlers
- **51** UI components
- **80+** service modules
- **372** RSS feed URLs
- **35+** map layers
- **14** languages
- **22** tracked nations for instability scoring

---

## API Layer (Vercel Edge Functions)

All endpoints in `/api/` run as Vercel Edge Functions (runtime: 'edge').

### Data Source APIs
| Endpoint | External Source | Auth Required |
|----------|---------------|---------------|
| `/api/earthquakes` | USGS GeoJSON (M4.5+ daily) | No |
| `/api/firms-fires` | NASA FIRMS VIIRS | NASA_FIRMS_API_KEY |
| `/api/acled` | ACLED protests/conflicts | ACLED_ACCESS_TOKEN |
| `/api/acled-conflict` | ACLED armed conflict | ACLED_ACCESS_TOKEN |
| `/api/ucdp` | Uppsala Conflict Data | No |
| `/api/ucdp-events` | UCDP event stream | No |
| `/api/gdelt-geo` | GDELT geopolitical events | No |
| `/api/gdelt-doc` | GDELT document API | No |
| `/api/ais-snapshot` | AISStream vessel data | AISSTREAM_API_KEY |
| `/api/opensky` | OpenSky aircraft states | OPENSKY credentials |
| `/api/finnhub` | Finnhub stock quotes | FINNHUB_API_KEY |
| `/api/yahoo-finance` | Yahoo Finance | No |
| `/api/coingecko` | CoinGecko crypto | No |
| `/api/fred-data` | Federal Reserve Economic | FRED_API_KEY |
| `/api/eia/[path]` | US Energy Information | EIA_API_KEY |
| `/api/polymarket` | Prediction markets | No |
| `/api/macro-signals` | Yahoo Finance composite | No |
| `/api/etf-flows` | BTC ETF tracker | No |
| `/api/stablecoin-markets` | Stablecoin data | No |
| `/api/stock-index` | Market indices | No |
| `/api/cloudflare-outages` | Cloudflare Radar | CLOUDFLARE_API_TOKEN |
| `/api/cyber-threats` | Multiple IOC sources | No |
| `/api/climate-anomalies` | ERA5 via Open-Meteo | No |
| `/api/worldbank` | World Bank indicators | No |
| `/api/worldpop-exposure` | WorldPop population | No |
| `/api/unhcr-population` | UNHCR displacement | No |
| `/api/hackernews` | HN API | No |
| `/api/github-trending` | GitHub trending | No |
| `/api/arxiv` | ArXiv papers | No |
| `/api/hapi` | Humanitarian access | No |
| `/api/nga-warnings` | NGA maritime warnings | No |
| `/api/faa-status` | FAA flight status | No |
| `/api/fwdstart` | Forward Start data | No |

### Intelligence/Analysis APIs
| Endpoint | Function |
|----------|----------|
| `/api/classify-event` | ML threat classification |
| `/api/classify-batch` | Batch event classification |
| `/api/country-intel` | Country risk scoring |
| `/api/risk-scores` | Multi-factor risk calculation |
| `/api/theater-posture` | Military theater assessment |
| `/api/temporal-baseline` | Trend baseline computation |
| `/api/service-status` | Service health dashboard |
| `/api/og-story` | OpenGraph metadata extraction |
| `/api/story` | Story data aggregation |

### AI Summarization Chain
| Endpoint | Provider | Free Tier |
|----------|----------|-----------|
| `/api/ollama-summarize` | Local Ollama | Unlimited (local) |
| `/api/groq-summarize` | Groq API | 14,400 req/day |
| `/api/openrouter-summarize` | OpenRouter | 50 req/day |
| Browser T5 | Transformers.js/ONNX | Unlimited (client) |

### Utility APIs
| Endpoint | Function |
|----------|----------|
| `/api/rss-proxy` | RSS feed CORS proxy |
| `/api/youtube/live` | YouTube live stream detection |
| `/api/youtube/embed` | YouTube iframe embedding |
| `/api/download` | Desktop app download resolver |
| `/api/version` | Version check |
| `/api/cache-telemetry` | Cache performance |
| `/api/debug-env` | Environment validation |

---

## Frontend Components (51 total)

### Map Components
- `DeckGLMap.ts` — 3858 lines, WebGL map with 35+ layers
- `Map.ts` — D3/SVG fallback for mobile
- `MapContainer.ts` — Map state management
- `MapPopup.ts` — Feature popups

### News & Media
- `LiveNewsPanel.ts` — YouTube live news streams (8 channels)
- `LiveWebcamsPanel.ts` — 19 global webcams (YouTube)
- `NewsPanel.ts` — RSS feed aggregation
- `GdeltIntelPanel.ts` — GDELT real-time intelligence

### Intelligence Panels
- `InsightsPanel.ts` — AI-generated briefings
- `StrategicPosturePanel.ts` — Theater military posture
- `StrategicRiskPanel.ts` — Regional risk heatmap
- `CIIPanel.ts` — Country Instability Index
- `CascadePanel.ts` — Infrastructure cascade analysis
- `PizzIntIndicator.ts` — PIZZINT signals

### Market Panels
- `MarketPanel.ts` — Stock/index performance
- `MacroSignalsPanel.ts` — 7-signal market radar
- `ETFFlowsPanel.ts` — BTC ETF flows
- `StablecoinPanel.ts` — Stablecoin reserves
- `EconomicPanel.ts` — FRED economic indicators
- `InvestmentsPanel.ts` — Gulf FDI (Finance variant)

### Environmental
- `SatelliteFiresPanel.ts` — NASA FIRMS
- `ClimateAnomalyPanel.ts` — Climate anomalies
- `PopulationExposurePanel.ts` — WorldPop
- `DisplacementPanel.ts` — UNHCR
- `UcdpEventsPanel.ts` — UCDP conflicts

### Utility
- `Panel.ts` — Base panel class
- `VirtualList.ts` — Efficient list rendering
- `SearchModal.ts` — Global search
- `MonitorPanel.ts` — Custom watchlists
- `SignalModal.ts` — Signal detail modal
- `StoryModal.ts` — Story export
- `ServiceStatusPanel.ts` — Service health

---

## Configuration Files

### `/src/config/feeds.ts` — RSS Feeds
- 372 unique URLs across categories
- Organized: politics, middleeast, tech, ai, finance, gov, thinktanks, crisis, regional, africa, latam, asia, energy, layoffs
- Source tier system (1-4) for prioritization
- Propaganda risk assessment per source
- Multi-language support (feeds in 8 languages)

### `/src/config/panels.ts` — Panel Configuration
- **Full variant:** 47 panels (geopolitical focus)
- **Tech variant:** 28 panels (startup/AI focus)
- **Finance variant:** 26 panels (market focus)
- Each panel has priority (1=primary, 2=secondary)
- 35+ map layer toggles per variant

### `/src/config/markets.ts` — Financial Instruments
- 12 sector ETFs, 6 commodities, 28 individual stocks, 3 crypto

### `/src/config/geo.ts` — Geopolitical Data
- Hotspot locations, military bases, conflict zones
- 8 regional presets for map navigation

### `/src/config/military.ts` — Military Reference
- ICAO hex ranges for military aircraft identification

---

## What to Reuse for tvOS

### Directly Portable (backend logic)
1. All API endpoint logic — can be wrapped in a Swift backend or kept as-is on Vercel
2. RSS feed URLs and tier/type classifications
3. Market symbol lists and configurations
4. Webcam feed definitions (channel handles + fallback IDs)
5. Live news channel definitions
6. Country instability scoring algorithm
7. Theater posture computation
8. Geopolitical hotspot/base/facility coordinates

### Needs Reimplementation (tvOS-native)
1. Map rendering — MapKit instead of deck.gl/MapLibre
2. UI components — SwiftUI instead of Vue/TypeScript
3. Video playback — AVPlayer instead of YouTube iframe embeds
4. ML/AI — Server-side only (no browser Transformers.js on tvOS)
5. WebSocket connections — URLSessionWebSocketTask
6. Storage — UserDefaults/CoreData instead of localStorage
7. Focus navigation — Siri Remote focus engine

### Not Needed for tvOS
1. Tauri desktop wrapper
2. PWA/Service Worker support
3. i18n (start English-only)
4. Mobile-specific fallbacks
5. Search modal (not useful on TV)
6. Custom monitor/watchlist creation (too complex for remote)
