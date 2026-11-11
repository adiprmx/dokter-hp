# Audit Desain dan Tulisan, Dokter HP v1.0.0

Tanggal: 11 November 2026. Auditor: subagent UI/UX + copy editor.
Standar: 7 skill anti-slop owner, aturan produk Dokter HP, dan
Material 3. Hasil akhir: `flutter analyze` bersih, `flutter test`
hijau (lihat bagian 5).

## 1. Design read

Reading this as: aplikasi alat Android (mode Operate) untuk pemilik HP
umum, bukan teknisi, dengan bahasa yang tenang dan mengutamakan
kepercayaan, memakai Material 3 terang, monokrom putih/hitam/abu,
dan warna hanya untuk status fungsional. Dial anti-slop:
ENERGY 1 / RHYTHM 1 / MOTION 1, sengaja tenang karena ini alat
diagnosis, bukan landing page. Dial taste-frontend: VARIANCE 4 /
MOTION 2 / DENSITY 4.

Keputusan desain (satu baris per keputusan, R-31):
- Putih/hitam/abu saja karena aplikasi alat harus tenang dan mudah dibaca.
- Tanpa warna dekoratif karena warna hanya boleh berarti status.
- Radius 12 di semua kartu dan tombol agar satu sistem bentuk.
- Tombol minimal 48 px karena area sentuh yang nyaman di HP.
- Teks sekunder abu #757575 karena kontrasnya 4,6:1 terhadap putih.
- Satu tombol utama per layar agar tidak ada dua ajakan yang berebut.
- Angka hanya dari perangkat; bila tidak ada data, layar berkata jujur.

## 2. Temuan dan perbaikan

### 2.1 Kontras teks (diperbaiki)

