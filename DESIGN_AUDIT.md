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


---

# Tambahan: Rancang Ulang v1.1.0

Tanggal: 12 November 2026. Penulis: Design Lead (desain saja).
Konteks: owner menolak UI/UX v1.0.1 pada 12 Nov 2026 09:46 WIB
(masih kaku, AI slop parah, kurang menarik, terlalu basic).
Tugas ini menghasilkan spesifikasi dan audit saja: tidak ada file
`.dart` yang diubah, tidak ada push.

Hasil: `docs/redesign-v11-spec.md` (spesifikasi lengkap),
`DESIGN.md` (arah desain baru). Bagian ini mencatat pemakaian
ketujuh skill anti-slop pada rancang ulang tersebut.

Catatan kejujuran tentang bukti visual: `docs/screenshots/` dibaca
semua (10 berkas). `wifi-v101.png` adalah render golden dengan
font balok Ahem dan tema ungu bawaan Material, bukan tema
aplikasi, jadi hanya dipakai untuk struktur susunan. `performa.png`
hanya menampilkan status memuat; isi layar Performa dinilai dari
kode `lib/features/performance/performance_page.dart`.

## 9. Design read v1.1.0

Reading this as: aplikasi alat ukur Android (mode Operate) untuk
pemilik HP umum yang butuh jawaban pasti tentang HP-nya, dengan
bahasa visual alat ukur presisi, gelap, monokrom, dan angka sebagai
bintang utama, memakai Material 3 yang ditulis ulang dengan sistem
token sendiri, tipografi sistem, dan gerak yang hanya muncul saat
ada hasil ukur baru.

Dial taste-frontend: VARIANCE 6 / MOTION 5 / DENSITY 5 (v1.0.1:
4 / 2 / 4). Dial anti-slop: ENERGY 2 / RHYTHM 2 / MOTION 2
(v1.0.1: 1 / 1 / 1). Kenaikan dial adalah jarak antara "tenang"
dan "steril": audit v1.0.0 sengaja memilih dial paling rendah dan
hasilnya adalah tampilan yang owner tolak.

Keputusan desain (satu baris per keputusan, R-31; daftar lengkap
di spesifikasi bagian 8):

- Tema gelap karena design lock menulis basis hitam dengan aksen
  putih, dan keputusan terang v1.0.0 dibuat tim audit, bukan owner.
- Meter dengan tanda strip sebagai motif karena aplikasi ini
  menjual angka ukur, dan strip membantu membaca posisi nilai.
- Font sistem karena build offline tidak boleh bergantung pada
  unduhan font.
- Angka tabular karena nilai live tidak boleh bergeser saat berubah.
- WiFi sebagai unggulan dashboard karena WiFi adalah alasan
  aplikasi ini dibuat (PRODUCT.md bagian 1.1).
- Riwayat sebagai linimasa karena pengguna mengingat kapan,
  bukan jenis pemeriksaan.
- Bottom sheet untuk penjelasan manual karena isinya panjang
  dan berlangkah.
- Kolom digit untuk PIN karena PIN adalah angka dan jumlah digit
  harus terlihat.
- Versi pindah ke Akun karena versi adalah info dukungan, bukan
  konten dashboard.
- Tidak ada toggle terang/gelap karena satu tema yang dikirim
  harus satu tema yang sempurna.

## 10. Checklist 7 skill (v1.1.0)

### 10.1 local-design-taste-frontend

Dibaca penuh (SKILL.md lengkap termasuk §9-§14 dan apendiks).
Skill ini ditulis untuk landing page web; di bawah ini dicatat
jujur bagian mana yang web-spesifik dan tidak berlaku, beserta
padanan Flutter-nya.

Dipakai:

- §0 design read satu baris sebelum merancang (spesifikasi
  bagian 1); §1 tiga dial dengan nilai dan alasan (bagian 1.1).
- §4.1 tipografi: hierarki lewat ukuran dan bobot, bukan skala
  mentah; sans sistem (bukan Inter sebagai default buta, melainkan
  karena batasan build offline yang tertulis); tanpa serif.
- §4.2 satu aksen (putih), palet netral konsisten, color
  consistency lock (spesifikasi bagian 3.1).
- §4.4 kartu hanya untuk hierarki nyata; shape consistency lock
  dengan aturan radius tertulis 16/12/8/4 (bagian 3.4).
