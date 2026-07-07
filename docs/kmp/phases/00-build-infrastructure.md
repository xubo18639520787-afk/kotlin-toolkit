# Phase 00 — Build Infrastructure

Read `docs/kmp/PLAN.md` first, especially the **Phase-00 spike findings** section: this phase was executed end-to-end in a throwaway spike on 2026-07-07 and every instruction below is validated. Follow it literally.

At the end of this phase, the repo builds exactly as before, plus the empty iOS targets of `readium-shared` compile, plus commonTest runs on the iOS simulator.

## Task 0.1 — Version catalog: audit-then-fill-gaps

**File:** `gradle/libs.versions.toml`

Already present (do NOT re-add): `kotlinx-serialization-json`, `kotlinx-datetime`, `kotlinx-coroutines`, `kotlin-junit`.

Add (latest stable versions at implementation time):

- `okio` (`com.squareup.okio:okio`)
- `ktor-client-core`, `ktor-client-okhttp`, `ktor-client-darwin` (`io.ktor:ktor-client-*`)
- `xmlutil-core` (`io.github.pdvrieze.xmlutil:core`)
- `uri-kmp` (`com.eygraber:uri-kmp`)
- `ksoup` (`com.fleeksoft.ksoup:ksoup`)

(No `kotlin-test` alias needed: commonTest uses `implementation(kotlin("test"))` directly.)

**Acceptance:** `./gradlew help` succeeds; no duplicate catalog aliases.

## Task 0.2 — Temporary subproject for the vendored zip Java

The KMP Android target compiles **no Java**. The 64 vendored Java files under `readium/shared/src/main/java/org/readium/r2/shared/util/zip/` (`compress/` 53 files, `jvm/` 10 files, `FileChannelAdapter.java`) are self-contained (JDK-only imports) and move to a temporary plain `java-library` subproject.

1. Create `readium/shared-zip-legacy/build.gradle.kts`:
   ```kotlin
   plugins {
       `java-library`
   }

   java {
       sourceCompatibility = JavaVersion.VERSION_11
       targetCompatibility = JavaVersion.VERSION_11
   }
   ```
2. `git mv` the 64 `.java` files (preserving their package directories) to `readium/shared-zip-legacy/src/main/java/org/readium/r2/shared/util/zip/…`.
3. Register in `settings.gradle.kts`:
   ```kotlin
   include(":readium:shared-zip-legacy")
   project(":readium:shared-zip-legacy")
       .name = "readium-shared-zip-legacy"
   ```
4. This project is **not published** (do not apply the readium convention plugins). Add a `README.md` in it saying it is temporary and deleted at the end of phase 05.

**Acceptance:** `./gradlew :readium:readium-shared-zip-legacy:build` passes.

## Task 0.3 — KMP convention plugin

**File (new):** `buildSrc/src/main/kotlin/readium.multiplatform-conventions.gradle.kts`

Model on `readium.library-conventions.gradle.kts` (same group/publishing/dokka blocks), with these validated specifics:

```kotlin
plugins {
    kotlin("multiplatform")
    id("com.android.kotlin.multiplatform.library")   // NOT com.android.library — AGP 9 rejects it with KMP
    id("com.vanniktech.maven.publish")
    kotlin("plugin.parcelize")
    id("org.jetbrains.dokka")
}

kotlin {
    explicitApi()

    androidLibrary {
        compileSdk = (property("android.compileSdk") as String).toInt()
        minSdk = (property("android.minSdk") as String).toInt()

        androidResources.enable = true   // shared uses R.string; disabled by default

        withHostTestBuilder {
        }.configure {
            isIncludeAndroidResources = true   // Robolectric
        }

        // Downstream modules are JVM 11; the default here is 21 and breaks inlining.
        compilations.configureEach {
            compileTaskProvider.configure {
                compilerOptions {
                    jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_11)
                }
            }
        }
    }

    iosArm64()
    iosSimulatorArm64()

    compilerOptions {
        freeCompilerArgs.add("-Xannotation-default-target=param-property")
        languageVersion = org.jetbrains.kotlin.gradle.dsl.KotlinVersion.KOTLIN_2_3
        allWarningsAsErrors = true
    }
}
```

Plus the `tasks.withType<Test> { failOnNoDiscoveredTests = false }` and the `mavenPublishing { … }` block copied from `readium.library-conventions.gradle.kts` (vanniktech handles KMP publications automatically; keep `coordinates(...)` with `pom.artifactId`).

