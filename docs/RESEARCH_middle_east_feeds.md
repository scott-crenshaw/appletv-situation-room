# Middle East / Persian Gulf Dashboard — Data Feed Research
**Date:** 2026-03-23

---

## CATEGORY 1: WAR/CONFLICT MONITORING

### 1A. GDELT Events 2.0 (Raw CSV Files) — CONFIRMED WORKING, NO AUTH
- **URL:** `http://data.gdeltproject.org/gdeltv2/lastupdate.txt` (index of latest files)
- **Data files:** Updated every 15 minutes, e.g. `http://data.gdeltproject.org/gdeltv2/20260323221500.export.CSV.zip`
- **Format:** Tab-delimited CSV (zipped), 61 columns per record
- **Auth:** None required
- **Rate limits:** None (bulk download)
- **Key fields for map plotting:**
  - Column 49: `ActionGeo_Lat` (latitude)
  - Column 50: `ActionGeo_Long` (longitude)
  - Column 53: `ActionGeo_FullName` (place name)
  - Column 27: `EventCode` (CAMEO code)
  - Column 28: `EventBaseCode`
  - Column 29: `EventRootCode` (14=Protest, 17=Coerce, 18=Assault, 19=Fight, 20=Conventional Military Force)
  - Column 31: `GoldsteinScale` (-10 to +10, negative = conflict)
  - Column 61: `SOURCEURL`
- **Middle East filtering:** Bounding box lat 10-45, lon 25-70 yielded 91 events in a single 15-min file
- **Conflict filtering:** EventRootCode >= 14 and GoldsteinScale < -5 isolates genuine conflict events
- **Visualization:** Heat map / point map with color-coded severity (Goldstein scale). Red dots for military actions (18-20), orange for coercion (17), yellow for protests (14).
- **Implementation notes:**
  1. Fetch `lastupdate.txt` to get current CSV URL
  2. Download & unzip the .export.CSV.zip
  3. Parse tab-delimited, filter by bounding box + event codes
  4. Plot lat/lon with color by severity
  5. Refresh every 15 minutes (matches GDELT update frequency)

### 1B. GDELT DOC 2.0 API (Article Search) — CONFIRMED WORKING, NO AUTH
- **URL:** `https://api.gdeltproject.org/api/v2/doc/doc?query=...&mode=ArtList&maxrecords=50&format=json`
- **Format:** JSON
- **Auth:** None
- **Rate limits:** Aggressive rate limiting (429 errors). Approximately 1 request per 5-10 seconds safe.
- **Key fields:** `url`, `title`, `seendate`, `domain`, `sourcecountry`, `language`
- **Limitations:** ArtList mode does NOT include lat/lon coordinates. Only text-based location (country name).
- **Visualization:** Scrolling news ticker / headline feed. NOT suitable for map plotting.
- **Best query:** `query=(conflict OR attack OR military) (iraq OR iran OR syria OR yemen OR gaza)&sourcelang=english`

### 1C. GDELT Translation Export — CONFIRMED WORKING, NO AUTH
- **URL:** `http://data.gdeltproject.org/gdeltv2/lastupdate-translation.txt`
- **Format:** Same as Events 2.0 but includes machine-translated non-English sources
- **Value:** Captures Arabic/Farsi/Hebrew media coverage that English-only feeds miss
- **Same column structure as 1A**

### 1D. UCDP (Uppsala Conflict Data Program) — REQUIRES AUTH TOKEN
- **URL:** `https://ucdpapi.pcr.uu.se/api/gedevents/25.1?pagesize=100`
- **Format:** JSON with lat/lon in WKT geometry
- **Auth:** Requires access token (email mertcan.yilmaz@pcr.uu.se)
- **Rate limits:** 5,000 requests/day
- **Status:** NOT usable without registration

### 1E. ACLED — REQUIRES REGISTRATION
- **URL:** `https://acleddata.com/`
- **Auth:** Requires myACLED account registration
- **Status:** NOT usable without registration

