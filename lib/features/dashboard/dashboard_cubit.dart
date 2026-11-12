import 'package:battery_plus/battery_plus.dart';
import 'package:dokter_hp/core/health_score.dart';
import 'package:dokter_hp/core/native/device_native.dart';
import 'package:dokter_hp/data/local/app_database.dart';
import 'package:drift/drift.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Status diagnosis satu ketuk di dashboard.
enum DiagnosisStatus { awal, berjalan, selesai, gagal }

/// State dashboard.
class DashboardState {
  const DashboardState({
    this.status = DiagnosisStatus.awal,
    this.tahap = '',
    this.skor,
    this.pesan = '',
    this.riwayatTerakhir = const [],
    this.wifiTerakhir,
    this.riwayatDimuat = false,
  });

  final DiagnosisStatus status;
  final String tahap;
  final HealthScoreResult? skor;
  final String pesan;
  final List<HealthCheck> riwayatTerakhir;

  /// Laporan WiFi terakhir, untuk baris status di kartu unggulan
  /// Dokter WiFi di dashboard (spesifikasi 6.1).
  final WifiReport? wifiTerakhir;

  /// True setelah pemuatan riwayat awal selesai (berhasil atau gagal):
  /// dashboard menampilkan skeleton sampai flag ini true.
  final bool riwayatDimuat;

  DashboardState copyWith({
    DiagnosisStatus? status,
    String? tahap,
    HealthScoreResult? skor,
    String? pesan,
    List<HealthCheck>? riwayatTerakhir,
    WifiReport? wifiTerakhir,
    bool? riwayatDimuat,
  }) {
    return DashboardState(
      status: status ?? this.status,
      tahap: tahap ?? this.tahap,
      skor: skor ?? this.skor,
      pesan: pesan ?? this.pesan,
      riwayatTerakhir: riwayatTerakhir ?? this.riwayatTerakhir,
      wifiTerakhir: wifiTerakhir ?? this.wifiTerakhir,
      riwayatDimuat: riwayatDimuat ?? this.riwayatDimuat,
    );
  }
}

/// Cubit dashboard: menjalankan diagnosis satu ketuk dari data nyata.
///
/// Setiap komponen yang datanya tidak tersedia dilewati, skor dihitung
/// dari komponen yang ada, dan layar menampilkan kondisi jujur.
class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit({required AppDatabase database})
      : _database = database,
        super(const DashboardState());

  final AppDatabase _database;

  Future<void> muatRiwayat() async {
    try {
      final riwayat = await _database.healthChecksAktif();
      final wifi = await _database.wifiReportsAktif();
      emit(
        state.copyWith(
          riwayatTerakhir: riwayat.take(3).toList(),
          wifiTerakhir: wifi.isEmpty ? null : wifi.first,
          riwayatDimuat: true,
        ),
      );
    } catch (_) {
      // Riwayat gagal dimuat, dashboard tetap tampil tanpa riwayat.
      emit(state.copyWith(riwayatDimuat: true));
    }
  }

  Future<void> jalankanDiagnosis() async {
    emit(
      state.copyWith(status: DiagnosisStatus.berjalan, tahap: 'Memeriksa...'),
    );
    try {
      int? levelBaterai;
      try {
        levelBaterai = await Battery().batteryLevel;
      } catch (_) {
        levelBaterai = null;
      }

      double? ruangKosongPersen;
      final penyimpanan = await DeviceNative.storageInfo();
      if (penyimpanan != null && penyimpanan.totalBytes > 0) {
        ruangKosongPersen =
            penyimpanan.freeBytes / penyimpanan.totalBytes * 100;
      }

      double? ramKosongPersen;
      final memori = await DeviceNative.memoryInfo();
      if (memori != null && memori.totalBytes > 0) {
        ramKosongPersen = memori.freeBytes / memori.totalBytes * 100;
      }

      final hasil = calculateHealthScore(
        batteryLevel: levelBaterai,
        storageFreePercent: ruangKosongPersen,
        ramFreePercent: ramKosongPersen,
      );

      if (hasil.details.isEmpty) {
        emit(
          state.copyWith(
            status: DiagnosisStatus.gagal,
            pesan: 'Tidak ada data perangkat yang bisa dibaca saat ini.',
          ),
        );
        return;
      }

      final sekarang = DateTime.now();
      final ringkasan = hasil.details.values.join(' ');
      await _database.simpanHealthCheck(
        HealthChecksCompanion.insert(
          id: _uuid(),
          score: hasil.score,
          category: hasil.category.name,
          summary: Value(ringkasan),
          createdAt: sekarang,
          updatedAt: sekarang,
        ),
      );
      await muatRiwayat();
      emit(
        state.copyWith(
          status: DiagnosisStatus.selesai,
          skor: hasil,
          tahap: '',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: DiagnosisStatus.gagal,
          pesan: 'Diagnosis gagal. Coba lagi.',
        ),
      );
    }
  }

  String _uuid() {
    final sekarang = DateTime.now().microsecondsSinceEpoch;
    return 'hc-$sekarang';
  }
}
