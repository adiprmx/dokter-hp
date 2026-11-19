# Lapisan Backend — Dokter HP

Tanggal: 19–20 November 2026 (Gelombang 2)
Repo: `adiprmx/dokter-hp`
Prinsip: setiap lapisan adalah cadangan bagi lapisan di atasnya. Aplikasi
tidak pernah bergantung pada satu backend saja.

## Arti status

| Status | Arti |
| --- | --- |
| Terbukti live | Sudah berjalan di layanan nyata dan terverifikasi |
| Berjalan | Sedang dikerjakan atau diverifikasi, belum terbukti |
| Rencana | Sudah diputuskan arahnya, belum dikerjakan |
| Ditolak | Dipertimbangkan lalu diputuskan untuk tidak dipakai |

---

## L0 — Mode lokal offline (Drift)

**Status: Terbukti (terverifikasi 19 November 2026, ~22:55 WIB).**

Aplikasi dirancang offline-first. Tanpa backend apa pun, aplikasi tetap
berfungsi: seluruh data tersimpan di perangkat dalam database SQLite lokal
(`dokter_hp.sqlite`) melalui Drift, dengan tabel `HealthChecks` dan
`WifiReports`. Sinkronisasi ke Supabase hanya terjadi bila Supabase
terkonfigurasi; tanpa itu status tetap `local_only`.

Yang berjalan tanpa backend apa pun:

- Pemeriksaan kesehatan perangkat dan penyimpanan riwayatnya di perangkat.
- Laporan dan riwayat WiFi di perangkat.
- Kunci aplikasi (PIN dan biometrik) — tersimpan lokal.
- Laporan PDF — dibuat di perangkat.

Bukti pengujian (19 November 2026, tanpa konfigurasi Supabase apa pun —
`isSupabaseConfigured == false`, persis kondisi backend tidak terjangkau):
`flutter analyze` 0 issue; `flutter test` **98 lolos, 0 gagal, 10 skip**
(10 skip disengaja: 9 tes tangkap-screenshot QA + 1 tes login Google yang
memang butuh backend). Tes mode-lokal spesifik dijalankan ulang terpisah:
**29/29 lolos** (sinkronisasi Drift, empty state jujur, chip mode lokal).
Bukti lengkap: `hidden_files/backend-unblock/bukti-offline-mode.md`.
Diverifikasi ulang untuk APK v1.1.1+4 (Gelombang 2, 19–20 November 2026):
`flutter analyze` 0 issue; `flutter test` 98 lolos, 0 gagal.

Bila semua lapisan di atas L0 mati, aplikasi kembali ke lapisan ini dan
pengguna tetap dapat memakai fitur pemeriksaan serta riwayat lokal.
Yang hilang hanyalah fitur yang memang membutuhkan server (lihat L1).

---

## L1 — Supabase proyek baru khusus Dokter HP (UTAMA)

**Status: Terbukti live (Gelombang 2, 19–20 November 2026). Semua butir
hijau — termasuk uji live 200 end-to-end `ai-diagnose` (lolos 20 Nov
2026 00:43 WIB, lihat di bawah).**

Akun Supabase lama (`adiprmx`) sudah penuh: 2 proyek gratis aktif
(`adipmusic` dan `adipqris-sg`), dan limit dihitung per anggota di semua
organisasi, sehingga organisasi baru tidak dapat mengakali limit ini
(bukti lengkap: `supabase/STATUS_BACKEND.md`, 12 November 2026).

Akun baru khusus Dokter HP sudah dibuat dan terverifikasi:
`adiplowkey+dokterhp@gmail.com` (alias → inbox `adiplowkey`), email
terkonfirmasi 19 November 2026, 23:41 WIB. Organisasi `dokter-hp`
(Free), proyek `dokter-hp`, ref `sugqpbkfrrrpadwxslzc`,
URL `https://sugqpbkfrrrpadwxslzc.supabase.co`, region ap-southeast-1,
Free/Nano/Healthy.

Yang sudah live dan terverifikasi di proyek baru:

- **Migrasi 01–06** diterapkan via Management API: 4 tabel (`profiles`,
  `health_checks`, `wifi_reports`, `ai_diagnoses`) + trigger
  `handle_new_user` (auto-create `profiles`) + grants (anon SELECT,
  authenticated CRUD, service_role ALL). Trigger TERBUKTI live:
  profil dibuat otomatis saat pengguna uji dibuat.
- **RLS re-run: 13 PASS, 0 FAIL** — tanpa kredensial 401; anon-only
  200 `[]` keempat tabel; function tanpa JWT 401.
- **Edge Function `ai-diagnose`: ter-deploy ACTIVE, uji live 200 LOLOS
  20 Nov 2026 00:43 WIB** (HTTP 200 dalam 17,0 dtk, JWT pengguna asli,
  diagnosis diterima 2056 karakter). Model utama
  `gemini-3.5-flash-lite` + cadangan `gemini-3.1-flash-lite`
  (`gemini-2.0-flash` pensiun — 404; `gemini-3.8-flash` overload malam
  itu — 503; keduanya terverifikasi live; v1beta tetap berlaku).
  Timeout 60 dtk per panggilan, maks 1 retry 5xx ke model cadangan.
  `GEMINI_API_KEY` diatur server-side. Cek pengguna-terautentikasi
  ditambahkan (anon JWT ditolak 401 sebelum memanggil Gemini).
