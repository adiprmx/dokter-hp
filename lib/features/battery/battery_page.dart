import 'dart:async';

import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/material.dart';
import 'package:dokter_hp/core/widgets/common_widgets.dart';

/// Layar Dokter Baterai.
///
/// Menampilkan level, status, dan mode hemat daya dari Battery API.
/// Daftar aplikasi boros hanya ditampilkan bila datanya tersedia dari
/// sistem, Android tidak membuka data pemakaian baterai per aplikasi
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
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _muat();
  }

  Future<void> _muat() async {
    // Batas 30 detik: bila pembacaan baterai macet, layar menampilkan
    // status galat dengan tombol "Coba lagi", bukan spinner selamanya.
    try {
      await _muatDalam().timeout(const Duration(seconds: 30));
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = true);
    }
  }

  Future<void> _muatDalam() async {
    final baterai = Battery();
    try {
      final level = await baterai.batteryLevel;
      // Stream status baterai bisa tidak mengirim event bila tidak ada
      // perubahan, batasi 5 detik agar layar tidak macet.
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
        _error = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = true);
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
  /// Label jelas sebagai perkiraan, bukan janji. Angka "10% per jam"
  /// adalah asumsi kasar pemakaian rata-rata, bukan hasil ukur, jadi
  /// tidak ditampilkan ke pengguna sebagai angka pasti.
  String _estimasiWaktuPakai() {
    if (_level == null || _state == BatteryState.charging) {
      return 'Tidak tersedia saat mengisi daya.';
    }
    // Perkiraan sederhana: pemakaian rata-rata 10% per jam.
    final jam = _level! / 10;
    final jamBulat = jam.floor();
    final menit = ((jam - jamBulat) * 60).round();
    return 'Perkiraan kasar sekitar $jamBulat jam $menit menit, '
        'bukan hasil ukur.';
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
                _error = false;
              });
              _muat();
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_error)
            ErrorState(
              title: 'Data baterai tidak bisa dibaca',
              message: 'Perangkat tidak memberikan data baterai saat ini. '
                  'Coba muat ulang.',
              onRetry: () {
                setState(() {
                  _level = null;
                  _error = false;
                });
                _muat();
              },
            )
          else if (_level == null)
            const LoadingState(label: 'Memuat data baterai...')
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
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Aplikasi boros baterai',
                    style: Theme.of(context).textTheme.titleMedium,
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
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tips merawat baterai',
                    style: Theme.of(context).textTheme.titleMedium,
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
