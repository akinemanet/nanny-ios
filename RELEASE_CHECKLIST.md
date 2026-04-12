# Release Checklist

Bu dosya, `nanny` iOS uygulamasi ve backend'i production'a almadan once hizli ama guvenli bir son kontroldur.

## 1. Apple / Push

- Apple Developer Program uyeligi aktif mi kontrol et.
- Xcode `APIEnvironment` target'i altinda dogru team secili mi kontrol et.
- `Signing & Capabilities` altinda `Push Notifications` acik mi kontrol et.
- `Background Modes > Remote notifications` acik mi kontrol et.
- Firebase `Cloud Messaging` ekraninda iOS app icin APNs key yuklu mu kontrol et.
- Uygulamada `Push Hata Ayiklama` ekraninda:
  - `APNs durumu: Hazir`
  - FCM token gorunuyor

## 2. Backend Env

- Sunucuda `docker-compose.yml` icinde:
  - `FIREBASE_SERVICE_ACCOUNT_PATH`
  - `./firebase-service-account.json:/opt/nanny-backend/firebase-service-account.json:ro`
  dogru mu kontrol et.
- `firebase-service-account.json` dosyasi sunucuda var mi kontrol et.
- `docker compose build api --no-cache`
- `docker compose up -d --force-recreate api`
- `docker compose logs --tail=200 api`
  Hata olmadan ayaga kalkiyor mu kontrol et.

## 3. DB Saglik Kontrolleri

- Mesaj notification kaydi olusuyor mu:
```bash
docker compose exec -T postgres psql -U nanny -d nanny -c "select id, user_id, title, body, read, created_at from notifications order by created_at desc limit 10;"
```

- Push token kaydi dusuyor mu:
```bash
docker compose exec -T postgres psql -U nanny -d nanny -c "select user_id, platform, left(token, 20) as token_prefix, created_at, updated_at from device_push_tokens order by updated_at desc limit 20;"
```

- Son rezervasyonlar:
```bash
docker compose exec -T postgres psql -U nanny -d nanny -c "select id, parent_user_id, provider_user_id, service, status, booking_type, start_at, end_at from bookings order by created_at desc limit 20;"
```

- Son aile talepleri:
```bash
docker compose exec -T postgres psql -U nanny -d nanny -c "select id, parent_user_id, assigned_provider_user_id, status, matched_booking_id, start_at, end_at from care_requests order by created_at desc limit 20;"
```

## 4. Uctan Uca Smoke

### Aile

- OTP login calisiyor.
- Talep olusturma calisiyor.
- Aday bakici aile ekraninda gorunuyor.
- Aday adina dokununca bakici profili aciliyor.
- Rezervasyon detayinda:
  - hizmet metinleri Turkce
  - tarih/saat formatlari duzgun
  - saatlik ucret ve toplam dolu
- Mesaj atabiliyor.

### Bakici

- OTP login dogru hesaba gidiyor.
- Profil ozeti dolu geliyor.
- Fotograf gorunuyor.
- Yas / deneyim / kategori kaydi calisiyor.
- Aile talepleri listede gorunuyor.
- Aday olabiliyor.
- Arama / mesaj butonlari calisiyor.
- Arama gecmisi kartlari duzgun gorunuyor.

## 5. Push Smoke

- Aile ve bakici uygulamayi bir kez acsin.
- `device_push_tokens` tablosuna iki cihaz da dusmus mu kontrol et.
- Aileden bakiciya mesaj at.
- Bakici app arka plandayken push geliyor mu kontrol et.
- Bakicidan aileye cevap at.
- Aile app arka plandayken push geliyor mu kontrol et.

## 6. Temizlik

- Test kullanicilari temizlendi mi?
- Bos / yarim provider kayitlari temizlendi mi?
- Eski deneme talepleri ve rezervasyonlari temizlendi mi?
- Admin hesabi ve gercek operasyon hesaplari korunuyor mu?

Temizlik icin SQL sablonu:
- [prod_cleanup_template.sql](/Users/clickajans/Desktop/nanny/APIEnvironment/Scripts/prod_cleanup_template.sql)

## 7. Son Karar

Asagidaki maddeler ayni anda saglaniyorsa release'e hazir say:

- Backend hata vermeden ayakta
- iOS son build cihazda
- Push token kaydi DB'ye dusuyor
- Mesaj, rezervasyon ve talep akislari calisiyor
- Test verileri temizlenmis
