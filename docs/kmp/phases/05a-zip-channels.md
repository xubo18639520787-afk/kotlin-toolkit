# Phase 05a — Zip: channel abstractions onto Okio

Read `docs/kmp/PLAN.md` first. Depends on phase 04. First of three zip phases; the goal of 05a–05c is to delete `:readium:readium-shared-zip-legacy` entirely.

## Background

The vendored zip stack (temporarily parked in `readium/shared-zip-legacy/`) is built on a vendored mirror of `java.nio.channels` in package `org.readium.r2.shared.util.zip.jvm` (10 files: `SeekableByteChannel`, `ReadableByteChannel`, `ByteChannel`, `Channel`, `WritableByteChannel` + 5 exception types). On top of it, Kotlin adapters live in shared androidMain: `ReadableChannelAdapter.kt`, `CachingReadableChannel.kt`, `BufferedReadableChannel.kt`, `FileChannelAdapter.java`.

## Task 5a.1 — Kotlin common channel interfaces

Translate the `jvm/` package to Kotlin in **commonMain**, same package (`org.readium.r2.shared.util.zip.jvm` — keep it; renaming is a later cleanup): interfaces are tiny (single-method); exceptions become Kotlin classes extending `IOException` equivalents (use `okio.IOException` for the KMP-safe base). `ByteBuffer` is the hard dependency: the channel methods take `java.nio.ByteBuffer`. Two options — **decide by inspecting call sites in `compress/`**:

- Preferred: replace `ByteBuffer` parameters with a minimal Readium-owned buffer type or plain `ByteArray + offset/length` if `compress/` uses only simple get/put/position/limit/flip operations.
- If `compress/` leans heavily on ByteBuffer semantics (slice, duplicate, byte order), port a minimal `ZipBuffer` class in commonMain implementing exactly the used subset (enumerate operations by grep: `\.flip()|\.slice()|\.order(|\.duplicate()` etc. across `compress/`).

Document the chosen buffer mapping in this file for 05b agents. <!-- to be filled during 05a -->

## Task 5a.2 — Port the Kotlin adapters

`ReadableChannelAdapter`, `CachingReadableChannel`, `BufferedReadableChannel` (androidMain) → commonMain onto the new interfaces, replacing `java.io`/`java.nio` internals with Okio/`ByteArray`. `FileChannelAdapter.java` → Kotlin in commonMain on `okio.FileHandle`.

These adapt Readium's `Readable` to channels — the seam that makes zip-over-HTTP work. Preserve the buffering/caching behavior exactly (read sizes, cache invalidation) — write characterization tests first in commonTest (a `Readable` fake + read-pattern assertions).

## Task 5a.3 — Compatibility with the legacy project

Until 05b lands, shared androidMain code (`FileZipContainer`, `StreamingZipContainer`…) still calls the **legacy Java** channels. Options, pick the one that compiles cleanly:

1. Keep legacy code using legacy channels; the new common channels live alongside unused-by-legacy until 05c swaps the containers. (Simplest — no interop needed.)
2. If names clash on the Android classpath (same FQN in commonMain and in the legacy jar), rename the legacy package in the legacy project (`…zip.legacyjvm`) with a mechanical find-replace inside `shared-zip-legacy` + the androidMain call sites.

**Phase acceptance:** commonTest channel/adapter characterization tests green on both platforms; canonical commands pass; no behavior change on Android (existing zip tests still green via legacy path).
