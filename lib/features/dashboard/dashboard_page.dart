import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dokter_hp/core/app_config.dart';
import 'package:dokter_hp/core/health_score.dart';
import 'package:dokter_hp/core/theme.dart';
import 'package:dokter_hp/core/widgets/common_widgets.dart';
import 'package:dokter_hp/data/local/app_database.dart';
import 'package:dokter_hp/features/ai_diagnosis/ai_diagnosis.dart';
import 'package:dokter_hp/features/auth/auth_page.dart';
import 'package:dokter_hp/features/battery/battery_page.dart';
import 'package:dokter_hp/features/dashboard/dashboard_cubit.dart';
import 'package:dokter_hp/features/history/history_page.dart';
import 'package:dokter_hp/features/performance/performance_page.dart';
import 'package:dokter_hp/features/security/security_page.dart';
import 'package:dokter_hp/features/storage/storage_page.dart';
import 'package:dokter_hp/features/wifi_doctor/wifi_doctor_page.dart';

/// Dashboard utama v1.1.0: skor kesehatan dengan meter strip,
/// Dokter WiFi sebagai unggulan, grid lima dokter lain, dan tiga
/// pemeriksaan terakhir.
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key, required this.database});

  final AppDatabase database;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DashboardCubit(database: database)..muatRiwayat(),
      child: _DashboardView(database: database),
    );
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView({required this.database});

  final AppDatabase database;

  void _buka(BuildContext context, Widget halaman) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => halaman),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<DashboardCubit, DashboardState>(
        builder: (context, state) {
          return CustomScrollView(
            slivers: [
              SliverAppBar.large(
                title: const Text('Dokter HP', style: AppTheme.headline),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.history),
                    tooltip: 'Riwayat pemeriksaan',
                    onPressed: () => _buka(
                      context,
                      HistoryPage(database: database),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.person),
                    tooltip: 'Akun dan keamanan',
                    onPressed: () => _buka(context, const AuthPage()),
                  ),
                ],
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.pagePadding,
                ),
                sliver: SliverList.list(
                  children: [
                    if (!AppConfig.isSupabaseConfigured) ...[
                      const StatusStrip(
                        icon: Icons.cloud_off,
                        text: 'Mode lokal. Diagnosis memakai data '
                            'perangkat ini.',
                      ),
                      const SizedBox(height: 20),
                    ],
                    if (!state.riwayatDimuat)
                      const _SkeletonDashboard()
                    else
                      _PanelSkor(
                        state: state,
                        onDiagnosis: () => context
                            .read<DashboardCubit>()
                            .jalankanDiagnosis(),
                      ),
                    const SectionHeader(title: 'Dokter'),
                    _BarisUnggulanWifi(
                      wifiTerakhir: state.wifiTerakhir,
                      onTap: () => _buka(
                        context,
                        WifiDoctorPage(database: database),
                      ),
                    ),
                    const SizedBox(height: AppTheme.cardGap),
                  ],
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.pagePadding,
                ),
                sliver: _GridDokter(
                  onBuka: (halaman) => _buka(context, halaman),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.pagePadding,
                ),
                sliver: SliverList.list(
                  children: [
                    if (state.riwayatTerakhir.isNotEmpty) ...[
                      const SectionHeader(title: 'Pemeriksaan terakhir'),
                      for (final item in state.riwayatTerakhir)
                        _BarisRiwayat(item: item),
                    ],
                    const SizedBox(height: AppTheme.bottomPadding),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Skeleton panel skor dan grid saat riwayat awal dimuat.
class _SkeletonDashboard extends StatelessWidget {
  const _SkeletonDashboard();

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonBlock(width: 120, height: 56),
          const SizedBox(height: 12),
          const SkeletonBlock(height: 8),
          const SizedBox(height: 20),
          const SkeletonBlock(height: 15),
          const SizedBox(height: 12),
          const SkeletonBlock(height: 15),
          const SizedBox(height: 20),
          const SkeletonBlock(height: 56),
          const SizedBox(height: 16),
          Text(
            'Memuat riwayat...',
            style: AppTheme.caption,
          ),
        ],
      ),
    );
  }
}

