import 'dart:async';

import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/material.dart';
import 'package:dokter_hp/core/theme.dart';
import 'package:dokter_hp/core/widgets/common_widgets.dart';

/// Layar Dokter Baterai v1.1.0.
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

  /// Label singkat status untuk chip di samping angka.
  String _labelStatus(BatteryState state) {
    switch (state) {
      case BatteryState.full:
        return 'Penuh';
      case BatteryState.charging:
        return 'Mengisi daya';
      case BatteryState.discharging:
        return 'Dipakai';
      case BatteryState.connectedNotCharging:
        return 'Tersambung';
      case BatteryState.unknown:
        return 'Tidak diketahui';
    }
  }

  StatusTone _toneStatus(BatteryState state) {
    switch (state) {
      case BatteryState.full:
        return StatusTone.success;
      case BatteryState.charging:
        return StatusTone.info;
      case BatteryState.discharging:
        return StatusTone.neutral;
      case BatteryState.connectedNotCharging:
        return StatusTone.warning;
      case BatteryState.unknown:
        return StatusTone.neutral;
    }
  }

  IconData _ikonStatus(BatteryState state) {
    switch (state) {
      case BatteryState.full:
        return Icons.check;
      case BatteryState.charging:
        return Icons.battery_charging_full;
      case BatteryState.discharging:
        return Icons.battery_std;
      case BatteryState.connectedNotCharging:
        return Icons.power;
      case BatteryState.unknown:
        return Icons.help_outline;
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
    return 'Perkiraan sekitar $jamBulat jam $menit menit. '
        'Bukan hasil ukur.';
  }

  void _muatUlang() {
    setState(() {
      _level = null;
      _error = false;
    });
    _muat();
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
            onPressed: _muatUlang,
          ),
        ],
      ),
      body: _error
          ? SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.pagePadding),
              child: ErrorState(
                title: 'Data baterai tidak bisa dibaca',
                message: 'Perangkat tidak memberikan data baterai saat '
                    'ini. Coba muat ulang.',
                onRetry: _muatUlang,
              ),
            )
          : _level == null
              ? const LoadingSkeleton(
                  label: 'Memuat data baterai...',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBlock(width: 120, height: 56),
                      SizedBox(height: 12),
                      SkeletonBlock(height: 8),
                      SizedBox(height: 20),
                      SkeletonBlock(height: 15),
                      SizedBox(height: 12),
                      SkeletonBlock(height: 15),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.pagePadding,
                    AppTheme.pagePadding,
                    AppTheme.pagePadding,
                    AppTheme.bottomPadding,
                  ),
                  children: [
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          MeterGauge(
                            fraction: _level! / 100,
                            displayValue: '$_level',
                            displayUnit: '%',
                            animatedNumber: _level!.toDouble(),
                            formatNumber: (nilai) => '${nilai.round()}',
                            chip: _state == null
                                ? null
                                : StatusChip(
                                    label: _labelStatus(_state!),
                                    icon: _ikonStatus(_state!),
                                    tone: _toneStatus(_state!),
                                  ),
                            semanticsLabel: 'Level baterai $_level persen'
                                '${_state == null ? '' : ', ${_labelStatus(_state!)}'}',
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _estimasiWaktuPakai(),
                            style: AppTheme.body.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    StatRow(
                      label: 'Mode hemat daya',
                      value: _hematDaya == null
                          ? 'Tidak tersedia'
                          : (_hematDaya! ? 'Aktif' : 'Tidak aktif'),
                      valueColor: _hematDaya == null
                          ? AppTheme.textSecondary
                          : null,
                    ),
                    const SectionHeader(title: 'Tips merawat baterai'),
                    const _BarisTips(
                      icon: Icons.thermostat,
                      teks: 'Hindari HP panas saat mengisi daya.',
                    ),
                    const SizedBox(height: 12),
                    const _BarisTips(
                      icon: Icons.battery_saver,
                      teks: 'Aktifkan mode hemat daya bila baterai '
                          'di bawah 20%.',
                    ),
                    const SizedBox(height: 12),
                    const _BarisTips(
                      icon: Icons.brightness_6,
                      teks: 'Kurangi kecerahan layar dan matikan '
                          'Bluetooth bila tidak dipakai.',
                    ),
                    const SizedBox(height: 20),
                    const StatusStrip(
                      icon: Icons.info_outline,
                      iconColor: AppTheme.info,
                      text: 'Android tidak membuka data pemakaian '
                          'baterai per aplikasi. Buka Pengaturan, '
                          'Baterai, Penggunaan baterai untuk melihat '
                          'aplikasi yang paling banyak memakai daya.',
                    ),
                  ],
                ),
    );
  }
}

class _BarisTips extends StatelessWidget {
  const _BarisTips({required this.icon, required this.teks});

  final IconData icon;
  final String teks;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppTheme.textSecondary),
        const SizedBox(width: 12),
        Expanded(child: Text(teks, style: AppTheme.body)),
      ],
    );
  }
}
