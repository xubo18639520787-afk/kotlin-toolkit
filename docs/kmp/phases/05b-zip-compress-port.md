# Phase 05b — Zip: Commons Compress port to Kotlin common

Read `docs/kmp/PLAN.md` first. Depends on 05a (channels + buffer mapping decided). This is the largest phase of the migration: translate the 53 vendored Java files in `readium/shared-zip-legacy/src/main/java/org/readium/r2/shared/util/zip/compress/` to Kotlin in shared **commonMain**, same packages.

## Ground rules for the translation

- **Read-only subset first.** Readium only *reads* zips. Before porting, grep shared for which compress classes are actually referenced (`ZipFile`, `ZipArchiveEntry`, entry/extra-field machinery, `InflaterInputStreamWithStatistics`, `utils/*` readers). Output/writer classes (`ZipArchiveOutputStream`, `ScatterZipOutputStream`, `ZipSplitOutputStream`, `StreamCompressor`, `parallel/*`) are candidates for **deletion instead of porting** — verify no reachable reference, then drop them and record it. Expect roughly half the files to be deletable.
- One task per file (or small cluster of interdependent files), bottom-up by dependency. Suggested order: `compress/utils` primitives (`ByteUtils`, `IOUtils`, `BoundedInputStream` family, `CountingInputStream`, `InputStreamStatistics`) → `archivers/zip` value types (`ZipShort`, `ZipLong`, `ZipEightByteInteger`, `GeneralPurposeBit`, `UnixStat`, `ZipMethod`, constants) → encodings (`ZipEncoding`, `NioZipEncoding` — replace `java.nio.charset` with a common encoding table; zip names are CP437 or UTF-8 only) → extra fields (`ZipExtraField`, `ExtraFieldUtils`, Zip64 fields, unicode fields) → entries (`ZipArchiveEntry`) → `ZipUtil` → `MultiReadOnlySeekableByteChannel`, `ZipSplitReadOnlySeekableByteChannel`, `BoundedSeekableByteChannelInputStream` → **`ZipFile`** last (the big one).
- `java.util.zip.Inflater` has no common equivalent: define `internal expect class Inflater` with the used subset (`setInput`, `inflate`, `finished`, `end`, `inflated bytes counts`); Android actual delegates to `java.util.zip.Inflater`; iOS actual wraps platform zlib (`platform.zlib` cinterop is available in Kotlin/Native out of the box). This is its own task with commonTest round-trip tests (deflate on JVM in androidHostTest fixtures, inflate in common).
- `InputStream`-shaped APIs: replace with Readium's `Readable`/the 05a channels or Okio `Source` — pick per class following how shared actually consumes it; do not recreate a general-purpose InputStream hierarchy in common.
- Keep Java semantics where tests depend on them (signed/unsigned arithmetic — use Kotlin `UInt`/`ULong` carefully; ZipLong etc. already encapsulate this).
- Translate file-by-file with `git mv`-style traceability: note the source Java file in the Kotlin file's KDoc header (the vendored files carry Apache license headers — **keep the Apache attribution** in the ported files).

## Tests

- Port/write commonTest suites as classes become available: value types (bytes ↔ values round-trips), extra-field parsing (use real-world fixture zips via `Fixtures`), and finally `ZipFile` reading the fixture set: stored + deflated entries, zip64, unicode names, data descriptors.
- Fixture zips: copy the existing test fixtures used by shared's current zip tests (find them under `readium/shared/src/androidHostTest/resources` — grep the zip tests for their resource paths) into `src/commonTest/fixtures/zip/`.
- Differential testing on Android: for each fixture, assert the ported `ZipFile` returns byte-identical entry contents to the legacy implementation (androidHostTest-only test that runs both).

**Phase acceptance:** every kept compress class is Kotlin in commonMain with tests green on both platforms; the legacy project still exists (deleted in 05c) but shared no longer references `compress/` from it (only 05c's container swap remains); canonical commands pass.