- **Sinkronisasi TERBUKTI live:** POST `health_checks` + `wifi_reports`
  201, GET 200; cleanup terverifikasi (pengguna uji + cascade
  `profiles` terhapus, 404).
- **Provider Google ENABLED** (pakai ulang klien "Dokter HP Web");
  rantai OAuth TERBUKTI: GET `/auth/v1/authorize` → 302 ke
  accounts.google.com dengan `redirect_to` `dokterhp://login-callback`
  + callback Supabase benar.
- **GitHub secrets terisi:** `SUPABASE_URL` + `SUPABASE_ANON_KEY`
  (HTTP 201, terverifikasi API).
- **APK v1.1.1+4:** wiring NOL perubahan Dart (config `--dart-define`);
  copy "Lupa PIN?" diperbaiki jujur; `flutter analyze` 0,
  `flutter test` 98 lolos 0 gagal; `hidden_files/` masuk `.gitignore`.

Yang masih belum hijau:

- **Uji login Google di HP FISIK masih menunggu owner** (tidak bisa
  dari VM/browser). Rantai OAuth di atas sudah terbukti sampai ke
  callback; yang belum adalah login sungguhan di perangkat.

Yang sengaja tidak dilakukan:

- `fcm-notify` sengaja TIDAK di-deploy — APK nol kode FCM.
- L2 (fallback Worker) dan L3 (jeda proyek lama / numpang proyek lama)
  — lihat di bawah; keduanya tidak menghalangi v1.1.1.

Catatan wiring (audit 19 November 2026): perubahan kode Dart NOL —
konfigurasi lewat `--dart-define` (`SUPABASE_URL` + `SUPABASE_ANON_KEY`,
`lib/core/app_config.dart`) dan CI sudah meneruskan GitHub secrets
bernama sama. APK v1.1.0+3 yang beredar tetap mode lokal selamanya
(nilai dibakar saat compile); backend hidup mulai APK v1.1.1+4.
Catatan skema: temuan audit soal `profiles` tanpa trigger SUDAH
TERATASI (trigger `handle_new_user` live, terbukti auto-create);
`ai_diagnoses` masih tanpa penulis (function tidak menulis ke sana).
Detail: `hidden_files/backend-unblock/audit-apk-supabase.md`.

Cara kerja saat gagal: bila Supabase tidak dapat dijangkau atau belum
terkonfigurasi, aplikasi jatuh ke L0 — mode lokal tetap berfungsi penuh,
data baru tersimpan di perangkat, dan sinkronisasi ditunda sampai
backend kembali tersedia. Kegagalan L1 tidak mematikan aplikasi.

---

## L2 — Cloudflare Worker API sebagai backend sekunder

**Status: Desain selesai — BELUM LAYAK sebagai fallback APK (putusan
19 November 2026). Pemblokirnya auth, bukan endpoint data.**

Web app Dokter HP sudah live melalui Cloudflare Worker API di
`https://dokter-hp-api.hiroohengkerr.workers.dev`. Desain fallback APK
selesai (`hidden_files/backend-unblock/desain-fallback-worker.md`):
endpoint data Worker sebagian besar cocok (health-checks, wifi-reports
+ samples, ai/diagnose + ai/diagnoses, history, profile; skema D1
kompatibel; enum `sumber` sudah mencakup `apk`), TAPI satu-satunya
jalan masuk adalah OAuth Google browser + cookie sesi HttpOnly —
tidak ada endpoint yang mengembalikan token di JSON, middleware hanya
membaca cookie (tanpa `Authorization: Bearer`), dan redirect skema
aplikasi (`dokterhp://`) ditolak. Tanpa perubahan Worker, APK tidak
bisa memperoleh sesi valid.

Gap lain yang dicatat desain: rute `/api/sync/*` + token perangkat
dari `docs/sync-apk.md` web app BELUM ADA sama sekali; ID dibuat
server tanpa upsert (retry → duplikat); `dibuat_pada` tidak bisa
dikirim; tidak ada pull benar (tanpa tombstone); label sinyal APK
(Indonesia) ditolak Worker (hanya `lemah`/`sedang`/`kuat`); identitas
ganda (ID pengguna Worker ≠ UID Supabase Auth).

Dua opsi ke depan (butuh kerja tim web dulu + keputusan owner):
Opsi A — endpoint login native + Bearer + client APK (SEDANG, dengan
batasan sisa); Opsi B — implementasi penuh `sync-apk.md` (BESAR).
Sampai salah satunya diputuskan dan dibangun, L2 adalah backend web
app, bukan pengganti L1 untuk APK.

