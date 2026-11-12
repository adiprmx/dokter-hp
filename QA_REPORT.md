# Laporan QA — Dokter HP v1.0.0

Tanggal: 11 November 2026
Auditor: QA Engineer + Security Reviewer (agen QA)
Repo: adiprmx/dokter-hp (workdir lokal `~/workspace/projects/dokter-hp`)
SDK: Flutter 3.47.6 (`/home/hatch/sdks/flutter/bin/flutter`)
Ruang lingkup: audit + perbaikan kecil yang aman. Tidak ada perubahan besar,
tidak ada push ke GitHub.

## Ringkasan eksekutif

- `flutter analyze`: 1 peringatan, dan peringatan itu berasal dari berkas
  sementara agen UI (`test/zz_tmp_visual_test.dart`, import `dart:ui` tidak
  terpakai). Sebelum berkas itu muncul, hasil analyze adalah
  "No issues found!". Kode milik proyek (lib, supabase, test asli) bersih.
- `flutter test`: **48 test lolos, 0 gagal** ("All tests passed!").
  Rinciannya: 32 test asli (logika skor kesehatan, logika WiFi, widget
  dashboard dan WiFi) + 7 test screenshot QA baru + 9 test visual sementara
  agen UI.
- Audit keamanan: tidak ditemukan secret atau kunci API di repo. Keempat
  tabel Supabase memakai RLS dengan policy `auth.uid() = user_id`. Token
  sesi diurus `supabase_flutter`, PIN hanya tersimpan sebagai hash SHA-256
  + salt, kunci Gemini hanya ada sebagai secret server Edge Function, dan
  tidak ada payment gateway.
- **Tidak ada temuan kritis.** Ada 3 temuan sedang yang wajib diperbaiki
  sebelum rilis dianggap penuh: (1) sinkronisasi Supabase memakai nama
  kolom yang tidak ada di migrasi sehingga selalu gagal diam-diam;
  (2) PIN bisa diatur tetapi tidak pernah ditegakkan saat aplikasi dibuka;
  (3) Edge Function `fcm-notify` bisa dipakai pengguna login mana pun
  untuk mengirim push ke token FCM mana pun.
- Satu perbaikan kecil sudah diterapkan: nama field request Diagnosis AI
  diperbaiki agar cocok dengan Edge Function (`keluhan` menjadi `gejala`).
- Catatan repo lokal: workdir lokal belum memiliki commit maupun remote
  git (`git log` melaporkan "No commits yet", status menampilkan semua
  berkas sebagai staged baru). Klaim commit `a8e538bc` yang sudah di-push
  ke main **tidak dapat diverifikasi dari workdir ini** — koordinator
  perlu memastikan commit tersebut memang ada di remote.

## 1. Verifikasi independen (test dan analyze)

Perintah dijalankan di workdir dengan SDK di atas:

| Perintah | Hasil |
| --- | --- |
| `flutter pub get` | Berhasil ("Got dependencies!"). 27 paket memiliki versi lebih baru yang tidak kompatibel dengan constraint saat ini — dicatat sebagai catatan, bukan temuan. |
| `flutter analyze` | 1 issue: `warning • Unused import: 'dart:ui'` di `test/zz_tmp_visual_test.dart:2:8`. Berkas itu dibuat agen UI paralel sebagai harness sementara dan rencananya dihapus setelah screenshot selesai. Sebelum berkas itu ada, analyze melaporkan "No issues found!" (dijalankan 11 Nov 2026, 31,9 detik). |
| `flutter test` | **48 lolos, 0 gagal.** |

Rincian test (total 48):

| Berkas | Jumlah | Keterangan |
| --- | --- | --- |
| `test/health_score_test.dart` | 11 | Skor kesehatan, kategori, format kecepatan. |
| `test/wifi_logic_test.dart` | 16 | Klasifikasi kecepatan, channel, RSSI, rekomendasi. |
| `test/dashboard_widget_test.dart` | 3 | Judul, empty state jujur, navigasi ke Dokter WiFi. |
| `test/wifi_doctor_widget_test.dart` | 2 | Empty state, gagal jujur tanpa sambungan. |
| `test/qa_screenshot_test.dart` (baru, QA) | 7 | Screenshot 7 layar utama (lihat bagian 3). |
| `test/zz_tmp_visual_test.dart` (agen UI) | 9 | Screenshot visual dengan font Roboto asli. |

