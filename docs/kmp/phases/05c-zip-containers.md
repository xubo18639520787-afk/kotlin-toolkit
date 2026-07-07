# Phase 05c — Zip: containers on the ported stack

Read `docs/kmp/PLAN.md` first. Depends on 05b.

## Task 5c.1 — Move the zip containers to commonMain

**Files (androidMain → commonMain):** `util/zip/FileZipContainer.kt`, `FileZipArchiveProvider.kt`, `StreamingZipContainer.kt`, `StreamingZipArchiveProvider.kt`.

- `FileZip*` currently uses `java.util.zip.ZipFile` (yes — the *file-based* path uses the JDK, only the streaming path uses the vendored stack; verify with the imports). Two options: (a) port both onto the 05b `ZipFile` and delete the distinction if performance is equivalent; (b) keep a JVM-fast path in androidMain via expect/actual provider. **Default to (a)** — one implementation — and benchmark a large EPUB open on Android before/after (the repo has `util/Benchmarking.kt`); fall back to (b) only on a measurable regression.
- `StreamingZip*` swap from legacy compress imports to the 05b common classes; should be near-mechanical after 05a/05b.

## Task 5c.2 — Behavioral parity tests

- Port the existing zip container tests to commonTest (`Fixtures` zips from 05b).
- **Zip-over-HTTP:** add a commonTest exercising `StreamingZipContainer` against an in-memory `Readable` that simulates ranged reads (count the read calls to assert random access, not full download). If an HTTP-level integration test exists today, port its logic onto a fake.
- Run the differential Android test from 05b once more over the containers, then delete it.

## Task 5c.3 — Delete `:readium:readium-shared-zip-legacy`

Remove the subproject (sources, settings.gradle.kts entry, shared's `api(project(...))` dependency). `grep -rn "shared-zip-legacy\|zip.legacyjvm" .` must return nothing.

**Phase acceptance:** EPUB opening works in the test-app (manual smoke or existing instrumentation); zip suites green on both platforms; legacy project gone; canonical commands pass.
