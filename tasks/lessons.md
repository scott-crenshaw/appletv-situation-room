# Lessons Learned

## API Testing Before Integration
**What went wrong:** Added NWS and MITRE CVE API calls to Swift code without testing the endpoints first. Both returned 400 errors.
**Why:** Assumed documented API params would work. NWS doesn't support `limit`, MITRE's query format has changed.
**Rule:** Always `curl` test API endpoints before writing Swift integration code. Verify response format and status codes.

## tvOS Simulator Screenshot Size
**What went wrong:** Context window rejected Apple TV simulator screenshots (3840x2160 > 2000px limit).
**Why:** tvOS simulator renders at full 4K resolution.
**Rule:** Always resize with `sips --resampleWidth 1920` before reading screenshots into context. Pipeline: `xcrun simctl io booted screenshot /tmp/full.png && sips --resampleWidth 1920 /tmp/full.png --out /tmp/small.png`

## Adding Files to Xcode Project
**What went wrong:** Created new .swift files but they weren't compiled because they weren't in the Xcode project's pbxproj.
**Why:** Xcode requires explicit file references in the project file, unlike SPM packages.
**Rule:** After creating any new .swift file, immediately add it to the project with:
```python
from pbxproj import XcodeProject
project = XcodeProject.load('SituationRoom.xcodeproj/project.pbxproj')
project.add_file('path/to/file.swift', force=False)
project.save()
```

## SwiftUI .repeatForever Animations Are Fragile With Dynamic Content
**What went wrong:** News ticker used `withAnimation(.repeatForever)` to scroll. Every 120s RSS refresh created new `NewsItem` objects with fresh `UUID()` ids, causing SwiftUI to destroy/recreate `ForEach` children and kill the animation. `.onChange(of: headlines.count)` didn't catch it because count stayed the same.
**Why:** `repeatForever` stores animation state in the view tree. When view identity changes (new UUIDs), the animation state is lost. Market ticker survived because `MarketQuote.id` = stable symbol strings.
**Rule:** For continuous scrolling animations on content that refreshes, use `TimelineView(.animation)` with offset computed from elapsed time. This is immune to view rebuilds because there's no animation state — just a pure function of the clock.

## Timing Screen Rotation for Screenshots
**What went wrong:** Calculated wait times for auto-rotation screenshots were sometimes off, capturing the wrong screen.
**Why:** Timer drift, data loading delays, and not accounting for the initial loading screen.
**Rule:** For reliable screen capture, take rapid sequential screenshots (every 32s for 8 cycles) to capture all screens, rather than trying to predict exact timing for one screen.

## MapKit Annotation Count vs Apple TV GPU
**What went wrong:** 2000 SwiftUI MapKit annotation views caused jerky ticker scrolling on Apple TV.
**Why:** Each `Annotation` in a `Map` is a full SwiftUI view. 2000 of them overwhelms the Apple TV's GPU, starving other animations (tickers) of frame budget.
**Rule:** Cap MapKit annotations to ~500 max on Apple TV. At global zoom levels, visual density difference between 500 and 2000 is negligible with 4pt dots.
