# Research: Situation Rooms, OSINT Dashboards & Free APIs
**Date:** 2026-03-24

---

## 1. What Real Situation Rooms Display

### White House Situation Room (2023 $50M Renovation)
- **8 screens** on main wall + 3 screens on each side wall
- World clocks for operationally relevant locations (Tehran, Kyiv, Niamey, etc.)
- Classified feeds from any intelligence agency worldwide
- Secure video teleconference (VTC) capability
- Cable news monitoring
- 24/7 watch floor staffed by military officers, senior intel analysts, State Dept aides
- "Unclassified" banner displayed in bright green when room is in unclassified mode

### NORAD / Cheyenne Mountain
- Large wall display + many small operator consoles
- Satellite orbit tracks (12+ revolutions projected forward)
- Aerospace and maritime monitoring
- Recognized Air Picture (RAP) -- all tracked aircraft
- Space debris/satellite tracking
- Missile warning and detection
- RGB Spectrum MediaWall V 4K video wall processors
- Real-time display with no dropped frames, multiple situational awareness feeds

### NATO Combined Air Operations Centre (CAOC)
- **Common Operational Picture (COP)**: integrated Recognized Maritime, Air, and Ground Pictures
- Enriched by theater plans, assets, intelligence, logistics
- Monitors up to **30,000 air movements per day** in European NATO airspace
- Air Command and Control System (ACCS) integrating sensor fusion
- Surface-to-air missile control, air traffic management
- Area air surveillance and recognized air picture production

### National Military Command Center (NMCC)
- Pentagon-based, supports the Joint Chiefs and SecDef
- Global military situation displays
- Nuclear command and control
- Crisis action team coordination

### Key Takeaway: Common Elements Across All
1. World clocks (multiple time zones relevant to current operations)
2. Global map with force positions / asset tracking
3. Live news feeds
4. Threat indicators / alert status levels
5. Secure communications status
6. Weather overlays
7. Multiple redundant data sources for each domain

---

## 2. Popular OSINT Dashboards & What They Show

### ShadowBroker (github.com/BigBodyCobain/Shadowbroker)
The most comprehensive open-source OSINT dashboard found. Displays:
- **Aviation**: OpenSky Network (~5,000+ aircraft), adsb.lol military endpoint
- **Maritime**: aisstream.io WebSocket (25,000+ ships) -- requires free API key
- **Satellites**: CelesTrak TLE + SGP4 propagation (2,000+ active satellites)
- **Carrier Strike Groups**: OSINT-estimated positions via GDELT news scraping (updates 00:00 & 12:00 UTC)
- **Conflict**: GDELT events (last 8h, ~1,000 events), DeepState Map Ukraine frontlines
- **Fire Hotspots**: NASA FIRMS NOAA-20 VIIRS (5,000+ thermal anomalies)
- **Space Weather**: NOAA SWPC Kp index & solar events
- **Internet Outages**: IODA (Georgia Tech) regional alerts
- **Earthquakes**: USGS global seismic events
- **GPS Jamming**: Real-time analysis of aircraft NAC-P values from ADS-B
- **Satellite Imagery**: NASA GIBS MODIS Terra daily true-color + Esri World Imagery + Microsoft Planetary Computer Sentinel-2
- **CCTV Feeds**: TfL London JamCams, TxDOT Austin, NYC DOT, Singapore LTA, Spanish DGT, Madrid, Malaga, Vigo
- **SDR Receivers**: KiwiSDR 500+ public receiver locations
- **Data Centers**: 2,000+ global data center locations
- **RSS Intelligence Feeds**: User-configurable, priority-weighted 1-5
- **Country Intel**: Wikidata SPARQL for heads of state, Wikipedia API, RestCountries

### World Monitor (worldmonitor.app)
- 45 data layers on dual map (globe.gl + deck.gl)
- 435+ curated RSS news feeds across 15 categories
- Country Instability Index (CII) -- real-time 0-100 score per nation
- Active conflict zones with escalation tracking
- 220+ military bases with live flight tracking
- Naval vessel monitoring
- Nuclear facilities
- Undersea cables
- Oil/gas pipelines
- AI datacenter clusters
- 92 stock exchanges, commodities, crypto
- 100+ RSS feeds with source tiering
- Multi-signal anomaly detection with AI classification
- No API keys required, runs in browser

### LiveUAMap
- Conflict mapping across multiple zones (Ukraine, Middle East, etc.)
- Event markers with source attribution
- Timeline scrubbing
- Color-coded by faction/event type