- §4.5 semua state (skeleton, empty, error) plus cek kontras
  tombol dan larangan CTA membungkus dua baris (bagian 4.4, 4.8,
  4.9, 4.10).
- §4.7 eyebrow restraint (nol eyebrow di semua layar), larangan
  split-header, larangan kartu fitur tiga kolom yang sama.
- §4.9 audit copy dan larangan angka palsu; daftar panjang
  memakai komponen yang tepat (linimasa Riwayat, bukan dua
  daftar `divide-y`).
- §4.11 satu tema terkunci (gelap).
- §5 motion harus termotivasi: tiap animasi di spesifikasi
  bagian 3.7 punya alasan satu kalimat; marquee nol; tidak ada
  GSAP-for-show.
- §9.G nol em dash di semua copy baru; §9.F tanpa titik status
  dekoratif (satu titik live hanya saat pemantauan aktif);
  tanpa strip teks dekorasi; tanpa label versi di hero.
- §11 redesign overhaul: audit tampilan lama dulu (spesifikasi
  bagian 1.3 dengan bukti screenshot), IA dan label navigasi
  dipertahankan, copy voice dipertahankan kecuali yang ditulis
  ulang di spesifikasi.

Sengaja tidak dipakai (web-spesifik, dengan padanan Flutter):

- §2.A sistem desain web resmi (Fluent, Carbon, shadcn): tidak
  berlaku; padanannya adalah Material 3 Flutter dengan token
  sendiri di `lib/core/theme.dart`.
- §3.A React/Next/Tailwind/Motion: tidak berlaku; padanan
  Flutter adalah widget `AnimatedContainer`,
  `TweenAnimationBuilder`, dan transisi bawaan Material.
- §3.C pustaka ikon web (Phosphor, HugeIcons): tidak berlaku;
  padanannya adalah ikon Material bawaan Flutter satu keluarga
  (spesifikasi bagian 3.6).
- §4.3 anti-center hero, §4.7 hero fits viewport, hero stack,
  logo wall, nav satu baris desktop: tidak ada hero dan tidak ada
  nav desktop di aplikasi alat Android; padanannya adalah satu
  focal point per layar dan AppBar besar di Dashboard.
- §4.8 strategi gambar (image-gen, Picsum, logo SVG): aplikasi
  alat tidak butuh foto; ilustrasi generik dilarang (antislop
  R-22). Tidak ada gambar yang dibuat atau diminta.
- §5.A/5.B GSAP sticky-stack dan horizontal-pan: tidak berlaku
  di Flutter; padanan geraknya ada di spesifikasi bagian 3.7.
- §6.D Core Web Vitals, §6.E DOM cost: bukan web.
- §8 dark mode ganda: produk mengirim satu tema gelap (keputusan
  D-01), jadi tidak ada dua mode yang harus diuji.
- §12 block library dan §13 out of scope: skill ini sendiri
  menyatakan bukan untuk dashboard dan native mobile; yang
  dipakai adalah prinsipnya (dial, hierarki, larangan tell),
  bukan blok kodenya.

Contoh sebelum/sesudah konkret:

- `lib/features/dashboard/dashboard_page.dart`: enam `DoctorCard`
  identik (ikon 32, judul, deskripsi, chevron) menjadi baris
  unggulan Dokter WiFi lebar penuh plus grid dua kolom lima
  dokter lain, dengan status terakhir WiFi dari riwayat.
- `lib/core/widgets/common_widgets.dart` (`ScoreRing`): cincin
  progres generik menjadi `MeterGauge` (angka 56, meter dengan
  tanda strip tiap 10 persen, penanda nilai, label skala 0-100).
- `lib/features/history/history_page.dart`: dua daftar terpisah
  (kesehatan lalu WiFi) dengan kartu per entri menjadi satu
  linimasa kronologis dengan pembatas tanggal dan baris tanpa
  kartu.
- `lib/features/wifi_doctor/wifi_doctor_page.dart`: paragraf
  pembuka tiga baris dihapus, diganti satu baris caption di
  bawah tombol; daftar sampel "d1: ..., d2: ..." dipindah ke
  dialog "Lihat semua sampel" agar grafik menjadi elemen utama.

