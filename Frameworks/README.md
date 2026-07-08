# Frameworks/

Prebuilt binary dependencies for building `TMGParseLiveQuery.xcframework`.
Linked into the `ParseLiveQuery-iOS` target as **Link → Do Not Embed** (TMGSDK
provides them at runtime).

- `TMGParseCore.xcframework` — from the TMG Parse-SDK fork
- `BoltsSwift.xcframework`, `Bolts.xcframework` — frozen upstream

Kept in sync with `TMGSDK/TMGLiveVideoData/XCFrameworks/`. **Do not hand-edit.**
To update a dependency and ship it, follow the process in [`../BUILD.md`](../BUILD.md) —
rebuild here, then move the whole set to the SDK together.
