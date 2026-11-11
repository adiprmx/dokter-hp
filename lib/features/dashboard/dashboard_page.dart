import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dokter_hp/core/app_config.dart';
import 'package:dokter_hp/core/theme.dart';
import 'package:dokter_hp/core/health_score.dart';
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

/// Dashboard utama: skor kesehatan, diagnosis satu ketuk, dan kartu dokter.
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
      appBar: AppBar(
        title: const Text('Dokter HP'),
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
      body: BlocBuilder<DashboardCubit, DashboardState>(
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (!AppConfig.isSupabaseConfigured)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.cloud_off),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Mode lokal, belum tersambung ke server. '
                            'Semua diagnosis memakai data perangkat ini.',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      if (state.skor != null)
                        ScoreRing(
                          score: state.skor!.score,
                          label: state.skor!.category.label,
                        )
                      else
                        const EmptyState(
                          icon: Icons.health_and_safety,
                          title: 'Belum ada data pemeriksaan',
                          message: 'Ketuk "Diagnosis satu ketuk" untuk '
                              'memeriksa kondisi HP ini.',
                        ),
                      const SizedBox(height: 16),
                      if (state.status == DiagnosisStatus.berjalan)
                        const LinearProgressIndicator(
                          backgroundColor: Colors.black12,
                          color: Colors.black,
                        ),
                      if (state.tahap.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(state.tahap),
                        ),
                      if (state.status == DiagnosisStatus.gagal)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: ErrorState(
                            title: 'Diagnosis gagal',
                            message: state.pesan,
                            onRetry: () => context
                                .read<DashboardCubit>()
                                .jalankanDiagnosis(),
                          ),
                        ),
                      const SizedBox(height: 8),
                      FilledButton.icon(
                        onPressed: state.status == DiagnosisStatus.berjalan
                            ? null
                            : () => context
                                .read<DashboardCubit>()
                                .jalankanDiagnosis(),
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Diagnosis satu ketuk'),
                      ),
                      if (state.skor != null) ...[
                        const SizedBox(height: 16),
                        const Divider(),
                        for (final entri in state.skor!.details.entries)
                          InfoRow(label: entri.key, value: entri.value),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              DoctorCard(
                icon: Icons.wifi,
                title: 'Dokter WiFi',
                description:
                    'Ukur kecepatan, latensi, sinyal, dan dapatkan perbaikan.',
                onTap: () => _buka(
                  context,
                  WifiDoctorPage(database: database),
                ),
              ),
              DoctorCard(
                icon: Icons.battery_full,
                title: 'Dokter Baterai',
                description: 'Kesehatan baterai dan estimasi waktu pakai.',
                onTap: () => _buka(context, const BatteryPage()),
              ),
              DoctorCard(
                icon: Icons.storage,
                title: 'Dokter Penyimpanan',
                description: 'Lihat ruang kosong dan bersihkan cache '
                    'dengan aman.',
                onTap: () => _buka(context, const StoragePage()),
              ),
              DoctorCard(
                icon: Icons.speed,
                title: 'Dokter Performa',
                description: 'RAM, CPU, dan suhu perangkat.',
                onTap: () => _buka(context, const PerformancePage()),
              ),
              DoctorCard(
                icon: Icons.security,
                title: 'Dokter Keamanan',
                description: 'Izin aplikasi yang perlu ditinjau.',
                onTap: () => _buka(context, const SecurityPage()),
              ),
              DoctorCard(
                icon: Icons.psychology,
                title: 'Diagnosis AI',
                description:
                    'Jelaskan keluhan HP dan dapatkan saran diagnosis.',
                onTap: () => _buka(context, const AiDiagnosisPage()),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'Dokter HP v${AppConfig.appVersion}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.mutedGrey,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
              if (state.riwayatTerakhir.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Pemeriksaan terakhir',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                for (final item in state.riwayatTerakhir)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.check_circle_outline),
                    title: Text(
                      'Skor ${item.score} '
                      '(${labelKategori(item.category)})',
                    ),
                    subtitle: Text(formatTanggalWaktu(item.createdAt)),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}
