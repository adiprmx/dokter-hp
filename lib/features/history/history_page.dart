import 'package:flutter/material.dart';
import 'package:dokter_hp/core/health_score.dart';
import 'package:dokter_hp/core/theme.dart';
import 'package:dokter_hp/core/widgets/common_widgets.dart';
import 'package:dokter_hp/data/local/app_database.dart';
import 'package:dokter_hp/features/history/pdf_report_service.dart';
import 'package:dokter_hp/features/wifi_doctor/wifi_doctor_page.dart';

/// Layar Riwayat v1.1.0: satu linimasa kronologis menurun dari database
/// lokal (Drift).
///
/// Laporan PDF dibuat dari data tercatat dan dibagikan lewat sheet
/// sistem (WhatsApp dan aplikasi lain). Hapus memakai soft-delete.
class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key, required this.database});

  final AppDatabase database;

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<HealthCheck>? _riwayat;
  List<WifiReport>? _wifi;
  bool _memuat = true;
  bool _membagikan = false;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _muat();
  }

  AppDatabase get _db => widget.database;

  Future<void> _muat() async {
    // Batas 30 detik: bila pembacaan database macet, layar menampilkan
    // status galat dengan tombol "Coba lagi", bukan spinner selamanya.
    try {
      await _muatDalam().timeout(const Duration(seconds: 30));
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _memuat = false;
        _error = true;
      });
    }
  }

  Future<void> _muatDalam() async {
    try {
      final riwayat = await _db.healthChecksAktif();
      final wifi = await _db.wifiReportsAktif();
      if (!mounted) return;
      setState(() {
        _riwayat = riwayat;
        _wifi = wifi;
        _memuat = false;
        _error = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _memuat = false;
        _error = true;
      });
    }
  }

  Future<void> _bagikan() async {
    setState(() => _membagikan = true);
    try {
      await PdfReportService(database: _db).bagikanLaporan();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          duration: Duration(seconds: 3),
          content: Text('Laporan gagal dibuat. Coba lagi.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _membagikan = false);
    }
  }

  Future<void> _hapus(_Entri entri) async {
    if (entri.kesehatan != null) {
      await _db.hapusHealthCheck(entri.kesehatan!.id);
    } else if (entri.wifi != null) {
      await _db.hapusWifiReport(entri.wifi!.id);
    }
    await _muat();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        duration: Duration(seconds: 3),
        content: Text('Entri dihapus.'),
      ),
    );
  }

  void _muatUlang() {
    setState(() {
      _memuat = true;
      _error = false;
    });
    _muat();
  }

  /// Gabung dua daftar menjadi satu linimasa kronologis menurun.
  List<_Entri> _linimasa(List<HealthCheck> riwayat, List<WifiReport> wifi) {
    final entri = <_Entri>[
      for (final item in riwayat) _Entri.kesehatan(item),
      for (final item in wifi) _Entri.wifi(item),
    ];
    entri.sort((a, b) => b.waktu.compareTo(a.waktu));
    return entri;
  }

  @override
  Widget build(BuildContext context) {
    final riwayat = _riwayat ?? const <HealthCheck>[];
    final wifi = _wifi ?? const <WifiReport>[];
    final kosong = riwayat.isEmpty && wifi.isEmpty;
    final linimasa = _linimasa(riwayat, wifi);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat pemeriksaan'),
        actions: [
          // Tombol bagikan disembunyikan bila riwayat kosong: tidak
          // ada laporan untuk dibagikan.
          if (!kosong && !_memuat && !_error)
            IconButton(
              icon: _membagikan
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.share),
              tooltip: 'Bagikan laporan PDF',
              onPressed: _membagikan ? null : _bagikan,
            ),
        ],
      ),
      body: _memuat
          ? const LoadingSkeleton(
              label: 'Memuat riwayat...',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBlock(height: 48),
                  SizedBox(height: 12),
                  SkeletonBlock(height: 48),
                  SizedBox(height: 12),
                  SkeletonBlock(height: 48),
                ],
              ),
            )
          : _error
              ? SingleChildScrollView(
                  padding: const EdgeInsets.all(AppTheme.pagePadding),
                  child: ErrorState(
                    title: 'Riwayat tidak bisa dibaca',
                    message: 'Data riwayat di perangkat ini tidak bisa '
                        'dibaca saat ini. Coba muat ulang.',
                    onRetry: _muatUlang,
                  ),
                )
              : kosong
                  ? SingleChildScrollView(
                      padding: const EdgeInsets.all(AppTheme.pagePadding),
                      child: EmptyState(
                        icon: Icons.history,
                        title: 'Belum ada riwayat pemeriksaan',
                        message: 'Hasil diagnosis dan pemeriksaan WiFi '
                            'tersimpan di perangkat ini dan tampil di sini.',
                        actions: [
                          PrimaryButton(
                            label: 'Jalankan diagnosis',
                            onPressed: () {
                              // Kembali ke dashboard: tombol diagnosis
                              // ada di sana.
                              Navigator.of(context).pop();
                            },
                          ),
                          SecondaryButton(
                            label: 'Periksa WiFi',
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => WifiDoctorPage(
                                    database: widget.database,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(
                        AppTheme.pagePadding,
                        AppTheme.pagePadding,
                        AppTheme.pagePadding,
                        AppTheme.bottomPadding,
                      ),
                      itemCount: linimasa.length,
                      itemBuilder: (context, index) {
                        final entri = linimasa[index];
                        // Pembatas tanggal di antara kelompok hari.
                        final tampilkanHeader = index == 0 ||
                            !_hariYangSama(
                              linimasa[index - 1].waktu,
                              entri.waktu,
                            );
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (tampilkanHeader)
                              Padding(
                                padding: EdgeInsets.only(
                                  top: index == 0 ? 0 : 24,
                                  bottom: 8,
                                ),
                                child: Text(
                                  formatTanggalHeader(entri.waktu),
                                  style: AppTheme.section,
                                ),
                              ),
                            _BarisEntri(
                              entri: entri,
                              onHapus: () => _hapus(entri),
                            ),
                          ],
                        );
                      },
                    ),
    );
  }

  bool _hariYangSama(DateTime a, DateTime b) {
    final lokalA = a.toLocal();
    final lokalB = b.toLocal();
    return lokalA.year == lokalB.year &&
        lokalA.month == lokalB.month &&
        lokalA.day == lokalB.day;
  }
}

