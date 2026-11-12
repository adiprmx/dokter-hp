import 'dart:math' as math;

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

/// Layar Dokter WiFi v1.1.0, fitur utama.
///
/// Tiga babak mengikuti alur kerja pengguna: ukur, pantau, perbaiki.
/// Semua tindakan perbaikan yang dibatasi Android dijelaskan jujur:
/// aplikasi tidak bisa menyambung ulang, melupakan jaringan, atau
/// mengganti DNS secara langsung.
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
          final berjalan = state.status == WifiStatus.berjalan;
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.pagePadding,
              AppTheme.pagePadding,
              AppTheme.pagePadding,
              AppTheme.bottomPadding,
            ),
            children: [
              PrimaryButton(
                label: berjalan ? 'Memeriksa' : 'Periksa WiFi sekarang',
                icon: Icons.wifi_find,
                onPressed: berjalan
                    ? null
                    : () => context.read<WifiCubit>().jalankanPemeriksaan(),
              ),
              const SizedBox(height: 8),
              const Text(
                'Hasil dari perangkat ini, bukan angka contoh.',
                style: AppTheme.caption,
              ),
              if (berjalan) ...[
                const SizedBox(height: 20),
                const LinearProgressIndicator(),
                if (state.tahap.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    state.tahap,
                    style: AppTheme.body.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ],
              if (state.status == WifiStatus.awal) ...[
                const SizedBox(height: 32),
                const EmptyState(
                  icon: Icons.wifi,
                  title: 'Belum ada hasil pemeriksaan WiFi',
                  message: 'Ketuk Periksa WiFi sekarang untuk mengukur '
                      'kecepatan unduh dan latensi. Hasilnya tersimpan '
                      'di perangkat ini.',
                ),
              ],
              if (state.status == WifiStatus.gagal) ...[
                const SizedBox(height: 32),
                ErrorState(
                  title: 'Pemeriksaan WiFi gagal',
                  message: state.pesan,
                  onRetry: () =>
                      context.read<WifiCubit>().jalankanPemeriksaan(),
                ),
              ],
              if (state.hasil != null) ...[
                const SizedBox(height: 32),
                _PanelHasil(
                  hasil: state.hasil!,
                  onBagikan: () => _bagikanHasil(state.hasil!),
                ),
              ],
              if (state.hasil != null &&
                  state.hasil!.ssid == null &&
                  state.hasil!.ssidPerluIzinLokasi) ...[
                const SizedBox(height: 20),
                _StripIzinLokasi(sedangMemeriksa: berjalan),
              ],
              const SectionHeader(title: 'Pantau live'),
              const _PanelLive(),
              const SectionHeader(title: 'Tes bertahan 30 detik'),
              const _PanelTesBertahan(),
              if (state.hasil != null) ...[
                const SectionHeader(title: 'Perbaikan'),
                _DaftarPerbaikan(hasil: state.hasil!),
              ],
              const SectionHeader(
                title: 'WiFi turun ke KB/detik? Cek dulu sebelum panik',
              ),
              const _Panduan(),
            ],
          );
        },
      ),
    );
  }
}

/// Panel hasil: angka kecepatan besar plus meter skala logaritmik,
/// latensi, info jaringan, rekomendasi, strip channel, tombol bagikan.
class _PanelHasil extends StatelessWidget {
  const _PanelHasil({required this.hasil, required this.onBagikan});

  final WifiCheckResult hasil;
  final VoidCallback onBagikan;

  /// Posisi kecepatan dalam skala logaritmik 1 sampai 10.000 KB/detik.
  /// Titik tandanya adalah ambang klasifikasi yang sudah ada
  /// (50, 200, 1000, 5000 KB/detik).
  static double _fraksiLog(double kbps) {
    final nilai = math.log(math.max(kbps, 1)) / math.ln10 / 4;
    return nilai.clamp(0.0, 1.0);
  }

