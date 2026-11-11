# PRODUCT.md: Dokter HP

> **Dokumen ini adalah spesifikasi produk (PRD) Dokter HP v1.0.0.**
> Bahasa: Bahasa Indonesia. Status: v1.0.0 selesai. Audit desain
> dan tulisan 11 November 2026 sudah diterapkan, `flutter analyze`
> bersih dan `flutter test` hijau (39/39).

---

## 1. Nama dan tujuan

**Dokter HP** adalah aplikasi Android yang mendeteksi, menjelaskan, dan
membantu memperbaiki masalah HP sehari-hari: WiFi lemot, baterai boros,
penyimpanan penuh, performa berat, dan keamanan.

### 1.1 Latar belakang

Pengguna mengalami WiFi lemot parah:

- WiFi ACHA, router ZTE F660, WiFi 4 (802.11n).
- Kecepatan koneksi 65 Mbps, sinyal sangat bagus.
- Kecepatan unduh turun dari 50 KB/detik ke 3,2 KB/detik.
- HP lain di jaringan yang sama normal.
- Data seluler lancar tetapi tidak ada kuota.

Aplikasi ini menjawab kasus itu secara langsung: ukur kecepatan nyata di
perangkat, tunjukkan apakah masalah ada di WiFi atau di HP, beri
rekomendasi yang bisa dilakukan (termasuk ganti channel router 2,4 GHz),
dan jelaskan jujur langkah yang tidak bisa dilakukan aplikasi karena
batasan Android.

### 1.2 Tujuan produk

1. Pengguna tahu kondisi nyata HP-nya dalam satu ketuk (skor 0-100).
2. Pengguna tahu kecepatan WiFi sebenarnya, bukan sekadar "sinyal penuh".
3. Pengguna mendapat langkah perbaikan yang nyata, bukan janji palsu.
4. Semua data tersimpan lokal; server bersifat opsional.

### 1.3 Bukan tujuan

- Bukan aplikasi penguat sinyal, bukan VPN, bukan "pembersih RAM" yang
  menutup paksa aplikasi lain (Android melarangnya).
- Bukan pengganti teknisi untuk kerusakan perangkat keras.
- Bukan alat pembayaran. Tanpa payment gateway.

## 2. Pengguna

| Aspek | Keterangan |
|---|---|
| Pengguna utama | Pemilik HP Android umum, bukan teknisi |
| Perangkat | Android 7.0 (API 23) ke atas |
| Bahasa | Bahasa Indonesia |
| Kondisi | Bekerja dari HP, tanpa PC; koneksi internet kadang lemot |

## 3. Fitur v1

### 3.1 Dashboard

- Skor kesehatan HP 0-100 beserta kategori (Baik / Cukup / Perlu
  perhatian).
- Tombol **Diagnosis satu ketuk**: membaca baterai, penyimpanan, dan RAM
  dari perangkat, menghitung skor, lalu menyimpan hasilnya ke riwayat.
- Kartu tiap dokter: WiFi, Baterai, Penyimpanan, Performa, Keamanan, AI.
- Banner status jujur: "Mode lokal, belum tersambung ke server" bila
  Supabase belum dikonfigurasi.
- Tiga pemeriksaan terakhir.

### 3.2 Dokter WiFi (fitur utama)

- **Tes kecepatan unduh**: mengunduh file 1 MB dari server publik
  (Cloudflare, cadangan OVH) dengan timeout 15 detik; hasil dalam
  KB/detik atau MB/detik. Klasifikasi: sangat lambat (< 50), lambat
  (< 200), cukup (< 1000), cepat (< 5000), sangat cepat (>= 5000).
- **Latensi HTTP**: round-trip request kecil; dilabeli "latensi HTTP"
  karena aplikasi pihak ketiga tidak bisa mengirim ping ICMP mentah.
- **Info jaringan**: SSID, alamat IP, gateway, DNS, kekuatan sinyal
  (RSSI dBm + label), kecepatan koneksi (link speed Mbps), channel
  (dari frekuensi).
- **Rekomendasi**: pindah dekat router bila sinyal lemah; tutup unduhan
  lain bila latensi tinggi; ganti channel router ke 1, 6, atau 11 di
  pita 2,4 GHz (hanya ketiganya yang tidak saling tumpang tindih).
- **Perbaikan**: tombol membuka pengaturan WiFi sistem; penjelasan
  langkah manual ganti DNS (1.1.1.1 / 8.8.8.8), lupakan jaringan, dan
  ganti channel router (contoh ZTE F660).
