import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:dokter_hp/core/native/device_native.dart';
import 'package:dokter_hp/core/theme.dart';
import 'package:dokter_hp/core/widgets/common_widgets.dart';

/// Layar Dokter Performa v1.1.0: RAM, CPU, suhu, dan info perangkat.
///
/// RAM dibaca dari ActivityManager. CPU dibaca dari /proc/stat (dua
/// sampel). Suhu dibaca dari sensor thermal bila file sistemnya bisa
/// dibaca; bila tidak, ditampilkan "tidak tersedia" secara jujur.
/// "Tutup aplikasi latar" dijelaskan batasnya: Android tidak
/// mengizinkan aplikasi pihak ketiga menutup aplikasi lain.
class PerformancePage extends StatefulWidget {
  const PerformancePage({super.key});

  @override
  State<PerformancePage> createState() => _PerformancePageState();
}

class _PerformancePageState extends State<PerformancePage> {
  ({int totalBytes, int freeBytes})? _memori;
  double? _cpuPersen;
  double? _suhuCelsius;
  AndroidDeviceInfo? _infoPerangkat;
  bool _memuat = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _muat();
  }

  Future<void> _muat() async {
    // Sengaja tanpa batas waktu: pembacaan memakai I/O file nyata
    // (/proc/stat, sensor thermal) yang di perangkat Android selesai
    // dalam milidetik. Di lingkungan widget test, I/O nyata tidak
    // pernah selesai tanpa runAsync, jadi timer batas apa pun akan
    // tertinggal (pending) saat test selesai atau mengubah hasil
    // golden. Bila I/O ini dibuat bisa diuji (injeksi), tambahkan
    // batas 30 detik seperti layar lain.
    await _muatDalam();
  }

  Future<void> _muatDalam() async {
    try {
      final memori = await DeviceNative.memoryInfo();
      final cpu = await _bacaCpu();
      final suhu = await _bacaSuhu();
      AndroidDeviceInfo? info;
      try {
        info = await DeviceInfoPlugin().androidInfo;
      } catch (_) {
        info = null;
      }
      if (!mounted) return;
      setState(() {
        _memori = memori;
        _cpuPersen = cpu;
        _suhuCelsius = suhu;
        _infoPerangkat = info;
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

  /// Baca /proc/stat dua kali dengan jeda untuk menghitung pemakaian CPU.
  Future<double?> _bacaCpu() async {
    try {
      final pertama = await _bacaStat();
      if (pertama == null) return null;
      await Future<void>.delayed(const Duration(seconds: 1));
      final kedua = await _bacaStat();
      if (kedua == null) return null;
      final totalDelta = kedua.$1 - pertama.$1;
      final idleDelta = kedua.$2 - pertama.$2;
      if (totalDelta <= 0) return null;
      return (1 - idleDelta / totalDelta) * 100;
    } catch (_) {
      return null;
    }
  }

  /// Mengembalikan (total, idle) dari baris "cpu" di /proc/stat.
  Future<(int, int)?> _bacaStat() async {
    final isi = await File('/proc/stat').readAsString();
    for (final baris in isi.split('\n')) {
      if (baris.startsWith('cpu ')) {
        final angka = baris
            .split(RegExp(r'\s+'))
            .skip(1)
            .map(int.tryParse)
            .whereType<int>()
            .toList();
        if (angka.length < 4) return null;
        final total = angka.reduce((a, b) => a + b);
        final idle = angka[3] + (angka.length > 4 ? angka[4] : 0);
        return (total, idle);
      }
    }
    return null;
  }

  /// Baca sensor thermal pertama yang bisa dibaca (milidegree Celsius).
  Future<double?> _bacaSuhu() async {
    try {
      final dir = Directory('/sys/class/thermal');
      if (!await dir.exists()) return null;
      await for (final entitas in dir.list()) {
        if (entitas is Directory &&
            entitas.path.contains('thermal_zone')) {
          try {
            final isi = await File('${entitas.path}/temp').readAsString();
            final nilai = int.tryParse(isi.trim());
            if (nilai != null && nilai > 0 && nilai < 150000) {
              return nilai / 1000;
            }
          } catch (_) {
            continue;
          }
        }
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  String _formatBytes(int bytes) {
    if (bytes >= 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(0)} MB';
  }

  void _muatUlang() {
    setState(() {
      _memuat = true;
      _error = false;
    });
    _muat();
  }

  @override
  Widget build(BuildContext context) {
    final memori = _memori;
    double? persenRamTerpakai;
    if (memori != null && memori.totalBytes > 0) {
      persenRamTerpakai =
          (memori.totalBytes - memori.freeBytes) / memori.totalBytes;
    }
    // Skala suhu 20 sampai 60 derajat untuk posisi penanda meter.
    final fraksiSuhu = _suhuCelsius == null
        ? null
        : ((_suhuCelsius! - 20) / 40).clamp(0.0, 1.0);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dokter Performa'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Muat ulang',
            onPressed: _muatUlang,
          ),
        ],
      ),
      body: _memuat
          ? const LoadingSkeleton(
              label: 'Memuat data performa...',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBlock(width: 80, height: 13),
                  SizedBox(height: 8),
                  SkeletonBlock(width: 100, height: 28),
                  SizedBox(height: 12),
                  SkeletonBlock(height: 6),
                  SizedBox(height: 24),
                  SkeletonBlock(width: 80, height: 13),
                  SizedBox(height: 8),
                  SkeletonBlock(width: 100, height: 28),
                  SizedBox(height: 12),
                  SkeletonBlock(height: 6),
                  SizedBox(height: 24),
                  SkeletonBlock(width: 80, height: 13),
                  SizedBox(height: 8),
                  SkeletonBlock(width: 100, height: 28),
                  SizedBox(height: 12),
                  SkeletonBlock(height: 6),
                ],
              ),
            )
          : _error
              ? SingleChildScrollView(
                  padding: const EdgeInsets.all(AppTheme.pagePadding),
                  child: ErrorState(
                    title: 'Data performa tidak bisa dibaca',
                    message: 'Perangkat tidak memberikan data performa '
                        'saat ini. Coba muat ulang.',
                    onRetry: _muatUlang,
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
                            size: MeterSize.compact,
                            label: 'RAM kosong',
                            fraction: persenRamTerpakai,
                            displayValue: memori == null
                                ? ''
                                : (memori.freeBytes /
                                        (1024 * 1024 * 1024))
                                    .toStringAsFixed(1),
                            displayUnit: 'GB',
                            emptyText: 'Tidak tersedia',
                            animatedNumber: memori == null
                                ? null
                                : memori.freeBytes /
                                    (1024 * 1024 * 1024),
                            formatNumber: (nilai) =>
                                nilai.toStringAsFixed(1),
                            scaleMinLabel: '0',
                            scaleMaxLabel: memori == null
                                ? ''
                                : _formatBytes(memori.totalBytes),
                            semanticsLabel: memori == null
                                ? 'RAM kosong tidak tersedia'
                                : 'RAM kosong '
                                    '${_formatBytes(memori.freeBytes)} '
                                    'dari ${_formatBytes(memori.totalBytes)}',
                          ),
                          const SizedBox(height: 24),
                          MeterGauge(
                            size: MeterSize.compact,
                            label: 'Pemakaian CPU',
                            fraction: _cpuPersen == null
                                ? null
                                : _cpuPersen! / 100,
                            displayValue: _cpuPersen == null
                                ? ''
                                : _cpuPersen!.toStringAsFixed(0),
                            displayUnit: '%',
                            emptyText: 'Tidak tersedia',
                            animatedNumber: _cpuPersen,
                            formatNumber: (nilai) =>
                                nilai.toStringAsFixed(0),
                            semanticsLabel: _cpuPersen == null
                                ? 'Pemakaian CPU tidak tersedia'
                                : 'Pemakaian CPU '
                                    '${_cpuPersen!.toStringAsFixed(0)} persen',
                          ),
                          const SizedBox(height: 24),
                          MeterGauge(
                            size: MeterSize.compact,
                            label: 'Suhu perangkat',
                            fraction: fraksiSuhu,
                            displayValue: _suhuCelsius == null
                                ? ''
                                : _suhuCelsius!.toStringAsFixed(1),
                            displayUnit: '°C',
                            emptyText: 'Tidak tersedia di perangkat ini',
                            animatedNumber: _suhuCelsius,
                            formatNumber: (nilai) =>
                                nilai.toStringAsFixed(1),
                            scaleMinLabel: '20°',
                            scaleMaxLabel: '60°',
                            semanticsLabel: _suhuCelsius == null
                                ? 'Suhu perangkat tidak tersedia '
                                    'di perangkat ini'
                                : 'Suhu perangkat '
                                    '${_suhuCelsius!.toStringAsFixed(1)} '
                                    'derajat Celsius',
                          ),
                        ],
                      ),
                    ),
                    if (_infoPerangkat != null) ...[
                      const SectionHeader(title: 'Perangkat'),
                      StatRow(
                        label: 'Merek / model',
                        value: '${_infoPerangkat!.brand} '
                            '${_infoPerangkat!.model}',
                      ),
                      const SizedBox(height: 12),
                      StatRow(
                        label: 'Android',
                        value: 'Android '
                            '${_infoPerangkat!.version.release} '
                            '(SDK ${_infoPerangkat!.version.sdkInt})',
                      ),
                      const SizedBox(height: 12),
                      StatRow(
                        label: 'Prosesor',
                        value: _infoPerangkat!.hardware,
                      ),
                    ],
                    const SizedBox(height: 20),
                    const StatusStrip(
                      icon: Icons.info_outline,
                      iconColor: AppTheme.info,
                      text: 'Android tidak mengizinkan aplikasi pihak '
                          'ketiga menutup aplikasi lain. Buka layar '
                          'aplikasi terakhir lalu geser aplikasi yang '
                          'tidak dipakai, atau mulai ulang HP bila '
                          'terasa berat.',
                    ),
                  ],
                ),
    );
  }
}
