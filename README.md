# Dokter HP

Aplikasi Android untuk mendeteksi dan memperbaiki masalah HP: WiFi lemot,
baterai boros, penyimpanan penuh, performa berat, dan keamanan.

Aplikasi berjalan penuh dalam **mode lokal** — semua diagnosis memakai data
nyata dari perangkat dan tersimpan di database lokal. Bila server Supabase
dikonfigurasi, tersedia tambahan: login Google, Diagnosis AI, dan
sinkronisasi riwayat.

> **Kasus awal:** WiFi ACHA, router ZTE F660, WiFi 4, kecepatan koneksi
> 65 Mbps, sinyal sangat bagus, tetapi kecepatan unduh turun dari
> 50 KB/detik ke 3,2 KB/detik. Dokter HP mengukur kecepatan sebenarnya,
> menampilkan sinyal, channel, dan latensi, lalu memberi langkah
> perbaikan yang jujur.

## Fitur

- **Dokter WiFi (fitur utama):** ukur kecepatan unduh dan latensi HTTP,
  tampilkan SSID, IP, gateway, DNS, kekuatan sinyal, kecepatan koneksi,
  dan channel. Rekomendasi ganti channel router (1/6/11 untuk 2,4 GHz)
  dan langkah perbaikan lewat pengaturan sistem. Hasil bisa dibagikan.
- **Dashboard:** skor kesehatan HP 0-100 dan diagnosis satu ketuk.
- **Dokter Baterai:** level, status, mode hemat daya, estimasi waktu pakai.
- **Dokter Penyimpanan:** ruang kosong dan bersih cache aplikasi sendiri
  (tidak menyentuh foto atau chat).
- **Dokter Performa:** RAM, CPU, suhu bila tersedia, info perangkat.
- **Dokter Keamanan:** izin berbahaya per aplikasi terpasang.
- **Riwayat:** pemeriksaan tersimpan lokal, laporan PDF yang bisa dibagikan
  (misalnya lewat WhatsApp).
- **Akun dan keamanan:** login Google via Supabase (bila tersambung),
  PIN lokal (disimpan sebagai hash SHA-256, tidak pernah plaintext),
  biometrik.
- **Diagnosis AI:** tanya jawab keluhan via Supabase Edge Function
  `ai-diagnose` (kunci Gemini hanya di server, tidak di APK).

## Prinsip kejujuran data

- Semua angka yang tampil adalah data nyata dari perangkat.
- Bila data tidak tersedia, layar menampilkan "tidak tersedia" atau
  "Belum ada data pemeriksaan" — bukan angka contoh.
- Android membatasi aplikasi pihak ketiga: aplikasi tidak bisa menyambung
  ulang WiFi, melupakan jaringan, mengganti DNS, menutup aplikasi lain,
  atau membaca pemakaian baterai per aplikasi secara langsung. Semua
  batasan ini dijelaskan jujur di layar terkait, beserta cara manual
  lewat pengaturan sistem.

## Persyaratan

- Flutter 3.47.6 (channel stable)
- Java 17
- Android 7.0 (API 23) ke atas untuk perangkat target

## Cara build (lokal)

```bash
flutter pub get
dart run build_runner build
flutter analyze
flutter test
flutter build apk --release
```

APK hasil build ada di `build/app/outputs/flutter-apk/app-release.apk`.

Untuk build lokal dengan Supabase:

```bash
flutter build apk --release \
  --dart-define=SUPABASE_URL=https://xxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=xxx
```

## Cara isi secret Supabase (opsional)

Tanpa secret, aplikasi tetap jalan penuh dalam mode lokal. Untuk
mengaktifkan login Google, Diagnosis AI, dan sinkronisasi riwayat:

1. Buat proyek Supabase (atau pakai proyek yang sudah ada).
2. Di proyek Supabase, buat Edge Function `ai-diagnose` yang menerima
   `{ "keluhan": string, "data_perangkat": object }` dan mengembalikan
   `{ "jawaban": string }`. Simpan kunci Gemini sebagai secret di
   Supabase (Dashboard > Edge Functions > Secrets) — jangan pernah
   menulis kunci di kode aplikasi.
3. Di repositori GitHub, buka **Settings > Secrets and variables >
   Actions**.
4. Tambahkan secret `SUPABASE_URL` (URL proyek Supabase) dan
   `SUPABASE_ANON_KEY` (kunci publishable/anon).
5. Daftarkan Redirect URL `dokterhp://login-callback` di Supabase
   (Authentication > URL Configuration) agar login Google kembali ke
   aplikasi.
6. Push ke branch `main` — workflow GitHub Actions membangun APK dengan
   secret tersebut. Bila secret kosong, build tetap jalan dalam mode
   lokal (hanya peringatan, bukan gagal).

## Cara unduh APK dari GitHub Actions

1. Buka repositori di GitHub, pilih tab **Actions**.
2. Pilih run workflow **Build APK** yang berhasil.
3. Di bagian **Artifacts**, unduh `dokter-hp-apk`.
4. Pasang file APK di HP Android (izinkan pemasangan dari sumber ini bila
   diminta).

## Struktur proyek

```
lib/
  main.dart                 # Boot, init Supabase opsional, sync background
  app.dart                  # MaterialApp + tema
  core/                     # Tema, skor kesehatan, config, MethodChannel
  data/local/               # Drift (SQLite): health_checks, wifi_reports
  data/sync/                # Sinkronisasi riwayat ke Supabase
  features/
    dashboard/ wifi_doctor/ battery/ storage/
    performance/ security/ history/ auth/ ai_diagnosis/
test/
  health_score_test.dart    # Unit skor 0-100
  wifi_logic_test.dart      # Unit klasifikasi kecepatan + channel
  dashboard_widget_test.dart # Widget dashboard + navigasi
```

## Teknologi

Flutter, Drift (SQLite lokal), Supabase (opsional), flutter_bloc,
local_auth, flutter_secure_storage. Tanpa payment gateway.

## Pemecahan masalah

| Gejala | Penyebab yang mungkin |
|---|---|
| `flutter pub get` lama | Unduhan paket pertama kali; tunggu sampai selesai, jangan batalkan |
| Build gagal karena `local.properties` | Jalankan `flutter build apk` dari root proyek; file dibuat otomatis |
| SSID tampil "tidak tersedia" | Izin lokasi belum diberikan (dibutuhkan Android 10+ untuk SSID) |
| Diagnosis AI belum tersedia | Secret Supabase belum diisi — aplikasi berjalan mode lokal |
| Tes unduh gagal | Periksa sambungan internet; server uji (Cloudflare/OVH) mungkin tidak terjangkau |
| Build APK lokal gagal TLS (`PKIX path validation failed`) | Egress proxy memakai CA sendiri yang tidak dikenal JDK. Buat truststore dari CA egress (`/run/hatch/egress-tls/hatch-egress-ca.pem`) dan jalankan build dengan `GRADLE_OPTS="-Djavax.net.ssl.trustStore=... -Djavax.net.ssl.trustStorePassword=..."`. Di GitHub Actions masalah ini tidak ada. |
| Build lokal macet di Gradle daemon | Di VM ini koneksi CLI ke daemon Gradle tidak tersambung (daemon jalan tetapi tidak menerima build). `org.gradle.daemon=false` sudah diatur di `android/gradle.properties`; bila tetap macet, andalkan build GitHub Actions. |

Lihat [PRODUCT.md](PRODUCT.md) untuk spesifikasi lengkap dan
[CHANGELOG.md](CHANGELOG.md) untuk riwayat versi.