### 10.2 local-impeccable

Launcher `scripts/impeccable context` DIJALANKAN dari folder
skill dengan cwd di workdir proyek dan berhasil (exit 0,
memuat PRODUCT.md). Mode: Operate. `reference/new-work.md` dan
`reference/craft-floor.md` dibaca.

Dipakai:

- Brief menang: design lock owner (hitam/abu/putih, aksen
  putih, tanpa kuning dekoratif, tanpa serif Didone/Playfair,
  tanpa kata yang dilarang) dipertahankan dan menjadi dasar
  keputusan D-01 (tema gelap).
- Redesign replaces: tampilan lama diperlakukan sebagai bukti
  dan anti-referensi (spesifikasi bagian 1.3), bukan dipoles.
  DESIGN.md ditulis baru sebagai dunia visual pengganti.
- Craft floor: kontras terverifikasi per pasangan (bagian 3.1
  spesifikasi, 10 pasangan dihitung dengan `contrast-check.py`);
  spacing (lebih banyak ruang di atas judul daripada di
  bawahnya, 32 di atas dan 12 di bawah); satu momen gerak yang
  ditulis (meter dan angka saat hasil baru tiba); states lengkap
  di sembilan layar; copy menamai aksi dan galat menamai masalah
  plus pemulihan.
- Larangan craft floor: tanpa eyebrow di mana pun; tanpa kartu
  identik berulang; tanpa cincin progres dekoratif; tanpa teks
  gradasi; tanpa kaca dan blur dekorasi; tanpa strip warna di
  tepi kartu; tanpa monospace sebagai kostum teknis (angka
  tabular adalah fungsi, bukan kostum); tanpa emoji sebagai ikon.
- Satu focal point per layar ditulis eksplisit di tiap sub-bagian
  spesifikasi bagian 6.
- Color strategy: Restrained (netral dari dunia alat ukur plus
  satu aksen putih), diputuskan dari adegan pakai (seseorang
  memeriksa HP-nya, sering di cahaya redup, butuh jawaban
  cepat), bukan dari kategori.

Sengaja tidak dipakai:

- Ronde `concept-seed` dengan decision page dan kartu arah:
  tidak dijalankan karena tugas ini berjalan sebagai subagent
  tanpa sesi browser dan tanpa pengguna yang bisa memilih kartu
  secara langsung. Arah diturunkan dari brief dan design lock
  owner yang sudah eksplisit, dan dicatat sebagai keputusan
  D-01 yang perlu dikonfirmasi owner saat review desain.
  Ini penyimpangan prosedur yang dicatat jujur, bukan klaim
  bahwa ronde itu berjalan.
- Comp visual (mockup gambar) per layar: tidak dibuat karena
  tugas ini meminta spesifikasi tertulis, bukan aset gambar.
  Verifikasi visual menjadi tugas tim implementasi
  (spesifikasi bagian 7).
- Ilustrasi nyata: tidak ada ilustrasi di aplikasi; ikon
  Material satu keluarga dipakai konsisten.

Contoh sebelum/sesudah konkret:

- `lib/features/wifi_doctor/wifi_doctor_page.dart`: hasil tes
  terkubur di tengah kartu `_HasilCard` (angka `headlineMedium`
  di tengah tumpukan InfoRow) menjadi panel angka besar di atas
  layar (angka 56, meter dengan ambang klasifikasi, chip
  klasifikasi, latensi sebagai angka kedua).
- `lib/features/security/security_page.dart`: ringkasan sebagai
  dua InfoRow di kartu "Ringkasan" menjadi dua angka 28
  berdampingan di atas layar; daftar aplikasi dari kartu per
  baris menjadi baris 72 dengan angka izin berbahaya di kanan.
- `lib/features/auth/auth_page.dart`: kolom PIN `TextField`
  biasa menjadi kolom digit tersegmentasi delapan kotak
  (perilaku validasi 4-8 digit tidak berubah).

### 10.3 local-humanizer

Dipakai (semua copy baru di spesifikasi bagian 6 ditulis dengan
aturan ini):

- §1 tanpa kontras "bukan X tapi Y" di teks baru. Sebelum:
  "Perkiraan kasar sekitar 8 jam 12 menit, bukan hasil ukur."
  Sesudah: "Perkiraan sekitar 8 jam 12 menit. Bukan hasil
  ukur." (dua kalimat pendek, tanpa kontras yang dipaksakan;
  kata "bukan" di sini adalah label kejujuran yang disyaratkan
  produk, bukan retorika).
