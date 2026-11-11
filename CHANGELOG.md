# Changelog — Dokter HP

Semua perubahan penting proyek ini dicatat di file ini.

## v1.0.1 — 12 November 2026

### Diperbaiki

- Dokter WiFi kini menampilkan SSID, alamat gateway, dan daftar DNS
  yang benar (nilai "Tidak tersedia" dan format alamat IPv6 yang
  tercampur nama antarmuka sudah dibersihkan); bila izin lokasi belum
  diberikan, aplikasi menjelaskan bahwa SSID memerlukan izin lokasi
  dan membuka permintaan izin runtime.
- Pengukuran kecepatan unduh memakai satuan mikrodetik, sehingga
  pembulatan waktu tidak lagi membuat hasil tes singkat meleset.

### Ditambahkan

- Pemantau live Dokter WiFi: kecepatan dan latensi diperbarui tiap
  2 detik, dengan probe kecil tiap 10 detik saat tidak ada unduhan
  berjalan.
- Tes bertahan 30 detik: mengukur apakah kecepatan bertahan dari awal
  sampai akhir, atau mulai cepat kemudian jatuh, lengkap dengan grafik
  batang dan kesimpulan bertahan / jatuh / tidak stabil.
- Kartu panduan "WiFi turun ke KB/detik" di dalam aplikasi, dengan teks
  yang sama seperti `docs/panduan-wifi-turun.md`.
- Panduan `docs/panduan-wifi-turun.md` kini menempatkan Mode router
  802.11b Only sebagai penyebab nomor 1 (paling mungkin): mode
  IEEE 802.11b Only di ZTE F660 (Network > WLAN > Basic) maksimal
  11 Mbps dan mudah jatuh ke KB/detik — ubah ke 802.11b/g/n Mixed.
  Channel 6, QoS Disabled, dan Tx Rate Auto sudah benar. Jangan tekan
  Submit sebelum memuat ulang halaman dan memastikan SSID Name
  tampil ACHA.

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