/// Panel skor: meter besar, rincian per komponen, tombol diagnosis.
class _PanelSkor extends StatelessWidget {
  const _PanelSkor({required this.state, required this.onDiagnosis});

  final DashboardState state;
  final VoidCallback onDiagnosis;

  /// Label tampil untuk kunci rincian diagnosis ('wifi', 'baterai',
  /// dan seterusnya). Isi penjelasannya tidak berubah.
  String _labelKomponen(String kunci) {
    switch (kunci) {
      case 'wifi':
        return 'WiFi';
      case 'baterai':
        return 'Baterai';
      case 'penyimpanan':
        return 'Penyimpanan';
      case 'performa':
        return 'Performa';
      case 'keamanan':
        return 'Keamanan';
      default:
        return kunci;
    }
  }

  StatusTone _toneKategori(HealthCategory kategori) {
    switch (kategori) {
      case HealthCategory.baik:
        return StatusTone.success;
      case HealthCategory.cukup:
        return StatusTone.warning;
      case HealthCategory.buruk:
        return StatusTone.danger;
    }
  }

  Color _warnaKategori(HealthCategory kategori) {
    switch (kategori) {
      case HealthCategory.baik:
        return AppTheme.success;
      case HealthCategory.cukup:
        return AppTheme.warning;
      case HealthCategory.buruk:
        return AppTheme.danger;
    }
  }

  @override
  Widget build(BuildContext context) {
    final skor = state.skor;
    final berjalan = state.status == DiagnosisStatus.berjalan;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (skor != null)
            MeterGauge(
              fraction: skor.score / 100,
              displayValue: '${skor.score}',
              displayUnit: '/ 100',
              animatedNumber: skor.score.toDouble(),
              formatNumber: (nilai) => '${nilai.round()}',
              fillColor: _warnaKategori(skor.category),
              chip: StatusChip(
                label: skor.category.label,
                icon: skor.category == HealthCategory.baik
                    ? Icons.check
                    : Icons.warning_amber,
                tone: _toneKategori(skor.category),
              ),
              semanticsLabel:
                  'Skor kesehatan ${skor.score} dari 100, '
                  '${skor.category.label}',
            )
          else
            const EmptyState(
              icon: Icons.health_and_safety,
              title: 'Belum ada skor kesehatan',
              message: 'Jalankan diagnosis untuk mengukur kondisi HP '
                  'ini. Hasilnya tersimpan di perangkat ini.',
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
          if (state.status == DiagnosisStatus.gagal) ...[
            const SizedBox(height: 20),
            ErrorState(
              title: 'Diagnosis gagal',
              message: state.pesan,
              onRetry: onDiagnosis,
            ),
          ],
          const SizedBox(height: 20),
          PrimaryButton(
            label: berjalan ? 'Mendiagnosis' : 'Diagnosis satu ketuk',
            icon: Icons.play_arrow,
            onPressed: berjalan ? null : onDiagnosis,
          ),
          if (skor != null) ...[
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 16),
            for (final entri in skor.details.entries) ...[
              StatRow(
                label: _labelKomponen(entri.key),
                value: entri.value,
              ),
              const SizedBox(height: 12),
            ],
          ],
        ],
      ),
    );
  }
}

/// Baris unggulan Dokter WiFi: lebar penuh, dengan status terakhir
/// dari riwayat WiFi bila ada.
class _BarisUnggulanWifi extends StatelessWidget {
  const _BarisUnggulanWifi({required this.wifiTerakhir, required this.onTap});

  final WifiReport? wifiTerakhir;
  final VoidCallback onTap;

