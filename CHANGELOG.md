# Changelog — Dokter HP

Semua perubahan penting proyek ini dicatat di file ini.

## v1.0.0 — 11 November 2026 (rilis pertama)

### Ditambahkan

- Dashboard: skor kesehatan HP 0-100, diagnosis satu ketuk, kartu tiap
  dokter, banner mode lokal/server, tiga pemeriksaan terakhir.
- Dokter WiFi: tes kecepatan unduh (Cloudflare, cadangan OVH), latensi
  HTTP, SSID, IP, gateway, DNS, kekuatan sinyal (RSSI), kecepatan
  koneksi, channel dari frekuensi, rekomendasi channel 1/6/11 untuk
  2,4 GHz, langkah perbaikan lewat pengaturan sistem, bagikan hasil,
  simpan otomatis ke riwayat.
- Dokter Baterai: level, status, mode hemat daya, estimasi waktu pakai
  (dilabeli perkiraan), penjelasan jujur soal daftar aplikasi boros.
- Dokter Penyimpanan: total/terpakai/kosong, ukuran cache, bersih cache
  aplikasi sendiri dengan konfirmasi.
- Dokter Performa: RAM, CPU dari `/proc/stat`, suhu bila tersedia, info
  perangkat, tombol muat ulang.
- Dokter Keamanan: daftar aplikasi pengguna, hitung izin berbahaya,
  bagian "Perlu ditinjau", tanggal pemasangan.
- Riwayat: database lokal Drift (`health_checks`, `wifi_reports`) dengan
  soft-delete dan `sync_status`; laporan PDF yang bisa dibagikan.
- Akun dan keamanan: login Google via Supabase (opsional), PIN lokal
  hash SHA-256 + salt, biometrik sistem.
- Diagnosis AI via Supabase Edge Function `ai-diagnose` (kunci Gemini
  hanya di server).
- Sinkronisasi riwayat ke Supabase di background (non-fatal, hanya bila
  terkonfigurasi).
- MethodChannel Android (`com.adiprmx.dokterhp/native`): RSSI, kecepatan
  link, frekuensi, DNS, penyimpanan, RAM, cache, daftar aplikasi.
- CI GitHub Actions: Flutter 3.47.6, Java 17, `pub get` + generate Drift
  + `analyze` + `test` + build APK release (obfuscate), artifact
  `dokter-hp-apk` retensi 14 hari. Secret Supabase kosong hanya
  peringatan — build tetap jalan mode lokal.
- Dokumen: PRODUCT.md (PRD lengkap), README.md, CHANGELOG.md.

### Prinsip

- Semua angka tampil adalah data nyata perangkat; tanpa angka dummy.
- Empty state jujur "Belum ada data pemeriksaan" bila belum ada data.
- Batasan Android dijelaskan jujur di layar terkait.
- Tanpa payment gateway; tanpa secret di dalam kode.
