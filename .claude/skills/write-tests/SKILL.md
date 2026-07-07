---
name: write-tests
description: Conventions and policy for writing unit tests in the Readium Kotlin
  Toolkit. Use whenever writing or modifying tests, fixing a bug (regression test
  required), or changing public API (tests required).
---

# Writing tests

## What must be tested (project policy)

- **Every public API change needs tests** covering the new or changed behavior — a public API PR without tests is incomplete.
- **Every bug fix needs a regression test.** Write it first and check that it fails without the fix, so it actually pins the bug.
- **Parser/format changes** (Streamer, OPDS, shared `mediatype`/`format`) need fixture-based tests exercising real files, not just in-memory structures.

## Conventions

Tests are plain JVM unit tests under `<module>/src/test/java/`, mirroring the package of the code under test. Run them with `./gradlew :readium:<module>:testDebugUnitTest`.

- **JUnit 4** with `@Test`; test names are backtick sentences describing the behavior:
  ```kotlin
  @Test
  fun `convert an hexadecimal string to a byte array`() { ... }
  ```
- **Robolectric** (`@RunWith(RobolectricTestRunner::class)`) only when the test touches Android framework types; plain JUnit otherwise.
- **Assertions**: `kotlin.test` assertions (`assertEquals`, `assertNull`, `assertContentEquals`) or `org.junit.Assert` — match the style of the surrounding test file. Use `assertJSONEquals` (from `readium/shared` `TestUtils.kt`) to compare `JSONObject`/`JSONArray`.
- **Coroutines**: wrap suspending code in `runBlocking` or `kotlinx.coroutines.test.runTest`, matching neighboring tests.
- Extract `private` helper functions when three or more tests share setup.

## Fixtures

Fixture files live in `<module>/src/test/resources/`, under the package path of the test that uses them. Load them through the classpath:

- In `shared`: use the `Fixtures` helper from `TestUtils.kt` (`fixtures.urlAt("..."), fixtures.fileAt(...)`).
- Elsewhere: `MyTest::class.java.getResource(path)` / `getResourceAsStream(path)`.

Prefer the smallest fixture that exercises the behavior: an in-memory value when the logic doesn't depend on file structure, a minimal crafted file when it does, a full publication only for integration-level parser tests. Name new fixtures after what they exercise.

## Test doubles

**Reuse the existing doubles before writing new ones** — search the module's test target for `Fake`, `Mock`, and `Test` prefixed types first. When a new double is needed, implement the toolkit interface (`Resource`, `HttpClient`, …) rather than inventing an ad-hoc abstraction, and put it in its own file. Never add test-only hooks to library code in `src/main/`.