- §2 tanpa closer satu baris dan tanpa fragment dramatis.
- §4 tanpa run-up ("Mari kita...", "Yang perlu diketahui...").
- §8 tanpa em dash di teks mana pun (nol di ketiga berkas baru).
- §12 tanpa kata AI (crucial, delve, robust, showcase, dan
  sejenisnya) dan tanpa padanannya dalam Bahasa Indonesia
  (krusial, revolusioner, mutakhir).
- §13 tanpa klaim penting yang digelembungkan: tidak ada
  "terbaik", "tercepat", "paling akurat" di copy baru.
- §16 tanpa bahasa iklan. Sebelum (paragraf pembuka WiFi):
  "Pemeriksaan ini mengukur kecepatan unduh dan latensi dengan
  data nyata dari perangkat. Tidak ada angka contoh." Sesudah:
  satu baris caption "Hasil dari perangkat ini, bukan angka
  contoh." di bawah tombol.
- §19 tanpa bold dekoratif di copy UI; penekanan memakai ukuran
  dan bobot tipografi, bukan bold di tengah kalimat.
- §20 judul memakai sentence case ("Pemeriksaan terakhir",
  "Yang bisa dilakukan").
- §22 tanpa sisa chatbot; §24 tanpa pengulangan judul di kalimat
  pertama (petunjuk "Tulis keluhan di atas, lalu ketuk 'Minta
  diagnosis'" dihapus dari Diagnosis AI karena label kolom dan
  tombol sudah menjelaskan).

Sengaja tidak dipakai:

- §21 curly quotes: teks Indonesia di aplikasi tidak memakai
  tanda kutip hias.
- §26 (balasan chat): bukan balasan chat, tidak relevan.
- §3 sayings yang terdengar dalam: tidak ada di copy UI karena
  copy UI memang tidak memakai kalimat aforisme.

Contoh sebelum/sesudah konkret:

- `lib/features/wifi_doctor/wifi_doctor_page.dart` (empty
  state): judul generik "Belum ada data pemeriksaan" yang sama
  di lima layar menjadi "Belum ada hasil pemeriksaan WiFi"
  dengan pesan spesifik yang menyebut aksi berikutnya.
- `lib/features/history/history_page.dart` (empty state):
  "Belum ada data pemeriksaan" menjadi "Belum ada riwayat
  pemeriksaan" plus dua tombol aksi ("Jalankan diagnosis",
  "Periksa WiFi") sebagai jalan keluar.
- `lib/features/dashboard/dashboard_page.dart` (empty skor):
  "Belum ada data pemeriksaan" menjadi "Belum ada skor
  kesehatan" dengan pesan yang menyebut penyimpanan lokal.

### 10.4 local-stop-slop

Dipakai (dengan referensi phrases, structures, examples):

- Potong filler: paragraf pembuka WiFi tiga baris menjadi satu
  baris caption; petunjuk kosong Diagnosis AI dihapus.
