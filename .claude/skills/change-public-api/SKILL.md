---
name: change-public-api
description: Rules for adding, changing, deprecating or removing public API in the
  Readium Kotlin Toolkit. Use this skill BEFORE adding, changing, or removing any
  `public` declaration under `readium/`.
---

# Changing the public API

The toolkit is a library. Every `public` symbol is a contract with third-party apps: breaking it breaks their builds. Treat public API changes as the highest-risk edits in this codebase.

## Overview

This toolkit is published to Maven Central: its public API surface is the product. Thousands of reading apps compile against it, so every `public` declaration is a commitment. All modules use Kotlin explicit API mode — visibility is always deliberate.

The stability contract is expressed with opt-in annotations defined in `readium/shared/src/main/java/org/readium/r2/shared/OptIn.kt`:

- `@ExperimentalReadiumApi` — may change without notice; consumers opt in with a warning.
- `@InternalReadiumApi` — for use across Readium modules only; opt-in is an error for consumers. No compatibility guarantees.
- `@DelicateReadiumApi` — stable but easy to misuse; requires reading the documentation.

New public API defaults to `@ExperimentalReadiumApi`, unless it is a trivial addition to an already stable type (e.g. a new optional property mirroring an existing pattern). When in doubt, mark it experimental: promoting to stable later is free, un-breaking a stable API is not. If the declaration only exists so another Readium module can use it, mark it `@InternalReadiumApi` instead.

## Backward-compatibility policy

Never break a stable public API in one step. Follow the deprecation cycle:

1. **Deprecate first**: add `@Deprecated` with a message telling the app developer what to use instead. Provide `replaceWith = ReplaceWith(...)` whenever a mechanical substitution exists. Keep the old symbol delegating to the new one when possible.
2. **Severity follows major versions**: a deprecation is introduced as a WARNING and is only raised to `level = DeprecationLevel.ERROR` in the **next major version** (e.g. deprecated in 3.2.x → error in 4.0.0). Symbols at ERROR level may be removed in the major version after that.
3. **Do not delete existing deprecated symbols**; they are removed deliberately at major releases, never as part of an unrelated change.

**Hard (shimless) breaking changes are exceptional.** If a deprecation shim isn't feasible (an interface requirement changed shape, the old behavior can't be emulated), stop and ask the maintainer for explicit approval before proceeding. Never ship a silent break.

## Experimental API

New public API whose shape isn't settled is marked `@ExperimentalReadiumApi` rather than committed to. Consumers opt in with a warning, and the symbol carries no stability guarantee — it may be changed or removed freely, but still document the change. Use this (sparingly, as the existing code does) when you'd otherwise hesitate between `internal` and stable `public`: promoting an experimental API to stable later is free; un-breaking a stable API is not.

## Type and error-handling idioms

- **Fallible operations return `Try<Success, Failure>`** (`org.readium.r2.shared.util.Try`) with a typed error implementing `Error`, not thrown exceptions. Library code must never crash the host app on malformed publications: return an error case, log with Timber, or skip the invalid element. No `TODO()`, no bare `throw` across public API boundaries.
- **URLs and hrefs**: never pass raw `String` or `java.net.URL` across public APIs for publication resources. Use the toolkit types (`Url`, `AbsoluteUrl`, `RelativeUrl` from `org.readium.r2.shared.util`).
- **Media types and formats**: use `MediaType` / `Format`, never string comparison on file extensions or MIME strings.
- **Prefer small domain types over primitives** — this codebase wraps concepts (`Locator`, `Language`, `Accessibility`) rather than passing maps and strings.
- **Configurable components** follow the Preferences/Settings pattern used by the navigators (preferences in, settings out, editors for UI). Don't invent ad-hoc configuration classes for user-adjustable behavior.

## Design conventions

- Keep new declarations `@InternalReadiumApi` or unexposed unless integrators genuinely need them. Making something stable later is free; unmaking it costs a deprecation cycle.
- Follow the naming and structure of neighboring stable APIs in the same module. Do not introduce a new pattern when an established one exists.
- Protocol-first for extension points (parsers, resources, HTTP clients), with a `Default…` or format-named implementation.
- New code goes in the lowest sensible module (see the module map in `AGENTS.md`); never add UI concerns to `shared`/`streamer`.

## Cross-toolkit alignment

Public APIs are expected to stay conceptually aligned with the Swift toolkit (`readium/swift-toolkit`). When designing a new public API, note in the PR description whether an equivalent exists on the Swift side and whether the shape matches.

## Required documentation

For every public API change:

1. **Migration guide** (`docs/migration-guide.md`): breaking changes and deprecations get an entry under `## Unreleased` (uncomment the placeholder if needed), explaining what an app developer must do to adapt. Look at the `## 3.0.0` section for tone and format.
2. **Changelog**: document the change using the `update-changelog` skill.
3. **KDoc**: new public declarations get a KDoc comment explaining what the API is for, not how it works, matching the style of surrounding files.

## Checklist before finishing

- [ ] No `public` declaration added without a stability annotation decision (stable, experimental, or internal).
- [ ] No stable API changed or removed without a deprecation step (or explicit maintainer approval for a hard break).
- [ ] New error paths use `Try` with typed errors; nothing can crash the host app.
- [ ] Deprecation messages point to the replacement; `ReplaceWith` provided where mechanical.
- [ ] Migration guide entry written for breaking changes; CHANGELOG.md entry added.
- [ ] Tests cover the new API (see `write-tests`).
- [ ] The change compiles with explicit API mode (`./gradlew :readium:<module>:compileDebugKotlin`).
