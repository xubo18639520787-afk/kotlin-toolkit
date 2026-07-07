# Phase 09 — Release sweep

Read `docs/kmp/PLAN.md` first. Depends on all previous phases.

## Task 9.1 — Residue sweep

- `readium/shared/src/androidMain` contains only the deliberate platform code (list documented at the end of phase 07). Grep checks: no `@KmpMigrationBridge` (besides its declaration — delete that too now), no `TODO(kmp` markers left unresolved, no `org.json`/`timber`/`jsoup` in core modules, `:readium:readium-shared-zip-legacy` gone.
- Downstream: navigator, navigators, lcp, adapters, test-app, `demos/navigator` compile and their tests pass.
- Run the test-app manually: open a local EPUB, a PDF, an OPDS catalog, an LCP publication (smoke).

## Task 9.2 — Migration guide & changelog

- Assemble `docs/migration-guide.md`'s new-major section from `docs/kmp/migration-notes.md` (accumulated since phase 02): JSONable flip + helper mapping table, Url/File relocations to androidMain extensions, CoverService image type, HttpRequest extras, XmlParser input types, Parcelize annotation package change.
- Update `CHANGELOG.md` (follow the existing format; see the `update-changelog` conventions).

## Task 9.3 — Publishing verification (two axes)

Using `publishToMavenLocal` (disable signing locally if needed — the vanniktech plugin skips signing when no signatory is configured only for snapshot-style setups; otherwise pass the documented `RELEASE_SIGNING_ENABLED=false` project property or equivalent):

1. **KMP consumer:** scratch KMP project (androidTarget + iosSimulatorArm64) with `commonMain { implementation("org.readium.kotlin-toolkit:readium-shared:<version>") }` — parses a manifest in commonMain, compiles for both targets.
2. **Pure-Android consumer:** scratch plain Android app depending on the same coordinates — resolves through Gradle Module Metadata variant selection to the `-android` artifact and builds. Also verify `readium-navigator` (still Android-only) resolves its `api(readium-shared)` dependency from the published artifacts correctly.

Record the final coordinate/variant scheme in PLAN.md's Publishing section.

## Task 9.4 — Docs & CI

- Dokka builds (`./gradlew dokkaHtml` or the repo's aggregate task; check `mkdocs.yml` integration still works).
- CI: add the iOS compile/test tasks from PLAN.md's canonical list to the CI workflow (macOS runner required for iOS simulator tests; if CI is Linux-only, add at minimum the `compileKotlinIosArm64` compile-only check, which works without Xcode via the Kotlin/Native cross toolchain — verify, else gate on a macOS job).
- README/docs mention KMP support and the supported targets.
