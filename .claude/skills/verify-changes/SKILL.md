---
name: verify-changes
description: >
  The Readium Kotlin Toolkit's definition of done. Use this skill BEFORE
  declaring any code change finished, claiming something works, or marking a
  PR as ready. Defines exactly which modules to compile and test, and how to
  report results honestly.
---

# Verify changes

A change is **not done** because it compiles, and not done because it "should work". It is done when the affected modules compile and their unit tests pass. Never claim a change works without having run them in this session. Verification here means **compiling the affected modules and running their unit tests** — do not launch or drive an Android emulator or device.

## Required verification

**Always — after any change:** identify the affected modules and run their unit tests.

1. **Map changed files to Gradle modules**: `readium/shared` → `:readium:shared`, `readium/navigator` → `:readium:navigator`, `readium/navigators/web` → `:readium:navigators:web`, etc. `test-app/` → `:test-app`.
2. **Run the unit tests for each affected module**, plus modules that depend on it when the public API changed (dependency direction: `shared` ← `streamer`/`navigator`/`opds`/`lcp`):
   ```shell
   ./gradlew :readium:shared:testDebugUnitTest
   ```
3. **If a module has no tests covering the change**, at least compile it:
   ```shell
   ./gradlew :readium:navigator:compileDebugKotlin
   ```

**Before declaring a PR ready:** run the same command as CI.

```shell
./gradlew assembleDebug testDebugUnitTest lintDebug
```

## Completeness checks

Beyond tests, a change isn't complete until:

- Edits under `readium/navigator/src/main/assets/_scripts/` or `readium/navigators/web/internals/scripts/` are rebundled (`make scripts-legacy` / `make scripts-new`) and the regenerated bundles are included in the change. (The Stop hook runs this automatically and blocks if bundling fails — fix the errors, don't bypass it.) Verify the TypeScript side directly with `pnpm run lint` and `pnpm run test` (if present) in the scripts directory when the JS layer changed.
- Public API changes carry their CHANGELOG.md / migration-guide entries (see `change-public-api`).

## Report honestly

- If tests fail, say so and show the failing output — never summarize a failure as a success or as "mostly passing".
- If you could not run the tests (missing tooling, timeout), state that explicitly instead of implying the change is verified.
- Unit tests cannot prove rendering, gesture, or WebView behavior. When the change touches the navigator's runtime behavior (rendering, scrolling, decorations, JS bridge, media playback), state plainly that it compiles and passes unit tests but was **not verified on a device**, so a human knows to test it in the test-app before merging.