### 1F. ReliefWeb API — CURRENTLY RETURNING 403
- **URL:** `https://api.reliefweb.int/v1/reports`
- **Status:** Blocked (403 Forbidden). Previously worked. May be temporarily down or have changed access policy.

---

## CATEGORY 2: SHIPPING/MARITIME ACTIVITY

### 2A. Finnish Digitraffic AIS — CONFIRMED WORKING, NO AUTH
- **URL:** `https://meri.digitraffic.fi/api/ais/v1/locations`
- **Headers required:** `Accept: application/json` and `Accept-Encoding: gzip`
- **Format:** GeoJSON FeatureCollection
- **Auth:** None
- **Vessels returned:** ~18,186 at any time
- **Coverage:** Baltic Sea, North Sea, Nordic waters ONLY. Zero vessels in Persian Gulf.
- **Sample record:**
```json
{
  "mmsi": 219598000,
  "type": "Feature",
  "geometry": { "type": "Point", "coordinates": [20.85169, 55.770832] },
  "properties": {
    "sog": 0.1, "cog": 346.5, "navStat": 1, "rot": 4,
    "posAcc": true, "heading": 79, "timestamp": 59
  }
}
```
- **Verdict:** Good proof-of-concept for AIS visualization, but wrong region for Persian Gulf focus.

### 2B. AISStream.io (WebSocket) — FREE API KEY REQUIRED
- **URL:** `wss://stream.aisstream.io/v0/stream`
- **Auth:** Free API key via GitHub OAuth login at aisstream.io
- **Format:** JSON over WebSocket
- **Coverage:** GLOBAL (including Persian Gulf / Strait of Hormuz)
- **Features:** Subscribe by bounding box, filter by MMSI (max 50), filter by message type
- **Rate:** ~300 messages/second globally; can subscribe to specific regions
- **Subscription message example:**
```json
{
  "APIKey": "YOUR_KEY",
  "BoundingBoxes": [[[23.0, 50.0], [30.0, 60.0]]],
  "FilterMessageTypes": ["PositionReport"]
}
```
- **Verdict:** BEST option for Persian Gulf vessel tracking. Free key is trivial to obtain. WebSocket gives real-time positions.

### 2C. AISHub — MEMBERSHIP REQUIRED
- **URL:** `https://data.aishub.net/ws.php`
- **Auth:** Membership (must contribute AIS station data)
- **Rate limits:** Max 1 request/minute
- **Verdict:** Impractical without running an AIS receiver

### 2D. MarineTraffic — API KEY REQUIRED (PAID)
- **URL:** `https://services.marinetraffic.com/api/exportvessels/...`
- **Auth:** Paid API key required
- **Verdict:** Not free

### 2E. VesselFinder — API KEY REQUIRED (PAID)
- **Auth:** Paid user key required
- **Verdict:** Not free

### 2F. Marine Cadastre (NOAA) — HISTORICAL ONLY
- **URL:** `https://hub.marinecadastre.gov/pages/vesseltraffic`
- **Coverage:** US coastal waters historical data
- **Verdict:** Historical bulk downloads, not real-time API

### 2G. World Bank Port Statistics — CONFIRMED WORKING, NO AUTH
- **URL:** `https://api.worldbank.org/v2/country/IRQ;IRN;SAU;ARE;YEM;OMN;QAT;BHR;KWT/indicator/IS.SHP.GOOD.TU?format=json`
- **Format:** JSON
- **Data:** Container port traffic (TEU) by country/year. UAE: 20.3M TEU (2022)
- **Verdict:** Background context data, not real-time vessel positions

---

## CATEGORY 3: SPACE OBJECTS

