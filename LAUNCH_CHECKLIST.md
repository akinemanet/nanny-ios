# Launch Checklist

## 1. Push Hazirligi

- Apple Developer uyeliginin aktiflestigini dogrula.
- Xcode target icinde `Push Notifications` capability ekle.
- `Background Modes > Remote notifications` secenegini ac.
- Firebase tarafinda APNs key baglantisini tamamla.
- Uygulamada `Push Hata Ayiklama` ekraninda `APNs durumu: Hazir` gor.
- Sunucuda cihaz token kaydini dogrula:

```bash
docker compose exec -T postgres psql -U nanny -d nanny -c "select user_id, platform, left(token, 20) as token_prefix, created_at, updated_at from device_push_tokens order by updated_at desc limit 20;"
```

- Uygulama arka plandayken test et:
  - yeni mesaj
  - yeni aday
  - rezervasyon / odeme gelismesi

## 2. Aile Smoke Testi

- giris / cikis
- talep olusturma
- adaylari gorme
- bakici profilini acma
- aday onaylama
- rezervasyon detayi
- odemeye gecis
- mesaj gonderme
- bildirimden ilgili ekrana gitme

## 3. Bakici Smoke Testi

- giris / cikis
- profil duzenleme
- belge / fotograf yukleme
- musaitlik guncelleme
- aile taleplerini gorme
- aday olma
- mesajlasma
- arama baslatma
- rezervasyon akisini tamamlama

## 4. Bildirim ve Rozet Kontrolu

- mesaj rozeti dogru artiyor mu
- sohbet acilinca okunmamis durum dusuyor mu
- bildirim rozetleri dogru gorunuyor mu
- `Tumunu Okundu Yap` dogru calisiyor mu
- bildirimler dogru ekrana yonleniyor mu

## 5. Odeme Kontrolu

- checkout baglantisi aciliyor mu
- basarili odeme sonrasi ekran guncelleniyor mu
- basarisiz odeme sonrasi metinler anlasilir mi
- provider odeme / IBAN / alt uye isyeri gorunumu dogru mu

## 6. Veri Temizligi

- test / demo kullanicilar temiz mi
- spam care request kayitlari silinmis mi
- eski test booking ve konusmalar kontrol edildi mi
- gercek aile / bakici / admin hesaplari korunuyor mu

## 7. Sunucu Kontrolu

- backend loglarinda kritik hata yok
- env degiskenleri dogru
- domain ve SSL calisiyor
- DB yedegi alindi
- push service account dosyasi yerinde

## 8. App Store Hazirligi

- uygulama adi
- aciklama
- anahtar kelimeler
- ekran goruntuleri
- gizlilik politikasi URL
- destek URL
- yas derecelendirmesi

## 9. Son Gercek Cihaz Kontrolu

- aile hesabinda release build ac
- bakici hesabinda release build ac
- temel akislari yeniden dene
- sessiz saatler davranisini kontrol et
- internet gidip geldiginde hata metinlerini kontrol et

## 10. TestFlight / Yayin

- archive al
- build yukle
- TestFlight ic test yap
- gerekirse dis tester ekle
- yayin notlarini hazirla