### Other Notable OSINT Platforms
- **Bellingcat OSINT Toolkit**: curated map of investigation tools
- **os-surveillance.io**: Commercial OSINT platform
- **Global Threat Map** (github.com/unicodeveloper/globalthreatmap): Open-source, dark-themed cyber threat visualization

---

## 3. Visually Impressive Displays for Dark Room / 4K TV

### What Looks Best
1. **Dark theme with accent colors** -- amber/orange for military, cyan/blue for maritime, green for radar, red for threats
2. **Animated map overlays** -- glowing flight paths, pulsing threat indicators, sweeping radar arcs
3. **Real-time counters/tickers** -- aircraft tracked, ships monitored, active threats
4. **World clock strip** -- multiple time zones across top or bottom
5. **Retro-CRT aesthetic elements** -- scanlines, phosphor glow, amber overlays (think WarGames/NORAD)
6. **Live cyber threat maps** -- animated attack arcs between source and target (Kaspersky, Check Point, Radware)
7. **Satellite imagery tiles** -- daily MODIS true-color as map base layer
8. **GPS jamming heatmap** -- hexagonal grid overlay showing interference zones
9. **Fire hotspot overlay** -- glowing thermal anomaly dots worldwide
10. **Submarine cable network** -- glowing lines across ocean floors

### Specific Visual Elements That Pop on Dark Screens
- **DDoS attack arcs** (like Kaspersky/Norse maps): animated lines showing source -> target
- **Carrier group icons** moving on dark ocean background
- **Radiation monitoring stations** with green/yellow/red status dots
- **Internet outage map** with country-level red zones pulsing
- **Satellite orbit paths** traced across dark globe (like NORAD tracking displays)
- **Seismic wave propagation** rings expanding from earthquake epicenters

### Display Layout Patterns from Real Command Centers
- Large central map with surrounding data panels
- Status bar across bottom with alert/threat levels
- Time-synced clocks across top
- Right sidebar for feed/event stream
- Left sidebar for asset status summary

---

## 4. Free Public APIs -- Specific Endpoints

### SHIP / VESSEL TRACKING (AIS)

**aisstream.io** (BEST OPTION -- free, real-time WebSocket)
- WebSocket: `wss://stream.aisstream.io/v0/stream`
- Free API key required (register at aisstream.io)
- 25,000+ ships worldwide
- Filter by bounding box, MMSI, message type
- Subscription JSON: `{"APIKey": "YOUR_KEY", "BoundingBoxes": [[lat1,lon1],[lat2,lon2]], "FilterMessageTypes": ["PositionReport"]}`

**AISHub** (free data exchange)
- URL: https://www.aishub.net/
- Requires contributing your own AIS data to access the feed
- JSON/XML/CSV formats

### MILITARY AIRCRAFT

**adsb.lol** (already using this -- has military endpoint)
- API docs: https://api.adsb.lol/docs
- Compatible with ADSBExchange Rapid API format
- Unfiltered -- includes military, blocked, VIP aircraft
- No authentication required

**ADS-B.nl** -- focused on military aircraft display (uses ADSBExchange API)

### NUCLEAR / RADIATION MONITORING

**Safecast API** (BEST -- no auth, global, CC0 license)
- Endpoint: `https://api.safecast.org/measurements.json`
- Query params: `?since=YYYY-MM-DD&until=YYYY-MM-DD`
- 150+ million readings, largest open radiation dataset
- No registration required

**EPA RadNet** (US only, 140 stations)
- Near-real-time gamma radiation across all 50 US states
- Envirofacts API for data access
- URL: https://www.epa.gov/radnet

**EURDEP** (Europe, ~5,000 stations)
- European Radiological Data Exchange Platform
- 38 countries, near real-time
- Portal: https://remon.jrc.ec.europa.eu
- Public data access via JRC Data Catalogue

### SUBMARINE CABLE STATUS

**TeleGeography Submarine Cable Map** (free GeoJSON)
- Cable routes: `https://www.submarinecablemap.com/api/v3/cable/cable-geo.json`
- Landing points: `https://www.submarinecablemap.com/api/v3/landing-point/landing-point-geo.json`
- All cables: `https://www.submarinecablemap.com/api/v3/cable/all.json`
- GeoJSON format, regularly updated

### INTERNET INFRASTRUCTURE / OUTAGES

**IODA** (Georgia Tech / CAIDA -- free, no auth)
- Base URL: `https://api.ioda.inetintel.cc.gatech.edu/v2/`
- Alerts: `/v2/outages/alerts`
- Events: `/v2/outages/events`
- Summary: `/v2/outages/summary`
- Time series: `/v2/signals/raw/{entityType}/{entityCode}`
- Detects via BGP, Internet Background Radiation, active probing
- Params: `from` and `until` in Unix epoch seconds

