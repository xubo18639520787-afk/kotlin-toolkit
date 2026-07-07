# Phase 08 — Streamer & OPDS conversion

Read `docs/kmp/PLAN.md` first. Depends on 05c, 06, 07. Both modules are nearly platform-clean; the heavy lifting happened in shared.

## Task 8.1 — Convert `readium-streamer` (module recipe from PLAN.md)

1. Flip to `readium.multiplatform-conventions` with all code in androidMain (same mechanics as phase 00 task 0.4; no vendored Java here; namespace `org.readium.r2.streamer`).
2. Known platform files (grep-verified): `parser/PublicationParser.kt`, `parser/pdf/PdfParser.kt`, `parser/readium/ReadiumWebPubParser.kt` import android (Context for the PDF factory wiring — keep the Context-taking entry points in androidMain; the parser cores take a `PdfDocumentFactory` and go common).
3. Move to commonMain, in order: extensions/utils → `parser/audio`, `parser/image` → `parser/epub` (the big one — XML-based, unblocked by phase 06) → `parser/readium` (RWPM/LCP-DF core; the LCP-specific service factories that reference lcp types stay androidMain if any) → `PublicationOpener`.
4. Tests: streamer has EPUB parsing suites with fixture publications — port to commonTest with `Fixtures`; Robolectric-only ones stay per the test rule.

## Task 8.2 — Convert `readium-opds`

1. Flip to the KMP convention plugin (namespace `org.readium.r2.opds`).
2. `OPDS1Parser` (XML via phase-06 XmlParser) and `OPDS2Parser` (JSON, already flipped in phase 03) move to commonMain along with the model types; anything importing android stays back (expected: nothing or nearly nothing — grep).
3. Port test suites (`TestUtils.kt` org.json usage was fixed in phase 03) to commonTest.

## Task 8.3 — Extend canonical verification commands

Update PLAN.md's canonical list, adding for each converted module:

```sh
./gradlew :readium:readium-streamer:compileKotlinIosSimulatorArm64 :readium:readium-opds:compileKotlinIosSimulatorArm64
./gradlew :readium:readium-streamer:testAndroidHostTest :readium:readium-streamer:iosSimulatorArm64Test
./gradlew :readium:readium-opds:testAndroidHostTest :readium:readium-opds:iosSimulatorArm64Test
```

**Phase acceptance:** an EPUB parses end-to-end in commonTest on the iOS simulator (open fixture container → parse → assert manifest); whole-repo canonical commands (now including the new iOS tasks) pass.
