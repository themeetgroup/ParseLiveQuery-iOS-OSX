# Building & releasing `TMGParseLiveQuery.xcframework`

This repo is a TMG fork of ParseLiveQuery. Its job is to produce
`TMGParseLiveQuery.xcframework`, which is vendored into **TMGSDK**
(`TMGSDK/TMGLiveVideoData/XCFrameworks/`).

Dependencies are vendored binary `xcframework`s linked directly by the Xcode project.

## Dependencies (`Frameworks/`)

| Framework | Code source of truth | Notes |
|---|---|---|
| `TMGParseCore.xcframework` | TMG **Parse-SDK fork** | The one that actually changes |
| `BoltsSwift.xcframework` | Bolts upstream | Effectively frozen |
| `Bolts.xcframework` | Bolts upstream | Effectively frozen |

These binaries are **copied from / kept in sync with** `TMGSDK/TMGLiveVideoData/XCFrameworks/`.
Do not hand-edit them.

## This repo is the binary *assembly point*

`TMGParseLiveQuery.xcframework` is **compiled against** the exact `TMGParseCore` in
`Frameworks/`. That coupling is why the binaries are assembled here: building them
together guarantees the set is ABI-consistent. Shipping a `TMGParseLiveQuery` that was
built against a *different* `TMGParseCore` than the SDK vendors risks symbol/ABI errors.

## Build

```sh
./Generate-XCFramework.sh
```

Requires Xcode (no `pod install`). The script:

1. **Runs the unit tests first** (`TMGParseLiveQueryTests`) on an auto-selected iOS
   simulator — **fail-fast**: if tests fail, no xcframework is produced.
2. Archives device + simulator from `Sources/ParseLiveQuery.xcodeproj`
   (scheme `ParseLiveQuery-iOS`, `BUILD_LIBRARY_FOR_DISTRIBUTION=YES`).
3. Emits `TMGParseLiveQuery.zip`.

Overrides:
- `SKIP_TESTS=1 ./Generate-XCFramework.sh` — skip the test gate (faster local rebuilds).
- `TEST_DESTINATION="platform=iOS Simulator,name=iPhone 16" ./Generate-XCFramework.sh`
  — pin a specific simulator instead of auto-select.

## Update flow (the process)

When `TMGParseCore` (or another dependency) needs updating:

1. **Rebuild the dependency** from its own fork (e.g. `TMGParseCore.xcframework` from
   the Parse-SDK fork).
2. **Stage it here**: replace `Frameworks/TMGParseCore.xcframework` with the new build.
3. **Rebuild this fork** against it: `./Generate-XCFramework.sh`.
4. **Move the whole set together** into `TMGSDK/TMGLiveVideoData/XCFrameworks/` —
   `TMGParseCore`, `Bolts`, `BoltsSwift`, **and** the freshly built `TMGParseLiveQuery`.
   Never ship a partial update.

Step 4 is the point: the SDK always receives a co-built, ABI-consistent group.
