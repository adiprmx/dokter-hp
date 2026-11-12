import 'package:flutter/material.dart';
import 'package:dokter_hp/core/native/device_native.dart';
import 'package:dokter_hp/core/theme.dart';
import 'package:dokter_hp/core/widgets/common_widgets.dart';

/// Layar Dokter Keamanan v1.1.0.
///
/// Membaca daftar aplikasi terpasang dari PackageManager dan menghitung
/// izin berbahaya tiap aplikasi. Aplikasi yang meminta banyak izin
/// berbahaya dan jarang dipakai ditandai untuk ditinjau, keputusan
/// hapus tetap di tangan pengguna lewat pengaturan sistem.
class SecurityPage extends StatefulWidget {
  const SecurityPage({super.key});

  @override
  State<SecurityPage> createState() => _SecurityPageState();
}

class _SecurityPageState extends State<SecurityPage> {
  List<AppInfo>? _aplikasi;
  bool _memuat = true;
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
      final aplikasi = await DeviceNative.installedApps();
      if (!mounted) return;
      aplikasi.sort(
        (a, b) => b.dangerousPermissionCount.compareTo(
          a.dangerousPermissionCount,
        ),
      );
      setState(() {
        _aplikasi = aplikasi;
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

  void _muatUlang() {
    setState(() {
      _memuat = true;
      _error = false;
    });
    _muat();
  }

  @override
  Widget build(BuildContext context) {
    final aplikasi = _aplikasi;
    final mencurigakan = (aplikasi ?? [])
        .where((a) => !a.isSystem && a.dangerousPermissionCount >= 4)
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dokter Keamanan'),
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
              label: 'Memuat daftar aplikasi...',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: SkeletonBlock(height: 28)),
                      SizedBox(width: 20),
                      Expanded(child: SkeletonBlock(height: 28)),
                    ],
                  ),
                  SizedBox(height: 32),
                  SkeletonBlock(height: 48),
                  SizedBox(height: 12),
                  SkeletonBlock(height: 48),
                  SizedBox(height: 12),
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
                    title: 'Daftar aplikasi tidak bisa dibaca',
                    message: 'Perangkat tidak memberikan daftar aplikasi '
                        'saat ini. Coba muat ulang.',
                    onRetry: _muatUlang,
                  ),
                )
              : aplikasi == null || aplikasi.isEmpty
                  ? const SingleChildScrollView(
                      padding: EdgeInsets.all(AppTheme.pagePadding),
                      child: EmptyState(
                        icon: Icons.security,
                        title: 'Daftar aplikasi tidak tersedia',
                        message: 'Perangkat tidak memberikan daftar '
                            'aplikasi saat ini. Coba buka lagi layar ini.',
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
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${aplikasi.length}',
                                    style:
                                        AppTheme.headline.copyWith(
                                      fontFeatures:
                                          AppTheme.tabularFigures,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Aplikasi terpasang',
                                    style: AppTheme.label,
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    height: 32,
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: mencurigakan.isEmpty
                                          ? const StatusChip(
                                              label: 'Tidak ada',
                                              icon: Icons.check,
                                              tone: StatusTone.success,
                                            )
                                          : Text(
                                              '${mencurigakan.length}',
                                              style: AppTheme.headline
                                                  .copyWith(
                                                fontFeatures: AppTheme
                                                    .tabularFigures,
                                              ),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Perlu ditinjau',
                                    style: AppTheme.label,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (mencurigakan.isNotEmpty) ...[
                          const SectionHeader(title: 'Perlu ditinjau'),
                          for (final app in mencurigakan) ...[
                            _BarisAplikasi(app: app, tinjau: true),
                            const SizedBox(height: 12),
                          ],
                        ],
                        const SectionHeader(title: 'Semua aplikasi pengguna'),
                        for (final app
                            in aplikasi.where((a) => !a.isSystem)) ...[
                          _BarisAplikasi(app: app, tinjau: false),
                          const SizedBox(height: 12),
                        ],
                        const SizedBox(height: 8),
                        const StatusStrip(
                          icon: Icons.info_outline,
                          iconColor: AppTheme.info,
                          text: 'Aplikasi yang tidak dikenal dan meminta '
                              'izin lokasi, kamera, mikrofon, atau SMS '
                              'sebaiknya ditinjau. Hapus lewat Pengaturan, '
                              'Aplikasi bila tidak dikenal atau tidak '
                              'dipakai.',
                        ),
                      ],
                    ),
    );
  }
}

/// Baris aplikasi tinggi 72: nama dan paket di kiri, angka izin
/// berbahaya di kanan. Baris kelompok tinjau memakai chip "Tinjau".
class _BarisAplikasi extends StatelessWidget {
  const _BarisAplikasi({required this.app, required this.tinjau});

  final AppInfo app;
  final bool tinjau;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        app.label.isEmpty ? app.packageName : app.label,
                        style: AppTheme.body.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (tinjau) ...[
                      const SizedBox(width: 8),
                      const StatusChip(
                        label: 'Tinjau',
                        icon: Icons.warning_amber,
                        tone: StatusTone.danger,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  app.packageName,
                  style: AppTheme.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${app.dangerousPermissionCount}',
                style: AppTheme.title.copyWith(
                  fontFeatures: AppTheme.tabularFigures,
                ),
              ),
              Text(
                'izin',
                style: AppTheme.caption,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