Catatan: pada satu kali jalan `flutter test` sebelumnya sempat muncul
pesan penutup "One or more uncaught errors occurred shutting down: Bad
state: Cannot add event while adding stream." (2 kali). Pesan itu tidak
muncul lagi pada jalan penuh terakhir yang mencatat "All tests passed!",
dan tidak ada test yang gagal karenanya. Penyebab pastinya belum
teridentifikasi; dicatat sebagai observasi, bukan temuan.

## 2. Audit keamanan

### 2.1 Row Level Security (migrasi SQL)

Semua 4 tabel di `supabase/migrations/` mengaktifkan RLS pada migrasi
yang sama dengan pembuatan tabel, dan masing-masing memiliki 4 policy
(select, insert, update, delete) yang membatasi ke baris milik sendiri:

| Tabel (migrasi) | `ENABLE ROW LEVEL SECURITY` | Policy | Kondisi |
| --- | --- | --- | --- |
| `profiles` (`20261111000001`) | Ya | 4 | `auth.uid() = id` |
| `health_checks` (`20261111000002`) | Ya | 4 | `auth.uid() = user_id` |
| `wifi_reports` (`20261111000003`) | Ya | 4 | `auth.uid() = user_id` |
| `ai_diagnoses` (`20261111000004`) | Ya | 4 | `auth.uid() = user_id` |

Tambahan: semua tabel memiliki index `user_id` dan `dibuat_pada`;
`health_checks` memakai soft-delete (`deleted_at`) dan aplikasi wajib
memfilter `deleted_at is null` — pemakaian di kode (`healthChecksAktif`,
`wifiReportsAktif`) sudah memfilter. **Verifikasi ini hanya membaca
file SQL; RLS belum diuji live di server Supabase** (belum ada proyek
Supabase yang terhubung dari workdir ini).

### 2.2 Secret dan kunci di repo

Pencarian (grep, pola: `service_role`, `sk-`, `AIza`, kunci API,
password, secret, token Bearer, `ghp_`, `AKIA`) di `lib/`, `android/`,
`supabase/`, `test/`, dan `pubspec.yaml` **tidak menemukan nilai
secret apa pun**. Yang ditemukan hanya penyebutan nama variabel
lingkungan, tanpa nilai:

- `supabase/functions/ai-diagnose/index.ts:69` —
  `Deno.env.get("GEMINI_API_KEY")` (dibaca dari secret server).
- `supabase/functions/fcm-notify/index.ts` —
  `Deno.env.get("FCM_PROJECT_ID")` dan `Deno.env.get("FCM_ACCESS_TOKEN")`
  (dibaca dari secret server).
- `supabase/README.md` — contoh perintah `supabase secrets set
  GEMINI_API_KEY=<redacted>` (placeholder, bukan nilai asli).
- Tidak ada berkas `.env` di repo. `.gitignore` sudah menutup
  `android/key.properties`, `*.keystore`, `*.jks`, dan
  `local.properties`.

Kunci Supabase di aplikasi hanya lewat `--dart-define`
(`SUPABASE_URL`, `SUPABASE_ANON_KEY`) di `lib/core/app_config.dart`,
dengan nilai default kosong sehingga aplikasi jalan mode lokal bila
tidak diisi. Kunci anon/publishable memang dirancang untuk disematkan
di klien; yang tidak boleh ada adalah `service_role` — dan kunci itu
tidak ditemukan di mana pun.

### 2.3 Token sesi, PIN, dan kunci Gemini di aplikasi

- **Token sesi:** tidak ada penyimpanan token manual. Login Google
  memakai `Supabase.instance.client.auth.signInWithOAuth` dan keluar
  memakai `signOut()` (`lib/features/auth/auth_page.dart`). Token
  diurus `supabase_flutter`. Grep `accessToken`, `refreshToken`,
  `setSession`, dan `SharedPreferences` di `lib/` tidak menemukan
  penyimpanan token manual (dependensi `shared_preferences` tercantum
  di `pubspec.yaml` tetapi tidak dipakai di `lib/`).