**Gelombang 2 (19–20 November 2026): L2 DITUNDA** — desain selesai,
tetap BELUM LAYAK (pemblokir auth di atas belum berubah: cookie-only,
tanpa Bearer, rute `/api/sync/*` belum ada). Penundaan ini TIDAK
menghalangi v1.1.1 karena L1 sudah terbukti live.

---

## L3 — Alternatif dan rencana

### Firebase (opsi D lama)

**Status: Rencana.**

Pindah backend ke Firebase pernah dipertimbangkan (opsi D di
`supabase/STATUS_BACKEND.md`). Firebase sudah dipakai proyek lain
(Karir), tetapi pemindahan ini mengubah arsitektur aplikasi Flutter
dan bukan keputusan sepihak tim backend. Opsi ini disimpan sebagai
cadangan bila jalur Supabase tertutup total.

### Akun Supabase kedua sebagai standby

**Status: Rencana.**

Bila proyek `dokter-hp` di akun baru bermasalah di kemudian hari
(misalnya akun terkunci atau proyek terhapus), disiapkan akun Supabase
berikutnya sebagai standby untuk membuat ulang proyek dari migrasi
dan function yang sudah ada di repo. Karena seluruh skema dan function
tersimpan di repo, pembuatan ulang tidak dimulai dari nol.

### Pause proyek lama

**Status: Ditolak (ditegaskan kembali Gelombang 2, 19–20 November 2026).**

Menjeda (pause) salah satu proyek di akun `adiprmx` akan membebaskan
satu slot proyek gratis, tetapi `adipmusic` dan `adipqris-sg` keduanya
adalah layanan live — menjeda salah satunya mematikan layanan tersebut.
Opsi ini ditolak.

### Menumpang di proyek yang sudah ada

**Status: Ditolak (tidak dipilih; ditegaskan kembali Gelombang 2,
19–20 November 2026).**

Menambahkan tabel Dokter HP ke proyek `adipmusic` atau `adipqris-sg`
pernah dipertimbangkan (opsi C di `supabase/STATUS_BACKEND.md`).
Risikonya: nama tabel dapat bertabrakan, data tercampur dengan proyek
produksi lain, dan aplikasi memakai URL/kunci proyek lain. Opsi ini
tidak dipilih.

### Rencana bila L1 gagal total

**Catatan Gelombang 2 (19–20 November 2026):** L1 sudah terbukti live,
jadi rencana di bawah ini sekarang hanya kontingensi bila proyek
`dokter-hp` bermasalah di kemudian hari — bukan lagi skenario utama.

Bila proyek Supabase baru ternyata tidak dapat dibuat sama sekali:

1. Aplikasi tetap berjalan di L0 — pengguna tidak kehilangan fungsi inti.
2. Percepat desain L2 (Worker sebagai backend APK) dengan keputusan
   auth yang eksplisit.
3. Evaluasi migrasi ke Firebase (opsi D) sebagai backend utama pengganti.
4. Siapkan akun Supabase standby sebagai percobaan pembuatan proyek
   berikutnya.

Urutan ini memastikan tidak ada satu kegagalan pun yang mematikan
aplikasi atau menghapus data pengguna.

---

## Tabel ringkas

| Lapisan | Status | Yang dihidupkan | Bila lapisan itu mati |
| --- | --- | --- | --- |
| L0 — Lokal offline (Drift) | Terbukti (98 tes lolos, 0 gagal) | Pemeriksaan, riwayat lokal, kunci aplikasi, laporan PDF | Tidak ada cadangan di bawahnya; ini fondasi terakhir |
| L1 — Supabase proyek baru (UTAMA) | Terbukti live (Gelombang 2, 19–20 Nov 2026; uji live 200 ai-diagnose belum lolos) | Login Google, Diagnosis AI, sinkron riwayat | Jatuh ke L0; aplikasi tetap berfungsi, sinkron tertunda |
| L2 — Cloudflare Worker API | Desain selesai — belum layak (auth), ditunda | Web app live; calon backend sekunder APK | Web app terdampak; APK tetap jalan di L1/L0 |
| L3 — Firebase | Rencana | Cadangan backend utama bila Supabase tertutup | Tidak berdampak; belum dipakai |
| L3 — Akun Supabase standby | Rencana | Pembuatan ulang proyek dari repo bila akun utama bermasalah | Tidak berdampak; belum dipakai |
| L3 — Pause proyek lama | Ditolak | — | — |
| L3 — Menumpang proyek lama | Ditolak | — | — |

## Referensi

- `supabase/STATUS_BACKEND.md` — bukti limit akun `adiprmx` (12 November
  2026) dan status unblock Gelombang 2 (19–20 November 2026).
- `supabase/migrations/` — 4 migrasi tabel beserta RLS.
- `supabase/functions/` — Edge Function `ai-diagnose` dan `fcm-notify`.
- `lib/data/local/app_database.dart` — database lokal Drift.
- `lib/data/sync/supabase_sync_service.dart` — kode sinkronisasi Supabase.