**Cloudflare Radar** (free, requires bearer token)
- Base URL: `https://api.cloudflare.com/client/v4/radar/`
- Traffic anomalies, outages, BGP events
- Create free API token at Cloudflare dashboard
- Auth: `Authorization: Bearer <API_TOKEN>`
- CC BY-NC 4.0 license

### GPS JAMMING / SPOOFING

**GPSJam.org** (free map, no API)
- Daily GPS interference map based on ADS-B aircraft NAC-P values
- Data from ADS-B Exchange
- Hexagonal grid: green (>98% good), yellow (2-10% low), red (>10% low)
- No known public API -- would need to scrape or derive from ADS-B data yourself

**FlightRadar24 GPS Jamming Map** -- updated every 6 hours (no API)

**DIY approach**: Analyze NAC-P (Navigation Accuracy Category - Position) values from adsb.lol aircraft data to build your own jamming heatmap

### SATELLITE IMAGERY

**NASA GIBS** (free, no auth required for tiles)
- WMTS tile URL: `https://gibs.earthdata.nasa.gov/wmts/epsg4326/best/MODIS_Terra_CorrectedReflectance_TrueColor/default/{YYYY-MM-DD}/250m/{z}/{y}/{x}.jpg`
- Web Mercator: replace `epsg4326` with `epsg3857`
- 900+ imagery products
- Most imagery updated within 3.5 hours of observation
- 250m/pixel resolution for MODIS true color
- No API key needed for tile access

**Copernicus / Sentinel Hub**
- Sentinel-2: 10m resolution, free
- Requires registration at dataspace.copernicus.eu
- API for on-demand imagery

### FIRE / THERMAL HOTSPOTS

**NASA FIRMS** (free, requires MAP_KEY registration)
- Endpoint: `https://firms.modaps.eosdis.nasa.gov/api/area/`
- Params: MAP_KEY, SOURCE, AREA_COORDINATES, DAY_RANGE
- VIIRS 375m resolution, MODIS 1km resolution
- US/Canada: real-time (<60 seconds of satellite flyover)
- Global: within 3 hours of observation
- Register for MAP_KEY at: https://firms.modaps.eosdis.nasa.gov/api/map_key/

### CYBER THREAT VISUALIZATION

**Check Point ThreatCloud**: https://threatmap.checkpoint.com/
**Radware Live Threat Map**: https://livethreatmap.radware.com/
**NETSCOUT Cyber Threat Horizon**: https://horizon.netscout.com/
**Digital Attack Map**: https://www.digitalattackmap.com/
(All web-based, no public APIs -- would need to scrape or use as inspiration)

### CARRIER STRIKE GROUP TRACKING

**USNI News Fleet Tracker** (best public source)
- URL: https://news.usni.org/category/fleet-tracker
- Updated weekly/biweekly with approximate carrier positions
- No API -- would need scraping or manual updates

**ShadowBroker approach**: Uses GDELT news analysis to estimate carrier positions from public reporting

### SDR RECEIVERS

**KiwiSDR Network**
- Map: http://kiwisdr.com/public/
- 500+ public receivers worldwide
- Receiver data available as JSON from map endpoint
- Can listen to shortwave, HF radio worldwide

### SPACE WEATHER (already have, but additional)

**NOAA SWPC**
- Kp Index: `https://services.swpc.noaa.gov/products/noaa-planetary-k-index.json`
- Solar wind: `https://services.swpc.noaa.gov/products/solar-wind/`
- DONKI: `https://api.nasa.gov/DONKI/`

---

## 5. New Screen Ideas (Not Currently in Dashboard)

Based on this research, screens that would add significant visual impact:

### A. Maritime / Ship Traffic Screen
- aisstream.io WebSocket for real-time vessel positions
- Carrier strike group positions from USNI Fleet Tracker
- Submarine cable overlay from TeleGeography
- Chokepoint focus areas (Strait of Hormuz, Suez, Malacca, Panama)
- AIS data includes vessel type -- can color-code tankers, cargo, military, fishing

### B. Nuclear / Radiation Monitoring Screen
- Safecast global sensor readings
- EURDEP European station status
- EPA RadNet US stations
- Nuclear facility locations as static layer
- Color-coded: normal (green) / elevated (yellow) / alert (red)