- **PIN:** `lib/features/auth/pin_service.dart` menyimpan PIN sebagai
  hash SHA-256 dengan salt acak per perangkat
  (`sha256("$salt::$pin")`), di `FlutterSecureStorage`. PIN tidak
  pernah disimpan plaintext. Biometrik memakai `local_auth` sistem,
  tanpa menyimpan data biometrik. Lihat temuan sedang nomor 2 dan
  temuan rendah nomor 4 soal penegakan dan kekuatan PIN.
- **Kunci Gemini:** tidak ada di APK. `lib/features/ai_diagnosis/
  ai_diagnosis.dart` hanya memanggil Edge Function `ai-diagnose`
  lewat `Supabase.instance.client.functions.invoke`. Kunci dibaca
  server dari secret `GEMINI_API_KEY`.
- **Payment gateway:** tidak ada. Grep `midtrans`, `xendit`,
  `stripe`, `in_app_purchase`, `google_pay`, `payment`, `bayar`,
  dan `qris` di `lib/`, `pubspec.yaml`, dan manifest hanya menemukan
  kalimat "tanpa payment gateway" di `supabase/README.md`. Dependensi
  di `pubspec.yaml` tidak berisi paket pembayaran.

### 2.4 Izin Android (`AndroidManifest.xml`)

| Izin | Kebutuhan |
| --- | --- |
| `INTERNET` | Wajib (cek kecepatan, Edge Function). |
| `ACCESS_WIFI_STATE`, `ACCESS_NETWORK_STATE` | Info WiFi dan status jaringan. |
| `ACCESS_FINE_LOCATION` | SSID di Android 10+ butuh izin lokasi; diminta saat runtime bila perlu. |
| `USE_BIOMETRIC` | Kunci biometrik (`local_auth`). |
| `QUERY_ALL_PACKAGES` | Daftar aplikasi terpasang untuk Dokter Keamanan. |

Tidak ada izin berbahaya lain (tanpa kamera, mikrofon, SMS, kontak,
atau lokasi latar belakang). `QUERY_ALL_PACKAGES` adalah izin sensitif
di Play Store dan membutuhkan deklarasi/pembenaran saat rilis — lihat
temuan rendah nomor 5. `allowBackup="false"` sudah diatur.

### 2.5 MainActivity.kt

API yang dipakai standar dan sesuai kebutuhan fitur:

- `WifiManager` (RSSI, link speed, frekuensi), `ConnectivityManager`
  (server DNS), `StatFs` (info penyimpanan), `ActivityManager`
  (info RAM), `PackageManager` (daftar aplikasi terpasang, izin yang
  diminta, waktu instalasi).
- MethodChannel `com.adiprmx.dokterhp/native` hanya menyediakan:
  `wifiRssi`, `wifiLinkSpeed`, `wifiFrequency`, `dnsServers`,
  `openWifiSettings` (membuka halaman pengaturan WiFi sistem),
  `storageInfo`, `memoryInfo`, `cacheSizeBytes`, `clearCache`
  (hanya menghapus cache aplikasi sendiri), `installedApps`.
- Tidak ada akses berbahaya: tidak ada eksekusi perintah shell, tidak
  ada akses root, tidak ada pengiriman data ke server pihak ketiga,
  dan semua metode mengembalikan null/kosong bila data tidak tersedia
  (Dart menampilkan "tidak tersedia", bukan angka palsu).
- Endpoint jaringan di `lib/features/wifi_doctor/wifi_service.dart`
  hanya URL publik untuk uji kecepatan dan deteksi captive portal:
  `speed.cloudflare.com`, `proof.ovh.net`, dan
  `google.com/generate_204`.

### 2.6 Edge Function

- `ai-diagnose`: membaca `GEMINI_API_KEY` dari secret server, memakai
  model `gemini-2.0-flash` lewat `generativelanguage.googleapis.com`.
  `config.toml` mengatur `verify_jwt = true` sehingga gateway Supabase
  menolak pemanggil tanpa JWT pengguna yang valid. Di dalam function
  sendiri tidak ada pemeriksaan JWT tambahan — masih aman selama
  `verify_jwt` tetap aktif saat deploy (lihat catatan di temuan
  rendah nomor 9).