  String _statusTerakhir() {
    final laporan = wifiTerakhir;
    if (laporan == null) {
      return 'Ukur kecepatan dan latensi WiFi';
    }
    final kecepatan = laporan.downloadKbps;
    if (kecepatan == null) {
      return 'Terakhir: ${formatTanggalWaktu(laporan.createdAt)}';
    }
    return 'Terakhir: ${formatKbps(kecepatan)}, '
        '${formatTanggalWaktu(laporan.createdAt)}';
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          const Icon(Icons.wifi, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Dokter WiFi', style: AppTheme.section),
                const SizedBox(height: 4),
                Text(
                  _statusTerakhir(),
                  style: AppTheme.body.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
        ],
      ),
    );
  }
}

/// Grid dua kolom lima dokter lain (sliver, agar dashboard hanya
/// punya satu Scrollable).
class _GridDokter extends StatelessWidget {
  const _GridDokter({required this.onBuka});

  final void Function(Widget halaman) onBuka;

  @override
  Widget build(BuildContext context) {
    final sel = <_SelDokter>[
      _SelDokter(
        icon: Icons.battery_full,
        title: 'Dokter Baterai',
        keterangan: 'Level, status, dan estimasi waktu pakai',
        halaman: const BatteryPage(),
      ),
      _SelDokter(
        icon: Icons.storage,
        title: 'Dokter Penyimpanan',
        keterangan: 'Ruang kosong dan cache aplikasi ini',
        halaman: const StoragePage(),
      ),
      _SelDokter(
        icon: Icons.speed,
        title: 'Dokter Performa',
        keterangan: 'RAM, CPU, dan suhu perangkat',
        halaman: const PerformancePage(),
      ),
      _SelDokter(
        icon: Icons.security,
        title: 'Dokter Keamanan',
        keterangan: 'Izin aplikasi yang perlu ditinjau',
        halaman: const SecurityPage(),
      ),
      _SelDokter(
        icon: Icons.psychology,
        title: 'Diagnosis AI',
        keterangan: 'Saran diagnosis dari keluhan yang ditulis',
        halaman: const AiDiagnosisPage(),
      ),
    ];
    return SliverGrid(
      // Tinggi sel 184, bukan 168 seperti spesifikasi: isi sel (ikon
      // 28 + jeda 12 + judul 2 baris + jeda 4 + keterangan 2 baris)
      // butuh 133 px, sementara 168 hanya memberi 128 px setelah
      // padding kartu. Judul "Dokter Penyimpanan" dan "Dokter
      // Keamanan" membungkus ke 2 baris di layar 390 px dan selnya
      // meluap 8 px. 184 memberi ruang 144 px.
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppTheme.cardGap,
        mainAxisSpacing: AppTheme.cardGap,
        mainAxisExtent: 184,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final item = sel[index];
          return AppCard(
            onTap: () => onBuka(item.halaman),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(item.icon, size: 28),
                const SizedBox(height: 12),
                Text(
                  item.title,
                  style: AppTheme.section,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  item.keterangan,
                  style: AppTheme.body.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
        childCount: sel.length,
      ),
    );
  }
}

class _SelDokter {
  const _SelDokter({
    required this.icon,
    required this.title,
    required this.keterangan,
    required this.halaman,
  });

  final IconData icon;
  final String title;
  final String keterangan;
  final Widget halaman;
}

/// Baris pemeriksaan terakhir: tanggal di kiri, skor tabular tebal
/// di kanan, tanpa ikon.
class _BarisRiwayat extends StatelessWidget {
  const _BarisRiwayat({required this.item});

  final HealthCheck item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              formatTanggalWaktu(item.createdAt),
              style: AppTheme.label,
            ),
          ),
          Text(
            'Skor ${item.score} (${labelKategori(item.category)})',
            style: AppTheme.body.copyWith(
              fontWeight: FontWeight.w600,
              fontFeatures: AppTheme.tabularFigures,
            ),
          ),
        ],
      ),
    );
  }
}