### C. Internet / Infrastructure Health Screen
- IODA real-time outage detection (country-level)
- Cloudflare Radar traffic anomalies
- Submarine cable map overlay
- BGP routing anomalies
- Data center locations
- Global internet traffic flow visualization

### D. GPS Jamming / Electronic Warfare Screen
- Derived from adsb.lol NAC-P values
- Hexagonal heatmap overlay
- Known conflict zone correlation
- Could combine with military aircraft tracks

### E. Fire / Natural Disaster Combined Screen
- NASA FIRMS thermal hotspots globally
- USGS earthquakes (already have)
- Severe weather (already have)
- Volcanic activity (Smithsonian GVP)
- Composite "natural threat level" view

### F. Cyber Threat Map Screen
- Animated DDoS attack arcs (inspired by Kaspersky/Check Point maps)
- CVE feed (already have)
- Infrastructure outages from IODA
- Would need to source attack data -- possibly from honeypot feeds or public DDoS feeds

### G. Satellite Imagery Screen
- NASA GIBS MODIS true-color daily
- Time-lapse slider showing last 7-30 days
- Highlight areas of interest (conflict zones, fire regions, flooding)
- Could overlay with FIRMS fire data

---

## Sources

- [PBS: Inside White House Situation Room Upgrade](https://www.pbs.org/newshour/nation/inside-the-white-house-situation-rooms-50-million-upgrade)
- [ABC: Rare Inside Look at Situation Room](https://abcnews.com/Politics/rare-inside-situation-room-recently-renovated-reporters-notebook/story?id=103012057)
- [CNN: $50M Situation Room Revamp](https://www.cnn.com/2023/09/08/politics/situation-room-makeover-white-house/index.html)
- [Wikipedia: Air Operations Center](https://en.wikipedia.org/wiki/Air_Operations_Center)
- [Wikipedia: Combined Air Operations Centre](https://en.wikipedia.org/wiki/Combined_Air_Operations_Centre)
- [Wikipedia: Cheyenne Mountain Complex](https://en.wikipedia.org/wiki/Cheyenne_Mountain_Complex)
- [Kottke: Inside NORAD (1966)](https://kottke.org/25/10/inside-norads-cheyenne-mountain-combat-center-c-1966)
- [RGB Spectrum: NORAD Command Center](https://www.rgb.com/case-studies/command-center-0)
- [ShadowBroker GitHub](https://github.com/BigBodyCobain/Shadowbroker)
- [ShadowBroker HN Discussion](https://news.ycombinator.com/item?id=47300102)
- [World Monitor](https://www.worldmonitor.app/)
- [World Monitor GitHub](https://github.com/koala73/worldmonitor)
- [aisstream.io](https://aisstream.io/)
- [aisstream.io Documentation](https://aisstream.io/documentation)
- [AISHub](https://www.aishub.net/)
- [Safecast](https://safecast.org/)
- [Safecast API](https://api.safecast.org/)
- [EURDEP](https://remon.jrc.ec.europa.eu/About/Rad-Data-Exchange)
- [EPA RadNet](https://www.epa.gov/radnet)
- [TeleGeography Submarine Cable Map](https://www.submarinecablemap.com/)
- [IODA Internet Outage Detection](https://ioda.inetintel.cc.gatech.edu/)
- [IODA API](https://api.ioda.inetintel.cc.gatech.edu/v2/)
- [Cloudflare Radar](https://radar.cloudflare.com/)
- [Cloudflare Radar API Docs](https://developers.cloudflare.com/radar/)
- [GPSJam](https://gpsjam.org/)
- [NASA GIBS API Docs](https://nasa-gibs.github.io/gibs-api-docs/)
- [NASA FIRMS](https://firms.modaps.eosdis.nasa.gov/)
- [NASA FIRMS API](https://firms.modaps.eosdis.nasa.gov/api/area/)
- [Copernicus Data Space](https://dataspace.copernicus.eu/)
- [USNI Fleet Tracker](https://news.usni.org/category/fleet-tracker)
- [adsb.lol API](https://api.adsb.lol/docs)
- [KiwiSDR Public Receivers](http://kiwisdr.com/public/)
- [Check Point ThreatCloud Map](https://threatmap.checkpoint.com/)
- [Radware Live Threat Map](https://livethreatmap.radware.com/)
- [NETSCOUT Cyber Threat Horizon](https://horizon.netscout.com/)
- [Digital Attack Map](https://www.digitalattackmap.com/)
- [Help Net Security: Global Threat Map](https://www.helpnetsecurity.com/2026/02/04/global-threat-map-open-source-osint/)