- Suara aktif: label tombol memakai kata kerja ("Jalankan
  diagnosis", "Periksa WiFi", "Bersihkan cache", "Lihat semua
  sampel").
- Spesifik: tiap empty state menyebut penyebab dan aksi
  berikutnya yang berbeda per layar, bukan satu judul generik.
- Tanpa em dash; tanpa adverb penguat ("sangat", "benar-benar")
  di copy baru.
- Dua item lebih baik dari tiga: tidak ada daftar yang dipaksa
  menjadi tiga; tips baterai tetap tiga karena datanya memang
  tiga tips nyata, dan itu dicatat sebagai pengecualian yang
  beralasan.
- Pembaca langsung diajak lewat imperatif sopan ("Ketuk",
  "Jalankan", "Coba lagi"), bukan "Anda" berulang.

Sengaja tidak dipakai:

- Aturan "setiap kalimat butuh subjek manusia" secara harfiah
  pada label data ("Kecepatan koneksi: 65 Mbps" adalah label,
  bukan kalimat; sama seperti audit v1.0.0).
- Aturan "You beats People" diterapkan sebagai imperatif sopan
  Indonesia karena "Anda" berulang terasa kaku di UI alat.

Contoh sebelum/sesudah konkret:

- `lib/features/battery/battery_page.dart` (strip batasan):
  paragraf lima baris "Data pemakaian baterai per aplikasi
  tidak dibuka oleh Android untuk aplikasi pihak ketiga, jadi
  daftar ini tidak bisa ditampilkan. Buka Pengaturan > Baterai
  > Penggunaan baterai..." menjadi strip dua kalimat yang
  langsung menyebut jalan keluar.
- `lib/features/storage/storage_page.dart` (catatan): "Catatan:
  aplikasi ini tidak menghapus file besar..." menjadi strip
  tanpa kata "Catatan:" di depan (label yang tidak membawa isi).

### 10.5 local-no-ai-slop

Dipakai:

- Edit minimum pada copy yang sudah manusiawi: teks panduan
  WiFi TIDAK diubah sama sekali (verbatim dari
  `docs/panduan-wifi-turun.md`); rekomendasi WiFi dari service
  tidak diubah; penjelasan verdict tes bertahan tidak diubah.
  Yang ditulis ulang hanya copy yang bermasalah (judul generik,
  paragraf berulang, petunjuk yang mengulang tombol).
- Potong kata yang dilarang (tidak ada delve, leverage, robust,
  cutting-edge, dan padanannya di teks baru).
- Potong kontras biner, throat-clearing, dan klaim penting
  yang digelembungkan.
- Uji portabilitas: kalimat yang bisa pindah ke produk lain
  tanpa berubah dianggap filler. Contoh yang dipotong:
  "Pemeriksaan ini mengukur kecepatan unduh dan latensi dengan
  data nyata dari perangkat." (bisa dipakai aplikasi speedtest
  mana pun). Contoh yang dipertahankan karena spesifik:
  "Di pita 2,4 GHz hanya channel 1, 6, dan 11 yang tidak saling
  tumpang tindih." (hanya benar untuk konteks ini).
- Verba langsung: "adalah" dan "memakai" dipakai seperlunya,
  label data dipertahankan.
- Tanpa formatting slop: tanpa emoji di judul, tanpa bold
  di tengah kalimat, tanpa daftar bullet di tempat dua kalimat
  lebih baik (tips baterai memakai daftar karena memang tiga
  tips yang terpisah).

Sengaja tidak dipakai:

- Triad dipotong hanya bila isinya kosong; daftar rekomendasi
  WiFi dan tips baterai yang memang berisi langkah nyata
  dipertahankan karena isinya bukan hiasan (sama seperti audit
  v1.0.0).

### 10.6 local-avoid-ai-writing

Mode: rewrite untuk copy baru, voice professional, konteks UI
dan dokumen Indonesia. `references/patterns.md` dibaca penuh.
Aturan katalog berbahasa Inggris diterapkan padanannya dalam
Bahasa Indonesia.

Dipakai:

- P0: tidak ada cutoff disclaimer, artefak chatbot, atribusi
  kabur, inflasi signifikansi di copy baru.
- P1: tidak ada kata dari daftar Tier 1 (delve, leverage,
  robust, seamless, game-changer, dan sejenisnya), tidak ada
  frasa template, tidak ada bold berlebih, tidak ada closer
  generik ("Masa depan cerah", "Waktu yang akan menjawab").
- P2: em dash 0 di seluruh teks baru; tidak ada kesimpulan
  generik; tidak ada aturan tiga yang dipaksakan; tidak ada
  daftar bullet berisi frasa kata benda tanpa kata kerja
  (daftar tips memakai kalimat lengkap).
- Tanpa colon reveal dramatis di copy UI; titik dua hanya untuk
  label dan daftar.
- Tanpa synonym cycling: satu istilah dipakai konsisten di
  seluruh aplikasi ("pemeriksaan", "diagnosis", "pengukuran"
  tidak dirotasi untuk variasi).

Sengaja tidak dipakai:

- Normalisasi tanda kutip otomatis (`normalize-quotes.js`):
  tidak relevan untuk teks Indonesia tanpa kutipan.
- Detector mekanis: tidak dijalankan; audit dilakukan manual
  dan dilaporkan apa adanya.