- **Bagikan hasil**: teks ringkasan lewat sheet berbagi sistem.
- Hasil pemeriksaan tersimpan otomatis ke riwayat lokal.

### 3.3 Dokter Baterai

- Level baterai (%), status (mengisi / dipakai / penuh), mode hemat daya.
- Estimasi waktu pakai dengan label jelas sebagai perkiraan (asumsi
  pemakaian rata-rata 10% per jam), bukan pengukuran pasti.
- Penjelasan jujur: daftar aplikasi boros baterai tidak bisa ditampilkan
  karena Android tidak membuka data itu untuk aplikasi pihak ketiga;
  pengguna diarahkan ke Pengaturan > Baterai.
- Tips merawat baterai.

### 3.4 Dokter Penyimpanan

- Total, terpakai, dan kosong (StatFs Android) beserta bilah pemakaian.
- Ukuran cache aplikasi Dokter HP sendiri.
- Tombol **Bersihkan cache** dengan dialog konfirmasi: hanya cache
  aplikasi ini yang dihapus; foto, chat, dan file lain tidak disentuh.

### 3.5 Dokter Performa

- RAM total dan kosong (ActivityManager) beserta bilah pemakaian.
- Pemakaian CPU dari `/proc/stat` (dua sampel, jeda 1 detik).
- Suhu perangkat dari sensor thermal bila file sistem bisa dibaca;
  bila tidak, tampil "tidak tersedia".
- Info perangkat: merek/model, versi Android, prosesor.
- Penjelasan jujur: aplikasi tidak bisa menutup aplikasi lain;
  pengguna diarahkan ke layar aplikasi terakhir atau mulai ulang HP.
- Tombol muat ulang.

### 3.6 Dokter Keamanan

- Daftar aplikasi pengguna terpasang dari PackageManager.
- Jumlah izin berbahaya per aplikasi (lokasi, kamera, mikrofon, SMS,
  kontak, dan sejenisnya).
- Bagian "Perlu ditinjau": aplikasi non-sistem dengan 4+ izin berbahaya.
- Tanggal pemasangan tiap aplikasi.
- Saran: tinjau dan hapus lewat Pengaturan > Aplikasi bila tidak dikenal.

### 3.7 Riwayat

- Daftar pemeriksaan kesehatan dan WiFi dari database lokal (Drift).
- Hapus dengan geser (soft-delete: `deleted_at` diisi, baris tidak
  dihapus permanen).
- Laporan PDF berisi kedua riwayat; dibagikan lewat sheet sistem
  (WhatsApp dan aplikasi lain).

### 3.8 Akun dan keamanan

- **Login Google via Supabase**: hanya bila Supabase terkonfigurasi.
  Mode lokal menampilkan kondisi jujur dan menyembunyikan tombol login.
- **PIN lokal**: 4-8 digit angka, disimpan sebagai hash SHA-256 + salt
  di `flutter_secure_storage`; PIN asli tidak pernah disimpan.
- **Gerbang kunci**: bila PIN sudah diatur, aplikasi menampilkan layar
  kunci PIN/biometrik sebelum dashboard setiap kali dibuka
  (`LockGate` di `lib/features/auth/lock_gate.dart`). Bila PIN belum
  diatur, aplikasi langsung terbuka tanpa memaksa; penawaran mengatur
  PIN ada di halaman ini. Setelah 5 kali PIN salah berturut-turut,
  masukan dikunci 30 detik.
- **Pemulihan bila PIN lupa**: PIN hanya tersimpan lokal sebagai hash,
  jadi tidak ada reset lewat server dan akun Supabase pengguna tidak
  ikut terkunci. Satu-satunya jalan pemulihan adalah menghapus data
  aplikasi lewat Pengaturan Android > Aplikasi > Dokter HP >
  Penyimpanan > Hapus data, lalu membuka kembali aplikasi dan
  mengatur PIN baru. Riwayat yang sudah tersinkron ke server tetap
  aman dan kembali setelah masuk; riwayat lokal yang belum
  tersinkron akan hilang. Jalan ini dijelaskan di layar kunci
  (dialog "Lupa PIN?") dan di halaman ini.
- **Biometrik**: sidik jari/wajah lewat autentikasi sistem
  (`local_auth`); data biometrik tidak pernah disimpan aplikasi.

