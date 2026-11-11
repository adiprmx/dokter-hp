import 'package:flutter/material.dart';
import 'package:dokter_hp/core/widgets/common_widgets.dart';
import 'package:dokter_hp/data/local/app_database.dart';
import 'package:dokter_hp/features/history/pdf_report_service.dart';

/// Layar Riwayat: daftar pemeriksaan dari database lokal (Drift).
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

  @override
  void initState() {
    super.initState();
    _muat();
  }

  AppDatabase get _db => widget.database;

  Future<void> _muat() async {
    final riwayat = await _db.healthChecksAktif();
    final wifi = await _db.wifiReportsAktif();
    if (!mounted) return;
    setState(() {
      _riwayat = riwayat;
      _wifi = wifi;
      _memuat = false;
    });
  }

  Future<void> _bagikan() async {
    setState(() => _membagikan = true);
    try {
      await PdfReportService(database: _db).bagikanLaporan();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Laporan gagal dibuat: $e')),
      );
    } finally {
      if (mounted) setState(() => _membagikan = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final riwayat = _riwayat ?? const [];
    final wifi = _wifi ?? const [];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat pemeriksaan'),
        actions: [
          IconButton(
            icon: _membagikan
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.black,
                    ),
                  )
                : const Icon(Icons.share),
            tooltip: 'Bagikan laporan PDF',
            onPressed: _membagikan ? null : _bagikan,
          ),
        ],
      ),
      body: _memuat
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : riwayat.isEmpty && wifi.isEmpty
              ? const EmptyState(
                  icon: Icons.history,
                  title: 'Belum ada data pemeriksaan',
                  message: 'Jalankan diagnosis dari dashboard atau '
                      'pemeriksaan WiFi. Hasilnya tersimpan di perangkat ini.',
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      'Pemeriksaan kesehatan',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    for (final item in riwayat)
                      Dismissible(
                        key: ValueKey(item.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Colors.black12,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 16),
                          child: const Icon(Icons.delete),
                        ),
                        onDismissed: (_) async {
                          await _db.hapusHealthCheck(item.id);
                          await _muat();
                        },
                        child: Card(
                          child: ListTile(
                            leading: const Icon(Icons.health_and_safety),
                            title: Text(
                              'Skor ${item.score} — ${item.category}',
                            ),
                            subtitle: Text(
                              item.createdAt.toLocal().toString(),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    Text(
                      'Pemeriksaan WiFi',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    for (final item in wifi)
                      Dismissible(
                        key: ValueKey(item.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Colors.black12,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 16),
                          child: const Icon(Icons.delete),
                        ),
                        onDismissed: (_) async {
                          await _db.hapusWifiReport(item.id);
                          await _muat();
                        },
                        child: Card(
                          child: ListTile(
                            leading: const Icon(Icons.wifi),
                            title: Text(
                              item.ssid ?? 'WiFi tanpa nama',
                            ),
                            subtitle: Text(
                              'Unduh: ${item.downloadKbps == null ? 'tidak terukur' : '${item.downloadKbps!.toStringAsFixed(1)} KB/detik'}'
                              ' • ${item.createdAt.toLocal()}',
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
    );
  }
}
