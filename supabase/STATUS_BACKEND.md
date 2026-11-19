# Status Backend Supabase — Dokter HP

Tanggal: 19–20 Nov 2026 WIB (Gelombang 2)
Status: **BLOKIR DICABUT — proyek Supabase baru live dan terverifikasi.**

## Proyek baru (Gelombang 2)

- Akun: `adiplowkey+dokterhp@gmail.com` (alias → inbox `adiplowkey`),
  email terkonfirmasi 19 Nov 2026, 23:41 WIB.
- Organisasi: `dokter-hp` (Free).
- Proyek: `dokter-hp`, ref `sugqpbkfrrrpadwxslzc`.
- URL: `https://sugqpbkfrrrpadwxslzc.supabase.co`
- Region: ap-southeast-1. Plan: Free/Nano. Status: Healthy.

Catatan keamanan: dokumen ini tidak memuat nilai secret/kunci/token
apa pun — hanya ref dan URL proyek (keduanya bukan rahasia).

## Yang sudah live dan terverifikasi (19–20 Nov 2026)

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

## Yang tersisa

1. **Uji login Google di HP FISIK masih menunggu owner** (tidak bisa
   dari VM/browser). Rantai OAuth sudah terbukti sampai ke callback;
   yang belum adalah login sungguhan di perangkat.

## Yang sengaja tidak dilakukan

- `fcm-notify` sengaja TIDAK di-deploy — APK nol kode FCM.
- L2 (fallback Worker Cloudflare): desain selesai, BELUM LAYAK
  (pemblokir auth: cookie-only, tanpa Bearer, rute `/api/sync/*`
  belum ada) — ditunda, tidak menghalangi v1.1.1.
- L3 (jeda proyek lama / numpang proyek lama): ditolak sesuai
  keputusan. Detail: `docs/backend-layers.md`.

---

## Riwayat: blokir 12 Nov 2026 (sudah tidak berlaku)

Tanggal: 12 Nov 2026 ~00:40 WIB (17:40 UTC)
Status saat itu: **TERBLOKIR — proyek Supabase baru tidak bisa dibuat
di akun ini.**

### Bukti limit (dari Supabase Management API, akun adiprmx)

Organisasi yang ada: 1 — `adipmusic` (`hszwvtnzencnuehcsbpx`).
Proyek aktif: 2 — `adipmusic` (`jebafddwupyqpwevhsqn`, ap-southeast-2) dan
`adipqris-sg` (`twterdlrwwxgocwrofrb`, ap-southeast-1). Keduanya
`ACTIVE_HEALTHY`.

Percobaan buat proyek `dokter-hp` (plan free, region ap-southeast-1):
- Di organisasi baru `dokter-hp` (`hzufjqvsqjnpjbzxcsrv`, berhasil dibuat):
  `POST /v1/projects` → `{"message":"Your account does not have the
  necessary privileges to access this endpoint..."}`
- Di organisasi lama `adipmusic` (uji pembeda, 2x percobaan): pesan eksplisit:
  > "The following organization members have reached their maximum limits
  > for the number of active free projects within organizations where they
  > are an administrator or owner: adiprmx (2 project limit). To continue,
  > these users will need to either delete, pause or upgrade one or more
  > of these projects."

Kesimpulan: limit 2 proyek gratis dihitung **per anggota (adiprmx) di semua
organisasi** tempat ia Owner/Admin — organisasi baru TIDAK bisa mengakali
limit ini. Dikonfirmasi juga oleh dokumentasi Supabase dan beberapa sumber
independen.

### Yang sudah disiapkan saat itu (siap jalan begitu proyek tersedia)

- 4 migrasi di `supabase/migrations/` sudah diperiksa isinya: tiap tabel
  (`profiles`, `health_checks`, `wifi_reports`, `ai_diagnoses`) memakai
  `ENABLE ROW LEVEL SECURITY` + 4 policy (select/insert/update/delete,
  `auth.uid() = user_id` / `id`). Format siap dieksekusi.
- Edge Function `ai-diagnose` dan `fcm-notify` ada di `supabase/functions/`;
  keduanya `verify_jwt = true` di `config.toml`. `fcm-notify` hanya admin
  via allowlist (`FCM_NOTIFY_ALLOWED_USER_IDS`).
- Password database proyek yang sempat dibuat acak SUDAH DIBUANG.
  INSIDEN 12 Nov 2026 ~00:50 WIB: file `secrets/supabase-db-pass.txt`
  tidak sengaja ter-push ke repo publik di commit 5019c158 (karena
  `.gitignore` belum mengecualikan `secrets/`). File sudah dihapus dari
  `main` di commit 77d7bc68 dan salinan lokal sudah dihapus. Nilai itu
  tidak pernah dipakai untuk database live apa pun (proyek tidak pernah
  dibuat), tetapi tetap TIDAK BOLEH dipakai lagi — saat proyek dibuat
  nanti, buat kata sandi baru yang baru. `.gitignore` sekarang
  mengecualikan `secrets/`.

### Opsi gratis yang dipertimbangkan saat itu (perlu keputusan owner)

A. **Pause salah satu proyek yang ada** (proyek yang di-pause tidak dihitung
   dalam limit) — tapi `adipmusic` dan `adipqris-sg` keduanya live; pause
   mematikan layanannya. Hanya owner yang boleh memilih.
B. **Buat proyek di akun Supabase lain milik owner** (mis. akun Google lain
   yang belum punya 2 proyek) — perlu owner login/buat proyek dari dashboard
   atau memberi akses API akun itu. Asisten tidak bisa dari kredensial saat ini.
C. **Numpang di proyek yang ada** (`adipqris-sg` atau `adipmusic`) — tabel
   Dokter HP ditambahkan ke proyek live. Risiko: nama tabel `profiles` bisa
   bertabrakan, data tercampur dengan proyek produksi, dan aplikasi memakai
   URL/kunci proyek lain. Perlu persetujuan eksplisit owner.
D. **Pindah backend ke Firebase** (sudah dipakai Karir) — perubahan arsitektur
   aplikasi Flutter, bukan keputusan sepihak backend.

Tidak ada layanan berbayar, kartu kredit, atau upgrade Pro yang dipakai
atau diusulkan dalam pekerjaan ini.

### Catatan teknis

- Konektor `custom.supabase-mgmt` (`sb_mgmt.py`) memakai path import
  `dynamic_credentials` yang sudah tidak ada
  (`/opt/muse/skills/custom-connector-setup/templates/skill/bin`); selama
  pekerjaan ini dipakai `PYTHONPATH=/opt/muse/skills/custom-connector-setup/bin`
  sebagai workaround. Sebaiknya diperbaiki di konektor.
- Egress VM sempat mati total ~00:20–00:35 WIB (google.com 000), lalu pulih
  dan sempat flaky per-rute. Runtime juga restart di tengah pekerjaan dan
  menghapus /tmp.
- Organisasi kosong `dokter-hp` (`hzufjqvsqjnpjbzxcsrv`) sudah tidak terdaftar
  lagi setelah perintah DELETE (respons API ambigu "Cannot DELETE ...", tapi
  dua kali pengecekan daftar organisasi hanya menampilkan `adipmusic`).
