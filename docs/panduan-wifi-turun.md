# Panduan: WiFi Turun ke KB/detik

Panduan diagnosis untuk pengguna Dokter HP v1.0.1. Bahasa di sini dibuat
sehari-hari supaya gampang diikuti tanpa latar belakang teknis.

## Yang perlu diketahui dulu

Di HP ini, kecepatan unduh biasanya 1 MB/detik, dan normalnya di atas
2 MB/detik. **Turun ke 1-3 KB/detik saat sedang memakai internet itu
tidak normal** — bukan sesuatu yang bisa dibiarkan begitu saja.

Tes singkat di Dokter WiFi pernah menunjukkan kecepatan 5,75 MB/detik,
dengan latensi 17-19 ms, sinyal -55 sampai -58 dBm (label Bagus),
kecepatan koneksi 65 Mbps, dan channel 6. Artinya, koneksi ini sebenarnya
bisa cepat. Kalau angka jatuh lagi begitu tes berhenti, penyebabnya ada
di tengah jalan — bukan karena sinyal lemah. Panduan ini membantu
mencari tahu penyebabnya, langkah demi langkah.

## Angka di bar atas itu apa

Angka kecepatan di bar atas adalah **laju data saat itu juga** — berapa
banyak data yang sedang lewat pada detik itu. Angka itu berubah-ubah
tergantung apa yang sedang dilakukan HP.

- Tes singkat hanya mengukur **kecepatan sesaat**: seberapa cepat data
  bisa lewat dalam waktu yang pendek.
- Tes bertahan 30 detik mengukur **apakah kecepatan bertahan atau jatuh
  di tengah jalan**: tes berjalan terus selama 30 detik, dan hasilnya
  menunjukkan apakah kecepatan stabil dari awal sampai akhir, atau
  mulai cepat kemudian jatuh.

Dua tes itu saling melengkapi. Tes singkat yang cepat saja belum cukup
membuktikan WiFi sehat — yang menentukan adalah apakah kecepatan
bertahan saat benar-benar dipakai.

## Dua tes pembeda

Sebelum mengubah pengaturan apa pun, lakukan dua tes sederhana ini.
Keduanya memakai HP sendiri, tanpa alat tambahan.

### Tes 1: Jatuh saat diam saja, atau jatuh juga saat dipakai?

1. Lihat angka kecepatan saat HP diam dan tidak ada yang diunduh.
2. Kemudian putar video 1080p atau unduh file besar selama 1 menit,
   dan perhatikan angka kecepatan selama video atau unduhan berjalan.

### Tes 2: HP lain di WiFi yang sama ikut jatuh atau tidak?

1. Sambungkan HP lain ke WiFi yang sama (SSID ACHA).
2. Putar video atau unduh file yang sama di HP lain itu, dan bandingkan
   kecepatannya dengan HP ini.

| Hasil tes | Artinya | Langkah berikutnya |
|---|---|---|
| Kecepatan kembali normal saat video 1080p diputar atau file besar diunduh selama 1 menit | WiFi masih bisa mengirim data saat dipakai; angka kecil tadi muncul saat tidak ada data yang sedang berjalan. Ulangi dengan tes bertahan 30 detik untuk memastikan kecepatan bertahan. | Lakukan tes bertahan 30 detik. Bila kecepatan bertahan, pantau dulu; bila jatuh di tengah jalan, lanjut ke daftar penyebab di bawah. |
| Kecepatan tetap jatuh ke KB/detik meski video 1080p sedang diputar atau file besar sedang diunduh | Masalahnya nyata — bukan soal HP sedang diam. Ada sesuatu yang menahan kecepatan saat data dipakai. | Lanjut ke daftar penyebab di bawah, mulai dari nomor 1. |
| HP lain normal, hanya HP ini yang jatuh | Masalah ada di HP ini, bukan di jaringan. | Periksa penyebab nomor 2, 3, 4, dan 7 (pengaturan HP). |
| HP lain ikut jatuh | Masalah ada di router atau jaringan, bukan di HP ini. | Periksa penyebab nomor 1, 5, 6, dan 7 (pengaturan router dan channel). |

## Penyebab umum dan cara memperbaiki

Semua langkah di bawah ini dilakukan dari HP, tanpa root, dan tanpa
mengubah halaman PPPoE di router. Pengaturan PPPoE sudah tersambung
(Connected) — jangan diubah.

### 1. Mode WiFi router masih 802.11b Only — penyebab paling mungkin

**Temuan:** Di halaman Network, lalu WLAN, lalu Basic pada router ZTE
F660, kolom Mode terisi **IEEE 802.11b Only**. Pengaturan ini salah
dan kemungkinan besar menjadi akar masalah.

802.11b adalah teknologi dari tahun 1999 dengan kecepatan maksimal
11 Mbps. Mode ini mudah jatuh ke KB/detik, terutama saat pemakaian
sedang berjalan. Pengaturan yang benar adalah **802.11b/g/n Mixed**,
supaya router memakai standar yang lebih baru (WiFi 4 / 802.11n)
dan kecepatan bisa naik sesuai kemampuan perangkat.