- `fcm-notify`: `verify_jwt = true` juga, tetapi tidak ada otorisasi
  per pengguna — lihat temuan sedang nomor 3. Token FCM memakai secret
  `FCM_ACCESS_TOKEN` yang dimasukkan manual dan berumur pendek; berkas
  function sendiri sudah menulis bahwa untuk produksi harus diganti
  penukaran token otomatis dari service account (lihat temuan rendah
  nomor 8).

## 3. Screenshot visual

Dibuat dengan widget test (`test/qa_screenshot_test.dart`, memakai
`matchesGoldenFile`), ukuran layar HP 390x844 @2x, semua channel
platform di-mock agar layar me-render kondisi "tidak ada data
perangkat" yang jujur. Berkas golden tersimpan di `test/goldens/`
dan disalin ke `docs/screenshots/` dengan prefix `qa-`:

| Layar | Berkas | Hasil visual |
| --- | --- | --- |
| Dashboard | `docs/screenshots/qa-dashboard.png` | Kartu dan empty state jujur tampil. |
| Dokter WiFi | `docs/screenshots/qa-wifi.png` | Empty state sebelum pemeriksaan tampil. |
| Baterai | `docs/screenshots/qa-baterai.png` | Kartu level 82 (mock) dan detail tampil. |
| Penyimpanan | `docs/screenshots/qa-penyimpanan.png` | Info penyimpanan (mock null = tidak tersedia) tampil. |
| Performa | `docs/screenshots/qa-performa.png` | **Masih menampilkan spinner loading** (lihat temuan rendah nomor 6). |
| Keamanan | `docs/screenshots/qa-keamanan.png` | Empty state jujur "Daftar aplikasi tidak tersedia" tampil. |
| Riwayat | `docs/screenshots/qa-riwayat.png` | Empty state riwayat kosong tampil. |

**Keterbatasan yang wajib diketahui:**

1. Teks pada screenshot QA tampil sebagai balok hitam, bukan huruf.
   Ini perilaku standar font test Flutter (`flutter_test` memakai
   font pengganti), bukan kerusakan aplikasi. Struktur layout,
   kartu, dan state terlihat dan bisa dinilai; keterbacaan teks
   tidak bisa dinilai dari berkas ini. Agen UI membuat screenshot
   terpisah dengan font Roboto asli (`test/zz_tmp_visual_test.dart`)
   untuk keperluan itu.
2. Build web sebagai jalan alternatif screenshot tidak dicoba sampai
   selesai: `lib/data/local/app_database.dart` mengimpor `dart:io`
   dan `drift/native.dart`, sehingga aplikasi tidak dapat dikompilasi
   untuk web tanpa perubahan kode. Screenshot perangkat nyata tetap
   menjadi verifikasi visual yang paling benar.
3. Pita diagonal merah-putih di pojok kanan atas adalah banner
   "DEBUG" bawaan Flutter yang ikut ter-render di golden test.

## 4. Daftar temuan

Tingkat: kritis = data bocor / aplikasi tidak bisa dipakai;
sedang = fitur yang dijanjikan tidak jalan atau celah keamanan nyata;
rendah = pengerasan dan kebersihan yang sebaiknya diperbaiki.

### Sedang

**S-1. Sinkronisasi Supabase memakai nama kolom yang tidak ada di
migrasi, sehingga selalu gagal diam-diam.**
`lib/data/sync/supabase_sync_service.dart` mengirim `upsert` dengan
kolom lokal Drift (`score`, `category`, `summary`, `created_at`,
`download_kbps`, `rssi_dbm`, `recommendation`, `updated_at`), sementara
migrasi memakai nama lain (`skor`, `ringkasan`, `dibuat_pada`,
`kecepatan_koneksi_mbps`, `kekuatan_sinyal`, `rekomendasi`) dan tidak
ada kolom-kolom lokal tersebut di server. Lebih penting lagi, `upsert`
tidak mengirim `user_id` (wajib `not null` di semua tabel dan syarat
policy RLS `auth.uid() = user_id`), sehingga insert pasti ditolak.
Semua error ditelan `catch (_) {}` tanpa log, jadi baris tetap
`pending` selamanya tanpa ada yang tahu. Dampak: fitur sinkronisasi
riwayat yang dijanjikan README tidak pernah berhasil; data lokal aman
(tidak hilang). Perbaikan yang diperlukan: petakan kolom lokal ke
kolom server (`score` menjadi `skor`, `summary` menjadi `ringkasan`
jsonb, `download_kbps` menjadi `kecepatan_koneksi_mbps` dalam Mbps,
`recommendation` menjadi `rekomendasi`, dan seterusnya), sertakan
`user_id` dari `Supabase.instance.client.auth.currentUser`, dan
catat kegagalan ke log agar tidak diam-diam. Tidak diperbaiki di
ronde QA ini karena perubahannya menyentuh pemetaan data dan belum
bisa diuji tanpa proyek Supabase live.