### 3.9 Diagnosis AI

- Kirim keluhan + ringkasan data perangkat ke Supabase Edge Function
  `ai-diagnose` dan tampilkan jawabannya.
- Kunci Gemini TIDAK PERNAH ada di APK. Kunci hanya tersimpan sebagai secret
  di sisi server Supabase.
- Mode lokal: fitur menampilkan pesan jujur bahwa Diagnosis AI belum
  tersedia.
- Jawaban AI dilabeli sebagai saran, bukan vonis pasti.

## 4. Fitur v2 (rencana, belum dikerjakan)

- Sinkronisasi riwayat ke Supabase bila pengguna masuk — pemetaan
  kolom, `user_id`, dan penandaan gagal sudah diterapkan di
  `SupabaseSyncService` (temuan QA S-1, 11 Nov 2026); verifikasi
  live ke proyek Supabase masih menunggu (belum ada proyek yang
  terhubung dari workdir ini).
- Diagnosis AI memakai ringkasan data perangkat otomatis.
- Notifikasi bila skor kesehatan turun.
- Panduan router per merek (ZTE, Huawei, TP-Link) berdasarkan hasil ukur.
- Pemeriksaan berkala otomatis (mingguan).
- Widget layar utama untuk skor kesehatan.

## 5. Alur pengguna

### 5.1 Alur utama (kasus WiFi lemot)

1. Buka aplikasi → Dashboard menampilkan banner mode lokal/server.
2. Ketuk kartu **Dokter WiFi**.
3. Ketuk **Periksa WiFi sekarang** → progres tahap demi tahap
   (info jaringan → kecepatan unduh → latensi).
4. Hasil tampil: kecepatan unduh, klasifikasi, SSID, IP, DNS, sinyal,
   channel, latensi, dan rekomendasi.
5. Bila kecepatan sangat lambat dan sinyal bagus: rekomendasi mengarah
   ke channel router atau gangguan jaringan, bukan ke HP.
6. Ikuti langkah perbaikan (buka pengaturan WiFi / ubah channel di
   admin router).
7. Ketuk **Bagikan hasil pemeriksaan** bila perlu diteruskan.
8. Hasil tersimpan otomatis; lihat lagi di **Riwayat**.

### 5.2 Alur diagnosis satu ketuk

1. Buka aplikasi → ketuk **Diagnosis satu ketuk**.
2. Skor 0-100 tampil beserta penjelasan per komponen.
3. Skor tersimpan ke riwayat; tiga pemeriksaan terakhir tampil di
   dashboard.

### 5.3 Alur kunci aplikasi

1. Buka **Akun dan keamanan** (ikon orang di dashboard).
2. Atur PIN 4-8 digit → disimpan sebagai hash.
3. Aktifkan biometrik bila perangkat mendukung → uji langsung.
4. Tutup lalu buka kembali aplikasi → layar kunci tampil sebelum
   dashboard; masukkan PIN (atau biometrik bila aktif) untuk membuka.
5. Bila PIN lupa: ketuk "Lupa PIN?" di layar kunci dan ikuti jalan
   pemulihan di sana (hapus data aplikasi lewat Pengaturan Android;
   akun dan data server tetap aman, lihat bagian 3.8).
6. Masuk Google (bila server tersambung) untuk sinkronisasi.

### 5.4 Alur laporan PDF

1. Buka **Riwayat** (ikon jam di dashboard).
2. Ketuk ikon bagikan → laporan PDF dibuat dari data tercatat →
   pilih WhatsApp atau aplikasi lain di sheet sistem.

## 6. Layar

| # | Layar | File |
|---|---|---|
| 1 | Dashboard | `lib/features/dashboard/dashboard_page.dart` |
| 2 | Dokter WiFi | `lib/features/wifi_doctor/wifi_doctor_page.dart` |
| 3 | Dokter Baterai | `lib/features/battery/battery_page.dart` |
| 4 | Dokter Penyimpanan | `lib/features/storage/storage_page.dart` |
| 5 | Dokter Performa | `lib/features/performance/performance_page.dart` |
| 6 | Dokter Keamanan | `lib/features/security/security_page.dart` |
| 7 | Riwayat pemeriksaan | `lib/features/history/history_page.dart` |
| 8 | Akun dan keamanan | `lib/features/auth/auth_page.dart` |
| 9 | Diagnosis AI | `lib/features/ai_diagnosis/ai_diagnosis.dart` |

