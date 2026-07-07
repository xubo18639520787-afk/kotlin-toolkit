# Phase 03 — JSON: org.json → kotlinx.serialization JsonElement

Read `docs/kmp/PLAN.md` first. Depends on phase 02. The single biggest public-API break. Append every break to `docs/kmp/migration-notes.md` as you go.

**Design rule:** we keep the lenient parse-with-warnings architecture. The target API is the kotlinx.serialization **tree** (`JsonObject`, `JsonElement`, `JsonArray`) — *not* `@Serializable` data classes. Parsing stays "read field, warn and skip on mismatch".

## Why the core flip cannot be bridged

`JSONable.toJSON(): JSONObject` (`JSONable.kt`) cannot gain a `toJSON(): JsonObject` overload (Kotlin forbids overloading on return type), and `org.json.JSONObject` does not exist on iOS, so any model implementing the old signature can never move to commonMain. Therefore task 3.2 is **atomic and repo-wide**. Do not attempt a bridge for it.

## Task 3.1 — Port the JSON helper extensions

**File:** `extensions/JSON.kt` (androidMain) — the `opt*`/mapping helpers the parsers rely on.

Create `util/json/Json.kt` in **commonMain** with equivalents on `JsonObject`/`JsonElement`: `optString`, `optNullableString`, `optBoolean`, `optInt`, `optDouble`, `optPositiveInt`, `optStringsFromArrayOrSingle`, `mapNotNull`-style iteration, `toMap`/`toList`, plus builders (`buildJsonObject` wrappers) mirroring what the old file offers (enumerate by reading `extensions/JSON.kt` — port every used helper, skip dead ones).

Add commonTest coverage for each helper (port `JSONTest` cases if present, else write characterization tests against the org.json behavior for: absent key, null value, wrong type, string-encoded numbers).

The old `extensions/JSON.kt` stays temporarily (still used until task 3.2 completes).

## Task 3.2 — ATOMIC: flip the `JSONable` contract repo-wide

One large, uniform change. Inventory (regenerate with grep before starting):

- `JSONable.kt`: `fun toJSON(): JSONObject` → `fun toJSON(): JsonObject` (kotlinx). 21 implementing files in shared, 27 `toJSON(): JSONObject` signatures.
- 56 shared files import org.json (signatures + `fromJSON`/companion parsers + `JSONParceler`).
- Downstream files to fix **in the same change**:
  - `opds`: `OPDS2Parser.kt`, test `TestUtils.kt`
  - `lcp` (12): `license/model/LicenseDocument.kt`, `StatusDocument.kt`, `components/Link.kt`, `Links.kt`, `components/lsd/Event.kt`, `PotentialRights.kt`, `components/lcp/Rights.kt`, `ContentKey.kt`, `Encryption.kt`, `User.kt`, `Signature.kt`, `UserKey.kt`
  - `navigator` (7): `DecorableNavigator.kt`, `R2BasicWebView.kt`, `html/HtmlDecorationTemplate.kt`, `extensions/JSON.kt`, `epub/EpubNavigatorViewModel.kt`, `epub/EpubNavigatorFragment.kt`, `epub/extensions/Decoration.kt`
  - `test-app` (4): `reader/ReaderRepository.kt`, `catalogs/CatalogFeedListViewModel.kt`, `data/model/Bookmark.kt`, `data/model/Highlight.kt`

Mechanics per file: swap `org.json.JSONObject` → `kotlinx.serialization.json.JsonObject`, `JSONArray` → `JsonArray`, old helpers → task-3.1 helpers. Mutation-style code (`put`) becomes builder-style (`buildJsonObject`). Where downstream code genuinely needs an `org.json.JSONObject` (e.g. Android WebView JS bridging in navigator), convert at the boundary with a small `JsonObject.toOrgJson()` helper placed **in navigator**, not in shared.

Note for lcp: those 12 files are Android-only and could keep org.json internally — only the surfaces interacting with shared types must flip. Prefer the smaller diff.

**Acceptance:** whole-repo canonical commands pass; `grep -rn "org.json" readium/shared/src` returns nothing; migration notes describe the `JSONable` flip and helper mapping table (old name → new name).

## Task 3.3 — Delete `extensions/JSON.kt` and `JSONParceler`

Remove the org.json-based helpers and any `JSONParceler` (Parcelize custom parceler for JSONObject — replace with a String-based parceler for `JsonObject` if a parcelized type carries JSON). Verify with grep that nothing references them.

## Task 3.4+ — Move models to commonMain, leaves first

With org.json gone, `publication/` models can move. **Topological order** (verify each with the compiler; a commonMain file cannot reference an androidMain sibling):

1. Enums & simple values: `ReadingProgression.kt` (drop its `java.util` import first — see phase-01 audit), `presentation/`, `encryption/`, `LocalizedString.kt` (check `java.util.Locale` → phase-01 Language helpers)
2. `Contributor`, `Subject`, `Collection`, `Metadata` satellites
3. `Properties`, `Link` (Href moved in phase 02)
4. `Locator`
5. `Manifest`, `Publication` core (**note:** `Publication` aggregates services; move only what compiles — services move in phase 07; if `Publication.kt` references service types that can't move yet, split the file or defer it to phase 07 with a `// TODO(kmp)` note)
6. `opds/` package in shared (9 files — OPDS properties on Link/Publication)
7. `MediaOverlayNode.kt`, `MediaOverlays.kt` (check their `java.*` imports)

One task per cluster; port each cluster's tests to commonTest (kotlin-test, fixtures via `Fixtures`); run canonical commands per cluster.

**Acceptance (phase end):** manifest/locator parsing test suites green on iOS simulator; no bridges remain (`grep KmpMigrationBridge`); migration notes complete.