**S-2. PIN bisa diatur tetapi tidak pernah ditegakkan.**
`PinService.periksaPin()` tidak memiliki satu pun pemanggil di `lib/`
(pencarian menemukan pemakaian hanya di `pin_service.dart` sendiri).
`lib/app.dart` langsung menampilkan `DashboardPage` tanpa gerbang
kunci, dan `lib/main.dart` juga tidak memeriksa PIN. Akibatnya,
pengguna yang mengatur PIN tidak mendapat perlindungan apa pun saat
aplikasi dibuka. Perbaikan: tambahkan gerbang kunci di startup yang
memanggil `periksaPin` bila PIN sudah diatur, sebelum dashboard
ditampilkan.

**S-3. Edge Function `fcm-notify` adalah relay push terbuka bagi
pengguna login mana pun.**
`supabase/functions/fcm-notify/index.ts` tidak memeriksa siapa
pengirim dan tidak memeriksa apakah token FCM tujuan milik pengirim.
`verify_jwt = true` di `config.toml` hanya memastikan pemanggil sudah
login — pengguna login mana pun bisa mengirim notifikasi push ke
token perangkat mana pun dan membakar kuota FCM. Perbaikan: di dalam
function, verifikasi JWT, ambil `user_id` dari token, dan hanya
izinkan pengiriman ke token yang terdaftar atas pengguna itu
(misalnya simpan pemetaan token perangkat per pengguna di tabel
server), serta batasi rate.

### Rendah

**R-1. PIN memakai SHA-256 sekali jalan tanpa iterasi dan tanpa batas
percobaan gagal.**
SHA-256 dengan salt acak sudah benar arahnya (bukan plaintext), tetapi
fungsi hash yang cepat membuat PIN 4 digit (10.000 kombinasi) murah
untuk brute force bila isi `FlutterSecureStorage` berhasil diekstrak.
Tidak ada jeda atau kunci setelah percobaan gagal berulang (tidak ada
logika lockout di `pin_service.dart` maupun `auth_page.dart`).
Rekomendasi: tambah hitung percobaan gagal dengan jeda bertambah dan
kunci sementara; bila memungkinkan, ganti ke derivasi kunci yang
lambat (misalnya PBKDF2) saat format penyimpanan berikutnya diubah.

**R-2. Halaman Performa tidak selesai memuat di lingkungan widget
test.**
Screenshot `qa-performa.png` masih menampilkan spinner loading.
`_muat()` di `performance_page.dart` membaca `/proc/stat` dua kali
dan `/sys/class/thermal`, yang di lingkungan `flutter_test`
(FakeAsync) tidak kunjung selesai; percobaan memakai `runAsync`
dengan jeda nyata 2 detik tidak mengubah hasil. Di perangkat nyata
semua langkah itu dibungkus try/catch dan mengembalikan null, jadi
halaman seharusnya selesai memuat — tetapi hal itu **belum terbukti
di perangkat nyata** dan wajib dicek saat uji perangkat.

**R-3. Peringatan analyze dari berkas sementara agen UI.**
`test/zz_tmp_visual_test.dart:2:8` — import `dart:ui` tidak terpakai.
Berkas ini milik agen UI dan rencananya dihapus setelah screenshot
selesai; bila tidak dihapus, CI `flutter analyze` akan gagal.
Koordinator perlu memastikan berkas itu terhapus sebelum push.

**R-4. `QUERY_ALL_PACKAGES` adalah izin sensitif Play Store.**
Izin ini diperlukan untuk Dokter Keamanan, tetapi Google Play meminta
deklarasi dan pembenaran untuk izin tersebut dan dapat menolak
aplikasi tanpa alasan yang jelas. Siapkan justifikasi rilis; bila
ditolak, pertimbangkan membatasi ke paket yang terdeteksi lewat
cara lain.