**Parcelize:** keep `kotlin("plugin.parcelize")` applied. Phase 01 defines the expect annotation; when it exists, add the `additionalAnnotation` compiler-plugin option for it. Leave a `// TODO(phase-01)` marker.

**Deliberately dropped from the old plugin — record each decision in the phase PR description:**
- `resourcePrefix = "readium_"` — lint-only; re-add if the new DSL exposes it, otherwise drop.
- `buildFeatures.buildConfig = true` — the spike compiled shared without it; verify nothing references `BuildConfig` in shared, then drop.
- release `buildTypes` + proguard files — the new DSL has no build types; verify no consumer-facing proguard rules are lost (check the old AAR for `consumer-rules.pro`).
- `coreLibraryDesugaring` — the spike compiled and passed 569 tests without it; audit shared for desugared-API usage (java.time on minSdk 23) before dropping for good.

**Acceptance:** `./gradlew :buildSrc:build` passes; plugin not yet applied anywhere.

## Task 0.4 — Flip readium-shared to KMP, all code in androidMain

**Files:** `readium/shared/build.gradle.kts`, source tree moves (use `git mv`).

1. `readium/shared/src/main/java` → `readium/shared/src/androidMain/kotlin` (the directory is named `java` but contains only Kotlin after task 0.2).
2. `readium/shared/src/main/AndroidManifest.xml` → `readium/shared/src/androidMain/AndroidManifest.xml`.
3. `readium/shared/src/main/res` → `readium/shared/src/androidMain/res`; delete the now-empty `src/main`.
4. `readium/shared/src/test/java` → `readium/shared/src/androidHostTest/kotlin` (note: **androidHostTest**, not androidUnitTest); move `src/test/resources` alongside.
5. The old build script's `androidTestImplementation` has no matching sources (`src/androidTest` doesn't exist) — drop it.
6. Rewrite `readium/shared/build.gradle.kts`:

```kotlin
plugins {
    id("readium.multiplatform-conventions")
    alias(libs.plugins.kotlin.serialization)
}

kotlin {
    androidLibrary {
        namespace = "org.readium.r2.shared"
    }

    sourceSets {
        androidMain.dependencies {
            api(project(":readium:readium-shared-zip-legacy"))
            implementation(libs.androidx.annotation)
            implementation(libs.timber)
            implementation(libs.kotlin.reflect)
            implementation(libs.kotlinx.coroutines.android)
            implementation(libs.kotlinx.datetime)
            implementation(libs.kotlinx.serialization.json)
            implementation(libs.jsoup)
        }

        commonTest.dependencies {
            implementation(kotlin("test"))
        }

        getByName("androidHostTest").dependencies {
            implementation(libs.junit)
            implementation(libs.assertj)
            implementation(libs.kotlin.junit)
            implementation(libs.kotlinx.coroutines.test)
            implementation(libs.robolectric)
        }
    }
}
```

7. `commonMain` gets a placeholder `readium/shared/src/commonMain/kotlin/org/readium/r2/shared/Kmp.kt` (an internal constant) so the iOS targets compile; removed when phase 01 moves real code in.

**Acceptance:** all canonical verification commands in PLAN.md pass, including whole-repo `compileDebugSources` (downstream modules untouched) and `testAndroidHostTest` running the full existing suite (569 tests at spike time).

## Task 0.5 — commonTest fixtures infrastructure

**Files (new):** `readium/shared/src/commonTest/kotlin/org/readium/r2/shared/Fixtures.kt` + wiring in the convention plugin.

Requirement: commonTest code must read fixture files (later phases add EPUB/RWPM/zip samples) in Android host tests *and* on the iOS simulator, without `ClassLoader.getResource`.

Design:

- `class Fixtures(group: String)` exposing `fun path(name: String): okio.Path` and `fun read(name: String): okio.ByteString`, reading from `readium/shared/src/commonTest/fixtures/<group>/`.
- The fixtures root is injected per-target by the convention plugin: an environment variable (e.g. `READIUM_FIXTURES_DIR`) set on `Test` tasks via `environment(...)` and on `KotlinNativeSimulatorTest` tasks likewise; read in common code via Okio's `FileSystem.SYSTEM` + `getenv` (expect/actual one-liner if needed).
- Requires `okio` in commonTest (or commonMain once phase 04 adds it) — add `implementation(libs.okio)` to commonTest for now.
- Prove it with one trivial test reading a small text fixture, passing on **both** `testAndroidHostTest` and `iosSimulatorArm64Test`.

**Acceptance:** the proof test passes on both platforms; the helper has KDoc so later phases use it uniformly.
