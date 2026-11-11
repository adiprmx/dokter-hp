import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:dokter_hp/core/native/device_native.dart';
import 'package:dokter_hp/core/widgets/common_widgets.dart';

/// Layar Dokter Performa: RAM, CPU, suhu, dan info perangkat.
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

  @override
  Widget build(BuildContext context) {
    final memori = _memori;
    double? persenRamTerpakai;
    if (memori != null && memori.totalBytes > 0) {
      persenRamTerpakai =
          (memori.totalBytes - memori.freeBytes) / memori.totalBytes;
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dokter Performa'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Muat ulang',
            onPressed: () {
              setState(() => _memuat = true);
              _muat();
            },
          ),
        ],
      ),
      body: _memuat
          ? const LoadingState(label: 'Memuat data performa...')
          : _error
              ? ErrorState(
                  title: 'Data performa tidak bisa dibaca',
                  message: 'Perangkat tidak memberikan data performa saat '
                      'ini. Coba muat ulang.',
                  onRetry: () {
                    setState(() {
                      _memuat = true;
                      _error = false;
                    });
                    _muat();
                  },
                )
              : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Memori (RAM)',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        if (persenRamTerpakai != null)
                          LinearProgressIndicator(
                            value: persenRamTerpakai,
                            backgroundColor: Colors.black12,
                            color: Colors.black,
                          ),
                        const SizedBox(height: 12),
                        InfoRow(
                          label: 'Total RAM',
                          value: memori == null
                              ? 'Tidak tersedia'
                              : _formatBytes(memori.totalBytes),
                        ),
                        InfoRow(
                          label: 'RAM kosong',
                          value: memori == null
                              ? 'Tidak tersedia'
                              : _formatBytes(memori.freeBytes),
                        ),
                        InfoRow(
                          label: 'Pemakaian CPU',
                          value: _cpuPersen == null
                              ? 'Tidak tersedia'
                              : '${_cpuPersen!.toStringAsFixed(0)}%',
                        ),
                        InfoRow(
                          label: 'Suhu perangkat',
                          value: _suhuCelsius == null
                              ? 'Tidak tersedia di perangkat ini'
                              : '${_suhuCelsius!.toStringAsFixed(1)}°C',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (_infoPerangkat != null)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Perangkat',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          InfoRow(
                            label: 'Merek / model',
                            value:
                                '${_infoPerangkat!.brand} ${_infoPerangkat!.model}',
                          ),
                          InfoRow(
                            label: 'Android',
                            value:
                                'Android ${_infoPerangkat!.version.release} '
                                '(SDK ${_infoPerangkat!.version.sdkInt})',
                          ),
                          InfoRow(
                            label: 'Prosesor',
                            value: _infoPerangkat!.hardware,
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Tutup aplikasi latar: Android tidak mengizinkan '
                      'aplikasi pihak ketiga menutup aplikasi lain. '
                      'Untuk mengurangi beban, buka layar aplikasi '
                      'terakhir lalu geser aplikasi yang tidak dipakai, '
                      'atau mulai ulang HP bila terasa berat.',
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
