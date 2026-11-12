# Rancang Ulang v1.1.0: Before / After

Verifikasi independen Lead QA atas rancang ulang UI/UX Dokter HP v1.1.0,
12 November 2026. Acuan kebenaran: `docs/redesign-v11-spec.md` (terutama
bagian 5 aturan mengikat dan bagian 6 per layar), `DESIGN.md`, dan checklist
v1.1.0 di `DESIGN_AUDIT.md` bagian 9-12.

Versi aplikasi TIDAK berubah di ronde ini: tetap 1.0.1+2. Tidak ada push,
tidak ada release, tidak ada perubahan `CHANGELOG.md` (itu tugas tim rilis).

## Bukti test

| Pemeriksaan | Hasil |
| --- | --- |
| `flutter analyze` | 0 issue (No issues found!) |
| `flutter test` (tanpa define) | 98/98 lulus, 10 skip |
| `flutter test` dengan `QA_CAPTURE=true` | 9/9 tangkapan berhasil |
| `flutter test` golden logo (dengan dart-define Supabase contoh) | lulus, `qa-akun-login.png` dibuat |

Rincian angka test: 76 test lama + 18 test `redesign_widget_test.dart`
(16 dari tim implementasi + 2 test regresi chip dari QA, lihat bagian
"Bug yang diperbaiki QA") + 4 test lain dari ronde implementasi = 98.
10 skip pada run biasa adalah 9 test tangkap layar (hanya jalan dengan
`--dart-define=QA_CAPTURE=true`, supaya `flutter test` biasa tidak
menulis berkas) dan 1 test golden logo Google (hanya jalan dengan
dart-define Supabase, supaya tidak butuh kredensial asli).

Klaim tim implementasi yang diverifikasi independen: analyze 0 issue
(benar), test 94/94 pada saat serah terima (benar, lalu naik jadi 98
setelah QA menambah 2 golden + 2 test regresi), nol kata terlarang di
`lib/` dan `test/` (benar, grep 0 hasil), nol em dash di string UI
(benar; 4 em dash ditemukan hanya di komentar kode dan sudah dibersihkan),
tema gelap di semua layar (benar), 9 layar ditulis ulang (benar).

## Cara membaca tabel per layar

- "Lama" = screenshot v1.0.1 dari `docs/screenshots/` (tema terang,
  state kosong terpusat). Berkas lama TIDAK ditimpa.
- "Baru" = screenshot v1.1.0 dari `docs/screenshots/*-v11.png`,
  ditangkap dari widget test, permukaan 390x844, pixelRatio 2.0
  (780x1688), font Roboto asli dari SDK.
- Semua screenshot baru menampilkan state yang sama dengan screenshot
  lama (state kosong / awal), supaya perbandingan setara. State terisi
  (dashboard berskor, panel hasil WiFi, riwayat berisi, daftar aplikasi)
  hanya bisa dibuktikan di HP fisik, lihat "Temuan terbuka".

## 1. Dashboard

| | Berkas |
| --- | --- |
| Lama | `dashboard.png` |
| Baru | `dashboard-v11.png` |

Perubahan:

1. Tema terang menjadi tema gelap penuh (latar hitam, kartu abu gelap,
   tombol putih).
2. Kartu skor menjadi titik fokus tunggal: ikon perisai dalam kotak,
   judul "Belum ada skor kesehatan", penjelasan, tombol
   "Diagnosis satu ketuk" satu baris penuh.
3. Strip status "Mode lokal. Diagnosis memakai data perangkat ini."
   di atas kartu skor, menggantikan teks kecil di bawah.
4. Navigasi dokter menjadi baris unggulan "Dokter WiFi" plus grid 2
   kolom untuk Baterai, Penyimpanan, Performa, Keamanan.

Penyimpangan dari spesifikasi: tinggi sel grid 184 px, bukan 168 px
contoh di spesifikasi. Spesifikasi bagian 6.1 menetapkan tinggi
minimum 96 px, jadi 184 px patuh. Nilai 184 px dipilih tim
implementasi setelah sel 176 px meluap 8 px di lebar 390 px; QA
membuktikan tidak ada luapan lagi (golden lulus, hitungan manual:
lebar sel 169 px, isi 133,2 px + padding 40 px = 173,2 px < 184 px,
sisa sekitar 11 px). Keterangan sel grid terpotong elipsis di lebar
390 px ("Level, status, dan estimasi waktu p..."), karena copy
spesifikasi lebih panjang dari dua baris pada lebar sel; ini sesuai
desain (maxLines 2 + ellipsis), bukan bug.

