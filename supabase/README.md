# Backend Supabase — Dokter HP

Backend untuk aplikasi Android Dokter HP: pemeriksaan kesehatan HP
(WiFi, baterai, penyimpanan, performa, keamanan), laporan WiFi, dan
diagnosis AI. Backend ini memakai **satu proyek Supabase saja**,
tanpa payment gateway, dan tanpa biaya pada paket gratis Supabase.

## Daftar isi

- [Arsitektur singkat](#arsitektur-singkat)
- [Prasyarat](#prasyarat)
- [Langkah setup](#langkah-setup)
- [Daftar tabel dan Row Level Security](#daftar-tabel-dan-row-level-security)
- [Edge Function](#edge-function)
- [Pengembangan lokal](#pengembangan-lokal)
- [Catatan penting](#catatan-penting)

## Arsitektur singkat

- **Database Postgres** di Supabase: 4 tabel, semua dengan Row Level
  Security (RLS) aktif.
- **Supabase Auth**: pengguna masuk dengan akun sendiri. Setiap baris
  data terikat pada id pengguna, dan policy RLS memastikan pengguna
  hanya dapat membaca dan menulis baris miliknya sendiri.
- **Edge Function `ai-diagnose`**: memanggil Gemini API untuk
  diagnosis berbahasa Indonesia.
- **Edge Function `fcm-notify`**: template pengiriman notifikasi push
  lewat Firebase Cloud Messaging (FCM).

## Prasyarat

- Akun Supabase (paket gratis sudah cukup).
- Supabase CLI terpasang di komputer pengembangan.
- Kunci API Gemini (dibuat di Google AI Studio). Kunci ini hanya
  disimpan sebagai secret, tidak pernah ditulis di file repositori.
- Untuk `fcm-notify`: proyek Firebase dengan Cloud Messaging aktif,
  serta id proyek dan token akses OAuth 2.0 (lihat catatan setup di
  file `functions/fcm-notify/index.ts`).

## Langkah setup

### 1. Buat proyek Supabase gratis

1. Buka dashboard Supabase dan buat proyek baru.
2. Pilih paket gratis. Catat URL proyek dan kunci anon (anon key)
   dari menu pengaturan API proyek.
3. Simpan URL dan kunci anon sebagai GitHub secrets di repositori
   `adiprmx/dokter-hp` (lihat langkah 5).

### 2. Hubungkan proyek lokal

```bash
cd dokter-hp
supabase link --project-ref <ref-id-proyek>
```

`<ref-id-proyek>` adalah id referensi proyek yang tampil di
dashboard Supabase (bagian dari URL proyek).

### 3. Jalankan migrasi

Migrasi berada di folder `supabase/migrations/` dan sudah berurutan.
Jalankan dari root repositori:

```bash
supabase db push
```

Perintah ini menerapkan semua migrasi ke proyek yang terhubung.
Periksa di dashboard Supabase (Table Editor) bahwa keempat tabel
sudah ada dan RLS aktif pada masing-masing tabel.

### 4. Deploy Edge Function dan atur secret

Atur secret Gemini terlebih dahulu, lalu deploy function:

```bash
supabase secrets set GEMINI_API_KEY=<kunci-api-gemini>
supabase functions deploy ai-diagnose
```

Untuk `fcm-notify` (opsional, hanya bila notifikasi push dipakai,
dan HANYA oleh admin — function ini **nonaktif secara default**):

```bash
supabase secrets set FCM_NOTIFY_ALLOWED_USER_IDS=<id-pengguna-admin>
supabase secrets set FCM_PROJECT_ID=<id-proyek-firebase>
supabase secrets set FCM_ACCESS_TOKEN=<token-akses-oauth-2-0>
supabase functions deploy fcm-notify
```

Tanpa secret `FCM_NOTIFY_ALLOWED_USER_IDS`, function menolak semua
panggilan dengan 503. Hanya pengguna yang id-nya tercantum di
allowlist (dipisah koma bila lebih dari satu) yang boleh mengirim
push; pengguna login lain ditolak dengan 403. Id pengguna dilihat di
dashboard Supabase (Authentication > Users). Token akses FCM berumur
pendek dan harus diperbarui secara berkala. Lihat keputusan keamanan
lengkap di `functions/fcm-notify/index.ts` dan di bagian
`fcm-notify` di bawah.

### 5. Atur GitHub secrets di repositori

Di repositori `adiprmx/dokter-hp`, buka Settings → Secrets and
variables → Actions, lalu tambahkan:

| Nama secret         | Isi                                   |
| ------------------- | ------------------------------------- |
| `SUPABASE_URL`      | URL proyek Supabase                   |
| `SUPABASE_ANON_KEY` | Kunci anon (anon key) proyek Supabase |

Aplikasi Android memakai dua nilai ini untuk terhubung ke Supabase.
Jangan pernah menulis kunci service role di aplikasi atau di
repositori. Kunci service role hanya dipakai di sisi server bila
benar-benar diperlukan, dan tidak dibutuhkan oleh aplikasi ini.

## Daftar tabel dan Row Level Security

Semua tabel memakai `ENABLE ROW LEVEL SECURITY` pada migrasi yang
sama dengan pembuatan tabel. Setiap tabel memiliki policy SELECT,
INSERT, UPDATE, dan DELETE dengan syarat `auth.uid() = user_id`
(pada `profiles`: `auth.uid() = id`). Artinya pengguna hanya dapat
membaca dan menulis baris miliknya sendiri.

| Tabel            | Kegunaan                                            |
| ---------------- | --------------------------------------------------- |
| `profiles`       | Profil pengguna. `id` sama dengan id di `auth.users`. Kolom: `nama`, `dibuat_pada`. |
| `health_checks`  | Hasil pemeriksaan kesehatan HP. Kolom: `skor` (0–100), `ringkasan` (JSON), `dibuat_pada`, `updated_at`, `deleted_at` (soft-delete), `sync_status` (`pending`, `synced`, `failed`). |
| `wifi_reports`   | Laporan pemeriksaan WiFi. Kolom: `ssid`, `kecepatan_koneksi_mbps`, `kekuatan_sinyal`, `channel`, `dns`, `ping_ms`, `rekomendasi`, `dibuat_pada`. |
| `ai_diagnoses`   | Riwayat tanya jawab diagnosis AI. Kolom: `health_check_id` (boleh kosong), `pertanyaan`, `jawaban`, `dibuat_pada`. |

Catatan:

- `health_checks.deleted_at` dipakai untuk soft-delete. Aplikasi
  wajib memfilter `deleted_at is null` saat menampilkan daftar
  pemeriksaan, agar baris yang sudah dihapus tidak tampil.
- `health_checks.updated_at` diperbarui otomatis oleh trigger
  setiap kali baris diubah.
- `ai_diagnoses.health_check_id` boleh kosong bila pertanyaan
  diajukan tanpa terikat pada satu hasil pemeriksaan.
- Tidak ada data seed. Tabel dibuat kosong dan hanya berisi data
  nyata dari pengguna aplikasi.

## Edge Function

### `ai-diagnose`

- Endpoint: `POST /functions/v1/ai-diagnose`
- Header wajib: `Authorization: Bearer <token pengguna>`
- Body JSON:

  ```json
  {
    "gejala": "WiFi sering putus dan baterai cepat habis",
    "hasil_pemeriksaan": { "skor": 62, "baterai": "kesehatan 78%" }
  }
  ```

- Respons sukses: `{ "diagnosis": "...jawaban berbahasa Indonesia..." }`
- Membutuhkan secret `GEMINI_API_KEY`.
- Endpoint dan nama model Gemini pada function ini wajib diverifikasi
  pada dokumentasi resmi Google AI saat setup, karena Google dapat
  mengubah nama model dan versi API.

### `fcm-notify` (template, nonaktif secara default)

- Endpoint: `POST /functions/v1/fcm-notify`
- Header wajib: `Authorization: Bearer <token pengguna>`
- Body JSON:

  ```json
  {
    "token": "<token perangkat FCM tujuan>",
    "title": "Pemeriksaan selesai",
    "body": "Skor kesehatan HP Anda 82 dari 100.",
    "data": { "jenis": "health_check" }
  }
  ```

- Membutuhkan secret `FCM_PROJECT_ID` dan `FCM_ACCESS_TOKEN`.
- Bila secret belum diatur, function mengembalikan galat 500 dengan
  pesan setup dan tidak mengirim apa pun.

**Keputusan keamanan (temuan QA S-3, 11 Nov 2026):** function ini
adalah relay push ke token perangkat mana pun, jadi tidak boleh
dipakai sembarang pengguna login. Karena itu function **nonaktif
secara default**: tanpa secret `FCM_NOTIFY_ALLOWED_USER_IDS`,
semua panggilan ditolak dengan 503. Bila allowlist sudah diatur,
function membaca klaim `sub` (id pengguna) dari JWT dan hanya
mengizinkan id yang tercantum di allowlist (biasanya akun admin);
pengguna lain ditolak dengan 403, token yang tidak valid ditolak
dengan 401. Model yang dipilih adalah relay khusus admin — yang
paling aman dan paling sederhana — bukan pengiriman mandiri per
pengguna, karena pengiriman mandiri membutuhkan tabel pemetaan
token perangkat per pengguna yang belum dibangun, dan aplikasi
v1.0.0 tidak memakai function ini sama sekali. Jangan pernah
men-deploy function ini dengan `verify_jwt = false`: gateway
adalah yang memverifikasi tanda tangan JWT sebelum request sampai
ke function.

Kedua function dikonfigurasi dengan `verify_jwt = true` di
`config.toml`, sehingga pemanggil wajib menyertakan token pengguna
yang valid pada header Authorization.

## Pengembangan lokal

```bash
# Menjalankan Supabase lokal (database, Auth, dan Studio)
supabase start

# Menerapkan ulang migrasi dari awal pada database lokal
supabase db reset

# Menjalankan satu function secara lokal
supabase functions serve ai-diagnose --env-file ./supabase/.env.local
```

File `.env.local` hanya untuk pengembangan lokal dan tidak boleh
di-commit ke repositori. Isi file tersebut dengan secret yang
dibutuhkan, misalnya `GEMINI_API_KEY`.

## Catatan penting

- **Satu proyek Supabase saja.** Jangan membuat proyek kedua untuk
  fungsi yang sama.
- **Tanpa payment gateway.** Backend ini tidak memproses pembayaran
  apa pun.
- **Tanpa biaya.** Paket gratis Supabase sudah cukup untuk tahap
  awal. Bila batas paket gratis tercapai, tinjau pemakaian di
  dashboard sebelum memutuskan langkah berikutnya.
- **Secret tidak pernah ditulis di repositori.** Semua kunci hanya
  disimpan sebagai secret Supabase atau GitHub secrets dengan nama
  yang tercantum di dokumen ini.
- **Tidak ada data contoh.** Tidak ada file seed dengan data
  pengguna palsu. Semua data berasal dari pemakaian nyata aplikasi.
