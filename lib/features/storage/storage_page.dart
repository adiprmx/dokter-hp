import 'package:flutter/material.dart';
import 'package:dokter_hp/core/native/device_native.dart';
import 'package:dokter_hp/core/theme.dart';
import 'package:dokter_hp/core/widgets/common_widgets.dart';

/// Layar Dokter Penyimpanan v1.1.0.
///
/// Membaca total dan ruang kosong lewat StatFs Android, serta ukuran
/// cache aplikasi sendiri. Pembersihan hanya menghapus cache aplikasi
/// ini, tidak pernah menyentuh foto, chat, atau file pengguna, dan
/// selalu meminta konfirmasi dulu.
class StoragePage extends StatefulWidget {
  const StoragePage({super.key});

  @override
  State<StoragePage> createState() => _StoragePageState();
}

class _StoragePageState extends State<StoragePage> {
  ({int totalBytes, int freeBytes})? _penyimpanan;
  int? _cacheBytes;
  bool _memuat = true;
  bool _membersihkan = false;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _muat();
  }

  Future<void> _muat() async {
    // Batas 30 detik: bila pembacaan sistem macet, layar menampilkan
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
      final penyimpanan = await DeviceNative.storageInfo();
      final cache = await DeviceNative.cacheSizeBytes();
      if (!mounted) return;
      setState(() {
        _penyimpanan = penyimpanan;
        _cacheBytes = cache;
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

  String _formatBytes(int bytes) {
    if (bytes >= 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    if (bytes >= 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '$bytes B';
  }

  /// Angka GB saja (tanpa satuan) untuk angka besar meter.
  String _formatGbAngka(int bytes) {
    return (bytes / (1024 * 1024 * 1024)).toStringAsFixed(1);
  }

  Future<void> _bersihkanCache() async {
    final setuju = await showAppConfirmDialog(
      context: context,
      title: 'Bersihkan cache?',
      content: 'Hanya file cache aplikasi Dokter HP yang dihapus. '
          'Foto, chat, dan file lain tidak disentuh.',
      confirmLabel: 'Bersihkan',
    );
    if (setuju != true) return;
    setState(() => _membersihkan = true);
    final berhasil = await DeviceNative.clearCache();
    if (!mounted) return;
    setState(() => _membersihkan = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 3),
        content: Text(
          berhasil
              ? 'Cache berhasil dibersihkan.'
              : 'Cache tidak bisa dibersihkan saat ini.',
        ),
      ),
    );
    await _muat();
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
    final penyimpanan = _penyimpanan;
    double? persenTerpakai;
    if (penyimpanan != null && penyimpanan.totalBytes > 0) {
      persenTerpakai =
          (penyimpanan.totalBytes - penyimpanan.freeBytes) /
              penyimpanan.totalBytes;
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Dokter Penyimpanan')),
      body: _memuat
          ? const LoadingSkeleton(
              label: 'Memuat data penyimpanan...',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBlock(width: 160, height: 56),
                  SizedBox(height: 12),
                  SkeletonBlock(height: 8),
                  SizedBox(height: 20),
                  SkeletonBlock(height: 15),
                  SizedBox(height: 12),
                  SkeletonBlock(height: 15),
                  SizedBox(height: 12),
                  SkeletonBlock(height: 15),
                ],
              ),
            )
          : _error
              ? SingleChildScrollView(
                  padding: const EdgeInsets.all(AppTheme.pagePadding),
                  child: ErrorState(
                    title: 'Data penyimpanan tidak bisa dibaca',
                    message: 'Perangkat tidak memberikan info penyimpanan '
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
                    if (penyimpanan == null)
                      const EmptyState(
                        icon: Icons.storage,
                        title: 'Data penyimpanan tidak tersedia',
                        message: 'Perangkat tidak memberikan info '
                            'penyimpanan saat ini. Tombol bersihkan cache '
                            'tetap bisa dipakai.',
                      )
                    else
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            MeterGauge(
                              fraction: persenTerpakai,
                              displayValue:
                                  _formatGbAngka(penyimpanan.freeBytes),
                              displayUnit: 'GB kosong',
                              animatedNumber: penyimpanan.freeBytes /
                                  (1024 * 1024 * 1024),
                              formatNumber: (nilai) =>
                                  nilai.toStringAsFixed(1),
                              scaleMinLabel: '0',
                              scaleMaxLabel:
                                  _formatBytes(penyimpanan.totalBytes),
                              semanticsLabel:
                                  '${_formatBytes(penyimpanan.freeBytes)} '
                                  'kosong dari '
                                  '${_formatBytes(penyimpanan.totalBytes)}',
                            ),
                            const SizedBox(height: 20),
                            StatRow(
                              label: 'Total',
                              value: _formatBytes(penyimpanan.totalBytes),
                            ),
                            const SizedBox(height: 12),
                            StatRow(
                              label: 'Terpakai',
                              value: _formatBytes(
                                penyimpanan.totalBytes -
                                    penyimpanan.freeBytes,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 20),
                    StatRow(
                      label: 'Cache aplikasi ini',
                      value: _cacheBytes == null
                          ? 'Tidak tersedia'
                          : _formatBytes(_cacheBytes!),
                      valueColor: _cacheBytes == null
                          ? AppTheme.textSecondary
                          : null,
                    ),
                    const SizedBox(height: 12),
                    PrimaryButton(
                      label: _membersihkan
                          ? 'Membersihkan...'
                          : 'Bersihkan cache',
                      icon: Icons.cleaning_services,
                      onPressed:
                          _membersihkan ? null : _bersihkanCache,
                    ),
                    const SizedBox(height: 20),
                    const StatusStrip(
                      icon: Icons.info_outline,
                      iconColor: AppTheme.info,
                      text: 'Aplikasi ini tidak menghapus file besar, '
                          'foto, video, atau chat secara otomatis. Hapus '
                          'file dari Galeri atau File secara manual '
                          'setelah memeriksa isinya.',
                    ),
                  ],
                ),
    );
  }
}
