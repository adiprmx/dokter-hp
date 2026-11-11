import 'package:flutter/material.dart';
import 'package:dokter_hp/data/local/app_database.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import 'package:dokter_hp/core/health_score.dart';
import 'package:dokter_hp/core/theme.dart';
import 'package:dokter_hp/core/native/device_native.dart';
import 'package:dokter_hp/core/widgets/common_widgets.dart';
import 'package:dokter_hp/features/wifi_doctor/wifi_cubit.dart';
import 'package:dokter_hp/features/wifi_doctor/wifi_service.dart';

/// Layar Dokter WiFi, fitur utama.
///
/// Menampilkan hasil ukur nyata (SSID, IP, DNS, sinyal, kecepatan unduh,
/// latensi) dan rekomendasi. Semua tindakan perbaikan yang dibatasi
/// Android dijelaskan jujur: aplikasi tidak bisa menyambung ulang,
/// melupakan jaringan, atau mengganti DNS secara langsung.
class WifiDoctorPage extends StatelessWidget {
  const WifiDoctorPage({super.key, required this.database});

  final AppDatabase database;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => WifiCubit(database: database),
      child: const _WifiDoctorView(),
    );
  }
}

class _WifiDoctorView extends StatelessWidget {
  const _WifiDoctorView();

  Future<void> _bagikanHasil(WifiCheckResult hasil) async {
    final kecepatan = hasil.downloadKbps == null
        ? 'tidak berhasil diukur'
        : formatKbps(hasil.downloadKbps!);
    final teks = 'Hasil pemeriksaan WiFi (Dokter HP)\n'
        'WiFi: ${hasil.ssid ?? 'tidak diketahui'}\n'
        'Kecepatan unduh: $kecepatan\n'
        'Latensi HTTP: ${hasil.pingMs == null ? 'tidak terukur' : '${hasil.pingMs} ms'}\n'
        'Sinyal: ${hasil.signalText}'
        '${hasil.rssiDbm == null ? '' : ' (${hasil.rssiDbm} dBm)'}\n'
        'Channel: ${hasil.channel ?? 'tidak diketahui'}\n'
        'Rekomendasi: ${hasil.recommendations.join(' ')}';
    await SharePlus.instance.share(ShareParams(text: teks));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dokter WiFi')),
      body: BlocBuilder<WifiCubit, WifiState>(
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Pemeriksaan ini mengukur kecepatan unduh dan latensi '
                'dengan data nyata dari perangkat. Tidak ada angka contoh.',
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: state.status == WifiStatus.berjalan
                    ? null
                    : () => context.read<WifiCubit>().jalankanPemeriksaan(),
                icon: const Icon(Icons.wifi_find),
                label: Text(
                  state.status == WifiStatus.berjalan
                      ? 'Memeriksa...'
                      : 'Periksa WiFi sekarang',
                ),
              ),
              if (state.status == WifiStatus.berjalan) ...[
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  backgroundColor: Colors.black12,
                  color: Colors.black,
                ),
                const SizedBox(height: 8),
                Text(state.tahap),
              ],
              if (state.status == WifiStatus.awal) ...[
                const SizedBox(height: 24),
                const EmptyState(
                  icon: Icons.wifi,
                  title: 'Belum ada data pemeriksaan',
                  message: 'Ketuk "Periksa WiFi sekarang" untuk mengukur '
                      'kondisi WiFi perangkat ini.',
                ),
              ],
              if (state.status == WifiStatus.gagal) ...[
                const SizedBox(height: 16),
                ErrorState(
                  title: 'Pemeriksaan WiFi gagal',
                  message: state.pesan,
                  onRetry: () =>
                      context.read<WifiCubit>().jalankanPemeriksaan(),
                ),
              ],
              if (state.hasil != null &&
                  state.hasil!.ssid == null &&
                  state.hasil!.ssidPerluIzinLokasi) ...[
                const SizedBox(height: 16),
                _IzinLokasiCard(
                  sedangMemeriksa: state.status == WifiStatus.berjalan,
                ),
              ],
              const SizedBox(height: 16),
              const _PantauLiveCard(),
              const SizedBox(height: 16),
              const _TesBertahanCard(),
              const SizedBox(height: 16),
              const _PanduanCard(),
              if (state.hasil != null) ...[
                const SizedBox(height: 16),
                _HasilCard(hasil: state.hasil!),
                const SizedBox(height: 16),
                _PerbaikanCard(hasil: state.hasil!),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => _bagikanHasil(state.hasil!),
                  icon: const Icon(Icons.share),
                  label: const Text('Bagikan hasil pemeriksaan'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _HasilCard extends StatelessWidget {
  const _HasilCard({required this.hasil});

  final WifiCheckResult hasil;

  @override
  Widget build(BuildContext context) {
    final kecepatan = hasil.downloadKbps;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hasil pemeriksaan',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (kecepatan != null)
              Center(
                child: Column(
                  children: [
                    Text(
                      formatKbps(kecepatan),
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      hasil.speedClass?.label ?? '',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              )
            else
              const Text('Kecepatan unduh: tidak berhasil diukur.'),
            const Divider(height: 24),
            InfoRow(
              label: 'Nama WiFi (SSID)',
              value: hasil.ssid ?? 'Tidak tersedia',
            ),
            InfoRow(
              label: 'Alamat IP',
              value: hasil.ipAddress ?? 'Tidak tersedia',
            ),
            InfoRow(
              label: 'Gateway',
              value: hasil.gateway ?? 'Tidak tersedia',
            ),
            InfoRow(
              label: 'DNS',
              value: hasil.dnsServers.isEmpty
                  ? 'Tidak tersedia'
                  : hasil.dnsServers.join(', '),
            ),
            InfoRow(
              label: 'Kekuatan sinyal',
              value: hasil.rssiDbm == null
                  ? 'Tidak tersedia'
                  : '${hasil.signalText} (${hasil.rssiDbm} dBm)',
            ),
            InfoRow(
              label: 'Kecepatan koneksi',
              value: hasil.linkSpeedMbps == null
                  ? 'Tidak tersedia'
                  : '${hasil.linkSpeedMbps} Mbps',
            ),
            InfoRow(
              label: 'Channel',
              value: hasil.channel == null
                  ? 'Tidak tersedia'
                  : '${hasil.channel}',
            ),
            InfoRow(
              label: 'Latensi HTTP',
              value: hasil.pingMs == null
                  ? 'Tidak berhasil diukur'
                  : '${hasil.pingMs} ms',
            ),
            const Divider(height: 24),
            Text(
              'Rekomendasi',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            for (final saran in hasil.recommendations)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('•  '),
                    Expanded(child: Text(saran)),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            const Text(
              'Tentang channel: di pita 2,4 GHz hanya channel 1, 6, dan 11 '
              'yang tidak saling tumpang tindih. Bila banyak jaringan '
              'tetangga memakai channel yang sama, pindah channel di '
              'pengaturan router (mis. ZTE F660: masuk ke alamat admin '
              'router, menu WLAN, ubah Channel) biasanya memperbaiki '
              'kecepatan.',
              style: TextStyle(color: AppTheme.mutedGrey),
            ),
          ],
        ),
      ),
    );
  }
}

class _PerbaikanCard extends StatelessWidget {
  const _PerbaikanCard({required this.hasil});

  final WifiCheckResult hasil;

  Future<void> _bukaPengaturanWifi(BuildContext context) async {
    final berhasil = await DeviceNative.openWifiSettings();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          berhasil
              ? 'Pengaturan WiFi dibuka.'
              : 'Tidak bisa membuka pengaturan WiFi otomatis. '
                  'Buka manual: Pengaturan > WiFi.',
        ),
      ),
    );
  }

