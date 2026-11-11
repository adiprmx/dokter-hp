import 'package:flutter/material.dart';
import 'package:dokter_hp/core/native/device_native.dart';
import 'package:dokter_hp/core/widgets/common_widgets.dart';

/// Layar Dokter Keamanan.
///
/// Membaca daftar aplikasi terpasang dari PackageManager dan menghitung
/// izin berbahaya tiap aplikasi. Aplikasi yang meminta banyak izin
/// berbahaya dan jarang dipakai ditandai untuk ditinjau — keputusan
/// hapus tetap di tangan pengguna lewat pengaturan sistem.
class SecurityPage extends StatefulWidget {
  const SecurityPage({super.key});

  @override
  State<SecurityPage> createState() => _SecurityPageState();
}

class _SecurityPageState extends State<SecurityPage> {
  List<AppInfo>? _aplikasi;
  bool _memuat = true;

  @override
  void initState() {
    super.initState();
    _muat();
  }

  Future<void> _muat() async {
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
    });
  }

  @override
  Widget build(BuildContext context) {
    final aplikasi = _aplikasi;
    final mencurigakan = (aplikasi ?? [])
        .where((a) => !a.isSystem && a.dangerousPermissionCount >= 4)
        .toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Dokter Keamanan')),
      body: _memuat
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : aplikasi == null || aplikasi.isEmpty
              ? const EmptyState(
                  icon: Icons.security,
                  title: 'Daftar aplikasi tidak tersedia',
                  message: 'Perangkat tidak memberikan daftar aplikasi '
                      'saat ini.',
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
                              'Ringkasan',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            InfoRow(
                              label: 'Aplikasi terpasang',
                              value: '${aplikasi.length}',
                            ),
                            InfoRow(
                              label: 'Perlu ditinjau',
                              value: mencurigakan.isEmpty
                                  ? 'Tidak ada'
                                  : '${mencurigakan.length} aplikasi meminta '
                                      'banyak izin berbahaya',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (mencurigakan.isNotEmpty) ...[
                      Text(
                        'Perlu ditinjau',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      for (final app in mencurigakan)
                        _AplikasiTile(app: app),
                      const SizedBox(height: 16),
                    ],
                    Text(
                      'Semua aplikasi pengguna',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    for (final app in aplikasi.where((a) => !a.isSystem))
                      _AplikasiTile(app: app),
                    const SizedBox(height: 16),
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Aplikasi yang tidak dikenal dan meminta izin '
                          'lokasi, kamera, mikrofon, atau SMS sebaiknya '
                          'ditinjau. Hapus aplikasi lewat Pengaturan > '
                          'Aplikasi bila tidak dikenal atau tidak dipakai.',
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _AplikasiTile extends StatelessWidget {
  const _AplikasiTile({required this.app});

  final AppInfo app;

  @override
  Widget build(BuildContext context) {
    final tanggal = DateTime.fromMillisecondsSinceEpoch(
      app.installTimeMillis,
    );
    return Card(
      child: ListTile(
        leading: const Icon(Icons.apps),
        title: Text(app.label.isEmpty ? app.packageName : app.label),
        subtitle: Text(
          '${app.packageName}\n'
          'Izin berbahaya: ${app.dangerousPermissionCount} • '
          'Dipasang: ${tanggal.day}/${tanggal.month}/${tanggal.year}',
        ),
        isThreeLine: true,
      ),
    );
  }
}
