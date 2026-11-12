# Spesifikasi Rancang Ulang UI/UX Dokter HP v1.1.0

Status: spesifikasi desain. Berlaku untuk implementasi v1.1.0.
Basis: main `db85d8f7`, v1.0.1+2. Tanggal: 12 November 2026.
Penulis: Design Lead (tugas desain saja, tanpa perubahan kode).

Dokumen ini bisa dipakai tim implementasi Flutter tanpa bertanya lagi.
Bila ada yang bertabrakan dengan dokumen ini, yang menang adalah
DESIGN.md (arah desain) untuk soal rasa, dan dokumen ini untuk soal
ukuran dan perilaku.

## 0. Ruang lingkup dan yang tidak berubah

Rancang ulang ini hanya mengubah tampilan. Semua fitur v1.0.1 tetap
ada dan tetap bekerja dengan cara yang sama:

- Navigasi dan label menu tidak berubah (Dashboard, Dokter WiFi,
  Dokter Baterai, Dokter Penyimpanan, Dokter Performa, Dokter
  Keamanan, Riwayat, Diagnosis AI, Akun dan keamanan).
- Semua data tetap data nyata dari perangkat. Tidak ada data contoh.
- Teks kartu panduan WiFi ("WiFi turun ke KB/detik? Cek dulu sebelum
  panik") WAJIB tetap kata per kata dari `docs/panduan-wifi-turun.md`.
  Hanya tampilannya yang berubah, isinya tidak boleh diparafrase.
- Prinsip kejujuran data PRODUCT.md bagian 9 tetap berlaku penuh.
- Layar kunci PIN/biometrik (`LockGate`) di luar ruang lingkup
  rancang ulang ini, kecuali penyesuaian token warna agar konsisten
  dengan tema baru. Fungsinya tidak berubah.
- Font tetap font sistem (keputusan build offline, PRODUCT.md
  bagian 8). Tidak ada unduhan font.

Satu keputusan besar yang berubah dan perlu dikonfirmasi owner saat
review desain (lihat D-01): tema terang v1.0.0 diganti tema gelap.
Alasannya ada di bagian 1 dan 3.1. Selain itu tidak ada keputusan
yang menunggu owner.

## 1. Design Read dan dial

Design Read (ala design-taste-frontend §0):

Reading this as: aplikasi alat ukur Android (mode Operate) untuk
pemilik HP umum yang butuh jawaban pasti tentang HP-nya, dengan
bahasa visual alat ukur presisi, gelap, monokrom, dan angka sebagai
bintang utama, leaning toward Material 3 yang ditulis ulang dengan
sistem token sendiri, tipografi sistem, dan gerak yang hanya muncul
saat ada hasil ukur baru.

### 1.1 Dial design-taste-frontend

| Dial | Nilai | Alasan |
|---|---|---|
| DESIGN_VARIANCE | 6 | Di atas simetri template (v1.0.1 ada di 4) karena dashboard memakai susunan asimetris: satu fitur unggulan lebar penuh plus grid dua kolom. Tidak lebih tinggi karena ini alat, bukan portofolio; keterbacaan data di atas kejutan komposisi. |
| MOTION_INTENSITY | 5 | Gerak hanya untuk transisi hasil ukur: jarum meter bergerak saat skor baru tiba, angka menghitung naik saat diagnosis selesai, nilai live berubah dengan transisi halus. Tidak ada animasi hiasan dan tidak ada loop tanpa henti, kecuali satu titik live yang memang menandai pemantauan aktif. |
| VISUAL_DENSITY | 5 | Layar data (WiFi, Performa, Keamanan) padat informasi nyata, tetapi tiap layar punya satu angka besar yang diberi ruang napas. Bukan kokpit (8+), bukan galeri (2). |

Perubahan dari v1.0.1 (VARIANCE 4 / MOTION 2 / DENSITY 4): naik satu
sampai tiga tingkat di tiap dial. Itulah jarak antara "tenang" dan
"steril". Audit v1.0.0 sengaja memilih dial paling rendah dan
hasilnya adalah tampilan yang owner tolak: semua layar tampak sama.

### 1.2 Dial anti-slop

ENERGY 2 / RHYTHM 2 / MOTION 2 (v1.0.1: 1 / 1 / 1).

- ENERGY 2: desain menyapa dengan satu angka besar dan satu tombol
  putih yang jelas, bukan dengan kartu abu yang semuanya sama.
- RHYTHM 2: komposisi berubah antar layar. Dashboard memakai
  unggulan plus grid, WiFi memakai angka besar plus grafik,
  Riwayat memakai linimasa, Akun memakai daftar pengaturan.
  Kesembilan layar tidak lagi memakai satu cetakan tumpukan kartu.
- MOTION 2: transisi hasil ukur dan perubahan status, bukan
  dekorasi gerak.

### 1.3 Diagnosis tampilan v1.0.1 (bukti dari screenshot)

Dibaca dari `docs/screenshots/` (10 berkas, 12 Nov 2026) dan kode
layar. Catatan kejujuran: `wifi-v101.png` adalah render golden
dengan font balok Ahem dan tema ungu bawaan Material, bukan tema
aplikasi, jadi hanya dipakai untuk struktur susunan, bukan untuk
menilai warna atau tipografi. `performa.png` hanya menampilkan
status memuat; isi layar Performa dinilai dari kode.

| Temuan | Bukti | Aturan yang dilanggar |
|---|---|---|
| Semua layar memakai satu cetakan: judul AppBar, lalu tumpukan kartu radius 12 yang identik, padding 16 di mana-mana | `dashboard.png`, `baterai.png`, `akun.png`, `ai-diagnosis.png` | antislop R-05 (uniform section rhythm), R-14 (copy-paste feature cards); taste §4.4 |
| Keenam kartu dokter identik: ikon 32, judul, deskripsi dua baris, chevron kanan. Fitur utama (WiFi) tidak dibedakan dari yang lain | `dashboard.png` | antislop R-14, C-3; impeccable craft floor (same-size cards of icon plus heading plus text) |
| Lima empty state memakai bentuk yang sama persis: ikon abu 48 di tengah, judul tengah, pesan tengah | `dashboard.png`, `wifi.png`, `penyimpanan.png`, `keamanan.png`, `riwayat.png` | antislop-ui (placeholder empty states: tidak menyebut penyebab dan aksi berikutnya dengan spesifik) |
| Status memuat di semua layar hanya spinner polos plus satu baris teks, tanpa bentuk layar yang akan datang | `performa.png` | taste §4.5 (skeleton harus meniru bentuk akhir); antislop R-27 |
| Tidak ada hierarki tipografi yang nyata: judul bagian selalu `titleMedium`, angka besar selalu `displayMedium`, label dan nilai selalu `bodyMedium` | Semua berkas layar | taste §4.1; impeccable craft floor (obvious scale and weight steps) |
| Skor kesehatan memakai cincin progres generik (ScoreRing), bentuk yang dipakai ribuan aplikasi alat | `lib/core/widgets/common_widgets.dart` | impeccable craft floor (progress rings standing in for content); antislop R-20 (tidak ada identitas) |
| Baris label dan nilai (InfoRow) dipakai untuk semua data, tanpa pembedaan antara angka yang penting dan angka pelengkap | `baterai.png`, `wifi_doctor_page.dart` | taste §4.9 (long lists need a different UI component) |
| Banner mode lokal tampil sebagai kartu penuh di tiga layar (Dashboard, AI, Akun) dengan bobot visual sama seperti konten utama | `dashboard.png`, `akun.png`, `ai-diagnosis.png` | antislop C-1 (elemen tanpa alasan hierarki yang jelas) |
| Tidak ada satu pun elemen yang membuat aplikasi ini dikenali bila nama dan logonya diganti | Keseluruhan | antislop R-20, tes "swap logo" di core principle |

## 2. Arah visual baru: alat ukur

Konsep: Dokter HP adalah alat ukur, bukan dasbor. Yang dijual
aplikasi ini adalah angka yang bisa dipercaya: skor, kecepatan,
persen, suhu, jumlah izin. Desain baru menaruh angka di depan dan
memperlakukan layar seperti panel instrumen: satu angka besar,
skala ukur dengan tanda strip (tick), label kecil yang jelas,
dan tombol yang tidak ragu.

Motif identitas: **meter dengan tanda strip**. Satu garis ukur
horizontal dengan strip kecil di tiap interval, plus penanda
posisi nilai. Motif ini dipakai di skor dashboard, kecepatan WiFi,
baterai, penyimpanan, RAM, CPU, dan suhu. Satu motif, diulang
dengan konsisten, adalah yang membuat aplikasi ini dikenali
(antislop Part 3: identity motif). Motif ini bukan hiasan: strip
membantu mata membaca posisi nilai dalam skala tanpa membaca angka
satuan.

Yang bukan arah ini: tema medis (palang merah, stetoskop, ilustrasi
dokter), tema "AI" (orb, sparkle, gradasi ungu), tema kartu
berwarna, dan tema neobrutalis (bayangan blok keras). Semuanya
dilarang di DESIGN.md.

## 3. Sistem desain

### 3.1 Warna

Keputusan D-01 (perlu konfirmasi owner saat review): tema terang
v1.0.1 diganti tema gelap. Alasan, satu baris per poin:

- Design lock tugas ini menulis basis hitam/abu/putih dengan aksen
  putih, dan itu yang dipakai owner di produk lain (portofolio
  memakai hitam murni `#000000`).
- Keputusan terang v1.0.0 dibuat tim audit, bukan owner, dan owner
  sudah menolak keseluruhan tampilan itu.
- Panel instrumen yang gelap membuat angka putih dan warna status
  fungsional terbaca lebih cepat, dan layar AMOLED menghemat daya.
- Satu tema saja yang dikirim (tema gelap), sesuai taste §4.11
  (page theme lock). Tidak ada toggle terang/gelap di v1.1.0.

Token permukaan (satu sistem, jangan tambah warna lain):

| Token | Nilai | Dipakai untuk |
|---|---|---|
| `bg` | `#000000` | Latar seluruh layar |
| `surface` | `#111111` | Kartu dan panel |
| `surfaceRaised` | `#1C1C1C` | Kartu di atas kartu, dialog, bottom sheet |
| `line` | `#262626` | Garis pemisah dan bingkai kartu (1 px) |
| `lineStrong` | `#3D3D3D` | Bingkai elemen interaktif (input, tombol outline) |
| `textPrimary` | `#FFFFFF` | Semua teks utama dan angka |
| `textSecondary` | `#A3A3A3` | Label, keterangan, nilai pelengkap |
| `textFaint` | `#757575` | Hanya untuk teks yang memang boleh redup (cap waktu, catatan kaki). Ini batas paling redup yang lolos 4,5:1 di atas hitam. Jangan pakai abu yang lebih gelap untuk teks. |
| `accent` | `#FFFFFF` | Tombol utama (latar putih, teks hitam), penanda meter, elemen fokus |
| `track` | `#2A2A2A` | Jalur meter dan progres yang belum terisi |

Warna status fungsional saja (bukan dekorasi). Dipakai hanya untuk
arti status, selalu ditemani teks atau ikon (tidak pernah warna
saja, antislop-human):

| Token | Nilai | Arti |
|---|---|---|
| `success` | `#4ADE80` | Baik, bertahan, sukses |
| `danger` | `#F87171` | Perlu perhatian, gagal, jatuh |
| `warning` | `#FACC15` | Cukup, tidak stabil, menunggu. Ini satu-satunya kuning yang diizinkan, dan hanya sebagai status. |
| `info` | `#60A5FA` | Info sistem, tautan penjelasan |

Kontras terverifikasi dengan `contrast-check.py` (skill
antislop-human) pada 12 Nov 2026:

| Pasangan | Rasio | Hasil |
|---|---|---|
| `#FFFFFF` di `#000000` | 21,00:1 | Lolos |
| `#A3A3A3` di `#000000` | 8,33:1 | Lolos |
| `#A3A3A3` di `#111111` | 7,49:1 | Lolos |
| `#757575` di `#000000` | 4,56:1 | Lolos (batas bawah) |
| `#4ADE80` di `#000000` | 12,05:1 | Lolos |
| `#F87171` di `#000000` | 7,59:1 | Lolos |
| `#60A5FA` di `#000000` | 8,26:1 | Lolos |
| `#FACC15` di `#000000` | 13,71:1 | Lolos |
| `#000000` di `#FFFFFF` (teks tombol utama) | 21,00:1 | Lolos |
| `#737373` di `#000000` | 4,43:1 | GAGAL. Bukti bahwa `#757575` adalah batas, bukan tebakan. |

Aturan warna yang mengikat:

- Tidak ada gradasi warna di mana pun (antislop R-01, tanpa tujuan
  hierarki yang tertulis). Satu-satunya pengecualian: tidak ada.
- Tidak ada glow, tidak ada bayangan berwarna, tidak ada blur kaca
  (R-10, R-12, R-13). Kedalaman ditunjukkan dengan permukaan yang
  lebih terang (`#111111` di atas `#000000`), bukan bayangan.
- Warna status tidak pernah dipakai sebagai latar tombol, latar
  kartu, atau dekorasi. Warna status hanya muncul sebagai teks,
  ikon kecil, chip, atau isi meter.
- Logo Google (tombol masuk) memakai warna brand aslinya, sesuai
  design lock (logo brand pihak ketiga dikecualikan).

### 3.2 Tipografi

Font tetap font sistem (Roboto di Android). Alasan: build offline
tidak boleh gagal karena unduhan font (PRODUCT.md bagian 8). Karakter
tipografi dibangun dari ukuran, bobot, dan jarak, bukan dari jenis
font baru. Dilarang memakai serif Didone/Playfair di mana pun.

Angka memakai angka tabular (`FontFeature.tabularFigures`) agar
lebar digit sama dan angka tidak bergeser saat nilai berubah
(penting untuk pemantau live dan tes bertahan).

Skala (satu sistem, semua layar memakai token ini, bukan ukuran
bebas):

| Token | Ukuran / bobot / tinggi baris | Dipakai untuk |
|---|---|---|
| `display` | 56 / 700 / 1,0, tracking -0,02em, tabular | Satu angka besar per layar (skor, kecepatan, persen baterai) |
| `headline` | 28 / 700 / 1,15 | Judul layar (AppBar besar di Dashboard) |
| `title` | 20 / 700 / 1,25 | Judul layar di AppBar biasa |
| `section` | 17 / 600 / 1,3 | Judul bagian di dalam layar |
| `body` | 15 / 400 / 1,5 | Isi, penjelasan, jawaban AI |
| `label` | 13 / 500 / 1,4, warna `textSecondary` | Label di atas nilai, keterangan baris |
| `caption` | 12 / 400 / 1,4, warna `textSecondary` | Cap waktu, catatan kaki. Minimal 12, tidak ada teks 10-11. |

Aturan tipografi:

- Judul memakai sentence case ("Dokter WiFi", "Pemeriksaan
  terakhir"), bukan Title Case dan bukan huruf kapital semua.
- Tidak ada label eyebrow (label kecil kapital dengan tracking
  lebar di atas judul). Larangan ini mutlak di taste §4.7 dan
  impeccable craft floor. Judul berdiri sendiri.
- Tidak ada teks miring untuk penekanan di UI. Penekanan memakai
  bobot atau ukuran.
- Tidak ada em dash di teks mana pun (R-02). Pakai koma, titik,
  atau dua kalimat.
- Judul bagian tidak pernah diikuti kalimat yang mengulang judul
  itu (humanizer §24).

### 3.3 Spacing

Skala 4 pt: 4, 8, 12, 16, 20, 24, 32, 48. Pemakaian yang mengikat:

| Tempat | Nilai |
|---|---|
| Padding horizontal halaman | 20 |
| Jarak antar bagian besar | 32 |
| Jarak antar kartu dalam satu kelompok | 12 |
| Padding dalam kartu | 20 (bukan 16, agar isi tidak menempel) |
| Jarak label ke nilai di bawahnya | 4 |
| Jarak judul bagian ke isi di bawahnya | 12 |
| Ruang di atas judul bagian lebih besar dari di bawahnya | 32 di atas, 12 di bawah (craft floor) |
| Padding bawah akhir daftar | 32, ditambah safe area |

### 3.4 Radius (satu sistem, aturan tertulis)

| Elemen | Radius |
|---|---|
| Kartu dan panel | 16 |
| Tombol utama, tombol outline, input teks | 12 |
| Chip status, lencana kecil | 8 |
| Bilah meter dan progres | 4 |
| Titik live, indikator status bulat | Penuh (lingkaran) |

Dilarang membuat semua elemen berbentuk pil (R-11). Dilarang radius
bebas di luar tabel ini.

### 3.5 Garis dan elevasi

- Kartu memakai latar `surface` plus bingkai 1 px `line`. Tanpa
  bayangan. Tanpa bayangan lembut di mana pun.
- Pemisah antar baris data memakai garis 1 px `line`, tetapi hanya
  di antara kelompok, bukan di bawah setiap baris (taste §9.F:
  larangan hairline di tiap baris). Di dalam satu kelompok,
  baris dipisah ruang 12, bukan garis.
- Dialog dan bottom sheet memakai `surfaceRaised` plus bingkai
  `lineStrong`.
- Tidak ada garis vertikal berwarna di tepi kartu (antislop-ui:
  colored left stripe). Status ditunjukkan chip dan teks, bukan
  strip.

### 3.6 Ikon

- Satu keluarga: ikon Material bawaan Flutter (`Icons.*`), gaya
  outline untuk ikon navigasi dan isi, gaya filled hanya untuk
  ikon yang memang menandai keadaan aktif (misal baterai penuh).
- Ukuran standar: 20 untuk ikon di baris dan tombol, 24 untuk
  ikon AppBar, 28 untuk ikon fitur di grid dashboard.
- Dilarang ikon sparkle, bintang, sihir, petir, berlian, robot,
  dan orb AI (R-04). Diagnosis AI memakai ikon `psychology`
  yang sudah ada, bukan ikon sparkle.
- Dilarang emoji di teks UI mana pun.
- Setiap ikon yang berdiri sendiri (tanpa teks di sampingnya)
  wajib punya tooltip atau label semantik.

### 3.7 Gerak

Satu tata gerak untuk seluruh aplikasi. Durasi: 200 ms untuk
umpan balik ketuk, 350 ms untuk transisi hasil, 600 ms untuk
hitungan angka. Easing: `Curves.easeOutCubic` untuk masuk,
`Curves.easeInOutCubic` untuk perubahan nilai.

| Gerakan | Alasan (satu kalimat) | Tempat |
|---|---|---|
| Jarum meter meluncur ke nilai baru (350 ms) | Menunjukkan bahwa angka ini hasil ukur yang baru tiba, bukan angka statis | Skor dashboard, kecepatan WiFi, baterai, RAM, CPU |
| Angka menghitung dari nilai lama ke nilai baru (600 ms) | Mata mengikuti perubahan dan memahami bahwa diagnosis menghasilkan sesuatu | Skor dashboard setelah diagnosis, kecepatan setelah tes WiFi |
| Nilai live berubah dengan crossfade 200 ms | Pembaruan tiap 2 detik tidak boleh berkedip kasar | Pemantau live WiFi |
| Batang grafik tes bertahan tumbuh satu per satu tiap detik | Grafik dibangun oleh tes yang sedang berjalan, jadi pengguna melihat datanya terkumpul | Tes bertahan 30 detik |
| Skeleton shimmer mengikuti bentuk layar akhir | Pengguna tahu bentuk konten yang sedang dimuat, bukan hanya menunggu | Semua layar data saat memuat |
| Tekan tombol: skala 0,97 selama 100 ms | Umpan balik sentuhan yang terasa fisik | Semua tombol |
| Transisi antar layar: bawaan Material (slide + fade) | Konsisten dengan platform, tidak perlu gerak kustom | Navigasi |

Larangan gerak:

- Tidak ada animasi loop tanpa henti kecuali titik live (satu
  titik, denyut halus 1,2 detik, hanya saat pemantau live aktif).
- Tidak ada animasi masuk berurutan (stagger) di daftar. Daftar
  muncul sekaligus.
- Tidak ada parallax, tidak ada animasi scroll, tidak ada
  marquee.
- Hormati pengaturan aksesibilitas: bila pengguna mengaktifkan
  pengurangan gerak di sistem, semua gerak di atas menjadi
  instan (nilai akhir langsung tampil). Implementasi memakai
  `MediaQuery.disableAnimations` atau `AnimationController`
  dengan durasi nol saat pengaturan itu aktif.

## 4. Sistem komponen

Semua komponen di bawah ini hidup di `lib/core/widgets/` (baru
atau revisi dari `common_widgets.dart`). Layar tidak boleh membuat
varian sendiri di luar sistem ini.

### 4.1 MeterGauge (komponen baru, motif identitas)

Pengganti `ScoreRing`. Meter horizontal dengan tanda strip.

Anatomi: angka besar (`display`, tabular) di kiri atas, label
kategori sebagai `StatusChip` di kanan angka, garis meter di
bawah angka (tinggi 8, radius 4, jalur `track`), strip vertikal
1 px tiap 10% di atas garis, penanda nilai berupa blok putih
lebar 3 px setinggi 16 yang menembus garis, dan label skala
("0" di kiri, "100" di kanan, `caption`) di bawah garis.

Perilaku: saat nilai berubah, penanda meluncur (350 ms) dan angka
menghitung (600 ms). Warna isi meter: putih untuk nilai netral,
warna status hanya untuk kategori (hijau bila Baik, kuning bila
Cukup, merah bila Perlu perhatian). Isi meter tidak pernah
bergradasi.

Varian ukuran: `large` (dashboard, WiFi, baterai) dengan angka
56, dan `compact` (Performa, Penyimpanan) dengan angka 28 dan
garis tinggi 6.

Semantik: `Semantics` mengumumkan "Skor kesehatan 82 dari 100,
Baik" (perilaku lama dipertahankan).

### 4.2 StatRow (pengganti InfoRow)

Satu baris data: label (`label`, `textSecondary`) di kiri, nilai
(`body`, tabular untuk angka) di kanan. Nilai yang tidak tersedia
menampilkan "Tidak tersedia" dengan warna `textSecondary`, bukan
tanda strip.

Aturan: baris dalam satu kelompok dipisah ruang 12, tanpa garis.
Garis pemisah hanya di antara kelompok yang berbeda arti.
Nilai terpenting di layar tidak memakai StatRow, melainkan
`MeterGauge` atau angka `display`.

### 4.3 StatusChip

Chip kecil (radius 8, padding horizontal 10, vertikal 6): ikon
16 plus teks `label`. Selalu berpasangan ikon dan teks, tidak
pernah warna saja. Latar: warna status dengan opasitas 12 persen
di atas `surface`, teks memakai warna status penuh, tanpa bingkai.
Contoh: chip "Baik" (ikon centang, hijau), "Perlu perhatian"
(ikon peringatan, merah), "Live" (titik denyut, hijau).

### 4.4 Tombol

| Jenis | Tampilan | Dipakai untuk |
|---|---|---|
| Utama | Latar putih, teks hitam 15/600, tinggi 56, radius 12, ikon 20 di kiri label bila ada | Satu aksi utama per layar ("Diagnosis satu ketuk", "Periksa WiFi sekarang", "Minta diagnosis") |
| Sekunder | Latar transparan, bingkai 1 px `lineStrong`, teks putih 15/600, tinggi 56, radius 12 | Aksi kedua ("Bagikan hasil pemeriksaan", "Coba lagi" di dalam kartu) |
| Teks | Tanpa latar dan bingkai, teks putih 15/600, tinggi minimum 48 | Aksi tersier di dalam kartu ("Hapus PIN", "Tutup") |
| Ikon | Area sentuh 48x48, ikon 24 | AppBar dan aksi baris |

Aturan: label tombol maksimal 3 kata untuk tombol utama, satu
baris, tidak pernah membungkus dua baris (taste §4.5). Satu label
per maksud di seluruh aplikasi: "Coba lagi" untuk semua percobaan
ulang, "Muat ulang" hanya untuk memuat ulang data layar.
Tombol utama yang nonaktif memakai latar `#2A2A2A` dengan teks
`#757575` (bukan putih redup yang mengecoh).

### 4.5 SectionHeader

Judul bagian (`section`, 17/600) plus aksi opsional di kanan
(tombol teks atau ikon). Tanpa eyebrow, tanpa garis hias, tanpa
nomor bagian. Jarak: 32 di atas, 12 di bawah.

### 4.6 Kartu

Latar `surface`, radius 16, bingkai 1 px `line`, padding 20,
tanpa bayangan. Kartu dipakai hanya bila kelompok konten butuh
batas yang jelas (hasil ukur, daftar aksi). Data yang berurutan
(list riwayat, daftar aplikasi) memakai baris dengan pemisah
ruang, bukan kartu per baris (larangan kartu bersarang dan kartu
identik berulang).

### 4.7 StatusStrip (pengganti kartu banner mode lokal)

Strip kompak satu baris: ikon 20, teks `body` satu sampai dua
baris, latar `surface`, radius 12, tanpa tombol di dalamnya.
Dipakai untuk status mode lokal di Dashboard dan Akun, dan untuk
penjelasan batasan Android di layar terkait. Tidak pernah
setinggi kartu konten.

### 4.8 Skeleton (pengganti spinner polos)

Saat layar memuat data, tampilkan rangka yang meniru bentuk layar
akhir: blok abu `#1C1C1C` (radius 8) di posisi angka besar,
garis meter, dan baris data, dengan shimmer halus (kilau bergerak
satu arah, 1,2 detik per putaran). Di bawah rangka, satu baris
teks yang menjelaskan apa yang sedang dimuat ("Memuat data
baterai..."). Skeleton hanya untuk pemuatan awal layar. Untuk aksi
yang dipicu pengguna (diagnosis, tes WiFi, minta diagnosis AI),
pakai progres nyata: bilah progres dengan teks tahap
("Mengukur kecepatan unduh..."), bukan skeleton.

### 4.9 EmptyState v2

Rata kiri, bukan tengah. Anatomi: ikon 28 di dalam kotak bingkai
(`surface`, radius 12, 56x56), judul `section`, pesan `body`
warna `textSecondary` yang menyebut penyebab dan aksi berikutnya
dengan spesifik, lalu tombol aksi bila ada (tombol utama bila
aksi itu adalah jalan keluar utama, tombol sekunder bila bukan).
Tiap layar memakai judul dan pesan yang berbeda, sesuai
penyebabnya (lihat bagian 6). Dilarang memakai judul generik
"Belum ada data pemeriksaan" di semua layar.

### 4.10 ErrorState v2

Sama seperti EmptyState v2 (rata kiri, kotak ikon, judul, pesan,
tombol), tetapi ikon memakai warna `danger` dan judul menyebut
apa yang gagal ("Diagnosis gagal", "Data baterai tidak bisa
dibaca"). Pesan menyebut penyebab yang diketahui dan apa yang
bisa dilakukan ("Perangkat tidak memberikan data baterai saat
ini. Coba muat ulang."). Tombol selalu "Coba lagi". Tidak pernah
menampilkan rincian exception sistem.

### 4.11 Dialog dan bottom sheet

- Konfirmasi destruktif atau penting (bersihkan cache): dialog
  tengah, latar `surfaceRaised`, radius 16, judul `section`,
  isi `body`, dua tombol (teks "Batal" di kiri, utama "Bersihkan"
  di kanan).
- Penjelasan langkah manual (ganti DNS, lupakan jaringan, ganti
  channel): bottom sheet, bukan dialog. Alasan: isinya panjang
  dan berlangkah, bottom sheet memberi ruang baca dan mudah
  ditutup dengan geser. Bottom sheet memakai pegangan (handle)
  32x4 di atas, judul `section`, isi `body` dengan langkah
  bernomor, dan tombol utama "Buka pengaturan WiFi" di bawah.
- SnackBar: latar `#1C1C1C`, teks putih, radius 8, durasi 3 detik.
  Hanya untuk konfirmasi singkat ("Cache berhasil dibersihkan.",
  "Pengaturan WiFi dibuka."), bukan untuk galat yang butuh aksi.

### 4.12 AppBar

- Dashboard: AppBar besar (SliverAppBar) dengan judul "Dokter HP"
  (`headline`, 28/700) yang mengecil saat di-scroll. Dua aksi
  ikon di kanan: Riwayat dan Akun, masing-masing area 48x48.
- Layar dalam: AppBar biasa, judul `title` (20/700) rata kiri,
  tombol kembali bawaan, aksi ikon di kanan bila ada (muat ulang,
  bagikan).
- Latar AppBar sama dengan latar layar (`#000000`), tanpa garis
  bawah, tanpa bayangan, tanpa elevasi saat scroll (tetap rata).

### 4.13 Boot splash

Latar `#000000`, teks "Dokter HP" putih (`headline`, 28/700)
di tengah. Tanpa logo gambar, tanpa spinner. Splash hanya tampil
sepintas saat boot; tidak perlu animasi.

## 5. Aturan yang mengikat implementasi

Aturan ini tidak bisa ditawar. Bila implementasi tidak bisa
memenuhi salah satunya, tim implementasi melapor ke Design Lead
sebelum mengubah aturan.

1. Tap target: semua elemen interaktif minimal 48x48 px, dengan
   jarak antar target minimal 8 px.
2. Kontras: teks biasa minimal 4,5:1, teks besar (18 ke atas)
   minimal 3:1, batas komponen interaktif minimal 3:1 terhadap
   latar sekitarnya. Abu paling gelap untuk teks adalah `#757575`.
3. Tidak ada data dummy. Angka yang tampil hanya dari perangkat
   atau dari riwayat tersimpan. Bila tidak ada data, pakai
   EmptyState v2 yang jujur.
4. Semua fitur v1.0.1 tetap berfungsi: diagnosis satu ketuk,
   tes WiFi, pemantau live, tes bertahan 30 detik, grafik sampel,
   panduan WiFi (teks verbatim), bersihkan cache dengan dialog,
   muat ulang Performa, daftar aplikasi dan izin, hapus riwayat
   dengan geser, laporan PDF, PIN, biometrik, masuk Google,
   Diagnosis AI.
5. Tidak ada em dash di teks UI mana pun.
6. Tidak ada kata ganti informal yang dilarang owner di teks mana
   pun (daftar lengkapnya ada di MEMORY.md).
7. Tidak ada emoji di teks UI.
8. Tidak ada warna dekoratif. Warna hanya untuk status fungsional
   dan logo brand pihak ketiga.
9. Tidak ada angka yang dikarang untuk keperluan tampilan,
   termasuk di screenshot dokumentasi. Screenshot memakai data
   dari harness dengan nilai yang dicatat sebagai nilai uji.
10. Semua layar punya tiga kondisi: memuat (skeleton atau progres
    nyata), galat (ErrorState v2 dengan "Coba lagi"), kosong
    (EmptyState v2 yang spesifik).
11. Gerak menghormati pengaturan pengurangan gerak di sistem.
12. Setiap layar punya tepat satu focal point (satu angka besar
    atau satu aksi utama). Bila dua elemen berebut perhatian,
    yang satu diturunkan bobotnya.
13. Tidak ada elemen interaktif yang tidak berfungsi. Tombol yang
    belum bisa bekerja tidak ditampilkan, atau ditampilkan
    nonaktif dengan penjelasan kenapa.

## 6. Spesifikasi per layar

### 6.1 Dashboard (`lib/features/dashboard/dashboard_page.dart`)

Focal point: skor kesehatan (angka besar plus meter).

Apa yang berubah dan kenapa:

- Cincin skor diganti `MeterGauge` besar. Alasan: cincin adalah
  bentuk generik yang dipakai ribuan aplikasi; meter dengan tanda
  strip adalah motif identitas aplikasi ini dan membaca posisi
  nilai dalam skala 0-100 dengan lebih jelas.
- Keenam kartu dokter yang identik diganti susunan dua tingkat:
  Dokter WiFi (fitur utama produk, PRODUCT.md bagian 1.1) menjadi
  baris unggulan lebar penuh dengan angka terakhir bila ada,
  lima dokter lain menjadi grid dua kolom. Alasan: hierarki isi
  yang nyata, bukan enam kartu yang berpura-pura sama penting
  (R-14, C-3).
- Banner mode lokal menjadi `StatusStrip` kompak di bawah AppBar,
  bukan kartu penuh. Alasan: status server adalah konteks, bukan
  konten utama.
- Label versi "Dokter HP v1.0.1" pindah dari kaki dashboard ke
  kaki layar Akun. Alasan: versi adalah info dukungan, bukan
  konten dashboard; satu tempat saja.
- Tiga pemeriksaan terakhir menjadi kelompok "Pemeriksaan
  terakhir" dengan baris yang menampilkan skor sebagai angka
  tabular tebal di kanan, bukan ikon centang generik di kiri.
  Alasan: angka adalah isi yang dicari, ikon centang tidak
  membawa informasi.

Susunan baru (atas ke bawah):

1. AppBar besar "Dokter HP", aksi Riwayat dan Akun.
2. `StatusStrip` mode lokal (hanya bila server belum
   terkonfigurasi).
3. Panel skor: `MeterGauge` besar (angka 56, meter, chip
   kategori), di bawahnya rincian per komponen sebagai StatRow
   (data dari `details` hasil diagnosis, tanpa perubahan isi),
   lalu tombol utama "Diagnosis satu ketuk" selebar panel.
   Saat diagnosis berjalan, tombol nonaktif dan panel menampilkan
   bilah progres plus teks tahap dari state yang sudah ada.
4. `SectionHeader` "Dokter", lalu baris unggulan Dokter WiFi:
   latar `surface`, ikon WiFi 28, judul, satu baris status
   terakhir bila ada (dari riwayat WiFi terakhir, misal
   "Terakhir: 1,2 MB/detik, 11 Nov 2026, 12:34"; bila belum ada,
   deskripsi singkat "Ukur kecepatan dan latensi WiFi"),
   chevron kanan.
5. Grid dua kolom (jarak 12): Baterai, Penyimpanan, Performa,
   Keamanan, Diagnosis AI. Tiap sel: ikon 28, judul `section`,
   satu baris keterangan singkat. Tinggi sel minimal 96.
   Diagnosis AI memakai ikon `psychology`, tanpa ikon sparkle.
6. `SectionHeader` "Pemeriksaan terakhir" (hanya bila riwayat
   ada). Baris: tanggal dan jam (`label`) di kiri, skor
   sebagai angka tabular tebal di kanan. Tanpa ikon di tiap
   baris.
7. Padding bawah 32.

Micro-interaction:

- Skor baru: angka menghitung 600 ms, jarum meter meluncur
  350 ms (alasan: menandai hasil ukur baru, lihat bagian 3.7).
- Ketuk kartu dokter: skala 0,97 selama 100 ms (umpan balik
  sentuhan).

State:

- Memuat riwayat awal: skeleton panel skor (blok angka, blok
  meter, dua baris StatRow) plus skeleton grid.
- Belum ada skor: panel menampilkan EmptyState v2 ("Belum ada
  skor kesehatan", pesan: "Jalankan diagnosis untuk mengukur
  kondisi HP ini. Hasilnya tersimpan di perangkat ini."),
  tombol "Diagnosis satu ketuk" tetap tampil di bawahnya.
- Diagnosis gagal: ErrorState v2 di dalam panel ("Diagnosis
  gagal", pesan dari state, tombol "Coba lagi").
- Riwayat kosong: kelompok "Pemeriksaan terakhir" tidak tampil
  sama sekali (bukan empty state terpisah, karena panel skor
  sudah menjelaskan).

Copy baru:

| Elemen | Teks baru |
|---|---|
| Judul AppBar | Dokter HP |
| Status strip mode lokal | Mode lokal. Diagnosis memakai data perangkat ini. |
| Empty skor, judul | Belum ada skor kesehatan |
| Empty skor, pesan | Jalankan diagnosis untuk mengukur kondisi HP ini. Hasilnya tersimpan di perangkat ini. |
| Tombol utama | Diagnosis satu ketuk |
| Tombol saat berjalan | Mendiagnosis |
| Judul bagian dokter | Dokter |
| Keterangan Dokter WiFi (belum ada hasil) | Ukur kecepatan dan latensi WiFi |
| Keterangan Dokter Baterai | Level, status, dan estimasi waktu pakai |
| Keterangan Dokter Penyimpanan | Ruang kosong dan cache aplikasi ini |
| Keterangan Dokter Performa | RAM, CPU, dan suhu perangkat |
| Keterangan Dokter Keamanan | Izin aplikasi yang perlu ditinjau |
| Keterangan Diagnosis AI | Saran diagnosis dari keluhan yang ditulis |
| Judul bagian riwayat | Pemeriksaan terakhir |
| Diagnosis gagal, judul | Diagnosis gagal |

### 6.2 Dokter WiFi (`lib/features/wifi_doctor/wifi_doctor_page.dart`)

Focal point: kecepatan unduh (angka besar plus meter).

Ini layar terpenting dan terpanjang. Susunannya berubah dari
tumpukan enam kartu yang sama menjadi tiga babak yang mengikuti
alur kerja pengguna: ukur, pantau, perbaiki.

Apa yang berubah dan kenapa:

- Paragraf pembuka ("Pemeriksaan ini mengukur...") dihapus.
  Alasan: layar sudah menjelaskan dirinya lewat tombol dan hasil;
  paragraf itu mengulang apa yang sudah jelas (humanizer §24).
  Satu baris kecil di bawah tombol menggantikannya: "Hasil dari
  perangkat ini, bukan angka contoh."
- Hasil pemeriksaan naik ke atas sebagai panel angka besar:
  kecepatan unduh (`display` 56) plus `MeterGauge` dengan skala
  logaritmik yang ditandai di titik 50, 200, 1000, dan 5000
  KB/detik (ambang klasifikasi yang sudah ada), chip klasifikasi
  ("Sangat lambat" sampai "Sangat cepat"), lalu latensi sebagai
  angka kedua. Alasan: kecepatan adalah jawaban yang dicari;
  di v1.0.1 ia terkubur di tengah kartu hasil.
- Info jaringan (SSID, IP, gateway, DNS, sinyal, kecepatan
  koneksi, channel) menjadi kelompok StatRow di bawah panel
  angka, tanpa kartu pembungkus. Alasan: data ini dibaca
  sekilas, tidak perlu kotak.
- Rekomendasi menjadi daftar bernomor dengan judul "Yang bisa
  dilakukan", tiap butir diawali kata kerja. Isi rekomendasi
  dari service tidak berubah. Alasan: rekomendasi adalah daftar
  tindakan, bukan paragraf.
- Penjelasan channel (2,4 GHz, channel 1/6/11) menjadi
  `StatusStrip` info di bawah rekomendasi, bukan paragraf abu
  di dalam kartu. Alasan: ini konteks, bukan hasil.
- Pemantau live menjadi panel tersendiri dengan header yang
  memuat chip "Live" (titik denyut hijau plus teks) saat aktif,
  dan angka unduh sebagai angka tabular besar yang diperbarui
  dengan crossfade. Info ringan (sinyal, kecepatan koneksi,
  channel, latensi) sebagai StatRow empat baris. Penjelasan
  kuota (600 KB per menit) menjadi satu baris `caption` di bawah
  sakelar, bukan paragraf. Alasan: panel live adalah instrumen
  yang sedang bekerja, tampilannya harus terasa hidup hanya
  lewat datanya, bukan lewat dekorasi.
- Tes bertahan 30 detik menjadi panel dengan grafik sebagai
  elemen utama: saat tes berjalan, batang tumbuh satu per satu
  tiap detik (dari sampel yang sudah ada); setelah selesai,
  grafik penuh tampil di atas ringkasan Terendah, Rata-rata,
  Tertinggi. Verdict menjadi `StatusChip` besar plus penjelasan
  satu kalimat dari `SustainedVerdict.penjelasan` (tidak
  berubah). Daftar "d1: ..., d2: ..." (Wrap teks) dihapus dari
  tampilan utama dan dipindah ke dialog "Lihat semua sampel"
  yang dibuka dari tombol teks di bawah grafik. Alasan: 30 angka
  mentah dalam Wrap adalah tumpukan teks yang tidak dibaca siapa
  pun; grafik sudah menceritakan bentuknya, angka detail tetap
  tersedia satu ketuk jauhnya.
- Kartu panduan ("WiFi turun ke KB/detik?") menjadi bagian
  terakhir dengan judul yang sama dan isi verbatim, tetapi
  tampil sebagai langkah bernomor dengan angka tabular besar
  (01, 02, 03, 04) di kiri tiap langkah, bukan teks "1." kecil.
  Alasan: langkah ini adalah prosedur, angka besar membantu mata
  mengikuti urutan. Isi teks tidak berubah satu kata pun.
- Perbaikan menjadi daftar aksi (bukan kartu dengan ListTile):
  tiap aksi adalah baris tinggi 64 dengan ikon 20, judul, dan
  satu baris keterangan, dipisah ruang 8. Ketuk membuka bottom
  sheet penjelasan (bukan dialog), kecuali "Sambung ulang WiFi"
  yang langsung membuka pengaturan sistem. Alasan: bottom sheet
  memberi ruang baca untuk langkah manual yang panjang.
- Tombol "Bagikan hasil pemeriksaan" menjadi tombol sekunder
  selebar layar di bawah panel hasil, hanya tampil bila hasil
  ada. Label tidak berubah.

Susunan baru (atas ke bawah):

1. AppBar "Dokter WiFi".
2. Tombol utama "Periksa WiFi sekarang" (atau "Memeriksa..."
   saat berjalan, nonaktif). Di bawahnya satu baris `caption`:
   "Hasil dari perangkat ini, bukan angka contoh."
3. Saat berjalan: bilah progres plus teks tahap dari state.
4. Panel hasil (bila hasil ada): angka kecepatan, meter,
   chip klasifikasi, latensi, StatRow info jaringan,
   rekomendasi, strip channel, tombol bagikan.
5. `SectionHeader` "Pantau live" plus panel live.
6. `SectionHeader` "Tes bertahan 30 detik" plus panel tes.
7. `SectionHeader` "Perbaikan" plus daftar aksi (hanya bila
   hasil ada).
8. Bagian panduan (judul dan isi verbatim).
9. Padding bawah 32.

Micro-interaction:

- Kecepatan baru: angka menghitung 600 ms, jarum meter
  meluncur 350 ms.
- Pemantau live: nilai berubah dengan crossfade 200 ms;
  chip "Live" berdenyut halus (satu-satunya loop yang
  diizinkan, karena menandai keadaan nyata).
- Tes bertahan: batang grafik tumbuh tiap detik; progres
  30 detik memakai bilah dengan teks "Detik 12 dari 30"
  dan kecepatan saat ini.

State:

- Belum ada hasil: EmptyState v2 di bawah tombol ("Belum ada
  hasil pemeriksaan WiFi", pesan: "Ketuk Periksa WiFi sekarang
  untuk mengukur kecepatan unduh dan latensi. Hasilnya
  tersimpan di perangkat ini."). Panel live, tes bertahan,
  dan panduan tetap tampil di bawahnya.
- Pemeriksaan gagal: ErrorState v2 ("Pemeriksaan WiFi gagal",
  pesan dari state, tombol "Coba lagi").
- Izin lokasi belum diberikan: `StatusStrip` dengan tombol
  "Izinkan lokasi dan periksa lagi" (teks dan perilaku tidak
  berubah, hanya bentuk strip).
- Tes bertahan gagal: pesan dari state plus tombol sekunder
  "Coba lagi" di dalam panel tes.
- Pemantau live tidak bisa dinyalakan saat tes berjalan:
  SnackBar dengan teks yang sudah ada.

Copy baru:

| Elemen | Teks baru |
|---|---|
| Keterangan di bawah tombol | Hasil dari perangkat ini, bukan angka contoh. |
| Tombol utama | Periksa WiFi sekarang |
| Tombol saat berjalan | Memeriksa |
| Empty hasil, judul | Belum ada hasil pemeriksaan WiFi |
| Empty hasil, pesan | Ketuk Periksa WiFi sekarang untuk mengukur kecepatan unduh dan latensi. Hasilnya tersimpan di perangkat ini. |
| Judul rekomendasi | Yang bisa dilakukan |
| Judul panel live | Pantau live |
| Keterangan kuota live | Sekitar 600 KB per menit. Probe 100 KB tiap 10 detik. |
| Label diperbarui live | Terakhir diperbarui pukul 12:34:56 |
| Judul panel tes bertahan | Tes bertahan 30 detik |
| Tombol tes bertahan | Tes bertahan 30 detik |
| Tombol berhenti tes | Berhenti |
| Tombol lihat sampel | Lihat semua sampel |
| Judul perbaikan | Perbaikan |
| Tombol bagikan | Bagikan hasil pemeriksaan |

### 6.3 Dokter Baterai (`lib/features/battery/battery_page.dart`)

Focal point: level baterai (angka besar plus meter).

Apa yang berubah dan kenapa:

- Persen baterai menjadi `MeterGauge` besar dengan chip status
  ("Mengisi daya", "Dipakai", "Penuh") di samping angka.
  Alasan: persen adalah jawaban utama; di v1.0.1 ia sudah besar
  tetapi tanpa meter dan tanpa status yang terlihat.
- Estimasi waktu pakai dipindah dari StatRow menjadi baris
  keterangan di bawah meter, dengan label "Perkiraan" yang
  jelas: "Perkiraan sekitar 8 jam 12 menit. Bukan hasil ukur."
  Alasan: estimasi adalah perkiraan, bukan data ukur, dan harus
  terbaca berbeda dari angka ukur.
- Kartu "Aplikasi boros baterai" menjadi `StatusStrip` info
  (bukan kartu penuh dengan judul besar). Alasan: isinya adalah
  penjelasan batasan, bukan hasil; kartu penuh memberi bobot
  yang tidak sepadan.
- Tips merawat baterai menjadi daftar tiga butir dengan ikon
  kecil yang relevan (termometer, hemat daya, layar), bukan
  satu blok teks dengan bullet. Isi tips tidak berubah.
  Alasan: tiga tips yang nyata memang tiga butir, dan ikon
  membantu memindai.

Susunan baru: AppBar "Dokter Baterai" (aksi muat ulang), panel
meter (angka, meter, chip status, estimasi), StatRow (Mode hemat
daya), `SectionHeader` "Tips merawat baterai" plus daftar tips,
`StatusStrip` batasan aplikasi boros baterai.

State:

- Memuat: skeleton (blok angka, blok meter, dua baris).
- Galat: ErrorState v2 ("Data baterai tidak bisa dibaca",
  pesan dan tombol "Coba lagi" seperti sekarang).
- Tidak ada kondisi kosong yang terpisah: bila level tidak bisa
  dibaca, itu galat, bukan kosong.

Copy baru:

| Elemen | Teks baru |
|---|---|
| Label estimasi | Perkiraan sekitar 8 jam 12 menit. Bukan hasil ukur. |
| Judul tips | Tips merawat baterai |
| Strip batasan | Android tidak membuka data pemakaian baterai per aplikasi. Buka Pengaturan, Baterai, Penggunaan baterai untuk melihat aplikasi yang paling banyak memakai daya. |

### 6.4 Dokter Penyimpanan (`lib/features/storage/storage_page.dart`)

Focal point: ruang kosong (angka besar plus meter tersegmentasi).

Apa yang berubah dan kenapa:

- Angka utama menjadi ruang kosong ("12,4 GB kosong dari
  64 GB"), bukan sekadar bilah persen. Alasan: yang ditanyakan
  pengguna adalah "masih ada ruang berapa", bukan "persen
  terpakai berapa".
- Bilah menjadi meter tersegmentasi: satu bilah yang menunjukkan
  porsi terpakai (putih) dan kosong (`track`), dengan penanda
  di batasnya. Alasan: dua angka dalam satu gambar lebih cepat
  dibaca daripada satu persen.
- Cache aplikasi ini menjadi baris tersendiri dengan nilai dan
  tombol "Bersihkan cache" tepat di bawahnya (bukan tombol
  terpisah jauh di bawah kartu). Alasan: tombol harus dekat
  dengan angka yang ia ubah.
- Catatan tentang file besar menjadi `StatusStrip` di bawah
  tombol. Alasan: konteks, bukan konten utama.

Susunan baru: AppBar "Dokter Penyimpanan", panel meter (angka
ruang kosong, meter tersegmentasi, StatRow Total dan Terpakai),
baris cache plus tombol utama "Bersihkan cache" (label saat
membersihkan: "Membersihkan..."), strip catatan, dialog
konfirmasi dengan teks yang tidak berubah.

State:

- Memuat: skeleton (blok angka, blok meter, tiga baris).
- Galat: ErrorState v2 ("Data penyimpanan tidak bisa dibaca",
  tombol "Coba lagi").
- Data tidak tersedia (penyimpanan null): EmptyState v2
  ("Data penyimpanan tidak tersedia", pesan: "Perangkat tidak
  memberikan info penyimpanan saat ini. Tombol bersihkan cache
  tetap bisa dipakai."). Tombol bersihkan cache tetap tampil.
  Alasan: di v1.0.1 layar ini menampilkan empty state tetapi
  tombol tetap ada di bawahnya; perilaku itu dipertahankan dan
  dijelaskan.

Copy baru:

| Elemen | Teks baru |
|---|---|
| Label angka utama | GB kosong dari 64 GB (nilai dari perangkat) |
| Tombol | Bersihkan cache |
| Judul dialog | Bersihkan cache? |
| Isi dialog | Hanya file cache aplikasi Dokter HP yang dihapus. Foto, chat, dan file lain tidak disentuh. |
| Strip catatan | Aplikasi ini tidak menghapus file besar, foto, video, atau chat secara otomatis. Hapus file dari Galeri atau File secara manual setelah memeriksa isinya. |

### 6.5 Dokter Performa (`lib/features/performance/performance_page.dart`)

Focal point: tidak ada satu angka utama. Layar ini memakai tiga
meter compact berdampingan vertikal: RAM, CPU, suhu. Alasan:
tidak ada satu pun dari ketiganya yang menjadi jawaban tunggal;
ketiganya sama penting dan dibaca bersama.

Apa yang berubah dan kenapa:

- RAM, CPU, dan suhu masing-masing menjadi `MeterGauge` compact
  (angka 28, meter, label). Alasan: tiga angka yang sekarang
  terkubur sebagai StatRow di bawah satu bilah RAM menjadi tiga
  instrumen yang bisa dipindai.
- Suhu yang tidak tersedia menampilkan "Tidak tersedia di
  perangkat ini" sebagai nilai meter yang kosong (meter tanpa
  isi, label jelas), bukan baris teks. Alasan: konsistensi
  bentuk; kekosongan terlihat sebagai meter yang tidak terisi.
- Info perangkat (merek/model, Android, prosesor) menjadi
  kelompok StatRow di bawah `SectionHeader` "Perangkat", tanpa
  kartu.
- Penjelasan batasan menutup aplikasi menjadi `StatusStrip`.

Susunan baru: AppBar "Dokter Performa" (aksi muat ulang), tiga
meter compact (RAM dengan nilai "3,2 GB kosong dari 8 GB",
CPU dengan persen, suhu dengan derajat), kelompok "Perangkat",
strip batasan.

State:

- Memuat: skeleton tiga meter (bentuk akhir layar, bukan
  spinner di tengah layar kosong seperti `performa.png`).
- Galat: ErrorState v2 ("Data performa tidak bisa dibaca",
  tombol "Coba lagi").
- Catatan implementasi: pemuatan Performa sengaja tanpa batas
  waktu (alasan di audit v1.0.0 bagian 2.6). Spesifikasi ini
  tidak mengubah perilaku itu.

Copy baru:

| Elemen | Teks baru |
|---|---|
| Label meter RAM | RAM kosong |
| Label meter CPU | Pemakaian CPU |
| Label meter suhu | Suhu perangkat |
| Suhu tidak tersedia | Tidak tersedia di perangkat ini |
| Judul kelompok | Perangkat |
| Strip batasan | Android tidak mengizinkan aplikasi pihak ketiga menutup aplikasi lain. Buka layar aplikasi terakhir lalu geser aplikasi yang tidak dipakai, atau mulai ulang HP bila terasa berat. |

### 6.6 Dokter Keamanan (`lib/features/security/security_page.dart`)

Focal point: jumlah aplikasi yang perlu ditinjau.

Apa yang berubah dan kenapa:

- Ringkasan menjadi dua angka berdampingan di atas: "Aplikasi
  terpasang" dan "Perlu ditinjau", masing-masing angka tabular
  28 dengan label. Bila jumlah yang perlu ditinjau nol,
  angkanya memakai chip "Tidak ada" hijau. Alasan: dua angka
  ini adalah jawaban layar; di v1.0.1 keduanya terkubur sebagai
  StatRow di kartu "Ringkasan".
- Daftar aplikasi tidak lagi memakai kartu per baris. Tiap
  aplikasi menjadi baris tinggi 72: nama aplikasi (`body`,
  tebal) di atas, nama paket (`caption`) di bawah, dan di kanan
  angka izin berbahaya sebagai angka tabular 20 plus label
  "izin" di bawahnya. Alasan: kartu per baris membuat daftar
  panjang terasa berat; baris dengan angka di kanan membuat
  pemindaian berdasarkan jumlah izin menjadi mungkin.
- Kelompok "Perlu ditinjau" (4+ izin berbahaya, non-sistem)
  tampil di atas dengan `SectionHeader` dan baris yang sama,
  ditambah chip merah kecil "Tinjau" di kanan nama. Daftar
  "Semua aplikasi pengguna" di bawahnya memakai baris yang sama
  tanpa chip. Alasan: pembedaan lewat chip dan posisi, bukan
  lewat kartu yang berbeda bentuk.
- Urutan tetap dari service (terbanyak izin berbahaya dulu).
  Tidak ada pencarian dan tidak ada filter baru di v1.1.0;
  itu pekerjaan lanjutan, bukan rancang ulang ini.
- Penjelasan hapus aplikasi menjadi `StatusStrip` di kaki layar.

Susunan baru: AppBar "Dokter Keamanan", dua angka ringkasan,
`SectionHeader` "Perlu ditinjau" plus daftar (hanya bila ada),
`SectionHeader` "Semua aplikasi pengguna" plus daftar, strip
penjelasan.

State:

- Memuat: skeleton (dua blok angka, lima baris daftar).
- Galat: ErrorState v2 ("Daftar aplikasi tidak bisa dibaca",
  tombol "Coba lagi").
- Daftar kosong: EmptyState v2 ("Daftar aplikasi tidak
  tersedia", pesan: "Perangkat tidak memberikan daftar aplikasi
  saat ini. Coba buka lagi layar ini."). Tanpa tombol aksi
  karena tidak ada aksi yang bisa dilakukan dari sini; muat
  ulang tersedia lewat aksi AppBar bila tim implementasi
  menambahkannya (opsional, bukan wajib).

Copy baru:

| Elemen | Teks baru |
|---|---|
| Label angka 1 | Aplikasi terpasang |
| Label angka 2 | Perlu ditinjau |
| Chip jumlah nol | Tidak ada |
| Chip baris tinjau | Tinjau |
| Judul kelompok 1 | Perlu ditinjau |
| Judul kelompok 2 | Semua aplikasi pengguna |
| Strip penjelasan | Aplikasi yang tidak dikenal dan meminta izin lokasi, kamera, mikrofon, atau SMS sebaiknya ditinjau. Hapus lewat Pengaturan, Aplikasi bila tidak dikenal atau tidak dipakai. |

### 6.7 Riwayat (`lib/features/history/history_page.dart`)

Focal point: entri terbaru.

Apa yang berubah dan kenapa:

- Dua daftar terpisah (kesehatan lalu WiFi) digabung menjadi
  satu linimasa kronologis menurun (terbaru di atas), dengan
  pembatas tanggal ("Hari ini", "Kemarin", atau "11 Nov 2026")
  di antara kelompok hari. Alasan: pengguna mengingat "kapan
  saya memeriksa", bukan "jenis pemeriksaan apa"; dua daftar
  terpisah memaksa mata melompat.
- Tiap entri menjadi baris tinggi 72 tanpa kartu: di kiri ikon
  jenis (kesehatan atau WiFi) 20 di dalam kotak bingkai 40x40,
  di tengah judul ("Skor 82, Baik" atau nama SSID) plus waktu
  (`caption`), di kanan angka sekunder ("12:34" sudah di tengah;
  untuk WiFi, kecepatan unduh sebagai angka tabular). Alasan:
  kartu per entri membuat riwayat panjang terasa berat.
- Hapus dengan geser dipertahankan persis (geser ke kiri,
  latar merah `danger` dengan ikon hapus putih). Perubahan
  visual: latar geser memakai warna `danger` penuh, bukan
  abu `black12`, karena hapus adalah aksi destruktif dan
  warnanya harus berarti. Setelah hapus, SnackBar "Entri
  dihapus." tampil 3 detik. (Perilaku soft-delete tidak
  berubah; tidak ada tombol urungkan di v1.1.0.)
- Tombol bagikan PDF tetap di AppBar. Bila riwayat kosong,
  tombol bagikan disembunyikan (tidak ada laporan untuk
  dibagikan). Alasan: tombol yang tidak bisa bekerja tidak
  ditampilkan (R-26).

Susunan baru: AppBar "Riwayat pemeriksaan" (aksi bagikan bila
ada data), linimasa dengan pembatas tanggal.

State:

- Memuat: skeleton (tiga baris entri).
- Galat: ErrorState v2 ("Riwayat tidak bisa dibaca", tombol
  "Coba lagi").
- Kosong: EmptyState v2 dengan dua tombol aksi ("Jalankan
  diagnosis" ke dashboard dan "Periksa WiFi" ke Dokter WiFi).
  Judul: "Belum ada riwayat pemeriksaan". Pesan: "Hasil
  diagnosis dan pemeriksaan WiFi tersimpan di perangkat ini
  dan tampil di sini." Alasan: empty state yang memberi jalan
  keluar lebih berguna daripada yang hanya menjelaskan.

Copy baru:

| Elemen | Teks baru |
|---|---|
| Judul AppBar | Riwayat pemeriksaan |
| Empty, judul | Belum ada riwayat pemeriksaan |
| Empty, pesan | Hasil diagnosis dan pemeriksaan WiFi tersimpan di perangkat ini dan tampil di sini. |
| Tombol empty 1 | Jalankan diagnosis |
| Tombol empty 2 | Periksa WiFi |
| Pembatas tanggal | Hari ini / Kemarin / 11 Nov 2026 |
| SnackBar hapus | Entri dihapus. |
| SnackBar gagal PDF | Laporan gagal dibuat. Coba lagi. |

### 6.8 Diagnosis AI (`lib/features/ai_diagnosis/ai_diagnosis.dart`)

Focal point: kolom keluhan dan tombol kirim.

Apa yang berubah dan kenapa:

- Banner mode lokal menjadi `StatusStrip` kompak. Di mode lokal,
  tombol "Minta diagnosis" tetap aktif (perilaku sekarang:
  service mengembalikan pesan jujur). Alasan: perilaku tidak
  berubah, hanya bobot visual strip yang diturunkan.
- Kolom keluhan memakai label di atas ("Keluhan HP") dan
  placeholder di dalam ("Contoh: WiFi lemot padahal sinyal
  penuh"). Alasan: label di atas input adalah pola form yang
  benar (taste §4.6); placeholder bukan label.
- Tombol "Minta diagnosis" menjadi tombol utama putih dengan
  ikon `psychology`. Saat memuat, label menjadi "Meminta
  diagnosis..." dan tombol nonaktif, plus bilah progres di
  bawah tombol (bukan di atas jawaban).
- Jawaban tampil sebagai panel hasil dengan header "Saran
  diagnosis" dan isi `body`. Di bawah jawaban, strip catatan:
  "Jawaban AI adalah saran, bukan vonis pasti. Cocokkan dengan
  hasil ukur di Dokter WiFi dan dokter lainnya." (teks tidak
  berubah, bentuk menjadi strip).
- Bila jawaban gagal, panel menampilkan ErrorState v2 ringkas
  ("Diagnosis AI gagal", tombol "Coba lagi") sebagai pengganti
  panel jawaban, bukan kartu teks plus tombol terpisah.
  Alasan: satu bentuk galat di seluruh aplikasi.
- Petunjuk kosong ("Tulis keluhan di atas...") dihapus. Alasan:
  label kolom dan tombol sudah menjelaskan; baris itu mengulang
  (humanizer §24).

Susunan baru: AppBar "Diagnosis AI", strip mode lokal (bila
mode lokal), label "Keluhan HP", kolom teks 4 baris, tombol
utama, bilah progres saat memuat, panel jawaban atau panel
galat, strip catatan.

State:

- Memuat: bilah progres plus teks "Meminta diagnosis...".
- Galat: ErrorState v2 ringkas di panel jawaban.
- Kosong (belum ada jawaban): tidak ada panel, tidak ada teks
  petunjuk. Kolom dan tombol sudah cukup.

Copy baru:

| Elemen | Teks baru |
|---|---|
| Label kolom | Keluhan HP |
| Placeholder | Contoh: WiFi lemot padahal sinyal penuh |
| Tombol | Minta diagnosis |
| Tombol saat memuat | Meminta diagnosis |
| Judul panel jawaban | Saran diagnosis |
| SnackBar kolom kosong | Tulis keluhan dulu. |
| Strip catatan | Jawaban AI adalah saran, bukan vonis pasti. Cocokkan dengan hasil ukur di Dokter WiFi dan dokter lainnya. |

### 6.9 Akun (`lib/features/auth/auth_page.dart`)

Focal point: status akun (masuk atau mode lokal).

Apa yang berubah dan kenapa:

- Tiga kartu yang sama besar diganti tiga kelompok dengan bobot
  berbeda: Akun (paling atas, dengan status yang jelas),
  PIN aplikasi (kelompok utama), Biometrik (kelompok kecil).
  Alasan: ketiganya bukan sama penting; PIN adalah fitur yang
  paling dipakai di layar ini.
- Status akun memakai `StatusChip`: "Mode lokal" (info, biru)
  bila server belum terkonfigurasi, "Masuk sebagai
  nama@email.com" (teks biasa) bila masuk. Tombol "Masuk dengan
  Google" memakai tombol putih dengan logo Google asli di kiri
  (satu-satunya tempat warna brand pihak ketiga muncul).
  Tombol "Keluar" menjadi tombol sekunder.
- PIN memakai kolom digit tersegmentasi: delapan kotak (maksimal
  8 digit), tiap kotak 48x56, radius 8, bingkai `lineStrong`,
  angka tersembunyi (titik). Kotak terisi memakai bingkai putih.
  Alasan: PIN adalah angka, dan kotak tersegmentasi membuat
  jumlah digit terlihat serta mengurangi salah ketik. Perilaku
  validasi (4-8 digit angka) tidak berubah; keyboard tetap
  keyboard angka.
- Penjelasan PIN dipersingkat menjadi dua baris `caption` di
  bawah kolom: "PIN disimpan dalam bentuk yang tidak bisa
  dibaca di HP ini. PIN asli tidak pernah disimpan." Penjelasan
  pemulihan bila lupa menjadi `StatusStrip` di bawah tombol
  simpan (teks tidak berubah, hanya bentuknya).
- Tombol "Hapus PIN" menjadi tombol teks merah (`danger`) di
  bawah kelompok PIN, hanya tampil bila PIN sudah diatur.
  Alasan: hapus adalah aksi destruktif dan harus terbaca
  berbeda dari aksi biasa.
- Biometrik: baris sakelar dengan label "Buka kunci dengan
  biometrik" plus tombol sekunder "Uji biometrik sekarang".
  Bila perangkat tidak mendukung, tampil strip "Perangkat ini
  tidak mendukung biometrik." tanpa sakelar.
- Kaki layar: "Dokter HP v1.0.1" (`caption`, `textFaint`,
  rata tengah) sebagai info versi. Alasan: versi pindah dari
  dashboard ke sini (lihat 6.1).

Susunan baru: AppBar "Akun dan keamanan", kelompok Akun
(chip status, teks status, tombol masuk/keluar), kelompok
"PIN aplikasi" (status, kolom digit, tombol "Simpan PIN",
caption penyimpanan, strip pemulihan, tombol teks "Hapus PIN"
bila ada), kelompok "Biometrik" (sakelar, tombol uji, atau
strip tidak mendukung), kaki versi.

State:

- Memuat: skeleton (tiga kelompok).
- Galat: ErrorState v2 ("Pengaturan tidak bisa dibaca",
  tombol "Coba lagi").
- Tidak ada kondisi kosong yang terpisah.

Copy baru:

| Elemen | Teks baru |
|---|---|
| Chip mode lokal | Mode lokal |
| Status mode lokal | Masuk Google belum tersedia sampai server dikonfigurasi. |
| Status belum masuk | Belum masuk. |
| Status masuk | Masuk sebagai nama@email.com |
| Tombol masuk | Masuk dengan Google |
| Tombol keluar | Keluar |
| Judul kelompok PIN | PIN aplikasi |
| Status PIN diatur | PIN sudah diatur. |
| Status PIN belum | PIN belum diatur. |
| Tombol simpan PIN | Simpan PIN |
| Caption PIN | PIN disimpan dalam bentuk yang tidak bisa dibaca di HP ini. PIN asli tidak pernah disimpan. |
| Tombol hapus PIN | Hapus PIN |
| Judul kelompok biometrik | Biometrik |
| Label sakelar | Buka kunci dengan biometrik |
| Tombol uji | Uji biometrik sekarang |
| Strip tidak mendukung | Perangkat ini tidak mendukung biometrik. |
| Kaki versi | Dokter HP v1.0.1 |

## 7. Rencana verifikasi implementasi

Tim implementasi membuktikan hasil dengan langkah ini sebelum
menyerahkan ke owner (proof standard):

1. `flutter analyze` tanpa masalah, `flutter test` hijau.
2. Screenshot sembilan layar dengan harness yang sama seperti
   `docs/screenshots/` (font dan tema asli, ukuran 390x844),
   ditambah screenshot kondisi: skor sudah ada (dashboard),
   hasil WiFi sudah ada, tes bertahan selesai, riwayat terisi,
   keamanan dengan daftar aplikasi.
3. Perbandingan sebelum/sesudah per layar: screenshot v1.0.1
   berdampingan dengan v1.1.0, diperiksa satu per satu.
4. Cek kontras ulang dengan `contrast-check.py` untuk semua
   pasangan teks/latar yang dipakai di implementasi akhir.
5. Cek tap target: semua tombol dan baris interaktif minimal
   48x48, diukur dari render, bukan dari kode saja.
6. Cek gerak: diagnosis baru menggerakkan meter dan angka;
   pemantau live berubah tanpa kedip; pengaturan pengurangan
   gerak membuat semua gerak instan.
7. Cek teks: tidak ada em dash, tidak ada kata yang dilarang,
   tidak ada angka contoh, teks panduan WiFi sama kata per kata
   dengan `docs/panduan-wifi-turun.md`.
8. Pasang APK di HP fisik dan periksa sembilan layar dengan mata
   (screenshot harness bukan pengganti perangkat nyata).

## 8. Keputusan yang dicatat (R-31, satu baris per keputusan)

- Tema gelap karena design lock menulis basis hitam dengan aksen
  putih, dan keputusan terang v1.0.0 dibuat tim audit, bukan
  owner.
- Meter dengan tanda strip sebagai motif karena aplikasi ini
  menjual angka ukur, dan strip membantu membaca posisi nilai.
- Font sistem karena build offline tidak boleh bergantung pada
  unduhan font.
- Angka tabular karena nilai live tidak boleh bergeser saat
  berubah.
- Radius 16/12/8/4 karena satu sistem bentuk yang konsisten
  lebih mudah diingat daripada radius bebas.
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