  void _tampilkanPenjelasan(
    BuildContext context,
    String judul,
    String isi,
  ) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(judul),
        content: Text(isi),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tutup'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _bukaPengaturanWifi(context);
            },
            child: const Text('Buka pengaturan WiFi'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Perbaikan',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Android membatasi aplikasi pihak ketiga: aplikasi tidak bisa '
              'menyambung ulang WiFi, melupakan jaringan, atau mengganti '
              'DNS secara langsung. Langkah di bawah ini memakai pengaturan '
              'sistem.',
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.wifi),
              title: const Text('Sambung ulang WiFi'),
              subtitle: const Text(
                'Matikan lalu nyalakan WiFi dari pengaturan sistem.',
              ),
              onTap: () => _bukaPengaturanWifi(context),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.dns),
              title: const Text('Ganti DNS ke 1.1.1.1 / 8.8.8.8'),
              subtitle: const Text(
                'DNS per jaringan hanya bisa diubah di pengaturan sistem '
                'atau router. Alternatif: aktifkan DNS Pribadi di '
                'Pengaturan > Jaringan > DNS Pribadi.',
              ),
              onTap: () => _tampilkanPenjelasan(
                context,
                'Ganti DNS',
                'Android tidak mengizinkan aplikasi mengubah DNS jaringan '
                'WiFi secara langsung.\n\n'
                'Cara manual:\n'
                '1. Buka Pengaturan > WiFi, ketuk jaringan yang dipakai, '
                'pilih Lanjutan > IP Statis, isi DNS 1: 1.1.1.1 dan '
                'DNS 2: 8.8.8.8.\n'
                '2. Atau aktifkan DNS Pribadi (Pengaturan > Jaringan > '
                'DNS Pribadi) dengan hostname dns.cloudflare-dns.com.\n'
                '3. Atau ubah DNS di halaman admin router agar berlaku '
                'untuk semua perangkat.',
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.wifi_off),
              title: const Text('Lupakan lalu sambung ulang jaringan'),
              subtitle: const Text(
                'Hanya bisa dilakukan dari pengaturan sistem.',
              ),
              onTap: () => _tampilkanPenjelasan(
                context,
                'Lupakan jaringan',
                'Android tidak mengizinkan aplikasi melupakan jaringan WiFi '
                'secara langsung.\n\n'
                'Cara manual: buka Pengaturan > WiFi, ketuk jaringan '
                '"${hasil.ssid ?? ''}", pilih "Lupakan", lalu sambungkan '
                'ulang dengan memasukkan kata sandi.',
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.router),
              title: const Text('Ganti channel router'),
              subtitle: Text(hasil.channelRecommendation),
              onTap: () => _tampilkanPenjelasan(
                context,
                'Ganti channel router',
                'Masuk ke halaman admin router (biasanya 192.168.1.1), '
                'buka menu WLAN, ubah Channel ke 1, 6, atau 11, lalu '
                'simpan dan mulai ulang router.\n\n'
                '${hasil.channelRecommendation}',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Kartu izin lokasi: nama WiFi tidak bisa dibaca Android tanpa izin
/// lokasi. Tombol menjalankan ulang pemeriksaan, yang meminta izin lagi.
class _IzinLokasiCard extends StatelessWidget {
  const _IzinLokasiCard({required this.sedangMemeriksa});

  final bool sedangMemeriksa;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nama WiFi tidak tampil',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Nama WiFi tidak tampil karena izin lokasi belum diberikan. '
              'Ketuk untuk mengizinkan, lalu periksa lagi. Bila sudah '
              'diizinkan tapi tetap tidak tampil, nyalakan layanan lokasi '
              'di perangkat.',
            ),
            const SizedBox(height: 12),
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: sedangMemeriksa
                  ? null
                  : () => context.read<WifiCubit>().jalankanPemeriksaan(),
              child: const Text('Izinkan lokasi dan periksa lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Kartu pemantau live: saat sakelar aktif, angka di layar diperbarui
/// otomatis tanpa perlu mengetuk tombol.
///
/// Batasan kuota yang jujur: probe unduh hanya tiap 10 detik dengan
/// file 100 KB (sekitar 600 KB per menit); info ringan (sinyal,
/// kecepatan koneksi, channel, latensi) diperbarui tiap 2 detik tanpa
/// mengunduh file.
class _PantauLiveCard extends StatelessWidget {
  const _PantauLiveCard();

  String _formatJam(DateTime waktu) {
    String dua(int n) => n.toString().padLeft(2, '0');
    return '${dua(waktu.hour)}:${dua(waktu.minute)}:${dua(waktu.second)}';
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WifiCubit, WifiState>(
      builder: (context, state) {
        final live = state.liveHasil;
        final sibuk = state.status == WifiStatus.berjalan ||
            state.sustainedStatus == SustainedStatus.berjalan;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Pantau live'),
                  subtitle: const Text(
                    'Saat sakelar ini aktif, angka di layar diperbarui '
                    'otomatis tanpa perlu mengetuk tombol.',
                  ),
                  value: state.pantauLive,
                  onChanged: (aktif) {
                    if (aktif && sibuk) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Pemantau live tidak bisa dinyalakan saat '
                            'pemeriksaan atau tes bertahan sedang berjalan.',
                          ),
                        ),
                      );
                      return;
                    }
                    context.read<WifiCubit>().alihkanPantauLive(aktif);
                  },
                ),
                const Text(
                  'Pemakaian data sekitar 600 KB per menit: probe unduh '
                  '100 KB setiap 10 detik. Info sinyal, kecepatan koneksi, '
                  'channel, dan latensi diperbarui setiap 2 detik tanpa '
                  'mengunduh file.',
                  style: TextStyle(color: AppTheme.mutedGrey),
                ),
                if (state.pantauLive) ...[
                  const SizedBox(height: 12),
                  InfoRow(
                    label: 'Kecepatan unduh',
                    value: live?.downloadKbps == null
                        ? 'Mengukur...'
                        : formatKbps(live!.downloadKbps!),
                  ),
                  InfoRow(
                    label: 'Kekuatan sinyal',
                    value: live?.rssiDbm == null
                        ? 'Tidak tersedia'
                        : '${live!.signalText} (${live.rssiDbm} dBm)',
                  ),
                  InfoRow(
                    label: 'Kecepatan koneksi',
                    value: live?.linkSpeedMbps == null
                        ? 'Tidak tersedia'
                        : '${live!.linkSpeedMbps} Mbps',
                  ),
                  InfoRow(
                    label: 'Channel',
                    value: live?.channel == null
                        ? 'Tidak tersedia'
                        : '${live!.channel}',
                  ),
                  InfoRow(
                    label: 'Latensi HTTP',
                    value: live?.pingMs == null
                        ? 'Tidak berhasil diukur'
                        : '${live!.pingMs} ms',
                  ),
                  if (state.liveDiperbarui != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Terakhir diperbarui pukul '
                        '${_formatJam(state.liveDiperbarui!)}.',
                        style: const TextStyle(color: AppTheme.mutedGrey),
                      ),
                    ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Kartu tes bertahan 30 detik: mengunduh file uji 1 MB berulang selama
/// 30 detik dan mencatat kecepatan tiap detik, lalu menilai apakah
/// kecepatan bertahan atau jatuh di tengah jalan.
class _TesBertahanCard extends StatelessWidget {
  const _TesBertahanCard();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WifiCubit, WifiState>(
      builder: (context, state) {
        final cubit = context.read<WifiCubit>();
        final berjalan = state.sustainedStatus == SustainedStatus.berjalan;
        final hasil = state.sustainedHasil;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tes bertahan 30 detik',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Mengunduh file uji 1 MB berulang selama 30 detik dan '
                  'mencatat kecepatan tiap detik, untuk melihat apakah '
                  'kecepatan bertahan atau jatuh di tengah jalan.',
                ),
                const SizedBox(height: 12),
                if (berjalan) ...[
                  LinearProgressIndicator(
                    value: state.sustainedDetik / 30,
                    backgroundColor: Colors.black12,
                    color: Colors.black,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Detik ${state.sustainedDetik} dari 30'
                    '${state.sustainedSampelTerakhir == null ? '' : ' — kecepatan saat ini ${formatKbps(state.sustainedSampelTerakhir!)}'}',
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    onPressed: () => cubit.batalkanTesBertahan(),
                    icon: const Icon(Icons.stop),
                    label: const Text('Berhenti'),
                  ),
                ] else ...[
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    onPressed: () => cubit.mulaiTesBertahan(),
                    icon: const Icon(Icons.timer),
                    label: const Text('Tes bertahan 30 detik'),
                  ),
                ],
                if (state.sustainedStatus == SustainedStatus.gagal) ...[
                  const SizedBox(height: 12),
                  Text(state.sustainedPesan),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    onPressed: () => cubit.mulaiTesBertahan(),
                    child: const Text('Coba lagi'),
                  ),
                ],
                if (hasil != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    hasil.verdict.label,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(hasil.verdict.penjelasan),
                  const SizedBox(height: 12),
                  InfoRow(
                    label: 'Terendah',
                    value: formatKbps(hasil.terendahKbps),
                  ),
                  InfoRow(
                    label: 'Rata-rata',
                    value: formatKbps(hasil.rataRataKbps),
                  ),
                  InfoRow(
                    label: 'Tertinggi',
                    value: formatKbps(hasil.tertinggiKbps),
                  ),
                  const SizedBox(height: 12),
                  _GrafikSampel(samples: hasil.samples),
                  const SizedBox(height: 12),
                  const Text(
                    'Kecepatan tiap detik:',
                    style: TextStyle(color: AppTheme.mutedGrey),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      for (var i = 0; i < hasil.samples.length; i++)
                        Text('d${i + 1}: ${formatKbps(hasil.samples[i])}'),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Grafik batang sederhana dari sampel per detik. Tinggi batang
/// sebanding dengan kecepatan (dinormalisasi ke sampel tertinggi);
/// bukan grafik contoh — tiap batang adalah satu detik tes yang nyata.
class _GrafikSampel extends StatelessWidget {
  const _GrafikSampel({required this.samples});

  final List<double> samples;

  @override
  Widget build(BuildContext context) {
    final maks = samples.reduce((a, b) => a > b ? a : b);
    return Semantics(
      label: 'Grafik kecepatan per detik selama tes bertahan',
      child: SizedBox(
        height: 72,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final nilai in samples)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1),
                  child: Container(
                    height: maks <= 0
                        ? 2
                        : (nilai / maks * 64).clamp(2.0, 64.0),
                    color: Colors.black87,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Kartu panduan saat WiFi turun ke KB/detik. Teks disalin kata per kata
/// dari docs/panduan-wifi-turun.md (bagian "Teks untuk kartu di
/// aplikasi"), jangan diubah atau diparafrase.
class _PanduanCard extends StatelessWidget {
  const _PanduanCard();

  static const _langkah = [
    'Putar video 1080p selama 1 menit sambil memperhatikan angka kecepatan.',
    'Bandingkan dengan HP lain di WiFi yang sama.',
    'Matikan penghemat baterai dan penghemat data, kemudian tes lagi.',
    'Lupakan jaringan, sambung ulang, kemudian mulai ulang router bila masih lambat.',
  ];

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'WiFi turun ke KB/detik? Cek dulu sebelum panik',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Angka di bar atas menunjukkan laju data saat itu. Tes '
              'singkat hanya mengukur kecepatan sesaat, sedangkan tes '
              'bertahan 30 detik menunjukkan apakah kecepatan bertahan '
              'atau jatuh di tengah jalan. Bila kecepatan tetap jatuh saat '
              'video sedang diputar, masalahnya nyata dan perlu dicari '
              'penyebabnya.',
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < _langkah.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${i + 1}.  '),
                    Expanded(child: Text(_langkah[i])),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