Pengaturan lain di halaman yang sama sudah benar dan tidak perlu
diubah: Channel 6, QoS Disabled, dan Tx Rate Auto.

**Cara perbaiki (router ZTE F660):**

1. Buka halaman admin router dari browser HP.
2. Buka menu Network, lalu WLAN, lalu Basic.
3. Ubah Mode dari **IEEE 802.11b Only** menjadi
   **802.11b/g/n Mixed**.
4. Biarkan Channel tetap 6, QoS tetap Disabled, dan Tx Rate tetap
   Auto.
5. **Penting — jangan tekan Submit dulu:** di tampilan yang sama,
   kolom SSID Name terlihat kosong dan Authentication terisi Open
   System. Muat ulang dulu halaman Basic dan pastikan SSID Name
   tampil **ACHA** sebelum menekan Submit. Menekan Submit saat SSID
   Name masih kosong berisiko menyimpan pengaturan yang salah.
6. Setelah SSID Name tampil ACHA, tekan Submit, tunggu router
   menerapkan perubahan, lalu sambungkan ulang HP ke WiFi.
7. Jalankan tes kecepatan di Dokter WiFi. Bila kecepatan kembali
   normal dan bertahan, penyebabnya sudah ketemu.

### 2. Mode hemat daya mematikan atau membatasi WiFi

**Cara cek:** Buka Pengaturan, lalu Baterai. Lihat apakah Penghemat
Baterai atau Mode Hemat Daya sedang aktif. Di sebagian HP, mode ini
ikut membatasi WiFi dan data latar belakang.

**Cara perbaiki:**

1. Matikan Penghemat Baterai sementara.
2. Jalankan lagi tes kecepatan di Dokter WiFi atau putar video 1080p
   selama 1 menit.
3. Bila kecepatan kembali normal, penyebabnya adalah mode hemat daya.
   Nyalakan lagi mode itu hanya bila sudah selesai memakai WiFi, atau
   atur supaya mode itu tidak aktif saat sedang butuh kecepatan penuh.

### 3. Data Saver (penghemat data) membatasi data latar belakang

**Cara cek:** Buka Pengaturan, lalu Jaringan atau Koneksi. Cari
Penghemat Data (Data Saver) dan lihat apakah sedang aktif. Fitur ini
membatasi data yang dipakai aplikasi di latar belakang, dan di sebagian
HP ikut menahan kecepatan unduh.

**Cara perbaiki:**

1. Matikan Penghemat Data sementara.
2. Jalankan lagi tes kecepatan atau putar video 1080p selama 1 menit.
3. Bila kecepatan kembali normal, penyebabnya adalah penghemat data.
   Bila fitur ini memang mau tetap dipakai, beri izin pemakaian data
   tanpa batas untuk aplikasi yang sedang dipakai (di sebagian HP ada
   di Pengaturan, lalu Aplikasi, lalu aplikasi yang dipakai, lalu Data
   seluler dan WiFi).

### 4. WiFi tidur saat layar mati

**Cara cek:** Buka Pengaturan, lalu WiFi, lalu setelan lanjutan
(di sebagian HP, ketuk ikon tiga titik atau menu lanjutan di halaman
WiFi). Cari pengaturan seperti "WiFi tetap aktif saat tidur" atau
"Jaga WiFi tetap aktif saat layar mati".

**Cara perbaiki:**

1. Ubah pengaturan itu supaya WiFi tetap aktif saat layar mati.
2. Kunci layar selama satu menit, buka lagi, lalu jalankan tes
   kecepatan.
3. Bila kecepatan tetap stabil setelah layar mati dan menyala lagi,
   penyebabnya sudah ketemu.

### 5. QoS atau batas kecepatan per perangkat di router untuk IP HP ini

**Cara cek:** Batas kecepatan per perangkat (QoS atau Bandwidth
Control) diatur di halaman admin router, bukan di HP. Perlu diketahui
dulu alamat IP HP ini: buka Dokter WiFi dan lihat alamat IP yang
tampil. Saat ini IP HP ini adalah 192.168.1.7 — sebelumnya pernah
192.168.1.3, jadi alamat ini bisa berubah saat HP tersambung ulang.

**Cara perbaiki:**

1. Buka halaman admin router dari browser HP (alamat dan kata sandi
   admin ada di stiker bawah router atau dari yang memasang router).
2. Cari menu QoS, Bandwidth Control, atau Batas Kecepatan.
3. Lihat apakah ada aturan yang membatasi IP HP ini (192.168.1.7)
   atau alamat perangkat HP ini. Bila ada, hapus atau naikkan batasnya.
