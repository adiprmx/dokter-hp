# Status Backend Supabase — Dokter HP v1.0.0

Tanggal: 12 Nov 2026 ~00:40 WIB (17:40 UTC)
Status: **TERBLOKIR — proyek Supabase baru tidak bisa dibuat di akun ini.**

## Bukti limit (dari Supabase Management API, akun adiprmx)

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

## Yang sudah disiapkan (siap jalan begitu proyek tersedia)

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

## Yang belum bisa dilakukan (menunggu keputusan owner)

1. Migrasi (langkah 3) — belum ada proyek target.
2. Deploy Edge Function (langkah 4) — belum ada proyek target.
3. Secret `GEMINI_API_KEY` — belum tersedia; JANGAN diisi karangan.
   Function `ai-diagnose` akan mengembalikan error sampai secret ini diisi.
   Secret lain yang akan dibutuhkan `fcm-notify`: `FCM_NOTIFY_ALLOWED_USER_IDS`,
   `FCM_PROJECT_ID`, `FCM_ACCESS_TOKEN` (semua belum tersedia).

## Opsi gratis yang tersisa (perlu keputusan owner)

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

## Catatan teknis

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