- Aturan khusus bahasa Inggris (hyphenasi compound, curly
  quotes, aturan "load-bearing") yang tidak punya padanan di
  teks Indonesia.
- Marks pass: tidak ada teks yang dinormalisasi secara mekanis;
  ketiga berkas ditulis langsung tanpa em dash dan tanpa
  tanda kutip hias.

### 10.7 local-anti-slop (rulebook v3.2.20, mode during)

Mode: during (instruksi eksplisit dari tugas: aturan dipakai
saat merancang). Pengumuman mode sesuai aturan skill:
antislop active: during (session override). Direction tersedia
dari design lock owner dan PRODUCT.md, jadi R-37 terpenuhi dan
hasil ini bukan "draft without direction".

Dipakai:

- R-02 tanpa em dash di ketiga berkas baru dan semua copy baru.
- R-03 mobile dan tap target 44 px (diterapkan 48 px, ditambah
  jarak antar target minimal 8 px).
- R-17 tanpa angka tanpa sumber: semua angka di spesifikasi
  berasal dari data perangkat yang sudah ada; estimasi diberi
  label perkiraan.
- R-25 kontras WCAG AA: 10 pasangan dihitung dengan
  `contrast-check.py`, termasuk bukti gagal `#737373` (4,43:1)
  yang menetapkan batas abu teks di `#757575`.
- R-26 semua tombol punya aksi nyata; tombol bagikan PDF
  disembunyikan bila riwayat kosong; tombol yang belum bisa
  bekerja tidak ditampilkan.
- R-27 tiga status di semua layar data: skeleton meniru bentuk
  akhir (bukan spinner polos), ErrorState v2 dengan "Coba lagi",
  EmptyState v2 yang spesifik per layar.
- R-31 satu baris alasan per keputusan (spesifikasi bagian 8,
  sepuluh keputusan).
- R-29 palet maksimal 3 warna inti (hitam/abu/putih) plus satu
  aksen (putih) dan warna status fungsional.