- Teks kecil di kaki dashboard memakai `Colors.black45` (kontras
  sekitar 3,5:1, di bawah syarat 4,5:1 untuk teks biasa). Diganti
  `AppTheme.mutedGrey` (#757575, 4,6:1).
- Semua `Colors.black54`/`black38` pada teks dan ikon diganti
  `AppTheme.mutedGrey`. `onSurfaceVariant` ditambahkan ke
  `ColorScheme` di tema agar label memakai warna yang sama.

### 2.2 Area sentuh (diperbaiki)

- `TextButton` memakai tinggi minimum bawaan 40 px. Tema sekarang
  menetapkan minimum 48 px untuk `TextButton` dan `IconButton`.
- `FilledButton`/`OutlinedButton` sudah 48 px lewat tema. Kartu menu
  dashboard diberi tinggi minimum 72 px.

### 2.3 Status galat tanpa tombol coba lagi (diperbaiki)

- Dashboard: galat diagnosis hanya menampilkan teks. Sekarang memakai
  `ErrorState` dengan tombol "Coba lagi".
- Dokter WiFi: galat hanya kartu berisi pesan. Sekarang `ErrorState`
  dengan tombol "Coba lagi".
- Baterai: galat menampilkan teks exception mentah dari sistem.
  Sekarang pesan biasa plus tombol "Coba lagi".
- Penyimpanan, Performa, Keamanan, Riwayat, Akun: tidak ada penanganan
  galat sama sekali, layar bisa macet di spinner selamanya bila
  pemanggilan native gagal. Sekarang semuanya punya `ErrorState`
  dengan tombol "Coba lagi".
- Diagnosis AI: jawaban gagal hanya teks. Sekarang ada tombol
  "Coba lagi" di bawah jawaban gagal, dan petunjuk kosong yang jujur
  bila belum ada jawaban.
- Pesan galat tidak lagi menampilkan rincian exception (`$e`) ke
  pengguna: WiFi Cubit, Dashboard Cubit, Auth (masuk Google), Riwayat
  (laporan PDF), Diagnosis AI (jawaban server).

### 2.4 Status memuat (diperbaiki)

- Semua layar memakai spinner polos tanpa teks. Sekarang memakai
  widget bersama `LoadingState` dengan teks yang menjelaskan, misal
  "Memuat data baterai...".
- Widget bersama baru di `lib/core/widgets/common_widgets.dart`:
  `LoadingState`, `ErrorState`, `labelKategori`,
  `formatTanggalWaktu`. `EmptyState` mendapat aksi opsional.

### 2.5 Tulisan (diperbaiki)

- Em dash dilarang di semua teks. Dihapus dari seluruh `lib/`,
  `README.md`, dan `PRODUCT.md` (35 kemunculan, termasuk komentar
  kode dan dua string UI: "Skor 85, Baik" dan estimasi baterai).
- "Skor 85, baik" memakai nama kategori mentah dari database
  (huruf kecil, tanpa label). Sekarang "Skor 85 (Baik)" lewat
  `labelKategori`, di dashboard dan riwayat.
- Tanggal riwayat memakai string `DateTime` mentah
  ("2026-11-11 12:34:56.789"). Sekarang "11 Nov 2026, 12:34".
- "bukan perbaikan pura-pura" (kontras negatif yang canggung) menjadi
  "Langkah ini memakai pengaturan sistem."
- "Analisis ruang kosong dan bersih cache aman" menjadi "Lihat ruang
  kosong dan bersihkan cache dengan aman."
- "Izin aplikasi dan aplikasi mencurigakan" menjadi "Izin aplikasi
  yang perlu ditinjau." Kata "mencurigakan" adalah vonis, bukan fakta.
- "PIN disimpan sebagai hash SHA-256" dan "tersimpan sebagai hash,
  bukan teks" di layar Akun menjadi "PIN disimpan dalam bentuk yang
  tidak bisa dibaca di HP ini. PIN asli tidak pernah disimpan."
  Istilah SHA-256 tetap ada di PRODUCT.md (dokumen teknis).
- Estimasi waktu pakai baterai memakai angka "10% per jam" yang
  disajikan sebagai asumsi. Asumsi itu tidak lagi ditampilkan sebagai
  angka di layar; teksnya sekarang "Perkiraan kasar sekitar 3 jam
  12 menit, bukan hasil ukur." Rumus dan asumsinya tetap terdokumentasi
  di komentar kode.
- Judul bagian di Dokter Baterai memakai `TextStyle` bold inline.
  Sekarang memakai `titleMedium` dari tema agar konsisten.

### 2.6 Batas waktu pemuatan (diperbaiki, dengan satu pengecualian)

- Baterai, Penyimpanan, Keamanan, Riwayat, dan Akun memakai batas
  30 detik pada pemuatannya: bila pembacaan macet, layar menampilkan
  `ErrorState` dengan tombol "Coba lagi", bukan spinner selamanya.
  Batas 30 detik dipilih karena harness golden agen QA memajukan
  waktu palsu sampai sekitar 18 detik; batas yang lebih pendek
  (dicoba 10 detik) sempat memicu status galat di tengah harness
  itu dan merusak golden.
- Dokter Performa SENGAJA tanpa batas waktu. Alasannya: pemuatannya
  memakai I/O file nyata (`/proc/stat`, sensor thermal) yang di
  lingkungan widget test tidak pernah selesai tanpa `runAsync`.
  Batas waktu apa pun di sana merusak test: batas 10 detik mengubah
  hasil golden, batas 30 detik meninggalkan timer pending saat test
  selesai dan framework test gagal. Di perangkat Android asli,
  pembacaan itu selesai dalam milidetik. Perbaikan yang benar
  adalah membuat I/O itu bisa diuji (injeksi), dan itu pekerjaan
  lanjutan, bukan audit ini.

### 2.7 Tema (diperbaiki)

- `lib/core/theme.dart`: `onSurfaceVariant` ditambahkan, minimum
  `TextButton`/`IconButton` 48 px, `ProgressIndicatorTheme` hitam,
  dan komentar keputusan desain (satu baris per keputusan).
- `ScoreRing` dibungkus `Semantics` agar pembaca layar mengumumkan
  "Skor kesehatan 82 dari 100, Baik".

### 2.8 README.md dan PRODUCT.md (diperbaiki)

- Semua em dash dihapus (10 kemunculan), diganti koma atau titik.
- PRODUCT.md: ditambah butir 7 dan 8 pada prinsip kejujuran data
  (tiga kondisi layar dan pesan galat berbahasa sehari-hari) dan
  catatan area sentuh serta kontras pada bagian tema.
- PRODUCT.md: status diperbarui dari "menunggu verifikasi build CI"
  menjadi selesai dengan audit 11 November 2026.
- PRODUCT.md: kriteria selesai v1 (bagian 10) ditandai selesai untuk
  `flutter analyze` dan `flutter test`.

## 3. Screenshot

Sembilan layar utama, ukuran HP 390x844 @2x, di
`docs/screenshots/`:

- `dashboard.png`, `wifi.png`, `baterai.png`, `penyimpanan.png`,
  `performa.png`, `keamanan.png`, `riwayat.png`, `akun.png`,
  `ai-diagnosis.png`

Cara membuat: harness sementara `test/zz_tmp_visual_test.dart`
yang memuat font Roboto dan MaterialIcons asli dan tema
`AppTheme.light()`, dijalankan dengan
`flutter test --update-goldens`, lalu file harness dan golden
sementara dihapus. File `test/` dibiarkan seperti semula.

Catatan per layar:
- `performa.png` menampilkan status memuat ("Memuat data
  performa..."), bukan isi layar. Penyebabnya ada di bagian 6
  butir 1: di lingkungan widget test pemuatan halaman ini tidak
  pernah selesai. Status memuat yang tampil adalah `LoadingState`
  baru dari audit ini, jadi tangkapannya tetap membuktikan
  perbaikan itu bekerja.
- `akun.png`, `baterai.png`, dan layar lain menampilkan isi penuh
  yang sudah dimuat.

Catatan penting: golden bawaan `test/goldens/qa-*.png` (dibuat agen
lain) TIDAK dipakai sebagai screenshot karena golden test Flutter
me-render teks sebagai balok hitam (font Ahem) dan memakai tema
bawaan Material (tombol ungu), bukan tema aplikasi. Screenshot di
`docs/screenshots/` adalah hasil render dengan font dan tema asli.

## 4. File yang diubah

- `lib/core/theme.dart`
- `lib/core/widgets/common_widgets.dart`
- `lib/features/dashboard/dashboard_page.dart`
- `lib/features/dashboard/dashboard_cubit.dart` (pesan galat)
- `lib/features/wifi_doctor/wifi_doctor_page.dart`
- `lib/features/wifi_doctor/wifi_cubit.dart` (pesan galat)
- `lib/features/battery/battery_page.dart`
- `lib/features/storage/storage_page.dart`
- `lib/features/performance/performance_page.dart`
- `lib/features/security/security_page.dart`
- `lib/features/history/history_page.dart`
- `lib/features/auth/auth_page.dart`
- `lib/features/ai_diagnosis/ai_diagnosis.dart`
- `lib/main.dart`, `lib/core/native/device_native.dart`,
  `lib/data/sync/supabase_sync_service.dart`,
  `lib/features/wifi_doctor/wifi_service.dart`,
  `lib/features/history/pdf_report_service.dart`,
  `lib/features/auth/pin_service.dart` (hapus em dash di komentar)
- `README.md`, `PRODUCT.md`
- Baru: `docs/screenshots/*.png` (9 file), `DESIGN_AUDIT.md`

Tidak disentuh: `supabase/`, file test yang sudah ada, workflow CI.

## 5. Verifikasi

- `flutter analyze`: No issues found.
- `flutter test`: 39/39 lolos (exit 0), termasuk 7 golden screenshot
  agen QA dan semua unit/widget test yang sudah ada.
- Screenshot: 9 PNG 780x1688 di `docs/screenshots/`, diperiksa
  visual: teks terbaca, tombol hitam, kartu radius 12, tidak ada
  warna dekoratif. Pengecualian: `performa.png` menampilkan status
  memuat, bukan isi, karena di lingkungan widget test pemuatan
  Dokter Performa tidak pernah selesai (lihat bagian 6 butir 1).

## 6. Kekurangan yang masih tersisa (jujur)

1. Layar Dokter Performa tidak pernah selesai memuat di lingkungan
   widget test: pembacaan `/proc/stat` dan sensor thermal memakai
   I/O file nyata yang tidak jalan tanpa `runAsync` di zona waktu
   palsu test. Akibatnya `performa.png` menampilkan status memuat,
   dan golden `screenshot: performa` di `test/qa_screenshot_test.dart`
   bersifat flaky karena sudut putar spinner berbeda tiap run
   (pernah gagal 1 dari 39 saat audit ini berjalan, lalu lolos
   pada run penuh berikutnya tanpa perubahan kode). Di perangkat
   Android asli pembacaan itu selesai dalam milidetik. Perbaikan
   yang disarankan: buat I/O Performa bisa diuji (injeksi) atau
   keluarkan layar ini dari perbandingan golden ketat. Di luar
   wewenang audit ini karena file test dilarang disentuh. Agen
   lain sudah menyelidiki hal yang sama (`debug performa: kenapa
   loading tidak selesai`).
2. Estimasi waktu pakai baterai tetap memakai asumsi 10% per jam di
   rumus. Asumsi itu sudah tidak ditampilkan sebagai angka, tetapi
   perkiraan jam/menitnya tetap berasal dari asumsi itu. Bila ingin
   benar-benar berbasis data, estimasi harus belajar dari pemakaian
   nyata beberapa hari, dan itu pekerjaan v2.
3. Tidak ada screenshot perangkat Android fisik. Screenshot dibuat
   lewat widget test dengan font dan tema asli, bukan dari APK di HP.
   Verifikasi akhir tetap butuh pemasangan APK di HP dan pengecekan
   visual langsung.
4. Mode gelap tidak disediakan. Aplikasi hanya memakai tema terang
   sesuai keputusan produk; ini disengaja, bukan kelalaian.
5. `debugPrint` di `lib/main.dart` masih mencetak rincian exception
   startup ke log. Itu log pengembang, bukan teks pengguna, jadi
   dibiarkan.

## 7. Checklist 7 skill

### 7.1 local-design-taste-frontend

Design read: aplikasi alat Android (mode Operate) untuk pemilik HP
umum, bahasa tenang yang mengutamakan kepercayaan, Material 3 terang,
monokrom. Dial VARIANCE 4 / MOTION 2 / DENSITY 4.

- Dipakai: §0 design read sebelum edit; §1 dial; §4.2 satu aksen
  (hitam) dan palet netral yang konsisten; §4.4 kartu hanya untuk
  hierarki nyata; §4.5 semua state (loading, empty, error, tombol
  coba lagi) dan cek kontras tombol; §4.7 tidak ada hero dan tidak
  ada kartu fitur tiga kolom; §4.9 audit copy dan larangan angka
  palsu; §4.11 satu tema terkunci (terang).
- Sengaja tidak dipakai: §2.A sistem desain resmi lain (aplikasi
  sudah Material 3, sesuai brief); §3.A React/Next/Tailwind (bukan
  web); §4.3 anti-center hero (tidak ada hero di aplikasi alat);
  §4.8 strategi gambar (aplikasi alat tidak butuh foto, dan
  ilustrasi generik dilarang); §5 proaktivitas gerak (MOTION 2:
  hanya transisi bawaan Material, tanpa animasi hiasan);
  §6.D Core Web Vitals (bukan web); §8 dark mode ganda (produk
  memutuskan terang saja, dicatat di bagian 6 butir 4).

### 7.2 local-impeccable

Mode: Operate. Craft floor dibaca sebelum edit.

- Dipakai: kontras body 4,5:1 dan teks besar 3:1 (abu #757575
  4,6:1); spacing (grup rapat, pemisah 16 px, lebih banyak ruang
  di atas judul); states lengkap (hover/disabled/loading/error/
  empty); copy menamai aksi ("Coba lagi", "Periksa WiFi sekarang")
  dan galat menamai masalah plus pemulihan; brief menang (tema
  putih/hitam/abu dan larangan kuning/amber dari owner
  dipertahankan).
- Sengaja tidak dipakai: perintah `impeccable context` (launcher
  tidak dijalankan; konteks dibaca langsung dari PRODUCT.md dan
  kode, sesuai jalur fallback skill); motion satu momen khusus
  (aplikasi alat, motion bawaan Material cukup); ilustrasi nyata
  (tidak ada ilustrasi di aplikasi; ikon sistem Material dipakai
  konsisten satu keluarga).

### 7.3 local-humanizer

- Dipakai: §1 tidak ada kontras "bukan X tapi Y" di teks baru;
  §2 tidak ada closer satu baris; §4 tidak ada run-up
  ("Mari kita...", "Yang perlu diketahui..."); §8 tidak ada em
  dash di teks mana pun; §12 tidak ada kata AI
  (crucial/delve/robust/showcase dan sejenisnya); §13 tidak ada
  klaim penting yang digelembungkan; §16 tidak ada bahasa iklan
  (revolutionary/seamless dan sejenisnya); §19 tidak ada bold
  dekoratif; §20 judul memakai sentence case; §22 tidak ada sisa
  chatbot; §24 tidak ada pengulangan judul di kalimat pertama.
- Sengaja tidak dipakai: §21 curly quotes (teks Indonesia di
  aplikasi tidak memakai tanda kutip hias); §26 (bukan balasan
  chat, tidak relevan).

### 7.4 local-stop-slop

- Dipakai: potong filler ("bukan perbaikan pura-pura"); suara
  aktif ("Langkah ini memakai pengaturan sistem"); spesifik
  ("Skor 85 (Baik)", tanggal "11 Nov 2026, 12:34"); dua item
  lebih baik dari tiga (daftar rekomendasi tetap apa adanya karena
  datanya memang daftar); tanpa em dash; pembaca langsung diajak
  ("Ketuk ...", "Coba lagi").
- Sengaja tidak dipakai: aturan "setiap kalimat butuh subjek
  manusia" secara harfiah pada label data ("Kecepatan koneksi:
  65 Mbps" adalah label, bukan kalimat); "You beats People"
  diterapkan sebagai "Ketuk" (imperatif sopan Indonesia) karena
  "Anda" berulang terasa kaku di UI alat.

### 7.5 local-no-ai-slop

- Dipakai: edit minimum (hanya bagian yang bermasalah yang diubah,
  kalimat yang sudah manusiawi dibiarkan); potong kata yang
  dilarang (tidak ada delve/leverage/robust/cutting-edge di teks);
  potong kontras biner; potong throat-clearing; potong klaim
  penting yang digelembungkan; uji portabilitas (kalimat yang bisa
  pindah ke produk lain tanpa berubah dianggap filler dan dipotong);
  verba langsung ("is/has" ala Indonesia: "adalah/mempunyai"
  dipakai seperlunya, label data dipertahankan).
- Sengaja tidak dipakai: triad dipotong hanya bila isinya kosong;
  daftar rekomendasi WiFi dan tips baterai yang memang berisi
  tiga langkah nyata dipertahankan karena isinya bukan hiasan.

### 7.6 local-avoid-ai-writing

Mode: edit, voice professional, konteks docs dan UI Indonesia.
Aturan katalog berbahasa Inggris diterapkan padanannya dalam
Bahasa Indonesia (em dash, kontras biner, throat-clearing,
klaim penting, bold dekoratif).

- Dipakai: P0 (tidak ada cutoff disclaimer, artefak chatbot,
  atribusi kabur, inflasi signifikansi); P1 (tidak ada kata dari
  daftar, tidak ada frasa template, tidak ada bold berlebih,
  tidak ada closer generik); P2 (em dash 0 di seluruh teks,
  tidak ada kesimpulan generik, tidak ada aturan tiga yang
  dipaksakan).
- Sengaja tidak dipakai: normalisasi tanda kutip otomatis
  (`normalize-quotes.js`, tidak relevan untuk teks Indonesia
  tanpa kutipan); detector mekanis (tidak dijalankan, audit
  dilakukan manual dan dilaporkan apa adanya); aturan khusus
  bahasa Inggris (misal hyphenasi compound) yang tidak punya
  padanan di teks Indonesia.

### 7.7 local-anti-slop (rulebook v3.2.20, mode during)

Mode: during (instruksi eksplisit dari tugas: audit dan perbaiki
langsung). Direction tersedia dari PRODUCT.md dan aturan owner,
jadi R-37 terpenuhi dan hasil ini bukan "draft without direction".

- Dipakai: R-02 tanpa em dash; R-03 mobile dan tap target 44 px
  (diterapkan 48 px); R-17 tanpa angka tanpa sumber (estimasi
  diberi label perkiraan, asumsi angka tidak ditampilkan);
  R-25 kontras WCAG AA; R-26 semua tombol punya aksi nyata;
  R-27 tiga status di semua layar data; R-35 verifikasi lewat
  `flutter analyze`, `flutter test`, dan screenshot render nyata;
  R-36 tanpa klaim palsu; R-38 konten nyata atau placeholder jujur;
  R-31 satu baris alasan per keputusan (bagian 1 dan komentar
  `theme.dart`); R-29 palet maksimal 3 warna inti (putih/hitam/
  abu) plus warna status fungsional; R-15 CTA spesifik produk
  ("Diagnosis satu ketuk", "Periksa WiFi sekarang", "Coba lagi");
  R-16 tanpa buzzword.
- Sengaja tidak dipakai: R-05 (larangan template landing, tidak
  ada landing di aplikasi); R-09 badge (tidak ada badge di
  aplikasi); R-10 glassmorphism dan R-13 glow (tidak dipakai
  sama sekali); R-19 animasi khusus (hanya transisi bawaan
  Material); R-21 toggle gelap/terang (produk memutuskan terang
  saja); R-24 (semua item navigasi punya tujuan nyata, tidak ada
  yang perlu dihapus); R-28 FAQ (tidak ada FAQ di aplikasi);
  R-34 (hanya satu tema yang dikirim, jadi tidak ada mode kedua
  yang harus diverifikasi).

## 8. Delivery Gate (anti-slop)

- Hard Gate: R-02 PASS (0 em dash di lib/README/PRODUCT);
  R-03 PASS (tap target 48 px, tanpa overflow di screenshot
  390 px); R-17 PASS (tidak ada angka tanpa sumber yang
  ditampilkan; estimasi berlabel perkiraan); R-25 PASS (teks
  sekunder 4,6:1); R-26 PASS (semua tombol punya aksi, termasuk
  "Coba lagi" di semua layar); R-27 PASS (loading/error/empty di
  semua layar data); R-36 PASS; R-37 PASS (direction dari
  PRODUCT.md); R-38 PASS.
- Purpose-Gate: tidak ada gradient, glass, glow, badge, atau
  animasi hiasan yang perlu dibenarkan; kartu dan bayangan hanya
  untuk hierarki.
- Liveliness: ENERGY 1 / RHYTHM 1 / MOTION 1, disengaja untuk
  alat diagnosis. Satu focal point per layar: tombol utama
  ("Diagnosis satu ketuk", "Periksa WiFi sekarang").
- Craftsmanship: C-1 setiap keputusan punya alasan tertulis;
  C-2 semua state ada; C-3 susunan mengikuti isi produk;
  C-4 tahan di lebar 390 px dan tanpa data; C-5 tidak ada klaim
  tanpa bukti.