## 7. Data model

### 7.1 health_checks (Drift / SQLite lokal)

| Kolom | Tipe | Keterangan |
|---|---|---|
| id | TEXT (PK) | ID unik (`hc-<microseconds>`) |
| score | INTEGER | Skor 0-100 |
| category | TEXT | `baik` / `cukup` / `buruk` |
| summary | TEXT? | Ringkasan komponen skor |
| created_at | DATETIME | Waktu pemeriksaan |
| updated_at | DATETIME | Terakhir diubah |
| deleted_at | DATETIME? | Soft-delete (null = aktif) |
| sync_status | TEXT | `pending` / `synced` / `local_only` |

### 7.2 wifi_reports (Drift / SQLite lokal)

| Kolom | Tipe | Keterangan |
|---|---|---|
| id | TEXT (PK) | ID unik (`wr-<microseconds>`) |
| ssid | TEXT? | Nama WiFi |
| download_kbps | REAL? | Kecepatan unduh terukur |
| ping_ms | INTEGER? | Latensi HTTP (ms) |
| rssi_dbm | INTEGER? | Kekuatan sinyal |
| channel | INTEGER? | Channel WiFi |
| recommendation | TEXT? | Rekomendasi yang diberikan |
| created_at | DATETIME | Waktu pemeriksaan |
| updated_at | DATETIME | Terakhir diubah |
| deleted_at | DATETIME? | Soft-delete (null = aktif) |
| sync_status | TEXT | `pending` / `synced` / `local_only` |

### 7.3 Penyimpanan aman (flutter_secure_storage)

| Kunci | Isi |
|---|---|
| `dokter_hp_pin_hash` | Hash SHA-256 PIN + salt |
| `dokter_hp_pin_salt` | Salt acak per pemasangan PIN |
| `dokter_hp_biometrik_aktif` | `true` / `false` |

### 7.4 Kontrak Edge Function `ai-diagnose` (server)

- **Request** (POST, dipanggil via `supabase.functions.invoke`):
  `{ "keluhan": string, "data_perangkat": object }`
- **Response**: `{ "jawaban": string }` (atau `diagnosis` / `hasil`).
- **Secret**: kunci Gemini hanya di secret server Supabase; tidak ada di
  APK dan tidak ada di repo aplikasi.

## 8. Arsitektur

```
lib/
  main.dart                 # Boot, init Supabase opsional, sync background
  app.dart                  # MaterialApp + tema
  core/
    app_config.dart         # --dart-define, status mode lokal/server
    health_score.dart       # Logika skor 0-100 (murni, teruji unit)
    theme.dart              # Material 3 terang: putih/hitam/abu
    native/device_native.dart  # MethodChannel ke Android
    widgets/common_widgets.dart # EmptyState, InfoRow, ScoreRing, DoctorCard
  data/
    local/                  # Drift: tables.dart, app_database.dart
    sync/                   # SupabaseSyncService (pending -> synced)
  features/
    dashboard/              # Cubit + halaman
    wifi_doctor/            # Service + Cubit + halaman
    battery/ storage/ performance/ security/
    history/                # Halaman + layanan PDF
    auth/                   # PinService (SHA-256) + halaman
    ai_diagnosis/           # Service + halaman
```

- **State**: `flutter_bloc` (Cubit) untuk Dashboard dan Dokter WiFi;
  `StatefulWidget` untuk layar baca data sekali jalan.
- **Native** (`MainActivity.kt`, channel `com.adiprmx.dokterhp/native`):
  RSSI, kecepatan link, frekuensi, DNS, penyimpanan (StatFs), RAM
  (ActivityManager), ukuran cache, hapus cache, daftar aplikasi, buka
  pengaturan WiFi. Semua metode mengembalikan null bila tidak tersedia.
- **Tema**: Material 3 terang, basis putih, aksen hitam/abu-abu. Tanpa
  warna dekoratif (tanpa kuning/amber). Font sistem (tanpa unduhan font,
  agar build offline tidak gagal). Tanpa font serif Didone/Playfair.
  Tombol dan area sentuh minimal 48 px. Teks sekunder memakai abu
  #757575 (kontras 4,6:1 terhadap putih, lolos WCAG AA).

## 9. Prinsip kejujuran data (aturan produk)

1. Semua angka yang tampil adalah data nyata dari perangkat.
2. Bila data tidak tersedia, tampilkan "tidak tersedia" atau empty state
   "Belum ada data pemeriksaan", bukan angka contoh.