**R-5. Token FCM dimasukkan manual dan berumur pendek.**
`fcm-notify` memakai secret `FCM_ACCESS_TOKEN` yang harus diperbarui
manual. Bila token kedaluwarsa, semua push gagal dengan 500. Ikuti
catatan di berkas function itu sendiri: ganti dengan penukaran token
otomatis dari service account Firebase sebelum pemakaian produksi.

**R-6. `ai-diagnose` bergantung sepenuhnya pada `verify_jwt` di
gateway.**
Function tidak memeriksa JWT sendiri. Ini masih aman selama
`config.toml` tetap mengatur `verify_jwt = true` saat deploy, tetapi
bila seseorang men-deploy dengan verifikasi dimatikan, siapa pun
dengan anon key bisa memakai kuota Gemini. Pertimbangkan pemeriksaan
JWT eksplisit di dalam function sebagai pertahanan lapis kedua.

**R-7. Dependensi `shared_preferences` tidak dipakai di `lib/`.**
Tercantum di `pubspec.yaml` tetapi tidak ada pemakaian di kode.
Hapus bila memang tidak dibutuhkan, agar permukaan dependensi tetap
kecil.

## 5. Yang sudah diperbaiki di ronde QA ini

**P-1. Nama field request Diagnosis AI diperbaiki
(`lib/features/ai_diagnosis/ai_diagnosis.dart`).**
Dart mengirim `{'keluhan': ..., 'data_perangkat': ...}`, sementara
Edge Function `ai-diagnose` membaca `gejala` dan `hasil_pemeriksaan`
dan menolak request dengan 400 "Kolom 'gejala' wajib diisi" bila
`gejala` kosong. Akibatnya Diagnosis AI selalu gagal saat server
aktif. Body request diubah menjadi `{'gejala': keluhan,
'hasil_pemeriksaan': dataPerangkat}` beserta komentar penjelas.
Respons function (`{diagnosis}`) sudah cocok dengan pembacaan di
Dart (`data['jawaban'] ?? data['diagnosis'] ?? data['hasil']`),
jadi tidak ada perubahan di sisi itu. Verifikasi: `flutter analyze`
tetap bersih untuk berkas ini dan seluruh suite test tetap hijau
(48/48). Perilaku end-to-end (panggilan nyata ke Edge Function)
belum bisa diuji tanpa proyek Supabase live.

**P-2. Tes screenshot QA ditambahkan
(`test/qa_screenshot_test.dart`).**
Tujuh test golden yang menghasilkan screenshot 7 layar utama
(lihat bagian 3). Selama pembuatan ditemukan dua hal yang ikut
diperbaiki di harness: mock EventChannel `charging` milik
`battery_plus` (tanpa mock, aktivasi stream melempar
`MissingPluginException` dan test gagal) dan fallback
`pumpAndSettle` bertimeout agar halaman yang masih loading tetap
menghasilkan screenshot.

## 6. Yang masih terbuka

1. S-1 (sinkronisasi kolom tidak cocok) — butuh perbaikan pemetaan +
   `user_id` + uji live ke Supabase.
2. S-2 (PIN tidak ditegakkan) — butuh gerbang kunci di startup.
3. S-3 (relay push `fcm-notify`) — butuh otorisasi per pengguna.
4. R-1 sampai R-7 di atas.
5. Verifikasi di perangkat Android nyata belum dilakukan: build APK
   release, halaman Performa, PIN, login Google, Diagnosis AI, dan
   sinkronisasi. CI GitHub (`.github/workflows/build-apk.yml`)
   sudah menjalankan `flutter analyze`, `flutter test`, dan build APK
   release dengan Supabase dari secrets — tetapi hasil CI tidak
   diperiksa di ronde ini.
6. RLS baru diverifikasi dari file SQL, belum diuji live dengan anon
   key terhadap proyek Supabase.

## 7. Perubahan berkas di ronde ini