### 3A. CelesTrak GP Data — CONFIRMED WORKING, NO AUTH
- **URL:** `https://celestrak.org/NORAD/elements/gp.php?GROUP={group}&FORMAT=json`
- **Format:** JSON (GP elements — modern replacement for TLE)
- **Auth:** None
- **Rate limits:** Not documented, but bulk downloads available
- **Available groups (52 total):** active (14,771), starlink (9,884), military (22), gps-ops (32), weather (70), stations (32), visual (147), last-30-days (338), geo (588), plus debris tracking groups
- **Sample record:**
```json
{
  "OBJECT_NAME": "ISS (ZARYA)",
  "OBJECT_ID": "1998-067A",
  "EPOCH": "2026-03-23T10:53:20.760000",
  "MEAN_MOTION": 15.48489537,
  "ECCENTRICITY": 0.0006177,
  "INCLINATION": 51.6345,
  "RA_OF_ASC_NODE": 4.3184,
  "ARG_OF_PERICENTER": 224.029,
  "MEAN_ANOMALY": 136.0206,
  "NORAD_CAT_ID": 25544,
  "BSTAR": 0.00028089,
  "MEAN_MOTION_DOT": 0.00014788,
  "MEAN_MOTION_DDOT": 0
}
```
- **Visualization:** SGP4 propagation from orbital elements gives real-time lat/lon/altitude for any satellite. Plot ground tracks, footprints, orbits on globe. Color by type (military=red, GPS=blue, weather=green, Starlink=gray).
- **Key groups for Middle East focus:**
  - `military` — 22 objects
  - `gps-ops` — 32 GPS satellites
  - `geo` — 588 geostationary satellites (many over Middle East)
  - `stations` — 32 space stations including ISS
  - `visual` — 147 bright/visible satellites

### 3B. ISS Position API — CONFIRMED WORKING, NO AUTH
- **URL:** `http://api.open-notify.org/iss-now.json`
- **Format:** JSON
- **Auth:** None
- **Rate limits:** None documented
- **Sample response:**
```json
{
  "iss_position": { "latitude": "29.0626", "longitude": "-0.6854" },
  "timestamp": 1774304426,
  "message": "success"
}
```
- **Visualization:** Real-time ISS dot on map with ground track trail. Simple and compelling.
- **Note:** Timed out during one test but generally reliable.

### 3C. NASA NEO (Near Earth Objects) — CONFIRMED WORKING, DEMO_KEY
- **URL:** `https://api.nasa.gov/neo/rest/v1/feed?start_date=2026-03-23&api_key=DEMO_KEY`
- **Format:** JSON
- **Auth:** DEMO_KEY works (30 req/hr, 50 req/day). Free registered key gets 1000 req/hr.
- **Data:** Today returned 14 NEOs, with size estimates, hazard flags, approach distances, velocities
- **Sample fields:** `name`, `absolute_magnitude_h`, `estimated_diameter`, `is_potentially_hazardous_asteroid`, `close_approach_data` (date, velocity, miss_distance in lunar/km/AU)
- **Visualization:** Dashboard panel showing approaching asteroids, sorted by distance. Red highlight for potentially hazardous. Size comparison graphics. Refresh daily.

### 3D. NASA EONET (Earth Observatory Natural Events) — CONFIRMED WORKING, NO AUTH
- **URL:** `https://eonet.gsfc.nasa.gov/api/v3/events?bbox=25,10,70,45&limit=50&status=open`
- **Format:** JSON with GeoJSON-style coordinates
- **Auth:** None
- **Data:** Active natural events with lat/lon: volcanoes, wildfires, severe storms
- **Middle East bbox returned:** 10 open events (volcanoes, wildfires in Horn of Africa area)
- **Visualization:** Map overlay with event icons by type. Good complement to conflict data.

### 3E. NASA DONKI (Space Weather) — CONFIRMED WORKING, DEMO_KEY
- **Solar Flares:** `https://api.nasa.gov/DONKI/FLR?startDate=2026-03-16&endDate=2026-03-23&api_key=DEMO_KEY`
  - 5 flares this week (M-class)
- **CMEs:** `https://api.nasa.gov/DONKI/CME?startDate=2026-03-16&endDate=2026-03-23&api_key=DEMO_KEY`
  - 45 CMEs this week, with speed (km/s) and half-angle data
