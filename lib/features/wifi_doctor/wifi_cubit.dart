import 'dart:async';

import 'package:dokter_hp/core/native/device_native.dart';
import 'package:dokter_hp/data/local/app_database.dart';
import 'package:drift/drift.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'wifi_service.dart';

/// Status pemeriksaan WiFi.
enum WifiStatus { awal, berjalan, selesai, gagal }

/// Status tes bertahan 30 detik.
enum SustainedStatus { tidakAda, berjalan, selesai, gagal }

/// State pemeriksaan WiFi.
class WifiState {
  const WifiState({
    this.status = WifiStatus.awal,
    this.tahap = '',
    this.hasil,
    this.pesan = '',
    this.pantauLive = false,
    this.liveHasil,
    this.liveDiperbarui,
    this.sustainedStatus = SustainedStatus.tidakAda,
    this.sustainedDetik = 0,
    this.sustainedSampelTerakhir,
    this.sustainedHasil,
    this.sustainedPesan = '',
  });

  final WifiStatus status;
  final String tahap;
  final WifiCheckResult? hasil;
  final String pesan;

  /// True bila pemantau live aktif.
  final bool pantauLive;

  /// Hasil ukur ringan terakhir dari pemantau live (sinyal, kecepatan
  /// koneksi, channel, latensi, dan kecepatan probe terakhir).
  final WifiCheckResult? liveHasil;

  /// Waktu pembaruan pemantau live terakhir.
  final DateTime? liveDiperbarui;

  final SustainedStatus sustainedStatus;

  /// Detik tes bertahan yang sedang berjalan (1-30).
  final int sustainedDetik;

  /// Sampel kecepatan terakhir selama tes bertahan berjalan.
  final double? sustainedSampelTerakhir;

  final SustainedTestResult? sustainedHasil;

  /// Pesan bila tes bertahan gagal.
  final String sustainedPesan;

  WifiState copyWith({
    WifiStatus? status,
    String? tahap,
    WifiCheckResult? hasil,
    String? pesan,
    bool? pantauLive,
    WifiCheckResult? liveHasil,
    DateTime? liveDiperbarui,
    SustainedStatus? sustainedStatus,
    int? sustainedDetik,
    double? sustainedSampelTerakhir,
    SustainedTestResult? sustainedHasil,
    String? sustainedPesan,
  }) {
    return WifiState(
      status: status ?? this.status,
      tahap: tahap ?? this.tahap,
      hasil: hasil ?? this.hasil,
      pesan: pesan ?? this.pesan,
      pantauLive: pantauLive ?? this.pantauLive,
      liveHasil: liveHasil ?? this.liveHasil,
      liveDiperbarui: liveDiperbarui ?? this.liveDiperbarui,
      sustainedStatus: sustainedStatus ?? this.sustainedStatus,
      sustainedDetik: sustainedDetik ?? this.sustainedDetik,
      sustainedSampelTerakhir:
          sustainedSampelTerakhir ?? this.sustainedSampelTerakhir,
      sustainedHasil: sustainedHasil ?? this.sustainedHasil,
      sustainedPesan: sustainedPesan ?? this.sustainedPesan,
    );
  }
}

/// Cubit pemeriksaan WiFi.
class WifiCubit extends Cubit<WifiState> {
  WifiCubit({
    WifiDoctorService? service,
    AppDatabase? database,
    String? liveProbeUrl,
  })  : _service = service ?? WifiDoctorService(),
        _database = database,
        _liveProbeUrl = liveProbeUrl ?? WifiDoctorService.liveProbeUrl,
        super(const WifiState());

  final WifiDoctorService _service;
  final AppDatabase? _database;

  /// URL probe pemantau live (bisa diganti di test dengan server lokal).
  final String _liveProbeUrl;

  Timer? _timerPemantau;
  bool _probeLiveBerjalan = false;
  bool _infoRinganBerjalan = false;
  bool _tesBertahanDibatalkan = false;