/// Satu entri linimasa: pemeriksaan kesehatan atau pemeriksaan WiFi.
class _Entri {
  const _Entri.kesehatan(this.kesehatan) : wifi = null;
  const _Entri.wifi(this.wifi) : kesehatan = null;

  final HealthCheck? kesehatan;
  final WifiReport? wifi;

  DateTime get waktu =>
      (kesehatan?.createdAt ?? wifi!.createdAt).toLocal();

  String get kunci =>
      kesehatan != null ? 'h-${kesehatan!.id}' : 'w-${wifi!.id}';
}

/// Baris entri tinggi 72 tanpa kartu: ikon jenis di kotak bingkai,
/// judul plus waktu di tengah, angka sekunder di kanan. Geser ke kiri
/// untuk menghapus (latar merah danger).
class _BarisEntri extends StatelessWidget {
  const _BarisEntri({required this.entri, required this.onHapus});

  final _Entri entri;
  final Future<void> Function() onHapus;

  @override
  Widget build(BuildContext context) {
    final kesehatan = entri.kesehatan;
    final wifi = entri.wifi;
    final judul = kesehatan != null
        ? 'Skor ${kesehatan.score} (${labelKategori(kesehatan.category)})'
        : (wifi!.ssid ?? 'WiFi tanpa nama');
    final angkaSekunder = wifi?.downloadKbps == null
        ? null
        : formatKbps(wifi!.downloadKbps!);
    return Dismissible(
      key: ValueKey(entri.kunci),
      direction: DismissDirection.endToStart,
      background: Container(
        color: AppTheme.danger,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: AppTheme.textPrimary),
      ),
      onDismissed: (_) => onHapus(),
      child: SizedBox(
        height: 72,
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius:
                    BorderRadius.circular(AppTheme.radiusChip),
                border: Border.all(color: AppTheme.line),
              ),
              child: Icon(
                kesehatan != null ? Icons.health_and_safety : Icons.wifi,
                size: 20,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    judul,
                    style: AppTheme.body.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatJam(entri.waktu),
                    style: AppTheme.caption,
                  ),
                ],
              ),
            ),
            if (angkaSekunder != null) ...[
              const SizedBox(width: 16),
              Text(
                angkaSekunder,
                style: AppTheme.body.copyWith(
                  fontWeight: FontWeight.w600,
                  fontFeatures: AppTheme.tabularFigures,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
