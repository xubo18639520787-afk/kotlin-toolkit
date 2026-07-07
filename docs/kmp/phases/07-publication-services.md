# Phase 07 — Publication Services & remaining models

Read `docs/kmp/PLAN.md` first. Depends on phases 03 and 06. Breaking phase: append to `docs/kmp/migration-notes.md`.

## Task 7.1 — expect/actual image type

**New (commonMain):** `util/Image.kt` — `public expect class ReadiumImage` (name TBD in-code; keep it small: width, height, and a platform accessor). Android actual wraps `android.graphics.Bitmap`; iOS actual wraps `CGImage`/`UIImage` (`platform.UIKit.UIImage`).

- `util/data/Decoding.kt` bitmap part (deferred from phase 04): `decodeBitmap` → common `decodeImage` (expect/actual: `BitmapFactory` / `UIImage(data:)`), including the scaled decoding used by `coverFitting` (Android `inSampleSize`; iOS thumbnail via ImageIO `CGImageSourceCreateThumbnailAtIndex`).
- `publication/services/CoverService.kt`: `cover(): Bitmap` → `cover(): ReadiumImage` (+ androidMain `coverAsBitmap()` convenience). Migration notes entry.
- `util/pdf/PdfDocument.kt`: same swap for `cover`; interface then moves to commonMain (PDFium/PSPDFKit adapters implement it from Android).
- Downstream: navigator + test-app call `cover()` — fix call sites (grep `\.cover(`).

## Task 7.2 — HTML content iteration onto Ksoup

**Files:** `publication/services/content/iterators/HtmlResourceContentIterator.kt`, `util/resource/content/ResourceContentExtractor.kt` (the 2 Jsoup files).

- Add `implementation(libs.ksoup)` to commonMain; replace `org.jsoup` imports with `com.fleeksoft.ksoup` (API mirrors Jsoup: `Ksoup.parse`, same `Document`/`Element`/selector API).
- Characterize before/after: the content iterator produces `Content.Element`s with locators (css selectors, text before/after) — port its existing test suite to commonTest and require identical output on a fixture set of real EPUB resource files.
- Remove `libs.jsoup` from shared when no usage remains.

## Task 7.3 — ICU expect/actuals: tokenizer + search

**Files:** `util/tokenizer/TextTokenizer.kt` (android.icu BreakIterator), `publication/services/search/StringSearchService.kt` (android.icu BreakIterator/Collator/StringSearch).

- `TextTokenizer` interface + non-ICU implementations → commonMain. `DefaultTextContentTokenizer` becomes expect/actual: Android actual keeps ICU (mind the existing `Build.VERSION` checks); iOS actual uses `CFStringTokenizer` (word/sentence units) — same `Locale`→`Language` handling via phase-01 helpers.
- `StringSearchService`: interface + orchestration → commonMain; the ICU-backed comparator is an expect/actual `SearchComparator`. iOS actual: `NSString.rangeOfString(options: [.caseInsensitive, .diacriticInsensitive], locale:)` loop. Accept documented minor behavior differences across platforms; assert shared behavior (exact match, case-insensitive) in commonTest, ICU-specifics in androidHostTest.
- `publication/services/content/Content.kt` + `LocatorService.kt` + `HtmlResourceContentIterator` java.* leftovers: clean and move with this task.

## Task 7.4 — Remaining moves to commonMain

Sweep what's left in androidMain that isn't deliberately platform-bound:

- `publication/` remainder: `Publication.kt` + services deferred from phase 03 (`PositionsService`, `SearchService`, `ContentService`, `LocatorService`, protection/`ContentProtection` — grep each for platform imports first).
- `accessibility/` (2 files — note `AccessibilityDisplayString` uses Android `R.string` resources: keep string resolution in androidMain via expect/actual provider; iOS actual returns the raw English strings or a lookup table — decide and record).
- `opds/` shared package if not done in phase 03.

**Deliberately androidMain forever** (document the final list in PLAN.md when done): ContentResolver/content-scheme assets, InputStream adapters, ICU actuals, Bitmap actuals, Logcat actual, Parcelize actuals.

**Phase acceptance:** search/TTS-tokenizer/content-iterator suites green on both platforms; `Publication` + all core services compile in commonMain; canonical commands pass.