4. Simpan, lalu jalankan lagi tes kecepatan.
5. Bila tidak ada menu seperti itu atau tidak yakin, lewati langkah
   ini dan lanjut ke penyebab berikutnya — jangan ubah pengaturan lain
   di halaman admin router, terutama halaman PPPoE.

### 6. Gangguan channel tetangga — ganti channel 1, 6, atau 11 dan Bandwidth 40 MHz (ZTE F660)

**Cara cek:** Di pita 2,4 GHz, channel yang dipakai banyak router
tetangga bisa saling mengganggu. Channel 1, 6, dan 11 adalah tiga
channel yang tidak saling tumpang tindih, jadi hanya ketiganya yang
dipakai untuk pindah. Channel 6 saat ini terukur ideal, tetapi bila
tetangga di sekitar juga memakai channel yang sama, gangguan tetap
bisa terjadi.

**Cara perbaiki (router ZTE F660):**

1. Buka halaman admin router dari browser HP.
2. Buka menu Network, lalu WLAN, lalu Basic.
3. Ubah Channel ke 1 atau 11 (coba satu dulu).
4. Ubah Bandwidth ke 40 MHz.
5. Simpan pengaturan, tunggu router menerapkan perubahan, lalu
   sambungkan ulang HP ke WiFi.
6. Jalankan tes kecepatan. Bila belum membaik, coba channel yang
   satunya lagi (1 atau 11, yang belum dicoba).
7. Catat channel mana yang hasilnya paling cepat, lalu pakai channel
   itu.

### 7. DHCP berubah atau IP bentrok — lupakan jaringan, sambung ulang, mulai ulang router

**Cara cek:** Alamat IP HP ini pernah berubah dari 192.168.1.3
menjadi 192.168.1.7. Perubahan seperti itu normal bila HP tersambung
ulang, tetapi bila disertai kecepatan jatuh, bisa jadi ada bentrok
alamat IP atau data sambungan lama yang rusak.

**Cara perbaiki:**

1. Lupakan jaringan WiFi, kemudian sambung ulang (langkah ini sudah
   ada di Dokter WiFi — ikuti petunjuk di aplikasi).
2. Bila masih lambat, mulai ulang router: cabut kabel daya router,
   tunggu 5 menit, colokkan lagi, dan tunggu sampai lampu router
   menyala normal.
3. Sambungkan HP ke WiFi, lalu jalankan lagi tes kecepatan.
4. Bila kecepatan kembali normal setelah mulai ulang, penyebabnya
   ada di router yang perlu diistirahatkan sesekali.

### 8. Terlalu jauh dari router atau terhalang

**Cara cek:** Berdiri di dekat router (sekitar 1-2 meter, tanpa dinding
di antaranya) dan jalankan tes kecepatan. Bandingkan dengan hasil tes
dari tempat biasa memakai HP.

**Cara perbaiki:**

1. Bila kecepatan di dekat router normal tetapi jauh dari router jatuh,
   penyebabnya adalah jarak atau halangan (dinding tebal, lemari besi,
   atau lantai berbeda).
2. Pakai HP lebih dekat dengan router saat butuh kecepatan penuh, atau
   pindahkan router ke tempat yang lebih terbuka dan lebih tinggi.
3. Bila sinyal sudah Bagus (-55 sampai -58 dBm) tetapi kecepatan tetap
   jatuh, jarak bukan penyebabnya — kembali ke penyebab nomor 1
   sampai 7.

## Langkah yang sudah ada di aplikasi

Dua langkah perbaikan sudah ada di Dokter WiFi dan tidak diulang
panjang di sini:

- **Lupakan lalu sambung ulang jaringan:** ikuti petunjuk di halaman
  Dokter WiFi; aplikasi membuka pengaturan WiFi sistem untuk
  melakukannya.
- **Ganti DNS ke 1.1.1.1 atau 8.8.8.8:** atur lewat DNS Pribadi di
  pengaturan sistem, sesuai petunjuk di halaman Dokter WiFi.

Bila kedua langkah itu sudah dicoba dan kecepatan masih jatuh, lanjut
ke daftar penyebab di atas — terutama penyebab nomor 1, 2, 3, 5, dan 6.

## Teks untuk kartu di aplikasi

Judul kartu:

**WiFi turun ke KB/detik? Cek dulu sebelum panik**

Penjelasan:

Angka di bar atas menunjukkan laju data saat itu. Tes singkat hanya mengukur kecepatan sesaat, sedangkan tes bertahan 30 detik menunjukkan apakah kecepatan bertahan atau jatuh di tengah jalan. Bila kecepatan tetap jatuh saat video sedang diputar, masalahnya nyata dan perlu dicari penyebabnya.

Langkah:

1. Putar video 1080p selama 1 menit sambil memperhatikan angka kecepatan.
2. Bandingkan dengan HP lain di WiFi yang sama.
3. Matikan penghemat baterai dan penghemat data, kemudian tes lagi.
4. Lupakan jaringan, sambung ulang, kemudian mulai ulang router bila masih lambat.
