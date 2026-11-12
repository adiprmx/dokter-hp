# DESIGN.md: Dokter HP v1.1.0

> Arah desain (visual world) Dokter HP mulai v1.1.0. Dokumen ini
> menggantikan tampilan v1.0.0/v1.0.1 yang ditolak owner pada
> 12 November 2026 karena kaku, terasa buatan AI, kurang menarik,
> dan terlalu basic. Spesifikasi lengkap ada di
> `docs/redesign-v11-spec.md`. Bila keduanya bertabrakan soal rasa,
> dokumen ini yang menang; bila bertabrakan soal ukuran dan
> perilaku, spesifikasi yang menang.

Dial: ENERGY 2 / RHYTHM 2 / MOTION 2. Dial taste-frontend:
DESIGN_VARIANCE 6 / MOTION_INTENSITY 5 / VISUAL_DENSITY 5.

## Konsep: alat ukur

Dokter HP adalah alat ukur, bukan dasbor dan bukan klinik.
Pengguna membuka aplikasi ini untuk satu hal: angka yang bisa
dipercaya tentang HP-nya. Skor, kecepatan unduh, persen baterai,
suhu, jumlah izin. Desain menaruh angka di depan dan memperlakukan
layar seperti panel instrumen: satu angka besar, skala ukur dengan
tanda strip, label kecil yang jelas, dan tombol yang tidak ragu.

Motif identitas: **meter dengan tanda strip**. Satu garis ukur
horizontal dengan strip kecil di tiap interval dan penanda posisi
nilai. Motif ini dipakai di skor dashboard, kecepatan WiFi,
baterai, penyimpanan, RAM, CPU, dan suhu. Satu motif yang diulang
dengan konsisten adalah yang membuat aplikasi ini dikenali bila
nama dan logonya diganti.

## Prinsip

1. **Angka dulu, penjelasan kemudian.** Jawaban yang dicari
   pengguna selalu menjadi elemen terbesar di layar. Penjelasan,
   konteks, dan catatan selalu lebih kecil dan selalu di bawah
   jawaban.
2. **Satu focal point per layar.** Satu angka besar atau satu aksi
   utama. Bila dua elemen berebut perhatian, yang satu diturunkan
   bobotnya.
3. **Hitam, abu, putih. Warna hanya berarti status.** Latar hitam
   murni, permukaan abu gelap, teks putih. Hijau berarti baik,
   merah berarti perlu perhatian, kuning berarti menunggu atau
   cukup, biru berarti info. Warna tidak pernah menjadi hiasan.
4. **Bentuk mengikuti isi, bukan cetakan.** Dashboard memakai
   unggulan plus grid karena WiFi adalah fitur utama. WiFi memakai
   angka besar plus grafik karena kecepatan adalah jawabannya.
   Riwayat memakai linimasa karena pengguna mengingat kapan.
   Akun memakai daftar pengaturan karena isinya pengaturan.
   Kesembilan layar tidak memakai satu cetakan.
5. **Jujur sampai ke piksel terakhir.** Angka yang tampil hanya
   dari perangkat atau riwayat tersimpan. Bila tidak ada data,
   layar berkata jujur dan memberi jalan keluar. Estimasi
   dilabeli perkiraan. Batasan Android dijelaskan, bukan
   disembunyikan.
6. **Gerak hanya saat ada hasil ukur baru.** Jarum meter bergerak
   saat skor baru tiba. Angka menghitung saat diagnosis selesai.
   Nilai live berubah dengan halus. Tidak ada gerak yang hanya
   untuk terlihat hidup.
7. **Kalimat pendek, kata kerja jelas.** Copy memakai Bahasa
   Indonesia netral dan profesional. Tombol menamai aksinya.
   Galat menamai masalahnya dan jalan keluarnya. Tidak ada
   kalimat puitis, tidak ada klaim bombastis, tidak ada kata
   yang dilarang owner.

## Sistem singkat

- Warna: latar `#000000`, permukaan `#111111` dan `#1C1C1C`,
  garis `#262626`, teks `#FFFFFF` dan `#A3A3A3`, abu paling redup
  `#757575`, aksen putih, status hijau `#4ADE80`, merah `#F87171`,
  kuning `#FACC15`, biru `#60A5FA`. Semua pasangan teks/latar
  terverifikasi lolos WCAG AA (lihat spesifikasi bagian 3.1).
- Tipografi: font sistem, angka tabular. Satu angka besar 56
  per layar, judul layar 28 atau 20, judul bagian 17, isi 15,
  label 13, keterangan 12.
- Spacing: skala 4 pt, padding halaman 20, jarak antar bagian 32.
- Radius: kartu 16, tombol dan input 12, chip 8, bilah meter 4.
- Ikon: satu keluarga ikon Material, gaya outline, ukuran 20/24/28.
- Tanpa bayangan. Kedalaman ditunjukkan permukaan yang lebih
  terang, bukan bayangan.

## Yang TIDAK boleh dilakukan

- Tidak ada gradasi warna, tidak ada glow, tidak ada blur kaca,
  tidak ada bayangan lembut di mana pun.
- Tidak ada warna dekoratif. Kuning/amber hanya sebagai status
  menunggu atau cukup, tidak pernah sebagai aksen atau latar.
- Tidak ada kartu identik berulang, tidak ada kartu di dalam
  kartu, tidak ada grid tiga kolom yang sama bentuknya.
- Tidak ada cincin progres sebagai hiasan. Skor memakai meter
  dengan tanda strip.
- Tidak ada label eyebrow (label kecil kapital dengan tracking
  lebar di atas judul). Judul berdiri sendiri.
- Tidak ada ikon sparkle, bintang, sihir, petir, berlian, robot,
  atau orb AI. Tidak ada emoji di teks UI.
- Tidak ada ilustrasi generik, tidak ada gambar stok, tidak ada
  avatar contoh, tidak ada ilustrasi dokter atau stetoskop.
- Tidak ada garis vertikal berwarna di tepi kartu. Status
  ditunjukkan chip berikon dan teks, bukan strip.
- Tidak ada angka contoh, tidak ada statistik tanpa sumber,
  tidak ada klaim tanpa bukti.
- Tidak ada animasi loop tanpa henti, kecuali satu titik live
  saat pemantau live benar-benar aktif.
- Tidak ada em dash di teks mana pun.
- Tidak ada kata ganti informal yang dilarang owner di teks mana
  pun (daftar lengkapnya ada di MEMORY.md).
- Tidak ada font serif Didone/Playfair.
- Tidak ada tema terang sebagai pilihan di v1.1.0. Satu tema
  gelap yang dikirim harus sempurna.
- Tidak ada elemen interaktif yang tidak berfungsi, tidak ada
  tombol tanpa aksi, tidak ada tautan ke tempat yang tidak ada.
- Tidak ada tiruan tampilan produk populer (Linear, Vercel,
  Stripe, Notion, Apple). Aplikasi ini punya dunianya sendiri:
  alat ukur.
