# Testing

Ana test komutu:

```bash
xcodebuild -project APIEnvironment.xcodeproj -scheme APIEnvironment -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath /tmp/APIEnvironmentDerivedData test
```

Bu komut `APIEnvironmentTests` target'indaki unit testleri calistirir. Su an burada su alanlar korunuyor:

- decode fallback'leri
- dashboard routing ve sohbet eslesmesi
- mesafe hesabi
- booking / notification mutation fallback planlari
- checkout completion detection
- chat socket payload ve reconnect backoff mantigi
- dashboard snapshot ve booking status presentation

Hizli mantik smoke check icin:

```bash
bash Scripts/run_logic_regressions.sh
```

Bu script halen mevcut ama artik ana dogrulama yolu degil; daha hizli bir saf Swift regresyon kosusu olarak duruyor.

iOS build dogrulamasi icin:

```bash
xcodebuild -project APIEnvironment.xcodeproj -scheme APIEnvironment -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/APIEnvironmentDerivedData build
```
