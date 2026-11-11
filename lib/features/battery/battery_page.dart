import 'dart:async';

import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/material.dart';
import 'package:dokter_hp/core/widgets/common_widgets.dart';

/// Layar Dokter Baterai.
///
/// Menampilkan level, status, dan mode hemat daya dari Battery API.
/// Daftar aplikasi boros hanya ditampilkan bila datanya tersedia dari
/// sistem — Android tidak membuka data pemakaian baterai per aplikasi
/// untuk aplikasi pihak ketiga, jadi bagian itu jujur menampilkan
/// kondisi "tidak tersedia", bukan daftar contoh.
class BatteryPage extends StatefulWidget {
  const BatteryPage({super.key});

  @override
  State<BatteryPage> createState() => _BatteryPageState();
}

class _BatteryPageState extends State<BatteryPage> {
  int? _level;
  BatteryState? _state;
  bool? _hematDaya;
  String? _error;

  @override
  void initState() {
    super.initState();
    _muat();
  }

  Future<void> _muat() async {
    final baterai = Battery();
    try {
      final level = await baterai.batteryLevel;
      // Stream status baterai bisa tidak mengirim event bila tidak ada
      // perubahan — batasi 5 detik agar layar tidak macet.
      BatteryState? state;
      try {
        state = await baterai.onBatteryStateChanged.first.timeout(
          const Duration(seconds: 5),
        );
      } on TimeoutException {
        state = null;
      }
      final hemat = await baterai.isInBatterySaveMode;
      if (!mounted) return;
      setState(() {
        _level = level;
        _state = state;
        _hematDaya = hemat;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Data baterai tidak bisa dibaca: $e');
    }
  }

  String _labelStatus(BatteryState state) {
    switch (state) {
      case BatteryState.full:
        return 'Penuh';
      case BatteryState.charging:
        return 'Mengisi daya';
      case BatteryState.discharging:
        return 'Dipakai (tidak mengisi daya)';
      case BatteryState.connectedNotCharging:
        return 'Tersambung, tidak mengisi daya';
      case BatteryState.unknown:
        return 'Tidak diketahui';
    }
  }

  /// Estimasi kasar waktu pakai dari level saat ini.
  /// Label jelas sebagai perkiraan, bukan janji.
  String _estimasiWaktuPakai() {
    if (_level == null || _state == BatteryState.charging) {
      return 'Tidak tersedia saat mengisi daya.';
    }
    // Perkiraan sederhana: pemakaian rata-rata 10% per jam.
    final jam = _level! / 10;
    final jamBulat = jam.floor();
    final menit = ((jam - jamBulat) * 60).round();
    return 'Perkiraan sekitar $jamBulat jam $menit menit '
        '(asumsi pemakaian rata-rata 10% per jam — bukan pengukuran pasti).';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dokter Baterai'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Muat ulang',
            onPressed: () {
              setState(() {
                _level = null;
                _error = null;
              });
              _muat();
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_error != null)
            Card(child: Padding(padding: const EdgeInsets.all(16), child: Text(_error!)))
          else if (_level == null)
            const Center(child: CircularProgressIndicator(color: Colors.black))
          else
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      '$_level%',
                      style: Theme.of(context)
                          .textTheme
                          .displayMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: _level! / 100,
                      backgroundColor: Colors.black12,
                      color: Colors.black,
                    ),
                    const SizedBox(height: 16),
                    InfoRow(
                      label: 'Status',
                      value: _state == null
                          ? 'Tidak tersedia'
                          : _labelStatus(_state!),
                    ),
                    InfoRow(
                      label: 'Mode hemat daya',
                      value: _hematDaya == null
                          ? 'Tidak tersedia'
                          : (_hematDaya! ? 'Aktif' : 'Tidak aktif'),
                    ),
                    InfoRow(
                      label: 'Estimasi waktu pakai',
                      value: _estimasiWaktuPakai(),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Aplikasi boros baterai',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Data pemakaian baterai per aplikasi tidak dibuka oleh '
                    'Android untuk aplikasi pihak ketiga, jadi daftar ini '
                    'tidak bisa ditampilkan. Buka Pengaturan > Baterai > '
                    'Penggunaan baterai untuk melihat aplikasi yang paling '
                    'banyak memakai daya.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tips merawat baterai',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• Hindari HP panas saat mengisi daya.\n'
                    '• Aktifkan mode hemat daya bila baterai di bawah 20%.\n'
                    '• Kurangi kecerahan layar dan matikan Bluetooth bila '
                    'tidak dipakai.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
