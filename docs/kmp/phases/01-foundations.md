# Phase 01 — Foundations

Read `docs/kmp/PLAN.md` first. Depends on phase 00. This phase creates the commonMain scaffolding that everything else builds on. All paths below are relative to `readium/shared/src/androidMain/kotlin/org/readium/r2/shared/` (post-phase-00 layout) unless noted.

Run the canonical verification commands after **every** task.

## Task 1.1 — `@KmpMigrationBridge` marker annotation

Create `org/readium/r2/shared/InternalReadiumApi`-style annotation in `androidMain` (it never ships to common): `@KmpMigrationBridge` — see PLAN.md "Always-green protocol". KDoc: "Temporary bridge kept only to keep downstream modules compiling during the KMP migration; deleted before the phase that introduced it ends."

## Task 1.2 — Logging facade

**New (commonMain):** `util/logging/Log.kt` — a minimal internal-first facade:

- `public interface ReadiumLogger { fun log(severity: Severity, tag: String, message: String, throwable: Throwable?) }`
- A `public object ReadiumLog` holding a configurable `logger: ReadiumLogger?` plus `internal` convenience functions `v/d/i/w/e` mirroring Timber's call style, so the swap is mechanical.
- **Defaults (expect/actual):** Android actual logs to Logcat; iOS actual uses `NSLog` (or `os_log` if straightforward).

**Mechanical swap:** replace `import timber.log.Timber` + `Timber.x(...)` in the **11 shared files** (grep `import timber` to list them) with the facade. Do NOT touch the other modules' Timber usage (navigator/lcp/adapters keep Timber — they stay Android-only); only fix shared and anything that breaks.

Remove `libs.timber` from shared's dependencies when no usage remains.

**Acceptance:** `grep -rn "timber" readium/shared/src` returns nothing; canonical commands pass.

## Task 1.3 — expect/actual Parcelize

**New (commonMain):** `util/Parcelize.kt`:

```kotlin
public expect annotation class Parcelize()
public expect interface Parcelable
public expect annotation class IgnoredOnParcel()
```

**Android actual:** typealiases to `kotlinx.parcelize.Parcelize`, `android.os.Parcelable`, `kotlinx.parcelize.IgnoredOnParcel`.
**iOS actual:** empty annotation classes and an empty interface.

Wire the compiler plugin: in `readium.multiplatform-conventions.gradle.kts`, resolve the `// TODO(phase-01)` marker by adding the parcelize `additionalAnnotation` option pointing at the new annotation's FQN for the android compilations.

**Mechanical swap:** in the 30 shared files importing `kotlinx.parcelize`, replace imports with the Readium ones (same short names — usage sites unchanged). Files stay in androidMain for now; the annotations just no longer block the later moves.

**Runtime-parcelization audit (do first, record in the PR):** grep `Bundle|writeToParcel|Parcel\b` in shared. Known hits: `util/http/DefaultHttpClient.kt`, `util/http/HttpRequest.kt` (Bundle extras — handled in phase 06), `util/format/Sniffing.kt` (verify what it does with Bundle and resolve or defer with a note). Anything else found: resolve per-site or file a note in the phase-06 doc.

**Acceptance:** `grep -rn "import kotlinx.parcelize" readium/shared/src` returns nothing; Android behavior unchanged (Parcelable still generated — verify by running the existing Parcelable-related tests); canonical commands pass.

## Task 1.4 — Digests onto Okio

Add `implementation(libs.okio)` to shared `commonMain` dependencies (moved from commonTest if phase 00 put it there).

The 3 files using `java.security.MessageDigest`: `extensions/File.kt`, `extensions/String.kt`, `extensions/ByteArray.kt`. Replace digest computations with Okio `ByteString` (`ByteString.of(...).sha256()` / `.md5()`). Keep function signatures unless they expose JVM types.

**Acceptance:** existing hash-related tests pass unchanged; canonical commands pass.

## Task 1.5 — Residual `java.util.Date` cleanup

Audit only (~4 usages; kotlinx.datetime is already the norm). Grep `java.util.Date|java.text` in shared and replace stragglers with `kotlinx.datetime.Instant` equivalents, preserving parsing behavior (RWPM dates are ISO-8601; there is an existing date-parsing helper — find and reuse it). **Do not touch code already on kotlinx.datetime.**

## Task 1.6 — `Language` / Locale expect/actual

`util/Language.kt` wraps `java.util.Locale`. Introduce an internal expect/actual for the two or three Locale capabilities actually used (grep the file: likely BCP-47 normalization, display name). Android/JVM actual keeps `java.util.Locale`; iOS actual uses `platform.Foundation.NSLocale`. Keep `Language`'s public API identical, then move `Language.kt` itself to commonMain.

**Acceptance:** existing `Language` tests pass; if they are Robolectric-free after the change, move them to commonTest per the test-porting rule.

## Task 1.7 — Move dependency-free files to commonMain

Move to `src/commonMain/kotlin` (with `git mv`) every shared file whose imports are already pure Kotlin/kotlinx (no android.*, java.*, org.json, timber). Generate the list mechanically:

```sh
cd readium/shared/src/androidMain/kotlin
grep -rL "^import \(android\|java\|org\.json\|org\.xmlpull\|timber\|org\.jsoup\)" -r . --include="*.kt"
```

Review each candidate for *transitive* blockers (it may reference a type whose file can't move yet — the compiler will tell you). Move what compiles; leave the rest with a `// TODO(kmp)` note naming the blocker. Delete the phase-00 placeholder `Kmp.kt`.

Port the tests of moved files to commonTest (kotlin-test assertions) per the test-porting rule. The 10 currently Robolectric-free test files are the first candidates: `TestUtils.kt`, `publication/LayoutTest.kt`, `publication/ReadingProgressionTest.kt`, `publication/epub/PropertiesTest.kt`, `util/InstantTest.kt`, `util/mediatype/MediaTypeTest.kt`, `util/format/TestContainer.kt`, `extensions/LongRangeTest.kt`, `extensions/StringTest.kt`, `extensions/URLTest.kt` (only those whose subjects have moved).

**Acceptance:** canonical commands pass; every moved file compiles for iOS; moved tests run on both `testAndroidHostTest` and `iosSimulatorArm64Test`.
