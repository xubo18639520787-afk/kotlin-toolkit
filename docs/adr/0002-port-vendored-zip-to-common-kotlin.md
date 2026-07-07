# Port the vendored zip stack to pure Kotlin in commonMain

The toolkit vendors a Java subset of Apache Commons Compress (plus `java.nio` channel shims) to support random-access and *streaming zips over HTTP* — opening a remote EPUB without downloading it entirely. For KMP we translate this vendored Java to pure Kotlin in `commonMain` instead of the two alternatives: per-platform zip implementations (expect/actual over `java.util.zip` and minizip) would mean maintaining two behaviors and reimplementing zip-over-HTTP on iOS anyway; third-party KMP zip libraries don't support random access over HTTP at all. We already own and maintain this code, so translating it keeps a single, identical behavior on all platforms.

Consequences: we permanently own a zip reader (~40 files after dropping the unused writer classes); its Apache attribution headers must be preserved; `Inflater` is the only platform seam (expect/actual over `java.util.zip.Inflater` / zlib).