- **Format:** JSON
- **Auth:** DEMO_KEY works
- **Visualization:** Timeline of solar events, CME speed gauges, solar flare classification display

### 3F. NOAA SWPC (Space Weather Prediction Center) — CONFIRMED WORKING, NO AUTH
- **Kp Index:** `https://services.swpc.noaa.gov/products/noaa-planetary-k-index.json` (geomagnetic activity)
- **Kp Forecast:** `https://services.swpc.noaa.gov/products/noaa-planetary-k-index-forecast.json`
- **Solar Wind:** `https://services.swpc.noaa.gov/products/solar-wind/plasma-7-day.json` (density, speed, temperature)
- **Space Weather Alerts:** `https://services.swpc.noaa.gov/products/alerts.json` (163 recent alerts)
- **NOAA Scales:** `https://services.swpc.noaa.gov/products/noaa-scales.json` (R/S/G scales for radio/solar/geomagnetic)
- **Solar Wind Speed:** `https://services.swpc.noaa.gov/products/summary/solar-wind-speed.json`
- **Format:** All JSON, no auth
- **Current data:** Kp=5.0 (moderate geomagnetic storm), solar wind 639 km/s
- **Visualization:** Gauge displays for Kp index, solar wind speed. Alert ticker. R/S/G scale indicators.

### 3G. N2YO Satellite Tracking — FREE API KEY REQUIRED
- **URL:** `https://api.n2yo.com/rest/v1/satellite/...`
- **Auth:** Free API key (register at n2yo.com)
- **Endpoints:** TLE data, satellite positions, visual passes, radio passes, "what's above" lookup
- **Rate limits:** 1,000 position/TLE requests, 100 pass requests
- **Verdict:** Good complement to CelesTrak. Provides pre-computed positions (no SGP4 needed).

### 3H. USGS Earthquakes (Bonus) — CONFIRMED WORKING, NO AUTH
- **URL:** `https://earthquake.usgs.gov/fdsnws/event/1/query?format=geojson&minlatitude=10&maxlatitude=45&minlongitude=25&maxlongitude=70&limit=50&orderby=time`
- **Format:** GeoJSON
- **Auth:** None
- **Data:** Seismic events with lat/lon/depth, magnitude, timestamp. M4.5 in Afghanistan in test.
- **Visualization:** Map overlay with magnitude-scaled circles. Color by depth. Excellent for Middle East seismic monitoring.

---

## SUMMARY: RECOMMENDED FEEDS BY PRIORITY

### Tier 1 — No Auth, High Visual Impact, Confirmed Working
| Feed | Use | Refresh Rate | Map Data |
|------|-----|-------------|----------|
| GDELT Events 2.0 CSV | Conflict events with coordinates | 15 min | Lat/lon per event |
| CelesTrak GP Data | Satellite orbits (military, GPS, ISS) | Daily | Computed via SGP4 |
| USGS Earthquakes | Seismic activity | Real-time | GeoJSON points |
| NASA EONET | Natural disasters | Hourly | GeoJSON points |
| NOAA SWPC | Space weather gauges | 3-hourly | Kp/solar wind values |
| ISS Position | ISS ground track | Real-time (poll) | Lat/lon |

### Tier 2 — Free Key Required, High Value
| Feed | Use | Key Source | Map Data |
|------|-----|-----------|----------|
| AISStream.io | Persian Gulf vessel tracking | GitHub OAuth (free) | WebSocket lat/lon |
| NASA NEO/DONKI | Asteroids & solar weather | DEMO_KEY or register | Dashboard panels |
| N2YO | Satellite positions (pre-computed) | Register (free) | Lat/lon positions |

### Tier 3 — Registration/Membership Required
| Feed | Use | Barrier |
|------|-----|---------|
| ACLED | Conflict events | Account registration |
| UCDP | Conflict events w/ coordinates | Email for token |
| AISHub | Vessel positions | Must share AIS station |
| NASA FIRMS | Active fires with coordinates | Free MAP_KEY registration |