  static const _tandaLog = [0.425, 0.575, 0.75, 0.925];

  /// Bagi "5,75 MB/detik" menjadi angka ("5,75") dan satuan
  /// ("MB/detik") agar angka besar dan satuan tampil beda ukuran.
  static (String, String) _bagiKecepatan(double kbps) {
    final teks = formatKbps(kbps);
    final pisah = teks.split(' ');
    if (pisah.length < 2) return (teks, '');
    return (pisah[0], pisah.sublist(1).join(' '));
  }

  StatusTone _toneKecepatan(SpeedClass? kelas) {
    switch (kelas) {
      case SpeedClass.sangatCepat:
      case SpeedClass.cepat:
        return StatusTone.success;
      case SpeedClass.cukup:
        return StatusTone.warning;
      case SpeedClass.lambat:
      case SpeedClass.sangatLambat:
        return StatusTone.danger;
      case null:
        return StatusTone.neutral;
    }
  }

  Color _warnaKecepatan(SpeedClass? kelas) {
    switch (kelas) {
      case SpeedClass.sangatCepat:
      case SpeedClass.cepat:
        return AppTheme.success;
      case SpeedClass.cukup:
        return AppTheme.warning;
      case SpeedClass.lambat:
      case SpeedClass.sangatLambat:
        return AppTheme.danger;
      case null:
        return AppTheme.accent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final kecepatan = hasil.downloadKbps;
    final kelas = hasil.speedClass;
    final bagi = kecepatan == null
        ? null
        : _bagiKecepatan(kecepatan);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MeterGauge(
                fraction: kecepatan == null
                    ? null
                    : _fraksiLog(kecepatan),
                displayValue: bagi?.$1 ?? '',
                displayUnit: bagi?.$2,
                emptyText: 'Kecepatan unduh tidak berhasil diukur.',
                animatedNumber: kecepatan,
                formatNumber: (nilai) => _bagiKecepatan(nilai).$1,
                fillColor: _warnaKecepatan(kelas),
                ticks: _tandaLog,
                scaleMinLabel: '0',
                scaleMaxLabel: '10 MB/detik',
                chip: kelas == null
                    ? null
                    : StatusChip(
                        label: kelas.label,
                        icon: _toneKecepatan(kelas) == StatusTone.success
                            ? Icons.check
                            : Icons.warning_amber,
                        tone: _toneKecepatan(kelas),
                      ),
                semanticsLabel: kecepatan == null
                    ? 'Kecepatan unduh tidak berhasil diukur'
                    : 'Kecepatan unduh ${formatKbps(kecepatan)}, '
                        '${kelas?.label ?? ''}',
              ),
              if (hasil.pingMs != null) ...[
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Expanded(
                      child: Text('Latensi HTTP', style: AppTheme.label),
                    ),
                    Text(
                      '${hasil.pingMs} ms',
                      style: AppTheme.title.copyWith(
                        fontFeatures: AppTheme.tabularFigures,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        StatRow(
          label: 'Nama WiFi (SSID)',
          value: hasil.ssid ?? 'Tidak tersedia',
          valueColor:
              hasil.ssid == null ? AppTheme.textSecondary : null,
        ),
        const SizedBox(height: 12),
        StatRow(
          label: 'Alamat IP',
          value: hasil.ipAddress ?? 'Tidak tersedia',
          valueColor:
              hasil.ipAddress == null ? AppTheme.textSecondary : null,
        ),
        const SizedBox(height: 12),
        StatRow(
          label: 'Gateway',
          value: hasil.gateway ?? 'Tidak tersedia',
          valueColor:
              hasil.gateway == null ? AppTheme.textSecondary : null,
        ),
        const SizedBox(height: 12),
        StatRow(
          label: 'DNS',
          value: hasil.dnsServers.isEmpty
              ? 'Tidak tersedia'
              : hasil.dnsServers.join(', '),
          valueColor: hasil.dnsServers.isEmpty
              ? AppTheme.textSecondary
              : null,
        ),
        const SizedBox(height: 12),
        StatRow(
          label: 'Kekuatan sinyal',
          value: hasil.rssiDbm == null
              ? 'Tidak tersedia'
              : '${hasil.signalText} (${hasil.rssiDbm} dBm)',
          valueColor:
              hasil.rssiDbm == null ? AppTheme.textSecondary : null,
        ),
        const SizedBox(height: 12),
        StatRow(
          label: 'Kecepatan koneksi',
          value: hasil.linkSpeedMbps == null
              ? 'Tidak tersedia'
              : '${hasil.linkSpeedMbps} Mbps',
          valueColor: hasil.linkSpeedMbps == null
              ? AppTheme.textSecondary
              : null,
        ),
        const SizedBox(height: 12),
        StatRow(
          label: 'Channel',
          value:
              hasil.channel == null ? 'Tidak tersedia' : '${hasil.channel}',
          valueColor:
              hasil.channel == null ? AppTheme.textSecondary : null,
        ),
        const SectionHeader(title: 'Yang bisa dilakukan'),
        for (var i = 0; i < hasil.recommendations.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${i + 1}.  ',
                  style: AppTheme.body.copyWith(
                    fontFeatures: AppTheme.tabularFigures,
                  ),
                ),
                Expanded(
                  child: Text(
                    hasil.recommendations[i],
                    style: AppTheme.body,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 20),
        const StatusStrip(
          icon: Icons.info_outline,
          iconColor: AppTheme.info,
          text: 'Tentang channel: di pita 2,4 GHz hanya channel 1, 6, '
              'dan 11 yang tidak saling tumpang tindih. Bila banyak '
              'jaringan tetangga memakai channel yang sama, pindah '
              'channel di pengaturan router (mis. ZTE F660: masuk ke '
              'alamat admin router, menu WLAN, ubah Channel) biasanya '
              'memperbaiki kecepatan.',
        ),
        const SizedBox(height: 20),
        SecondaryButton(
          label: 'Bagikan hasil pemeriksaan',
          icon: Icons.share,
          onPressed: onBagikan,
        ),
      ],
    );
  }
}

/// Strip izin lokasi: nama WiFi tidak bisa dibaca Android tanpa izin
/// lokasi. Tombol menjalankan ulang pemeriksaan, yang meminta izin lagi.
class _StripIzinLokasi extends StatelessWidget {
  const _StripIzinLokasi({required this.sedangMemeriksa});

  final bool sedangMemeriksa;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StatusStrip(
          icon: Icons.location_off,
          text: 'Nama WiFi tidak tampil karena izin lokasi belum '
              'diberikan. Ketuk untuk mengizinkan, lalu periksa lagi. '
              'Bila sudah diizinkan tapi tetap tidak tampil, nyalakan '
              'layanan lokasi di perangkat.',
        ),
        const SizedBox(height: 12),
        SecondaryButton(
          label: 'Izinkan lokasi dan periksa lagi',
          onPressed: sedangMemeriksa
              ? null
              : () => context.read<WifiCubit>().jalankanPemeriksaan(),
        ),
      ],
    );
  }
}

