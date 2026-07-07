# Phase 04 — I/O Core onto Okio

Read `docs/kmp/PLAN.md` first. Depends on phase 01 (can run in parallel with 02/03 if coordinated — safest sequentially after 03). Breaking phase: append to `docs/kmp/migration-notes.md`.

Readium's own abstractions (`Readable`, `Resource`, `Container`, `Asset`) are already platform-neutral in shape; this phase swaps their `java.io`/`java.nio` internals for Okio and moves them to commonMain.

Subsystem sizes: `util/data` 6 files, `util/file` 4, `util/io` 1, `util/resource` 13, `util/asset` 4, `util/cache` 1, `util/archive` 2.

## Task 4.1 — `util/data` (Readable, Decoding, Reading, InputStream adapters)

- `Data.kt`/`Reading.kt`: interfaces are pure Kotlin → commonMain.
- `Decoding.kt`: the bitmap decoding part uses `android.graphics.BitmapFactory` — split it out; bitmap decoding moves to phase 07 (image type). String/JSON/XML decoding: commonMain (JSON decoding now uses kotlinx tree; XML decoding depends on phase 06 — if `decodeXml` blocks the move, leave that single function in androidMain temporarily with a `// TODO(kmp phase-06)`).
- `InputStream.kt` adapters (`Readable` ↔ `java.io.InputStream`): androidMain permanently (InputStream is a JVM type; Android callers keep them). Common code must use `Readable` directly.

## Task 4.2 — `util/io` + `util/file` (FileResource, DirectoryContainer)

- Add a commonMain `FileResource` implemented on `okio.FileHandle` (positional `read(range)`) via `FileSystem.SYSTEM`; `DirectoryContainer` on `FileSystem.list/metadata`.
- The public API currently exposes `java.io.File`. Introduce a KMP-friendly file reference: reuse `Url`/`AbsoluteUrl` (file scheme) as the canonical cross-platform reference, keeping `java.io.File` overloads as androidMain extensions (pattern from phase 02). Record breaks in migration notes.
- `CountingInputStream` (`util/io`): stays androidMain if only used by InputStream adapters; check its users first (grep).

## Task 4.3 — `util/resource` (13 files)

Buffering, transforming, fallback resources, `ResourceContentExtractor` **excluded** (Jsoup — phase 07). Mostly pure logic over `Readable` — move to commonMain, replacing any `java.io` leftovers with Okio. `ReadableInputStreamAdapterTest` etc.: check destinations per the test rule.

## Task 4.4 — `util/asset` + `util/cache` + `util/archive`

- `AssetRetriever` (4 files): the scheme/format resolution core → commonMain; the `ContentResolver`-backed resource factory and `extensions/ContentResolver.kt`, `util/content/ContentResource.kt` → androidMain permanently (Android `content://` support).
- `util/cache` (1 file): pure Kotlin? grep and move.
- `util/archive` (2 files): the `ArchiveOpener`/provider interfaces → commonMain (implementations arrive in phase 05).

**Phase acceptance:** file/resource/asset test suites ported to commonTest with `Fixtures`, green on both platforms; `grep -rn "^import java.io" readium/shared/src/commonMain` returns nothing; canonical commands pass.
