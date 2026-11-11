import 'package:flutter/material.dart';
import 'package:dokter_hp/core/native/device_native.dart';
import 'package:dokter_hp/core/widgets/common_widgets.dart';

/// Layar Dokter Penyimpanan.
///
/// Membaca total dan ruang kosong lewat StatFs Android, serta ukuran
/// cache aplikasi sendiri. Pembersihan hanya menghapus cache aplikasi
/// ini — tidak pernah menyentuh foto, chat, atau file pengguna — dan
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

  @override
  void initState() {
    super.initState();
    _muat();
  }

  Future<void> _muat() async {
    final penyimpanan = await DeviceNative.storageInfo();
    final cache = await DeviceNative.cacheSizeBytes();
    if (!mounted) return;
    setState(() {
      _penyimpanan = penyimpanan;
      _cacheBytes = cache;
      _memuat = false;
    });
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

  Future<void> _bersihkanCache() async {
    final setuju = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bersihkan cache?'),
        content: const Text(
          'Hanya file cache aplikasi Dokter HP yang dihapus. '
          'Foto, chat, dan file lain tidak disentuh.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Bersihkan'),
          ),
        ],
      ),
    );
    if (setuju != true) return;
    setState(() => _membersihkan = true);
    final berhasil = await DeviceNative.clearCache();
    if (!mounted) return;
    setState(() => _membersihkan = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          berhasil
              ? 'Cache berhasil dibersihkan.'
              : 'Cache tidak bisa dibersihkan saat ini.',
        ),
      ),
    );
    await _muat();
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
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (penyimpanan == null)
                  const EmptyState(
                    icon: Icons.storage,
                    title: 'Data penyimpanan tidak tersedia',
                    message: 'Perangkat tidak memberikan info penyimpanan '
                        'saat ini.',
                  )
                else
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Penyimpanan internal',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          if (persenTerpakai != null)
                            LinearProgressIndicator(
                              value: persenTerpakai,
                              backgroundColor: Colors.black12,
                              color: Colors.black,
                            ),
                          const SizedBox(height: 12),
                          InfoRow(
                            label: 'Total',
                            value: _formatBytes(penyimpanan.totalBytes),
                          ),
                          InfoRow(
                            label: 'Terpakai',
                            value: _formatBytes(
                              penyimpanan.totalBytes - penyimpanan.freeBytes,
                            ),
                          ),
                          InfoRow(
                            label: 'Kosong',
                            value: _formatBytes(penyimpanan.freeBytes),
                          ),
                          InfoRow(
                            label: 'Cache aplikasi ini',
                            value: _cacheBytes == null
                                ? 'Tidak tersedia'
                                : _formatBytes(_cacheBytes!),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _membersihkan ? null : _bersihkanCache,
                  icon: const Icon(Icons.cleaning_services),
                  label: Text(
                    _membersihkan ? 'Membersihkan...' : 'Bersihkan cache',
                  ),
                ),
                const SizedBox(height: 16),
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Catatan: aplikasi ini tidak menghapus file besar, '
                      'foto, video, atau chat secara otomatis. Bila ruang '
                      'hampir penuh, hapus file dari aplikasi Galeri atau '
                      'File secara manual setelah memeriksa isinya.',
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
