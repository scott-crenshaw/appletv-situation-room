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

## Timing Screen Rotation for Screenshots
**What went wrong:** Calculated wait times for auto-rotation screenshots were sometimes off, capturing the wrong screen.
**Why:** Timer drift, data loading delays, and not accounting for the initial loading screen.
**Rule:** For reliable screen capture, take rapid sequential screenshots (every 32s for 8 cycles) to capture all screens, rather than trying to predict exact timing for one screen.
