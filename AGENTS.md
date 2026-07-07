# Readium Kotlin Toolkit

Android library for building ebook reading apps, with support for EPUB, PDF, audiobooks and comics. It is a **library consumed by third-party apps**: its public API is a contract, and quality expectations are high. `test-app/` is the demo reading app. PRs target the `develop` branch.

`CONTEXT.md` defines the project's domain language (Publication, Manifest, Locator, Resource, Container, Asset…) — use those terms, and their listed alternatives to avoid, in code and documentation.

## Modules

Each module lives under `readium/` and is published as a separate artifact.

| Module | Responsibility |
|---|---|
| `readium/shared` | Core models (`Publication`, `Link`, `Locator`), toolkit (`Url`, `Try`, HTTP, data/resources, formats). Everything else depends on it. |
| `readium/streamer` | Parsing publications (EPUB, PDF, audiobook, comics) into `Publication` objects. |
| `readium/navigator` | Rendering and navigating publications (legacy generation). UI-facing code lives here. |
| `readium/navigators` | New generation of navigators (web, media). |
| `readium/opds` | OPDS catalog feed parsing. |
| `readium/lcp` | Readium LCP DRM support. |
| `readium/adapters` | Bridges to third-party dependencies (PDFium, ExoPlayer…). |

Put new code in the lowest layer that needs it — never add UI concerns to `shared`/`streamer`, never parse publications in navigators.

## Commands

- `make format` — format Kotlin sources with ktlint (run before finishing any Kotlin change)
- `make lint` — check Kotlin formatting (what CI runs)
- `./gradlew :readium:<module>:testDebugUnitTest` — run a module's unit tests
- `./gradlew assembleDebug testDebugUnitTest lintDebug` — full CI build

## EPUB navigator JavaScript layer

The EPUB navigator injects JavaScript bundles into publication resources. The bundles are committed and CI fails if they are out of sync with their sources:

- Legacy navigator: sources in `readium/navigator/src/main/assets/_scripts/` → regenerate with `make scripts-legacy`
- New web navigator: sources in `readium/navigators/web/internals/scripts/` → regenerate with `make scripts-new`

Never edit the generated bundles directly.

## Policies

### Discuss new features first

Before implementing a **new feature**, warn the user: the Readium project asks that new features be discussed first in a GitHub issue or discussion at <https://github.com/readium/kotlin-toolkit>, and undiscussed feature changes may be refused. Ask the user to confirm they want to proceed anyway. This does not apply to bug fixes or small changes such as typos.

### Public API is a contract

All modules use Kotlin explicit API mode. Changing or removing a stable `public` declaration requires a deprecation cycle, a `CHANGELOG.md` entry, and an entry in `docs/migration-guide.md` under `## Unreleased` when integrators must change their code. Hard (shimless) breaking changes require explicit maintainer approval — never ship them silently. See the `change-public-api` skill before touching any public API.

### Verification

Compile the affected modules and run their unit tests, and run the full CI build before a PR is ready. Do not drive an emulator; instead state explicitly when runtime behavior was not verified on a device. See the `verify-changes` skill.

## Skill routing

Consult the matching skill **before** starting these tasks — not after:

| When you are about to… | Use skill |
|---|---|
| Add, change, or remove any `public` declaration in `readium/` | `change-public-api` |
| Write or modify tests, fix a bug (regression test required) | `write-tests` |
| Declare a task finished or a PR ready | `verify-changes` |
| Document a change for app developers | `update-changelog` |
| Announce a new release | `write-release-announcement` |

## More documentation

- `CONTRIBUTING.md` — coding standard, JS layer details
- `MAINTAINING.md` — release process
- `docs/guides/` — user-facing guides for app developers
- `CHANGELOG.md` — user-facing changes, updated via the `update-changelog` skill