  Future<void> jalankanPemeriksaan() async {
    // Jangan dua pengukuran jalan bersamaan: matikan pemantau live dan
    // hentikan tes bertahan yang mungkin sedang berjalan.
    _hentikanPemantauLive();
    _tesBertahanDibatalkan = true;
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

  /// Nyalakan atau matikan pemantau live.
  ///
  /// Saat aktif, info ringan (sinyal, kecepatan koneksi, channel,
  /// latensi HTTP) diperbarui tiap 2 detik, dan probe unduh 100 KB
  /// dijalankan tiap 10 detik (sekitar 600 KB data per menit). Probe
  /// tidak pernah lebih sering dari tiap 10 detik agar hemat kuota.
  /// Pemantau tidak bisa dinyalakan saat pemeriksaan penuh atau tes
  /// bertahan sedang berjalan.
  void alihkanPantauLive(bool aktif) {
    if (aktif) {
      if (state.status == WifiStatus.berjalan ||
          state.sustainedStatus == SustainedStatus.berjalan) {
        return;
      }
      _mulaiPemantauLive();
    } else {
      _hentikanPemantauLive();
    }
  }

  void _mulaiPemantauLive() {
    _timerPemantau?.cancel();
    emit(state.copyWith(pantauLive: true));
    var tick = 0;
    _timerPemantau = Timer.periodic(const Duration(seconds: 2), (_) async {
      tick++;
      if (isClosed ||
          state.status == WifiStatus.berjalan ||
          state.sustainedStatus == SustainedStatus.berjalan) {
        return;
      }
      await _perbaruiInfoRinganLive();
      // Probe unduh tiap 10 detik (tiap tick ke-5).
      if (tick % 5 == 0) {
        await _probeKecepatanLive();
      }
    });
    // Probe pertama langsung, tanpa menunggu 10 detik.
    unawaited(_probeKecepatanLive());
  }

  void _hentikanPemantauLive() {
    _timerPemantau?.cancel();
    _timerPemantau = null;
    if (state.pantauLive) {
      emit(state.copyWith(pantauLive: false));
    }
  }

  /// Perbarui info ringan pemantau live: sinyal, kecepatan koneksi,
  /// channel, dan latensi HTTP. Tidak mengunduh file.
  Future<void> _perbaruiInfoRinganLive() async {
    if (_infoRinganBerjalan || isClosed) return;
    _infoRinganBerjalan = true;
    try {
      final rssi = await DeviceNative.wifiRssiDbm();
      final link = await DeviceNative.wifiLinkSpeedMbps();
      final frekuensi = await DeviceNative.wifiFrequencyMhz();
      final latensi = await _service.measureLatency();
      if (isClosed) return;
      emit(
        state.copyWith(
          liveHasil: _gabungLive(
            rssiDbm: rssi,
            linkSpeedMbps: link,
            frequencyMhz: frekuensi,
            pingMs: latensi,
          ),
          liveDiperbarui: DateTime.now(),
        ),
      );
    } finally {
      _infoRinganBerjalan = false;
    }
  }

  /// Probe unduh pemantau live: unduh file 100 KB sekali, catat
  /// kecepatannya. Dijaga agar tidak pernah jalan dua kali bersamaan.
  Future<void> _probeKecepatanLive() async {
    if (_probeLiveBerjalan || isClosed) return;
    _probeLiveBerjalan = true;
    try {
      final kbps =
          await _service.measureDownloadSpeed(urls: [_liveProbeUrl]);
      if (isClosed || kbps == null) return;
      emit(
        state.copyWith(
          liveHasil: _gabungLive(downloadKbps: kbps),
          liveDiperbarui: DateTime.now(),
        ),
      );
    } finally {
      _probeLiveBerjalan = false;
    }
  }

  /// Gabung nilai baru ke hasil live terakhir (atau hasil pemeriksaan
  /// penuh bila belum ada hasil live). Nilai yang tidak diberikan
  /// dipertahankan dari hasil sebelumnya.
  WifiCheckResult _gabungLive({
    double? downloadKbps,
    int? pingMs,
    int? rssiDbm,
    int? linkSpeedMbps,
    int? frequencyMhz,
  }) {
    final dasar = state.liveHasil ?? state.hasil;
    return WifiCheckResult(
      ssid: dasar?.ssid,
      ipAddress: dasar?.ipAddress,
      gateway: dasar?.gateway,
      dnsServers: dasar?.dnsServers ?? const [],
      rssiDbm: rssiDbm ?? dasar?.rssiDbm,
      linkSpeedMbps: linkSpeedMbps ?? dasar?.linkSpeedMbps,
      frequencyMhz: frequencyMhz ?? dasar?.frequencyMhz,
      downloadKbps: downloadKbps ?? dasar?.downloadKbps,
      pingMs: pingMs ?? dasar?.pingMs,
      ssidPerluIzinLokasi: dasar?.ssidPerluIzinLokasi ?? false,
    );
  }

  /// Mulai tes bertahan 30 detik. Mematikan pemantau live dulu agar
  /// tidak ada dua pengukuran yang jalan bersamaan.
  Future<void> mulaiTesBertahan() async {
    if (state.sustainedStatus == SustainedStatus.berjalan) return;
    _hentikanPemantauLive();
    _tesBertahanDibatalkan = false;
    emit(
      WifiState(
        status: state.status,
        tahap: state.tahap,
        hasil: state.hasil,
        pesan: state.pesan,
        pantauLive: false,
        liveHasil: state.liveHasil,
        liveDiperbarui: state.liveDiperbarui,
        sustainedStatus: SustainedStatus.berjalan,
        sustainedDetik: 0,
      ),
    );
    final hasil = await _service.measureSustainedSpeed(
      onSample: (detik, kbps) {
        if (isClosed) return;
        emit(
          state.copyWith(
            sustainedDetik: detik,
            sustainedSampelTerakhir: kbps,
          ),
        );
      },
      cekBerhenti: () => _tesBertahanDibatalkan,
    );
    if (isClosed) return;
    if (_tesBertahanDibatalkan) {
      // Dibatalkan pengguna: kembali ke keadaan sebelum tes, tanpa
      // hasil dan tanpa pesan gagal.
      emit(
        WifiState(
          status: state.status,
          tahap: state.tahap,
          hasil: state.hasil,
          pesan: state.pesan,
          pantauLive: false,
          liveHasil: state.liveHasil,
          liveDiperbarui: state.liveDiperbarui,
          sustainedStatus: SustainedStatus.tidakAda,
        ),
      );
      return;
    }
    if (hasil == null) {
      emit(
        state.copyWith(
          sustainedStatus: SustainedStatus.gagal,
          sustainedPesan:
              'Tes bertahan gagal, tidak ada satu pun sampel kecepatan '
              'yang berhasil dicatat. Periksa sambungan internet, lalu '
              'coba lagi.',
        ),
      );
      return;
    }
    emit(
      state.copyWith(
        sustainedStatus: SustainedStatus.selesai,
        sustainedDetik: hasil.samples.length,
        sustainedHasil: hasil,
      ),
    );
  }

  /// Minta tes bertahan berhenti. Tes berhenti di batas detik
  /// berikutnya; sampel yang sudah ada dibuang karena tes tidak selesai.
  void batalkanTesBertahan() {
    _tesBertahanDibatalkan = true;
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

  @override
  Future<void> close() {
    _timerPemantau?.cancel();
    _timerPemantau = null;
    _tesBertahanDibatalkan = true;
    return super.close();
  }
}