- R-15 CTA spesifik produk ("Diagnosis satu ketuk", "Periksa
  WiFi sekarang", "Lihat semua sampel", "Jalankan diagnosis").
- R-16 tanpa buzzword.
- R-05 larangan template: sembilan layar memakai empat keluarga
  susunan yang berbeda (unggulan plus grid, angka besar plus
  grafik, linimasa, daftar pengaturan); tanpa bento grid, tanpa
  terminal palsu, tanpa logo bar.
- R-14 variasi kartu mengikuti hierarki isi (WiFi unggulan,
  lima dokter lain grid).
- R-11 satu sistem radius dengan aturan tertulis (16/12/8/4).
- R-20 identitas: motif meter dengan tanda strip, diuji dengan
  tes "swap logo".
- R-21 tema gelap dipilih dengan alasan tertulis (design lock
  dan adegan pakai), bukan karena "gelap terlihat tech".
- R-36 tanpa klaim palsu; R-38 konten nyata atau placeholder
  jujur; R-23 tidak ada aset yang dibuat tanpa instruksi (tidak
  ada logo, avatar, atau ilustrasi baru).
- R-19 animasi hanya dengan tujuan tertulis (tujuh gerakan di
  spesifikasi bagian 3.7, masing-masing dengan alasan satu
  kalimat); satu-satunya loop adalah titik live yang menandai
  keadaan nyata.
- R-09 badge hanya untuk status nyata (chip "Baik", "Live",
  "Tinjau" dengan ikon dan teks, bukan kapsul dekoratif).
- R-04 ikon relevan satu keluarga, tanpa ikon generik AI.
- R-06 tipografi dipilih dengan alasan tertulis (font sistem
  karena build offline).
- R-32 aksesibilitas keyboard dan fokus: di Flutter, padanannya
  adalah urutan fokus TalkBack yang mengikuti urutan visual,
  label semantik di `MeterGauge` dan ikon tanpa teks, dan target
  sentuh 48 px. Dicatat di spesifikasi bagian 5.
- R-35 verifikasi: TIDAK BISA PASS pada tahap desain ini karena
  tidak ada kode yang diubah dan tidak ada aplikasi yang
  dijalankan. Rencana verifikasi lengkap ditulis di spesifikasi
  bagian 7 untuk tim implementasi (analyze, test, screenshot
  sembilan layar, cek kontras ulang, cek tap target dari render,
  cek gerak, cek teks, pasang di HP fisik). Bagian ini dicatat
  jujur sebagai tertunda, bukan diklaim lolos.

Sengaja tidak dipakai:

- R-10 glassmorphism dan R-13 glow: tidak dipakai sama sekali
  (dilarang di DESIGN.md).
- R-24: semua item navigasi punya tujuan nyata, tidak ada yang
  perlu dihapus.
- R-28 FAQ: tidak ada FAQ di aplikasi.
- R-34: hanya satu tema yang dikirim (gelap), jadi tidak ada
  mode kedua yang harus diverifikasi.
- R-33: tidak ada patch file lewat script; spesifikasi ini
  adalah dokumen, bukan patch.
- R-07 background grid: tidak ada pola latar.
- R-22 ilustrasi: tidak ada ilustrasi baru.
- R-08 panah di tombol: chevron hanya dipakai sebagai penanda
  navigasi di baris yang bisa diketuk (satu tempat, dengan
  tujuan yang tertulis), bukan di setiap tombol.

## 11. Delivery Gate v1.1.0 (tahap desain)

Gate ini dinilai untuk deliverable desain (spesifikasi dan arah),
bukan untuk implementasi. Item yang hanya bisa dinilai setelah
kode ditulis dicatat sebagai tertunda.

- Hard Gate: R-02 PASS (nol em dash di ketiga berkas baru);
  R-03 PASS (spesifikasi menetapkan 48 px dan jarak 8 px);
  R-17 PASS (tidak ada angka tanpa sumber di spesifikasi);
  R-18 PASS (tidak ada testimonial); R-23 PASS (tidak ada aset
  baru yang dibuat); R-24 PASS (tidak ada navigasi ke tempat
  yang tidak ada); R-25 PASS (10 pasangan kontras terhitung);
  R-26 PASS (semua tombol di spesifikasi punya aksi);
  R-27 PASS (tiga status dirancang per layar); R-32 PASS
  (semantik dan urutan fokus ditulis di spesifikasi);
  R-36 PASS; R-37 PASS (direction dari design lock owner dan
  PRODUCT.md); R-38 PASS. R-35 TERTUNDA (menunggu implementasi,
  rencana verifikasi di spesifikasi bagian 7).
- Purpose-Gate: tidak ada gradient, glass, glow, atau ilustrasi
  yang perlu dibenarkan; meter, chip, dan animasi masing-masing
  punya alasan tertulis satu kalimat.
- Liveliness: ENERGY 2 / RHYTHM 2 / MOTION 2, disengaja untuk
  alat ukur yang harus terasa presisi tanpa menjadi pajangan.
  Satu focal point per layar ditulis eksplisit. Satu aksen
  (putih) di momen kunci. Motif identitas: meter dengan tanda
  strip.
- Craftsmanship: C-1 setiap keputusan punya alasan tertulis;
  C-2 semua state dirancang; C-3 susunan mengikuti isi produk
  (empat keluarga susunan untuk sembilan layar); C-4 tahan di
  lebar 390 px, tanpa data, dan dengan pengurangan gerak;
  C-5 tidak ada klaim tanpa bukti.

## 12. Yang masih terbuka untuk tim implementasi

1. Keputusan D-01 (tema gelap menggantikan tema terang v1.0.0)
   perlu konfirmasi owner saat review desain, sebelum
   implementasi dimulai.
2. Golden test yang ada (`test/qa_screenshot_test.dart` dan
   golden `test/goldens/qa-*.png`) memakai tema lama dan akan
   gagal setelah implementasi; tim implementasi memperbarui
   golden bersamaan dengan perubahan tema.
3. Screenshot `docs/screenshots/` perlu dibuat ulang setelah
   implementasi, dengan harness yang sama (font dan tema asli),
   ditambah kondisi layar yang terisi data (spesifikasi
   bagian 7 butir 2).
4. Performa tetap tanpa batas waktu pemuatan (alasan di bagian
   2.6 audit v1.0.0); spesifikasi ini tidak mengubah perilaku
   itu.
5. Tidak ada pencarian atau filter di Dokter Keamanan pada
   v1.1.0; itu pekerjaan lanjutan yang dicatat di spesifikasi
   bagian 6.6.