/// Panel pemantau live: saat sakelar aktif, angka di layar diperbarui
/// otomatis tanpa perlu mengetuk tombol.
///
/// Batasan kuota yang jujur: probe unduh hanya tiap 10 detik dengan
/// file 100 KB (sekitar 600 KB per menit); info ringan (sinyal,
/// kecepatan koneksi, channel, latensi) diperbarui tiap 2 detik tanpa
/// mengunduh file.
class _PanelLive extends StatelessWidget {
  const _PanelLive();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WifiCubit, WifiState>(
      builder: (context, state) {
        final live = state.liveHasil;
        final sibuk = state.status == WifiStatus.berjalan ||
            state.sustainedStatus == SustainedStatus.berjalan;
        final kecepatan = live?.downloadKbps;
        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: state.pantauLive
                        ? const LiveChip()
                        : const Text(
                            'Tidak aktif',
                            style: AppTheme.caption,
                          ),
                  ),
                  Semantics(
                    label: 'Pantau live',
                    child: Switch(
                      value: state.pantauLive,
                      onChanged: (aktif) {
                        if (aktif && sibuk) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              duration: Duration(seconds: 3),
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
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Sekitar 600 KB per menit. Probe 100 KB tiap 10 detik.',
                style: AppTheme.caption,
              ),
              if (state.pantauLive) ...[
                const SizedBox(height: 20),
                const Text('Kecepatan unduh', style: AppTheme.label),
                const SizedBox(height: 4),
                AnimatedSwitcher(
                  duration: AppTheme.animationsDisabled(context)
                      ? Duration.zero
                      : AppTheme.tapFeedback,
                  child: kecepatan == null
                      ? Text(
                          'Mengukur...',
                          key: const ValueKey('mengukur'),
                          style: AppTheme.body.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        )
                      : Text(
                          formatKbps(kecepatan),
                          key: ValueKey(kecepatan),
                          style: AppTheme.headline.copyWith(
                            fontFeatures: AppTheme.tabularFigures,
                          ),
                        ),
                ),
                const SizedBox(height: 20),
                StatRow(
                  label: 'Kekuatan sinyal',
                  value: live?.rssiDbm == null
                      ? 'Tidak tersedia'
                      : '${live!.signalText} (${live.rssiDbm} dBm)',
                  valueColor: live?.rssiDbm == null
                      ? AppTheme.textSecondary
                      : null,
                ),
                const SizedBox(height: 12),
                StatRow(
                  label: 'Kecepatan koneksi',
                  value: live?.linkSpeedMbps == null
                      ? 'Tidak tersedia'
                      : '${live!.linkSpeedMbps} Mbps',
                  valueColor: live?.linkSpeedMbps == null
                      ? AppTheme.textSecondary
                      : null,
                ),
                const SizedBox(height: 12),
                StatRow(
                  label: 'Channel',
                  value: live?.channel == null
                      ? 'Tidak tersedia'
                      : '${live!.channel}',
                  valueColor: live?.channel == null
                      ? AppTheme.textSecondary
                      : null,
                ),
                const SizedBox(height: 12),
                StatRow(
                  label: 'Latensi HTTP',
                  value: live?.pingMs == null
                      ? 'Tidak berhasil diukur'
                      : '${live!.pingMs} ms',
                  valueColor: live?.pingMs == null
                      ? AppTheme.textSecondary
                      : null,
                ),
                if (state.liveDiperbarui != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Terakhir diperbarui pukul '
                    '${formatJamDetik(state.liveDiperbarui!)}',
                    style: AppTheme.caption,
                  ),
                ],
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Panel tes bertahan 30 detik: mengunduh file uji 1 MB berulang selama
/// 30 detik dan mencatat kecepatan tiap detik, lalu menilai apakah
/// kecepatan bertahan atau jatuh di tengah jalan.
class _PanelTesBertahan extends StatelessWidget {
  const _PanelTesBertahan();

  StatusTone _toneVerdict(SustainedVerdict verdict) {
    switch (verdict) {
      case SustainedVerdict.bertahan:
        return StatusTone.success;
      case SustainedVerdict.jatuh:
        return StatusTone.danger;
      case SustainedVerdict.tidakStabil:
        return StatusTone.warning;
    }
  }

  Future<void> _tampilkanSemuaSampel(
    BuildContext context,
    List<double> samples,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Semua sampel'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: samples.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: StatRow(
                  label: 'Detik ${index + 1}',
                  value: formatKbps(samples[index]),
                ),
              );
            },
          ),
        ),
        actions: [
          AppTextButton(
            label: 'Tutup',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WifiCubit, WifiState>(
      builder: (context, state) {
        final cubit = context.read<WifiCubit>();
        final berjalan = state.sustainedStatus == SustainedStatus.berjalan;
        final hasil = state.sustainedHasil;
        // Selama tes berjalan, grafik tumbuh dari sampel yang sudah
        // terkumpul; setelah selesai, grafik memakai hasil penuh.
        final sampelGrafik = berjalan
            ? state.sustainedSampelBerjalan
            : (hasil?.samples ?? const <double>[]);
        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Mengunduh file uji 1 MB berulang selama 30 detik dan '
                'mencatat kecepatan tiap detik, untuk melihat apakah '
                'kecepatan bertahan atau jatuh di tengah jalan.',
                style: AppTheme.body,
              ),
              const SizedBox(height: 16),
              if (berjalan) ...[
                LinearProgressIndicator(
                  value: state.sustainedDetik / 30,
                ),
                const SizedBox(height: 8),
                Text(
                  'Detik ${state.sustainedDetik} dari 30'
                  '${state.sustainedSampelTerakhir == null ? '' : ', kecepatan saat ini ${formatKbps(state.sustainedSampelTerakhir!)}'}',
                  style: AppTheme.body.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                PrimaryButton(
                  label: 'Berhenti',
                  icon: Icons.stop,
                  onPressed: () => cubit.batalkanTesBertahan(),
                ),
              ] else
                PrimaryButton(
                  label: 'Tes bertahan 30 detik',
                  icon: Icons.timer,
                  onPressed: () => cubit.mulaiTesBertahan(),
                ),
              if (state.sustainedStatus == SustainedStatus.gagal) ...[
                const SizedBox(height: 16),
                Text(
                  state.sustainedPesan,
                  style: AppTheme.body.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                SecondaryButton(
                  label: 'Coba lagi',
                  onPressed: () => cubit.mulaiTesBertahan(),
                ),
              ],
              if (sampelGrafik.isNotEmpty) ...[
                const SizedBox(height: 20),
                _GrafikSampel(samples: sampelGrafik),
              ],
              if (hasil != null) ...[
                const SizedBox(height: 20),
                StatusChip(
                  label: hasil.verdict.label,
                  icon: hasil.verdict == SustainedVerdict.bertahan
                      ? Icons.check
                      : Icons.warning_amber,
                  tone: _toneVerdict(hasil.verdict),
                  large: true,
                ),
                const SizedBox(height: 8),
                Text(
                  hasil.verdict.penjelasan,
                  style: AppTheme.body.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                StatRow(
                  label: 'Terendah',
                  value: formatKbps(hasil.terendahKbps),
                ),
                const SizedBox(height: 12),
                StatRow(
                  label: 'Rata-rata',
                  value: formatKbps(hasil.rataRataKbps),
                ),
                const SizedBox(height: 12),
                StatRow(
                  label: 'Tertinggi',
                  value: formatKbps(hasil.tertinggiKbps),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: AppTextButton(
                    label: 'Lihat semua sampel',
                    onPressed: () => _tampilkanSemuaSampel(
                      context,
                      hasil.samples,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Grafik batang dari sampel per detik. Tinggi batang sebanding dengan
/// kecepatan (dinormalisasi ke sampel tertinggi); bukan grafik contoh,
/// tiap batang adalah satu detik tes yang nyata.
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
                  child: AnimatedContainer(
                    duration: AppTheme.animationsDisabled(context)
                        ? Duration.zero
                        : AppTheme.tapFeedback,
                    height: maks <= 0
                        ? 2
                        : (nilai / maks * 64).clamp(2.0, 64.0),
                    decoration: BoxDecoration(
                      color: AppTheme.accent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Daftar aksi perbaikan (bukan kartu dengan ListTile): tiap aksi
/// adalah baris tinggi 64 dengan ikon, judul, dan satu baris keterangan.
/// Ketuk membuka bottom sheet penjelasan, kecuali "Sambung ulang WiFi"
/// yang langsung membuka pengaturan sistem.
class _DaftarPerbaikan extends StatelessWidget {
  const _DaftarPerbaikan({required this.hasil});

  final WifiCheckResult hasil;

  Future<void> _bukaPengaturanWifi(BuildContext context) async {
    final berhasil = await DeviceNative.openWifiSettings();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 3),
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
    showAppBottomSheet(
      context: context,
      title: judul,
      body: Text(isi, style: AppTheme.body),
      primaryLabel: 'Buka pengaturan WiFi',
      onPrimary: () {
        Navigator.of(context).pop();
        _bukaPengaturanWifi(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Android membatasi aplikasi pihak ketiga: aplikasi tidak bisa '
          'menyambung ulang WiFi, melupakan jaringan, atau mengganti '
          'DNS secara langsung. Langkah di bawah ini memakai pengaturan '
          'sistem.',
          style: AppTheme.body,
        ),
        const SizedBox(height: 16),
        _BarisPerbaikan(
          icon: Icons.wifi,
          title: 'Sambung ulang WiFi',
          keterangan: 'Matikan lalu nyalakan WiFi dari pengaturan sistem.',
          onTap: () => _bukaPengaturanWifi(context),
        ),
        const SizedBox(height: 8),
        _BarisPerbaikan(
          icon: Icons.dns,
          title: 'Ganti DNS ke 1.1.1.1 / 8.8.8.8',
          keterangan: 'DNS per jaringan hanya bisa diubah di pengaturan '
              'sistem atau router.',
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
        const SizedBox(height: 8),
        _BarisPerbaikan(
          icon: Icons.wifi_off,
          title: 'Lupakan lalu sambung ulang jaringan',
          keterangan: 'Hanya bisa dilakukan dari pengaturan sistem.',
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
        const SizedBox(height: 8),
        _BarisPerbaikan(
          icon: Icons.router,
          title: 'Ganti channel router',
          keterangan: hasil.channelRecommendation,
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
    );
  }
}

class _BarisPerbaikan extends StatelessWidget {
  const _BarisPerbaikan({
    required this.icon,
    required this.title,
    required this.keterangan,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String keterangan;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusButton),
        border: Border.all(color: AppTheme.line),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusButton),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              child: Row(
                children: [
                  Icon(icon, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: AppTheme.body.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          keterangan,
                          style: AppTheme.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Panduan saat WiFi turun ke KB/detik. Teks disalin kata per kata
/// dari docs/panduan-wifi-turun.md (bagian "Teks untuk kartu di
/// aplikasi"), jangan diubah atau diparafrase.
class _Panduan extends StatelessWidget {
  const _Panduan();

  static const _langkah = [
    'Putar video 1080p selama 1 menit sambil memperhatikan angka kecepatan.',
    'Bandingkan dengan HP lain di WiFi yang sama.',
    'Matikan penghemat baterai dan penghemat data, kemudian tes lagi.',
    'Lupakan jaringan, sambung ulang, kemudian mulai ulang router bila masih lambat.',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Angka di bar atas menunjukkan laju data saat itu. Tes '
          'singkat hanya mengukur kecepatan sesaat, sedangkan tes '
          'bertahan 30 detik menunjukkan apakah kecepatan bertahan '
          'atau jatuh di tengah jalan. Bila kecepatan tetap jatuh saat '
          'video sedang diputar, masalahnya nyata dan perlu dicari '
          'penyebabnya.',
          style: AppTheme.body,
        ),
        const SizedBox(height: 20),
        for (var i = 0; i < _langkah.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 48,
                  child: Text(
                    '0${i + 1}',
                    style: AppTheme.headline.copyWith(
                      fontFeatures: AppTheme.tabularFigures,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(_langkah[i], style: AppTheme.body),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
