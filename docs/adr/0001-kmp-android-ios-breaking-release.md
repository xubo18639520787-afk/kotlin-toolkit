# Migrate the core to Kotlin Multiplatform (Android + iOS) as a breaking major release

The shared models and parsing layer (`readium-shared`, `readium-streamer`, `readium-opds`) are duplicated between the Kotlin and Swift toolkits. We migrate these modules to Kotlin Multiplatform targeting Android, iosArm64 and iosSimulatorArm64, so KMP app developers can consume them from `commonMain`. The Android public API breaks in one major release (org.json, `java.io.File` and `android.net.Uri` cannot exist in common code) rather than maintaining parallel modules or compatibility bridges, which would double maintenance and encourage divergence. Navigators, LCP and adapters deliberately stay Android-only. iosX64 (Intel simulator) is deliberately not targeted, matching the broader KMP ecosystem; Swift-export polish (SKIE, XCFramework) is out of scope while the iOS consumer is KMP apps rather than the Swift toolkit.

See `docs/kmp/PLAN.md` for the execution plan.