## 2. Dokter WiFi

| | Berkas |
| --- | --- |
| Lama | `wifi.png` (dan `wifi-v101.png`) |
| Baru | `wifi-v11.png` |

Perubahan:

1. Tema gelap; tombol "Periksa WiFi sekarang" pindah ke atas layar
   sebagai aksi utama, satu baris penuh.
2. Keterangan kejujuran di bawah tombol: "Hasil dari perangkat ini,
   bukan angka contoh."
3. Empty state rata kiri dengan kotak ikon, menggantikan state
   terpusat.
4. Panel "Pantau live" (saklar + keterangan biaya data "Sekitar
   600 KB per menit. Probe 100 KB tiap 10 detik.") dan panel
   "Tes bertahan 30 detik" kini berupa kartu terpisah dengan judul
   seksi masing-masing.

Tidak ada penyimpangan. Panduan WiFi (kartu teks saat hasil turun)
diverifikasi QA kata per kata terhadap `docs/panduan-wifi-turun.md`:
judul, paragraf penjelasan, dan keempat langkah cocok persis.

## 3. Dokter Baterai

| | Berkas |
| --- | --- |
| Lama | `baterai.png` |
| Baru | `baterai-v11.png` |

Perubahan:

1. Tema gelap; angka utama "82%" besar di dalam kartu meter dengan
   batang ukur, tanda skala 0-100, dan penanda posisi.
2. Estimasi waktu diberi label jujur: "Perkiraan sekitar 8 jam
   12 menit. Bukan hasil ukur."
3. Baris "Mode hemat daya / Tidak aktif" dan seksi "Tips merawat
   baterai" (3 tips dengan ikon) menggantikan daftar teks lama.
4. Strip info biru menjelaskan Android tidak membuka data pemakaian
   baterai per aplikasi, dengan arahan ke Pengaturan.

Penyimpangan dari spesifikasi (dilaporkan tim implementasi,
dikonfirmasi QA): chip "Mengisi daya" memakai ikon
`battery_charging_full`; skala suhu meter memakai 20-60 derajat C.
Keduanya wajar dan tidak melanggar aturan mengikat. Nilai 82 pada
screenshot adalah nilai mock harness test, bukan data perangkat.

## 4. Dokter Penyimpanan

| | Berkas |
| --- | --- |
| Lama | `penyimpanan.png` |
| Baru | `penyimpanan-v11.png` |

Perubahan:

1. Tema gelap; empty state rata kiri dengan kotak ikon,
   menggantikan state terpusat.
2. Baris baru "Cache aplikasi ini / 0 B" di antara empty state dan
   tombol (nilai 0 B adalah nilai mock harness).
3. Tombol "Bersihkan cache" putih penuh (dulu hitam di latar terang).
4. Kotak "Catatan:" berbingkai menjadi strip info biru berikon
   dengan teks yang sama intinya.

Tidak ada penyimpangan.

## 5. Dokter Performa

| | Berkas |
| --- | --- |
| Lama | `performa.png` |
| Baru | `performa-v11.png` |

Perubahan:

1. Tema gelap; state memuat berubah dari spinner tunggal di tengah
   layar menjadi skeleton tiga meter (bentuk batang abu-abu yang
   meniru layout isi) plus keterangan "Memuat data performa...".
2. Tombol muat ulang di AppBar dipertahankan.

Tidak ada penyimpangan. Di lingkungan test, pembacaan `/proc/stat`
tidak selesai sehingga layar memang menampilkan skeleton; QA
memastikan tampilannya rapi dan bukan macet. State terisi (tiga
meter CPU, RAM, suhu) hanya bisa dibuktikan di HP fisik.

## 6. Dokter Keamanan

| | Berkas |
| --- | --- |
| Lama | `keamanan.png` |
| Baru | `keamanan-v11.png` |

Perubahan:

1. Tema gelap; empty state rata kiri dengan kotak ikon perisai,
   menggantikan state terpusat.
2. Tombol muat ulang ditambahkan di AppBar (opsional menurut
   spesifikasi, ditambahkan tim implementasi).
3. Teks empty state ditambah petunjuk "Coba buka lagi layar ini."

Tidak ada penyimpangan. Daftar aplikasi terisi hanya bisa dibuktikan
di HP fisik (di lingkungan test, daftar aplikasi kosong).

## 7. Riwayat Pemeriksaan

| | Berkas |
| --- | --- |
| Lama | `riwayat.png` |
| Baru | `riwayat-v11.png` |

Perubahan:

1. Tema gelap; empty state rata kiri dengan kotak ikon, judul
   berubah dari "Belum ada data pemeriksaan" menjadi "Belum ada
   riwayat pemeriksaan".
2. Dua tombol aksi di empty state: "Jalankan diagnosis" (primer)
   dan "Periksa WiFi" (sekunder). Dulu tidak ada tombol apa pun.
3. Tombol bagikan di AppBar kini DISEMBUNYIKAN saat riwayat kosong
   (dulu selalu tampil walau tidak ada yang bisa dibagikan). Ini
   memperbaiki pelanggaran aturan 13 spesifikasi (tidak ada elemen
   interaktif mati).

Penyimpangan kecil: judul entri riwayat memakai format
"Skor 82 (Baik)", sedangkan contoh di spesifikasi bagian 6.7 menulis
"Skor 82, Baik". Format kurung konsisten dengan dashboard dan
diharapkan test redesign; dicatat, bukan bug.

## 8. Diagnosis AI

| | Berkas |
| --- | --- |
| Lama | `ai-diagnosis.png` |
| Baru | `ai-diagnosis-v11.png` |

Perubahan:

1. Tema gelap; strip mode lokal di atas ("Mode lokal, belum
   tersambung ke server. Diagnosis AI membutuhkan server Supabase
   dan belum bisa dipakai.").
2. Label "Keluhan HP" di atas kolom teks, dengan placeholder
   "Contoh: WiFi lemot padahal sinyal penuh".
3. Tombol "Minta diagnosis" putih penuh dengan ikon kepala
   (psikologi), satu baris.

Tidak ada penyimpangan. Layar ini belum bisa dipakai tanpa server
Supabase; itu perilaku v1.0.1 yang dipertahankan, bukan regresi.

## 9. Akun dan Keamanan

| | Berkas |
| --- | --- |
| Lama | `akun.png` |
| Baru | `akun-v11.png` |

Perubahan:

1. Tema gelap; status akun memakai chip "Mode lokal" (biru) di
   bawah judul seksi "Akun".
2. PIN aplikasi memakai 8 kotak digit (lebar fleksibel, bukan 48 px
   tetap) dengan tombol "Simpan PIN" putih penuh dan penjelasan
   bahwa PIN disimpan dalam bentuk yang tidak bisa dibaca.
3. Strip info menjelaskan konsekuensi PIN belum diatur.
4. Seksi "Biometrik" menampilkan strip "Perangkat ini tidak
   mendukung biometrik." (di lingkungan test, mock local_auth
   melaporkan tidak ada biometrik). Footer versi "Dokter HP v1.0.1"
   dipertahankan.

Penyimpangan dari spesifikasi (dilaporkan tim implementasi,
dikonfirmasi QA): kotak digit PIN lebar fleksibel, bukan 48 px tetap
seperti contoh spesifikasi. Alasannya benar secara teknis: 8 kotak
48 px + 7 celah 8 px = 440 px, melebihi lebar konten 350 px di layar
390 px, sehingga lebar tetap mustahil. Pilihan lebar fleksibel adalah
keputusan rekayasa yang benar.

Logo Google pada tombol "Masuk dengan Google" digambar tangan via
CustomPainter (tanpa aset gambar). QA memverifikasi: busur empat
warna berjumlah 360 derajat (biru -60 sampai 60, hijau 60 sampai 150,
kuning 150 sampai 210, merah 210 sampai 300) plus batang biru, warna
brand benar. Golden `test/goldens/qa-akun-login.png` menunjukkan logo
G berwarna ter-render wajar, tidak rusak. Tampilan di HP fisik tetap
perlu dicek (temuan terbuka).

## Kepatuhan 13 aturan mengikat (spesifikasi bagian 5)

Semua 13 aturan LOLOS. Ringkasan bukti per aturan:

| # | Aturan | Bukti |
| --- | --- | --- |
| 1 | Tap target minimal 48 px | Tema: IconButton min 48x48, tombol min tinggi 56, TextButton min 64x48. Widget: baris fix min 64, baris riwayat/keamanan 72, sel grid 184, kolom PIN 56. |
| 2 | Kontras teks minimal 4,5:1 | Dihitung ulang independen (rumus WCAG): putih/hitam 21,00; abu #A3A3A3/hitam 8,33; abu #757575/hitam 4,56 (lolos). #757575 di atas kartu #111111 (4,10) dan #1C1C1C (3,70) TIDAK lolos, tetapi `textFaint` hanya dipakai di dua tempat: teks tombol nonaktif (dikecualikan WCAG, sesuai spesifikasi bagian 4.4) dan footer versi Akun di latar hitam (4,56, lolos). Tidak ada `textFaint` di atas kartu. |
| 3 | Tidak ada data dummy | Tidak ada nilai karangan di UI. Baterai 82 hanya mock test. Estimasi diberi label "Perkiraan... Bukan hasil ukur." |
| 4 | Semua fitur v1.0.1 tetap ada dan terjangkau | Diagnosis satu ketuk, tes WiFi, pemantau live, tes bertahan 30 detik + grafik, panduan WiFi verbatim, bersihkan cache, muat ulang Performa, daftar aplikasi/izin, hapus riwayat geser, laporan PDF, PIN, biometrik, masuk Google, Diagnosis AI: semua ada di kode dan terjangkau dari UI. |
| 5 | Tidak ada em dash di string UI | 0 di string UI. 4 em dash ditemukan di komentar kode, sudah dibersihkan QA. |
| 6 | Tidak ada kata terlarang | Grep lima kata ganti informal yang dilarang owner (batas kata, tanpa peduli huruf besar-kecil) di `lib/` + `test/`: 0 hasil. |
| 7 | Tidak ada emoji di teks UI | Pemindaian Python di `lib/` + `test/`: 0 hasil. |
| 8 | Tidak ada warna dekoratif di luar status fungsional | Semua literal warna adalah token spesifikasi + warna brand Google + `#2E2E2E` sorotan shimmer. Tidak ada pemakaian `Colors.*`. Satu-satunya gradasi adalah shimmer skeleton monokrom yang DIWAJIBKAN spesifikasi bagian 4.8 (abu-abu saja, bukan warna dekoratif). Tidak ada bayangan/blur. |
| 9 | State loading/skeleton, error dengan "Coba lagi", empty state spesifik | Ketiganya ada di tiap layar yang relevan, termasuk kasus N/A yang disetujui spesifikasi (misal layar tanpa pemuatan jaringan tidak butuh skeleton). |
| 10 | Satu titik fokus per layar | Terpenuhi; tiga meter kompak di Performa adalah pengecualian yang disetujui spesifikasi. |
| 11 | Reduced motion dihormati | `_PressScale`, `MeterGauge`, `Shimmer`, `LiveDot`, `AnimatedSwitcher`, `_GrafikSampel` semuanya memeriksa pengaturan gerakan perangkat. |
| 12 | Tidak ada ikon terlarang | Tidak ada sparkle/bintang/petir/berlian/robot/sihir. `fontSize: 10` hanya ada di `pdf_report_service.dart` (dokumen PDF, bawaan v1.0.1, bukan UI). |
| 13 | Tidak ada elemen interaktif mati | Tombol bagikan disembunyikan saat riwayat kosong. Semua tombol lain memicu aksi nyata. |

## Bug yang diperbaiki QA

### 1. Chip melebar selebar layar (bug aplikasi nyata)

File: `lib/core/widgets/common_widgets.dart` (`StatusChip`, `LiveChip`).

Temuan: screenshot `akun-v11.png` pertama menunjukkan chip
"Mode lokal" tampil sebagai bar selebar layar, bukan chip kecil
seperti spesifikasi bagian 4.3. Penyebab: `Container` tanpa lebar
melebar selebar parent bila chip diletakkan langsung di
ListView/Column (kendala lebar ketat). Tempat yang terdampak:
chip "Mode lokal" di Akun, chip hasil tes bertahan di WiFi, dan
chip Live di panel pantau (di dalam Expanded).

Perbaikan: bungkus `Container` chip dengan `UnconstrainedBox`
(rata kiri), yang melonggarkan kendala untuk latar chip sehingga
latar selalu sekecil isinya. Dua pendekatan lain dicoba dan GAGAL
dibuktikan test regresi, jadi tidak dipakai: `Row`
mainAxisSize.min (kendala ketat mengabaikannya) dan
`IntrinsicWidth` (ukuran widget tetap dipaksa selebar parent oleh
kendala ketat). Pelajaran ini didokumentasikan di komentar kode.

Test regresi baru di `test/redesign_widget_test.dart` (2 test):
"StatusChip tidak melebar selebar parent di ListView" dan "LiveChip
tidak melebar selebar parent di ListView". Keduanya mengukur
Container latar chip (bagian yang terlihat), bukan kotak widget
yang memang selebar parent tetapi transparan.

Dampak terukur: setelah perbaikan, dari 10 golden hanya
`qa-akun.png` yang berubah (sha256), dan dari 9 screenshot baru
hanya `akun-v11.png` yang berubah. Screenshot akun yang diperbaiki
menunjukkan chip "Mode lokal" kecil dan rapi.

### 2. Em dash di komentar kode (pembersihan kecil)

Empat em dash di komentar (bukan string UI) diganti koma/titik:
`device_native.dart:37`, `wifi_service.dart:317`,
`dashboard_widget_test.dart:59`, `qa_screenshot_test.dart:31`.
Non-fungsional, demi konsistensi dengan aturan DESIGN.md yang
lebih ketat.

### 3. Import tidak perlu di harness tangkap layar

`dart:typed_data` di `test/qa_capture_v11_test.dart` dihapus
setelah `flutter analyze` melaporkan `unnecessary_import` (semua
elemen yang dipakai sudah disediakan `package:flutter/services.dart`).
Analyze kembali 0 issue.

## Catatan kejujuran harness screenshot

- Screenshot baru memakai font Roboto asli dari cache SDK Flutter
  (Regular/Medium/Bold + MaterialIcons), BUKAN font balok Ahem.
  Dua masalah harness ditemukan dan diperbaiki QA: (1) tangkapan
  pertama menggantung karena `toImage()` tidak pernah selesai di
  zona FakeAsync, diperbaiki dengan membungkus tangkapan dalam
  `tester.runAsync()`; (2) judul AppBar dan label tombol tetap
  tampil sebagai balok Ahem karena tema AppBar/tombol menggantikan
  (bukan menggabungkan) gaya teks ambient tanpa fontFamily,
  diperbaiki dengan `temaHarness()` yang menerapkan fontFamily
  Roboto ke gaya teks tema. Tidak ada token desain yang diubah;
  patch hanya meniru font sistem Android di harness.
- Golden test (`test/goldens/`) tetap memakai font Ahem bawaan
  Flutter test. Akibatnya teks tombol membungkus 2 baris di golden
  ("Periksa WiFi sekarang", "Masuk dengan Google"). Itu artefak
  font test, bukan bug: dengan Roboto asli, label-label tersebut
  terbukti satu baris di screenshot `*-v11.png`.
- Nilai di screenshot adalah nilai harness test, bukan data
  perangkat: level baterai 82 (mock), nama perangkat "QA Phone",
  penyimpanan null, daftar aplikasi kosong, database riwayat kosong.
- Screenshot lama v1.0.1 tidak ditimpa; semua berkas baru memakai
  akhiran `-v11`.

## Catatan kecil lain (bukan bug)

- Splash LockGate memakai gaya teks body default, bukan headline
  28/700 seperti spesifikasi bagian 4.13 (splash boot di `main.dart`
  sudah sesuai). LockGate di luar cakupan spesifikasi kecuali
  penyesuaian token, jadi dicatat saja; bila owner ingin gaya
  headline di sana juga, itu keputusan desain kecil.
- Keterangan sel grid dashboard terpotong elipsis di lebar 390 px
  (lihat bagian Dashboard). Sesuai desain.

## Temuan terbuka untuk tim rilis / owner

Hal-hal berikut hanya bisa dibuktikan di HP fisik (APK dari CI)
dan belum terverifikasi di ronde ini:

1. State terisi: dashboard dengan skor kesehatan, panel hasil WiFi,
   tes bertahan 30 detik yang selesai + grafik, riwayat berisi,
   daftar aplikasi Keamanan berisi, Performa dalam keadaan termuat.
2. Logo Google CustomPainter di perangkat nyata (golden terverifikasi,
   perangkat nyata belum).
3. Render font di perangkat nyata (harness memakai Roboto SDK;
   font sistem perangkat bisa sedikit berbeda).
4. Build APK release (tugas CI, bukan QA; Gradle lokal rusak di VM
   ini, bukan salah kode).
5. RLS Supabase baru diverifikasi dari file SQL (temuan lama dari
   QA_REPORT.md, masih berlaku).