| Berkas | Perubahan |
| --- | --- |
| `lib/features/ai_diagnosis/ai_diagnosis.dart` | Perbaikan P-1 (nama field request). |
| `test/qa_screenshot_test.dart` (baru) | Harness screenshot 7 layar (P-2). |
| `test/goldens/qa-*.png` (baru, 7 berkas) | Hasil golden screenshot test. |
| `docs/screenshots/qa-*.png` (baru, 7 berkas) | Salinan screenshot untuk laporan. |
| `QA_REPORT.md` (baru) | Laporan ini. |

Tidak ada perubahan di folder `supabase/`. Tidak ada push ke GitHub.

---

## 8. Ronde v1.1.0: verifikasi rancang ulang (12 Nov 2026)

Auditor: Lead QA (agen QA). Acuan: `docs/redesign-v11-spec.md`,
`DESIGN.md`, checklist v1.1.0 di `DESIGN_AUDIT.md` bagian 9-12.
Laporan before/after lengkap per layar:
`docs/redesign-v11-before-after.md`.

Versi TIDAK berubah di ronde ini (tetap 1.0.1+2). Tidak ada push,
tidak ada release, tidak ada perubahan `CHANGELOG.md`.

### 8.1 Bukti test

- `flutter analyze`: 0 issue ("No issues found!").
- `flutter test` (tanpa dart-define): 98/98 lulus, 10 skip
  (9 test tangkap layar + 1 test golden logo, keduanya hanya jalan
  dengan dart-define). Saat serah terima tim implementasi: 94/94.
  Kenaikan 4 test berasal dari QA: 2 golden baru (AI Diagnosis,
  Akun) + 2 test regresi chip.
- `flutter test --dart-define=QA_CAPTURE=true`: 9/9 tangkapan
  screenshot berhasil.
- Golden logo Google (dart-define Supabase contoh): lulus,
  `test/goldens/qa-akun-login.png` dibuat; logo G ter-render wajar.
- Klaim tim implementasi terverifikasi independen: analyze 0 issue,
  test 94/94 saat serah terima, nol kata terlarang di `lib/` +
  `test/`, nol em dash di string UI, tema gelap, 9 layar ditulis
  ulang. Semua benar.
- Tidak ada test logika yang dilonggarkan (`health_score`,
  `wifi_logic`, `wifi_fix`, `wifi_live_sustained`, `lock_gate`,
  `supabase_sync` tidak disentuh).

### 8.2 Kepatuhan 13 aturan mengikat

Semua 13 aturan spesifikasi bagian 5 LOLOS (bukti per aturan di
`docs/redesign-v11-before-after.md`). Sorotan: kontras dihitung
ulang independen (rumus WCAG), cocok dengan tabel spesifikasi;
`textFaint` (#757575) hanya dipakai di tombol nonaktif (dikecualikan
WCAG) dan footer versi Akun di latar hitam (4,56:1, lolos); panduan
WiFi diverifikasi verbatim kata per kata; tidak ada data dummy,
emoji, warna dekoratif, atau ikon terlarang di UI.

### 8.3 Temuan dan perbaikan di ronde ini

1. **Chip melebar selebar layar (bug aplikasi nyata, DIPERBAIKI).**
   `StatusChip` dan `LiveChip` di `lib/core/widgets/common_widgets.dart`
   tampil selebar layar bila diletakkan langsung di ListView/Column
   (terbukti di layar Akun: chip "Mode lokal" jadi bar selebar layar).
   Perbaikan: bungkus `Container` dengan `UnconstrainedBox` rata kiri.
   `Row` mainAxisSize.min dan `IntrinsicWidth` dicoba dan GAGAL
   dibuktikan test (kendala ketat memaksa ukuran selebar parent).
   Ditambah 2 test regresi di `test/redesign_widget_test.dart`.
   Dampak terukur: hanya `qa-akun.png` (dari 10 golden) dan
   `akun-v11.png` (dari 9 screenshot) yang berubah.
2. **Em dash di komentar kode (pembersihan kecil).** 4 em dash di
   komentar diganti koma/titik (`device_native.dart:37`,
   `wifi_service.dart:317`, `dashboard_widget_test.dart:59`,
   `qa_screenshot_test.dart:31`). Non-fungsional.
3. **Import tidak perlu (lint).** `dart:typed_data` dihapus dari
   `test/qa_capture_v11_test.dart` setelah analyze melaporkan
   `unnecessary_import`. Analyze kembali 0 issue.
