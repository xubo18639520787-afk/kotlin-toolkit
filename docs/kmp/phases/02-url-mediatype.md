# Phase 02 — Url & MediaType

Read `docs/kmp/PLAN.md` first. Depends on phase 01. This is the **first breaking phase**: start appending every public-API break to `docs/kmp/migration-notes.md` as you go.

`Url` is carried by the publication models (Link, Href, Locator), so this phase must land before phase 03 (JSON).

## Task 2.1 — HIGH RISK: pure-Kotlin path normalization

**File:** `util/Url.kt` (line ~202): `normalize()` delegates path collapsing to `java.io.File(it).normalize().path`, and `resolve`/`relativize`/`equivalent` build on it. This is the core of relative-HREF resolution for every publication.

Reimplement the normalization in pure Kotlin (RFC 3986 §5.2.4 "remove dot segments", adjusted to match `java.io.File.normalize` behavior where they differ — write characterization tests against the JVM implementation FIRST to capture: `.` / `..` collapsing, leading `..` retention, trailing-slash handling, duplicate separators, empty path).

**Parity gate:** the existing `UrlTest.kt`, `HrefTest.kt`, `URLTest.kt` suites are the acceptance criterion. Extend `UrlTest` with the characterization cases before switching the implementation, then make the pure-Kotlin version pass identically.

This task changes no public API; it lands while `Url.kt` is still in androidMain.

## Task 2.2 — `Url` onto uri-kmp

Add `implementation(libs.uri.kmp)` to commonMain. `util/Url.kt` currently uses `android.net.Uri`, `android.net.UrlQuerySanitizer`, `java.net.URI/URL`, `java.io.File`:

- Replace `android.net.Uri` with `com.eygraber.uri.Uri` (near-identical API — parsing, `buildUpon`, percent-encoding, query access).
- Replace `UrlQuerySanitizer` usage with uri-kmp query parsing or a small internal helper.
- `Url.toFile(): File?` and any `java.io.File`/`java.net.URI|URL` conversions: keep them as **androidMain extension functions** in a new `androidMain … util/UrlAndroid.kt` (e.g. `fun Url.toFile(): File?`, `fun File.toUrl(): AbsoluteUrl`, `fun Url.toURI(): URI`). Record each relocation in the migration notes.
- The `@Parcelize` on Url already uses the phase-01 expect annotation.

Then move `util/Url.kt` (+ `Href.kt` in `publication/`) to commonMain. Fix downstream call sites (inventory below).

**Downstream call-site inventory (grep `\.toFile()\|toUrl()\|Url(` in each before starting):** navigator, lcp, streamer, opds, test-app all construct Urls and call `toFile()`; the androidMain extensions keep them compiling — only imports may need updating. Atomic task; bridges should not be needed.

**Acceptance:** parity suites from task 2.1 pass in **commonTest** on both platforms now; canonical commands pass.

## Task 2.3 — `extensions/URL.kt` and friends

`extensions/URL.kt`, `extensions/String.kt`, `extensions/File.kt` contain `java.net`/`java.io` helpers. Split: pure-string helpers → commonMain; JVM-type helpers (on `java.net.URL`, `java.io.File`) → stay androidMain (they serve Android callers). Move `URLTest.kt` cases covering the common parts to commonTest.

## Task 2.4 — MediaType & format sniffing to commonMain

**Files:** `util/mediatype/` (MediaType + charset handling; check `java.util.Locale` and `java.nio.charset` usage — replace with the phase-01 Language/locale helpers and Kotlin's `Charsets`/manual charset names) and `util/format/` (`Format.kt`, `FormatRegistry`, `Sniffers.kt`, `Sniffing.kt`).

- Content-independent sniffing (extension/media-type maps) and content-based sniffers reading bytes through Readium's own `Readable` abstractions: move to commonMain.
- Anything touching `ContentResolver`, `Bundle` (see `Sniffing.kt` — phase-01 audit note) or other Android APIs: keep in androidMain as platform sniffers registered into the common registry.
- `MediaTypeTest.kt` and the format/sniffer tests move to commonTest, fixtures via the phase-00 `Fixtures` helper.

**Acceptance:** sniffer tests green on both platforms; canonical commands pass; migration notes updated with any relocated public symbols.