3. Estimasi diberi label perkiraan, bukan pengukuran pasti.
4. Latensi disebut "latensi HTTP", bukan "ping", karena bukan ICMP.
5. Batasan Android dijelaskan di layar terkait, beserta cara manual.
6. Skor dihitung hanya dari komponen yang datanya tersedia; komponen
   tanpa data dilewati dan bobot dinormalisasi ulang.
7. Setiap layar yang memuat data punya tiga kondisi: memuat (dengan
   teks yang menjelaskan), galat (dengan tombol "Coba lagi"), dan
   kosong yang jujur (bukan angka contoh).
8. Pesan galat ditulis dengan bahasa sehari-hari dan tidak menampilkan
   rincian teknis dari sistem.

## 10. Kriteria selesai v1 (terukur)

- [x] `flutter analyze` tanpa error (11 November 2026: No issues found).
- [x] `flutter test` hijau (11 November 2026: 39/39): unit skor kesehatan, logika WiFi, widget
      dashboard (termasuk navigasi ke Dokter WiFi).
- [ ] Build APK release berhasil di GitHub Actions, mode lokal (tanpa
      secret) maupun dengan secret Supabase.
- [ ] Dokter WiFi menampilkan hasil ukur nyata di perangkat Android.
- [ ] Semua layar tanpa data menampilkan empty state jujur.
- [ ] Tidak ada angka dummy yang tampil seolah data nyata.
- [ ] Tidak ada secret/kunci API di dalam kode.
- [ ] Setiap tombol melakukan aksi nyata atau menampilkan pesan jujur.

## 11. Batasan jujur Android

| Batasan | Dampak di aplikasi |
|---|---|
| Aplikasi tidak bisa menyambung ulang WiFi / melupakan jaringan / mengganti DNS (Android 10+) | Perbaikan lewat pengaturan sistem; aplikasi membuka pengaturannya dan menjelaskan langkah manual |
| Aplikasi tidak bisa menutup aplikasi lain | Dokter Performa menjelaskan cara manual (layar aplikasi terakhir / mulai ulang) |
| Pemakaian baterai per aplikasi tidak dibuka | Dokter Baterai menampilkan penjelasan dan mengarahkan ke Pengaturan > Baterai |
| SSID di Android 10+ butuh izin lokasi | SSID tampil "tidak tersedia" bila izin belum diberikan |
| Suhu hanya bila sensor sistem bisa dibaca | Tampil "tidak tersedia di perangkat ini" bila tidak bisa dibaca |
| Izin `QUERY_ALL_PACKAGES` dibatasi Play Store | Dokter Keamanan memakai daftar aplikasi yang diizinkan sistem |

## 12. Keamanan dan privasi

- PIN tidak pernah disimpan plaintext (hash SHA-256 + salt).
- Token sesi Supabase dikelola `supabase_flutter`; tidak disimpan manual.
- Data diagnosis tersimpan lokal; sinkronisasi hanya bila pengguna masuk
  dan server terkonfigurasi.
- Tidak ada pelacakan, iklan, atau pengiriman data diam-diam.
- Tanpa payment gateway.

## 13. Hal yang tidak dilakukan

- Tanpa payment gateway.
- Tanpa data dummy yang tampil seolah nyata.
- Tanpa menyimpan PIN plaintext.
- Tanpa mengumpulkan data pengguna tanpa izin.
- Tanpa kunci API di dalam kode.

## 14. Changelog

### v1.0.0 (11 November 2026), rilis pertama

- Dashboard dengan skor kesehatan 0-100 dan diagnosis satu ketuk.
- Dokter WiFi: tes unduh, latensi HTTP, info jaringan, sinyal, channel,
  rekomendasi channel 1/6/11, langkah perbaikan, bagikan hasil.
- Dokter Baterai, Penyimpanan, Performa, Keamanan.
- Riwayat lokal (Drift) dengan laporan PDF yang bisa dibagikan.
- Akun: login Google via Supabase (opsional), PIN hash SHA-256, biometrik.
- Diagnosis AI via Edge Function `ai-diagnose` (kunci hanya di server).
- Mode lokal penuh tanpa Supabase.
- CI GitHub Actions: Flutter 3.47.6, Java 17, analyze + test + build APK
  release, artifact `dokter-hp-apk` (retensi 14 hari).