4. **Harness tangkap layar (test saja, 2 bug diperbaiki).**
   `test/qa_capture_v11_test.dart` (baru): tangkapan pertama
   menggantung karena `toImage()` tidak selesai di zona FakeAsync
   (diperbaiki dengan `tester.runAsync()`); judul AppBar dan label
   tombol tetap balok Ahem karena tema menggantikan gaya teks
   ambient tanpa fontFamily (diperbaiki dengan `temaHarness()` yang
   menerapkan fontFamily Roboto ke gaya teks tema). Screenshot baru
   memakai font Roboto asli, bukan Ahem.
5. **Penyimpangan spesifikasi yang dikonfirmasi (bukan bug):** sel
   grid dashboard 184 px (spesifikasi min 96, patuh; tidak meluap
   lagi di 390 px, dibuktikan golden + hitungan manual); kotak digit
   PIN lebar fleksibel (8x48 px = 440 px melebihi lebar konten
   350 px, jadi lebar tetap mustahil); chip "Mengisi daya" pakai
   `battery_charging_full`; skala suhu 20-60 derajat C; tombol muat
   ulang di AppBar Keamanan; logo Google CustomPainter; judul
   riwayat "Skor 82 (Baik)" vs contoh spesifikasi "Skor 82, Baik";
   shimmer skeleton gradasi monokrom (diwajibkan spesifikasi 4.8).
6. **Catatan kecil (bukan bug):** splash LockGate memakai gaya teks
   body default, bukan headline 28/700 (splash boot di `main.dart`
   sudah sesuai); keterangan sel grid dashboard terpotong elipsis
   di lebar 390 px (sesuai desain, copy spesifikasi).

### 8.4 Screenshot baru

Sembilan berkas di `docs/screenshots/` (780x1688, Roboto asli,
permukaan 390x844 @2.0). Berkas lama TIDAK ditimpa:
`dashboard-v11.png`, `wifi-v11.png`, `baterai-v11.png`,
`penyimpanan-v11.png`, `performa-v11.png`, `keamanan-v11.png`,
`riwayat-v11.png`, `ai-diagnosis-v11.png`, `akun-v11.png`.
Golden bertambah dari 7 menjadi 10 (`qa-ai-diagnosis.png`,
`qa-akun.png`, `qa-akun-login.png`).

### 8.5 Perubahan berkas di ronde ini

| Berkas | Perubahan |
| --- | --- |
| `lib/core/widgets/common_widgets.dart` | Perbaikan chip (UnconstrainedBox) + komentar. |
| `lib/data/native/device_native.dart`, `lib/data/wifi/wifi_service.dart` | Em dash di komentar dibersihkan. |
| `test/redesign_widget_test.dart` | +2 test regresi chip (16 menjadi 18 test). |
| `test/qa_screenshot_test.dart` | +3 test golden (AI Diagnosis, Akun, Akun masuk Google) + mock auth. |
| `test/qa_capture_v11_test.dart` (baru) | Harness tangkap 9 layar, font Roboto asli, gated `QA_CAPTURE=true`. |
| `test/goldens/qa-ai-diagnosis.png`, `qa-akun.png`, `qa-akun-login.png` (baru) | Golden baru. `qa-akun.png` diregenerasi setelah perbaikan chip. |
| `test/dashboard_widget_test.dart`, `test/qa_screenshot_test.dart` | Em dash di komentar dibersihkan. |
| `docs/screenshots/*-v11.png` (baru, 9 berkas) | Screenshot rancang ulang. |
| `docs/redesign-v11-before-after.md` (baru) | Laporan before/after per layar. |
| `QA_REPORT.md` | Bagian 8 ini. |

### 8.6 Masih terbuka (hanya bisa dibuktikan di HP fisik)

1. State terisi: dashboard berskor, panel hasil WiFi, tes bertahan
   selesai + grafik, riwayat berisi, daftar aplikasi Keamanan berisi,
   Performa termuat.
2. Logo Google CustomPainter di perangkat nyata.
3. Render font di perangkat nyata (harness memakai Roboto SDK).
4. Build APK release (tugas CI; Gradle lokal rusak di VM ini,
   bukan salah kode).
5. RLS Supabase baru diverifikasi dari file SQL (temuan lama
   bagian 6, masih berlaku).
