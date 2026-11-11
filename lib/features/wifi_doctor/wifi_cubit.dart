import 'package:dokter_hp/data/local/app_database.dart';
import 'package:drift/drift.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'wifi_service.dart';

/// Status pemeriksaan WiFi.
enum WifiStatus { awal, berjalan, selesai, gagal }

/// State pemeriksaan WiFi.
class WifiState {
  const WifiState({
    this.status = WifiStatus.awal,
    this.tahap = '',
    this.hasil,
    this.pesan = '',
  });

  final WifiStatus status;
  final String tahap;
  final WifiCheckResult? hasil;
  final String pesan;

  WifiState copyWith({
    WifiStatus? status,
    String? tahap,
    WifiCheckResult? hasil,
    String? pesan,
  }) {
    return WifiState(
      status: status ?? this.status,
      tahap: tahap ?? this.tahap,
      hasil: hasil ?? this.hasil,
      pesan: pesan ?? this.pesan,
    );
  }
}

/// Cubit pemeriksaan WiFi.
class WifiCubit extends Cubit<WifiState> {
  WifiCubit({WifiDoctorService? service, AppDatabase? database})
      : _service = service ?? WifiDoctorService(),
        _database = database,
        super(const WifiState());

  final WifiDoctorService _service;
  final AppDatabase? _database;

  Future<void> jalankanPemeriksaan() async {
    emit(state.copyWith(status: WifiStatus.berjalan, tahap: 'Memulai...'));
    final tersambung = await _service.isWifiConnected();
    if (!tersambung) {
      emit(
        state.copyWith(
          status: WifiStatus.gagal,
          pesan:
              'Perangkat tidak tersambung ke WiFi. Sambungkan ke jaringan '
              'WiFi dulu, lalu coba lagi.',
        ),
      );
      return;
    }
    try {
      final hasil = await _service.runFullCheck(
        onProgress: (tahap) =>
            emit(state.copyWith(status: WifiStatus.berjalan, tahap: tahap)),
      );
      if (hasil.error != null && hasil.downloadKbps == null) {
        emit(
          state.copyWith(
            status: WifiStatus.gagal,
            hasil: hasil,
            pesan: hasil.error!,
          ),
        );
        return;
      }
      emit(state.copyWith(status: WifiStatus.selesai, hasil: hasil));
      await _simpanLaporan(hasil);
    } catch (_) {
      emit(
        state.copyWith(
          status: WifiStatus.gagal,
          pesan: 'Pemeriksaan gagal. Periksa sambungan internet, '
              'lalu coba lagi.',
        ),
      );
    }
  }

  /// Simpan laporan ke database lokal (bila database tersedia).
  /// Kegagalan simpan tidak menggagalkan hasil yang sudah tampil.
  Future<void> _simpanLaporan(WifiCheckResult hasil) async {
    final db = _database;
    if (db == null) return;
    try {
      final sekarang = DateTime.now();
      await db.simpanWifiReport(
        WifiReportsCompanion.insert(
          id: 'wr-${sekarang.microsecondsSinceEpoch}',
          ssid: Value(hasil.ssid),
          downloadKbps: Value(hasil.downloadKbps),
          pingMs: Value(hasil.pingMs),
          rssiDbm: Value(hasil.rssiDbm),
          channel: Value(hasil.channel),
          recommendation: Value(hasil.recommendations.join(' ')),
          createdAt: sekarang,
          updatedAt: sekarang,
        ),
      );
    } catch (_) {
      // Riwayat gagal disimpan, hasil ukur tetap tampil.
    }
  }
}
