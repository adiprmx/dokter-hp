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
              if (state.status == WifiStatus.gagal) ...[
                const SizedBox(height: 16),
                ErrorState(
                  title: 'Pemeriksaan WiFi gagal',
                  message: state.pesan,
                  onRetry: () =>
                      context.read<WifiCubit>().jalankanPemeriksaan(),
                ),
              ],
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
              if (state.status == WifiStatus.awal) ...[
                const SizedBox(height: 24),
                const EmptyState(
                  icon: Icons.wifi,
                  title: 'Belum ada data pemeriksaan',
                  message: 'Ketuk "Periksa WiFi sekarang" untuk mengukur '
                      'kondisi WiFi perangkat ini.',
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
