# Visual Aesthetics Research — Situation Room Dashboard

**Date**: 2026-02-20
**Purpose**: Inspiration catalog for tvOS 4K situation room app with dark theme

---

## 1. Hacker / Cyberpunk Dashboard Aesthetics

### Matrix Rain / Digital Rain
- **What it looks like**: Columns of green (or cyan/amber) characters cascading down the screen at varying speeds. Characters are half-width katakana, Latin letters, and numerals. Some columns are bright (leading edge), fading to dim as they trail. The overall effect creates a "data waterfall."
- **Why it's striking on a big screen**: Fills dead space with ambient motion. Creates depth — fast columns feel close, slow ones feel distant. Instantly signals "this is a tech environment" to anyone walking in. On a 4K display, thousands of individual characters are legible.
- **Data that could drive it**: Real data streams — hex values from network traffic, stock tickers, IP addresses, CVE IDs, RSS headlines encoded character-by-character. Or purely decorative random characters.
- **SwiftUI/tvOS feasibility**: YES. Use SwiftUI `Canvas` for drawing characters at specific positions with opacity gradients. A `TimelineView` can drive the animation at 30fps. Metal shaders via the [Inferno library](https://github.com/twostraws/Inferno) could handle this even more efficiently. The [Vortex particle system](https://github.com/twostraws/Vortex) could approximate the effect with particle emitters.

### Scan Lines
- **What it looks like**: Thin horizontal lines (1-2px) overlaid on the entire screen or specific panels, simulating a CRT monitor. Can be static or slowly scrolling. Sometimes combined with a subtle horizontal "sweep" line that moves top-to-bottom.
- **Why it's striking**: Adds texture and depth to flat UI. Creates a retro-futuristic feel. On 4K, you have enough resolution that scan lines are visible but don't degrade readability.
- **Data**: None — purely decorative overlay.
- **SwiftUI/tvOS feasibility**: YES. A simple overlay `View` with horizontal `Rectangle` stripes at 50% opacity. Or a Metal shader for the sweep effect. WWDC24's ["Create custom visual effects with SwiftUI"](https://developer.apple.com/videos/play/wwdc2024/10151/) covers exactly this pattern.

### Glitch Effects
- **What it looks like**: Momentary horizontal displacement of screen regions (like a VHS tracking error). RGB channel separation where red, green, blue layers shift independently. Blocky artifacts that appear and disappear. Digital "tearing" on transitions.
- **Why it's striking**: Creates tension and energy. Signals "live data" or "system under stress." Brief glitch bursts during screen transitions add dramatic flair.
- **Data**: Trigger glitches on alert conditions — new threat detected, market crash, etc.
- **SwiftUI/tvOS feasibility**: YES. The [Inferno shader library](https://github.com/twostraws/Inferno) includes glitch-style effects. SwiftUI's `.colorEffect()` and `.layerEffect()` modifiers (iOS 17+ / tvOS 17+) can apply Metal shaders directly to views.

### Terminal-Style Text / Typewriter Effect
- **What it looks like**: Monospaced font (Menlo, SF Mono, or Courier). Text appears character-by-character with a blinking cursor. Green or amber text on black. Command prompts (`$`, `>`, `root@`). Scrolling log output.
- **Why it's striking**: Implies real-time data processing. Humans are drawn to watch text being "typed." Monospace creates clean column alignment for data tables.
- **Data**: Real API responses, live log entries, system status messages, alert feeds.
- **SwiftUI/tvOS feasibility**: YES. Simple `Timer`-based character reveal on `Text` views. Blinking cursor with `.opacity` animation. SwiftUI `Text` supports `Font.system(.body, design: .monospaced)`.

### Radar Sweep
- **What it looks like**: Circular display with a rotating "arm" (bright line from center to edge, like a clock hand). As the arm passes, it illuminates blips that then slowly fade. Concentric rings show distance. Cardinal directions labeled.
- **Why it's striking**: Constant motion draws the eye. The fade-and-reveal cycle creates anticipation. Universally recognized as "surveillance" or "tracking."
- **Data**: Earthquake locations (distance from reference point), ISS position, satellite positions, threat source locations on a radial projection.
- **SwiftUI/tvOS feasibility**: YES. `Canvas` with `TimelineView` for the rotating arm. Draw blips with opacity based on time-since-last-sweep. Use `AngularGradient` for the sweep fade effect.

### Pulse / Heartbeat Animations
- **What it looks like**: Expanding circles from a point (like sonar pings). ECG-style line traces across a panel. Glowing dots that rhythmically brighten and dim.
- **Why it's striking**: Suggests the system is "alive." Rhythmic motion is calming but attention-holding. Works at any scale — from a tiny status indicator to a full-panel animation.
- **Data**: API polling intervals (pulse on each fetch), alert frequency, system heartbeat status.
- **SwiftUI/tvOS feasibility**: YES. `Circle` with `.scaleEffect` and `.opacity` animations on repeat. `Path` drawing for ECG traces.

### Sci-Fi Command Interfaces (LCARS, Iron Man HUD, Minority Report)

#### LCARS (Star Trek)
- **Visual elements**: Rounded rectangular frames in pastel purples (#cc99ff), oranges (#ff9900), blues (#5566ff), golds (#ffaa00) on black. Pill-shaped buttons. Swiss 911 Ultra Compressed font (or similar condensed sans-serif). All text uppercase. Curved "elbows" connecting horizontal and vertical bars. [Full color palette](https://www.thelcars.com/colors.php) available.
- **Why it works**: The rounded shapes feel organic and futuristic simultaneously. The muted pastels against black have excellent contrast without being harsh. The frame layout naturally creates information hierarchy.
- **Translatable elements**: The "elbow" frame connectors, pill-shaped section headers, and pastel-on-black color scheme could define panel borders. The dense labeling style works for status readouts.
- **SwiftUI feasibility**: YES. `RoundedRectangle` with custom corner radii, `Capsule` shapes for buttons. Custom font via `.font(.custom())`.

#### Iron Man HUD (JARVIS/FRIDAY)
- **Visual elements**: Translucent cyan/blue circles, arcs, and ring segments. Radial layouts — information arranged in concentric rings. Thin glowing lines connecting data points. A central targeting reticle. Status indicators arranged on an invisible sphere. Diagnostic panels that expand/collapse radially. See [Jayse Hansen's portfolio](https://jayse.tv/v2/?portfolio=hud-2-2) for the actual film designs.
- **Why it works**: The radial organization naturally creates hierarchy (center = primary, outer = secondary). The translucent layers create depth. The cyan-on-dark color scheme is high contrast and easy on the eyes.
- **Translatable elements**: Radial gauge clusters, arc-based progress indicators, connecting lines between related data points, the "expand from center" animation pattern.
- **SwiftUI feasibility**: YES. `Canvas` for arc drawing, `AngularGradient` for ring segments. `GeometryEffect` for radial animations.

#### Minority Report
- **Visual elements**: Translucent floating panels. Gesture-driven manipulation. Data presented as physical "cards" that can be arranged in 3D space. Blue/white color palette.
- **Translatable elements**: Card-based data panels with depth (shadows, layering). The idea of data as manipulable objects.

---

## 2. Bloomberg Terminal Design

### The Distinctive Aesthetic
- **Background**: Pure black (#000000)
- **Primary text**: Amber/orange (#fb8b1e or #ff9900)
- **Key colors**: Orange (#fb8b1e), Blue (#0068ff), Cyan/Green (#4af6c3), Red (#ff433d)
- **Typography**: Dense monospaced text. Information packed into every pixel. No whitespace wasted.
- **Layout**: Originally 4 fixed panels, now tabbed. Each panel runs an independent function/view.

### What Makes It Visually Distinctive
1. **Extreme data density**: Every square inch shows data. No decorative elements, no padding, no breathing room. This communicates "professional-grade" and "comprehensive."
2. **Color as pure function**: Orange = default/neutral data. Green = up/positive. Red = down/negative. Blue = interactive/clickable. White = headers/labels. No color is decorative.
3. **The "status symbol" effect**: [As UX Magazine noted](https://uxmag.com/articles/the-impossible-bloomberg-makeover), the ugliness became a feature — visual complexity signals professional exclusivity.
4. **Fixed-width everything**: Monospaced fonts mean numbers always align in columns. This makes scanning rows of data extremely fast.

### Bloomberg Elements That Translate to a Wall Display
| Element | Description | Wall Display Adaptation |
|---------|-------------|------------------------|
| **Ticker tape** | Scrolling price updates across top/bottom | Horizontal scrolling bar with color-coded prices |
| **Quote screen** | Dense grid of symbols, prices, changes | Table with sparklines per row |
| **MOST function** | Top movers ranked by % change | Sorted list with bar chart overlay |
| **GIP map** | Geopolitical risk map with color coding | World map with threat heat overlay |
| **PORT analytics** | Portfolio risk/return scatter plots | Scatter plot with animated data points |
| **CRVD function** | Yield curve visualization | Animated line chart showing curve shifts |

### Color Palette (Hex Values)
```
Black background:  #000000
Amber/Orange text: #fb8b1e  (primary data)
Blue:              #0068ff  (interactive elements)
Cyan/Teal:        #4af6c3  (positive/up)
Red:               #ff433d  (negative/down)
White:             #ffffff  (headers)
Dark gray:         #333333  (panel borders, separators)
```

---

## 3. Trading Floor Wall Displays

### What Prop Trading Firms Display

#### Real-Time P&L Board
- **What it looks like**: Large numbers showing daily P&L for each desk/strategy/trader. Color transitions from green to red. Often the largest single display. Font size is huge — readable from 30 feet.
- **Why it's striking**: Big numbers with color = instant emotional impact. The P&L board is the "scoreboard" of the trading floor.
- **Data**: Portfolio values, daily change, % change. Updated every second.
- **SwiftUI feasibility**: YES. Large `Text` with `.foregroundStyle` conditional on value. `contentTransition(.numericText())` for animated number changes.

#### Risk Dashboard
- **What it looks like**: Multiple panels showing VaR (Value at Risk), Greeks (delta, gamma, vega, theta), exposure by sector/geography, and drawdown metrics. Often uses gauges and meters.
- **Why it's striking**: The multi-panel layout with different chart types creates visual variety. Red/amber/green traffic light indicators for risk levels provide instant status.
- **Data**: Position-level risk calculations, portfolio aggregates, limit utilization.
- **SwiftUI feasibility**: YES. Custom gauge views, conditional coloring.

#### Correlation Matrix / Heatmap
- **What it looks like**: NxN grid where each cell is colored by correlation strength. Row/column headers are asset names. Color scale: deep blue (-1.0 negative correlation) through white (0 neutral) to deep red (+1.0 positive correlation). The diagonal is always red (self-correlation = 1.0).
- **Why it's striking**: The color pattern creates an immediately recognizable visual "fingerprint" of market relationships. Pattern changes over time signal regime shifts.
- **Data**: Rolling correlation of asset returns (20-day, 60-day windows). Equities, bonds, commodities, currencies.
- **SwiftUI feasibility**: YES. Grid of colored `Rectangle` views. `Color` interpolation based on correlation value.

#### Volatility Surface
- **What it looks like**: 3D wireframe or colored surface plot. X-axis = strike price, Y-axis = expiration date, Z-axis (height/color) = implied volatility. The "smile" or "smirk" shape is visually distinctive.
- **Why it's striking**: The 3D shape is immediately different from flat charts. Surface deformations signal market stress.
- **Data**: Options implied volatility across strikes and tenors.
- **SwiftUI feasibility**: PARTIAL. True 3D requires SceneKit or Metal. A 2D heatmap representation (strike x tenor, color = vol) is fully achievable in SwiftUI.

#### Scrolling Ticker / News Feed
- **What it looks like**: Horizontal scrolling text at bottom or top of display. Headlines from financial news wires. Each headline color-coded by sentiment or urgency.
- **Data**: RSS/API news feeds, price alerts.
- **SwiftUI feasibility**: YES. Horizontal `ScrollView` with `Timer`-driven offset, or `marquee`-style animation.

### Key Design Principle from Trading Floors
> "Every pixel must answer a question someone on this floor is asking right now."

Trading floor displays have ZERO decorative elements. Every visualization exists because a trader needs that information within 2 seconds or less. The aesthetic appeal comes entirely from the density and organization of functional data.

---

## 4. SOC (Security Operations Center) Wall Displays

### What Goes on the Big Screens

Based on [SOC dashboard research](https://raffy.ch/blog/2015/01/15/dashboards-in-the-security-opartions-center-soc/) and [Splunk ES documentation](https://help.splunk.com/en/splunk-enterprise-security-8/user-guide/8.1/analytics/soc-operations-dashboard):

#### Threat Map / "Pew Pew Map"
- **What it looks like**: World map (usually dark/black). Attack sources shown as bright dots. Animated arcs trace from attacker to target, creating the "pew pew" effect of glowing projectiles flying across the globe. Color indicates attack type (red = critical, orange = high, yellow = medium).
- **Why it's striking**: Constant motion. The arc animations create a "space war" aesthetic. [CyberSierra notes](https://cybersierra.co/blog/security-dashboard-kpis/) these are often derided as "pew pew maps" because they look impressive but aren't actionable — yet they're universally loved for wall displays precisely because of their visual impact.
- **Data**: GeoIP-resolved source IPs of blocked connections, IDS alerts, firewall drops.
- **SwiftUI feasibility**: YES. Custom `Shape` for map outline, `Path` with animation for arcs, `Canvas` for dot rendering.

#### Alert Timeline / Event Stream
- **What it looks like**: Vertical scrolling feed of security events. Each entry has: timestamp, severity icon (colored dot), source, event type, brief description. Critical alerts pulse or flash. New entries slide in from the top.
- **Why it's striking**: The constant scrolling signals "this system is always watching." Color-coded severity creates a visual heartbeat of the security posture.
- **Data**: SIEM alerts, IDS/IPS events, firewall logs, authentication failures.
- **SwiftUI feasibility**: YES. `List` or `ScrollView` with `.transition(.move)` for new entries.

#### Security Posture Overview
- **What it looks like**: Large central number or gauge showing overall risk score (0-100). Surrounded by smaller panels: open incidents, mean time to respond, alerts by severity, top targeted assets. Traffic light indicators (green/amber/red) for each security domain.
- **Why it's striking**: The single large number acts as a focal point. The surrounding panels provide context. Color changes in the central gauge create immediate situational awareness.
- **Data**: Aggregated risk scores, incident counts, SLA metrics.
- **SwiftUI feasibility**: YES. Custom `Gauge` views, ring charts with `trim(from:to:)`.

#### Network Topology / Attack Surface
- **What it looks like**: Node-and-edge graph showing network segments. Nodes sized by criticality. Edges show traffic flow (thickness = volume). Compromised or attacked nodes pulse red. Often uses a force-directed layout.
- **Why it's striking**: The organic, web-like structure is visually complex and fascinating. Animated traffic flows create constant subtle motion.
- **Data**: Network topology data, traffic flows, alert correlation.
- **SwiftUI feasibility**: PARTIAL. Static graphs are doable with `Canvas`. Force-directed layout animation would need custom physics (possible but complex).

#### Top-N Lists with Comparison
- **What it looks like**: Ranked lists showing "Top 10 Blocked IPs," "Top 10 Targeted Ports," "Top 10 Failed Logins." Each entry has a horizontal bar showing volume. Current value overlaid with same-time-last-week for comparison.
- **Why it's striking**: Bar lengths create instant visual hierarchy. The comparison overlay shows trends without extra chart real estate.
- **Data**: Aggregated firewall/IDS/auth log data.
- **SwiftUI feasibility**: YES. Simple horizontal bar charts with overlay.

#### Key SOC Design Principle
> Dashboards should be **context providers**, not anomaly detectors. Analysts reference overhead displays while investigating incidents — the displays show "what's normal right now" so deviations are immediately apparent. Show current metrics overlaid against same-time-last-week data to absorb seasonality patterns.

---

## 5. Cool Micro-Visualizations

### Sparklines
- **What it looks like**: Tiny line charts (typically 60-100px wide, 20px tall) embedded inline with text or in table cells. No axes, no labels, no grid — just the shape of the data. Often show the last 24 hours or 7 days.
- **Why it's striking on a big screen**: Dozens of sparklines in a table create a "wall of trends" effect — you can instantly spot which rows are trending up, down, or volatile without reading any numbers.
- **Data**: Any time series — prices, alert counts, temperatures, latencies, request rates.
- **SwiftUI feasibility**: YES. [DSFSparkline](https://github.com/dagronf/DSFSparkline) is a dedicated library supporting macOS, iOS, and tvOS. Or build with `Path` in ~20 lines of SwiftUI code.

### Mini Gauges / Radial Progress
- **What it looks like**: Small circular arcs (like a speedometer) showing a value within a range. The arc is colored by zone (green/amber/red). A needle or filled arc shows the current value. Diameter: 40-80px.
- **Why it's striking**: Compact yet information-rich. The arc shape is visually distinctive from surrounding rectangular elements. Color zones communicate status instantly.
- **Data**: CPU load, risk scores, capacity utilization, confidence levels.
- **SwiftUI feasibility**: YES. `Circle().trim(from:to:)` with `.rotation` and conditional `.foregroundStyle`.

### Heat Strips
- **What it looks like**: A single horizontal row of small colored rectangles (like a 1D heatmap). Each cell represents a time period. Color intensity = value magnitude. Think of a GitHub contribution graph compressed to one row.
- **Why it's striking**: Extremely space-efficient. Shows temporal patterns (daily cycles, weekend effects) in minimal space. Multiple heat strips stacked create a mini heatmap.
- **Data**: Hourly alert counts, daily market returns, per-hour temperature readings.
- **SwiftUI feasibility**: YES. `HStack` of small colored `Rectangle` views.

### Radial Bar Charts
- **What it looks like**: Concentric circular bars, each representing a category. Bar length (arc angle) shows value. Like nested `Activity Ring` charts from Apple Watch. Bars can be color-coded by category.
- **Why it's striking**: Compact, visually interesting, immediately recognizable from Apple Watch fitness rings. Works well for comparing 3-6 categories.
- **Data**: Budget allocation, threat categories, asset allocation percentages.
- **SwiftUI feasibility**: YES. Nested `Circle().trim()` with different radii.

### Flame Graphs
- **What it looks like**: Stacked horizontal bars forming a "flame" shape. Width = proportion of total. Each level represents a hierarchy level. Colors often random or by category. [Brendan Gregg's reference](https://www.brendangregg.com/flamegraphs.html).
- **Why it's striking**: The organic, jagged shape is visually distinctive. The width proportions create immediate hierarchy. On a big screen, you can read deep hierarchies.
- **Data**: Spending breakdown by category/subcategory, network traffic by protocol/source, threat taxonomy breakdown.
- **SwiftUI feasibility**: YES. Stack of `HStack`s with proportionally-sized `Rectangle` views.

### Treemaps
- **What it looks like**: Nested rectangles where area = value. Categories are large rectangles containing subcategory rectangles. Color = secondary dimension (e.g., % change). Think of the classic finviz.com stock market map.
- **Why it's striking**: Uses space extremely efficiently. The area-as-value encoding is intuitive. Color overlay adds a second data dimension. On 4K, hundreds of cells are legible.
- **Data**: Market cap by sector/stock, budget allocation, threat volume by category.
- **SwiftUI feasibility**: YES (but complex). Requires implementing a squarified treemap layout algorithm. Rendering is simple (`Rectangle` with `overlay` text). The layout math is the hard part.

### Dot Matrix / LED-Style Displays
- **What it looks like**: Numbers rendered as dot grids (like an airport departure board). Each "LED" is a small circle, either lit (bright color) or unlit (dim). Digits update with smooth transitions.
- **Why it's striking**: Retro-industrial aesthetic. The individual dots create texture. On 4K, you can render very large dot-matrix numbers with hundreds of dots per digit.
- **Data**: Key metrics — price, index value, countdown timer, risk score.
- **SwiftUI feasibility**: YES. Grid of `Circle` views with conditional fill. Or `Canvas` for performance.

### Animated Number Counters
- **What it looks like**: Large numbers that "roll" or "slot machine" through intermediate values when updating. Each digit independently animates from old to new value.
- **Why it's striking**: Movement draws the eye to changed values. The rolling animation communicates "live updating data." Large format is readable from across a room.
- **Data**: Any key metric — market indices, alert counts, portfolio value.
- **SwiftUI feasibility**: YES. SwiftUI's `.contentTransition(.numericText())` does exactly this. Also achievable with custom `GeometryEffect`.

### Circular / Radial Timelines
- **What it looks like**: A 24-hour or 12-month timeline arranged in a circle (like a clock). Events or data points are plotted at their time position. Intensity shown by color or dot size.
- **Why it's striking**: The circular form factor is visually distinctive. Shows cyclical patterns naturally. The clock metaphor is universally understood.
- **Data**: Alert distribution by hour, market activity by month, earthquake frequency by time of day.
- **SwiftUI feasibility**: YES. `Canvas` with trigonometric positioning, or `ForEach` with `.rotationEffect`.

---

## 6. Composite Design Recommendations for the Situation Room

### Color Palette (Recommended)

Primary palette inspired by Bloomberg + cyberpunk:

```
Background:         #0a0a0f  (near-black with slight blue)
Panel background:   #12121a  (slightly lighter for depth)
Panel border:       #1a1a2e  (subtle separation)
Primary text:       #e0e0e0  (warm white)
Secondary text:     #6c6c8a  (muted for labels)
Accent/highlight:   #00ff88  (cyber green — primary accent)
Danger:             #ff3333  (red for threats/down)
Warning:            #ffaa00  (amber for caution)
Info/Neutral:       #4488ff  (blue for informational)
Positive:           #00cc66  (green for up/good)
Cyan glow:          #00ffff  (for decorative elements, scan lines)
```

### Visual Hierarchy (for 4K / 3840x2160)

```
Layer 0: Background      — Near-black with subtle gradient or noise texture
Layer 1: Panel frames    — Thin borders (#1a1a2e), slightly lighter bg (#12121a)
Layer 2: Data content    — Charts, text, numbers within panels
Layer 3: Overlays        — Scan lines, subtle vignette at edges
Layer 4: Alerts          — Pulsing borders, glowing elements for critical data
```

### Animation Budget
- **Ambient**: Scan lines (constant), matrix rain (background panels), pulse dots (status indicators) — always running, low intensity
- **Transition**: Glitch effect on screen rotation, slide/fade for panel content changes
- **Alert**: Border pulse on critical events, color flash on threshold breaches
- **Data update**: Number roll on value changes, sparkline extend on new data points

### Typography Stack
```
Headlines:    SF Pro Display Bold, 48-72pt
Data values:  SF Mono Bold, 36-48pt (for number alignment)
Labels:       SF Pro Text Medium, 18-24pt
Micro text:   SF Mono Regular, 14-16pt (for log entries, feeds)
```

### Panel Layout Patterns

**The "Command Wall" (8 screens rotating)**:
Each screen should have:
- A title bar with screen name + timestamp
- 2-4 major panels of varying size (golden ratio proportions)
- 1-2 micro-visualization strips (sparklines, heat strips) at top or bottom
- Optional ambient element (radar sweep, matrix rain) in one panel

**Information density target**: Bloomberg-level data density in the primary panels, with breathing room provided by the ambient/decorative elements in secondary panels.

---

## Sources

- [Cyberpunk UI on Dribbble](https://dribbble.com/tags/cyberpunk-ui)
- [Cybercore.css Framework](https://www.cssscript.com/cyberpunk-css-framework-cybercore/)
- [Bloomberg Terminal - Wikipedia](https://en.wikipedia.org/wiki/Bloomberg_Terminal)
- [The Impossible Bloomberg Makeover - UX Magazine](https://uxmag.com/articles/the-impossible-bloomberg-makeover)
- [Bloomberg Terminal Color Palette](https://www.color-hex.com/color-palette/111776)
- [LCARS Color Guide](https://www.thelcars.com/colors.php)
- [LCARS Design Analysis](https://craftofcoding.wordpress.com/2015/10/13/the-user-interfaces-of-star-trek-lcars/)
- [Iron Man HUD Breakdown - Sci-Fi Interfaces](https://scifiinterfaces.com/2015/07/01/iron-man-hud-a-breakdown/)
- [Jayse Hansen — Iron Man UI Designer](https://jayse.tv/v2/?portfolio=hud-2-2)
- [SOC Dashboard Design - Medium](https://medium.com/@adarshpandey180/designing-the-perfect-soc-security-dashboard-a8deea653eb0)
- [SOC Dashboard Best Practices - Raffy.ch](https://raffy.ch/blog/2015/01/15/dashboards-in-the-security-opartions-center-soc/)
- [Splunk SOC Operations Dashboard](https://help.splunk.com/en/splunk-enterprise-security-8/user-guide/8.1/analytics/soc-operations-dashboard)
- [Security Dashboard Evolution - CyberSierra](https://cybersierra.co/blog/security-dashboard-kpis/)
- [Flame Graphs - Brendan Gregg](https://www.brendangregg.com/flamegraphs.html)
- [DSFSparkline for tvOS](https://github.com/dagronf/DSFSparkline)
- [Inferno Metal Shaders for SwiftUI](https://github.com/twostraws/Inferno)
- [Vortex Particle Effects for SwiftUI](https://github.com/twostraws/Vortex)
- [WWDC24 Custom Visual Effects](https://developer.apple.com/videos/play/wwdc2024/10151/)
- [Sparklines & Microcharts Impact](https://medium.com/microsoft-power-bi/sparklines-microcharts-and-tiny-visuals-with-big-impact-2709164ee61e)
- [Correlation Heatmap - TradingView](https://www.tradingview.com/script/uy1LMmRg-Correlation-Matrix-Heatmap-By-Leviathan/)
