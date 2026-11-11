import 'package:dokter_hp/core/app_config.dart';
import 'package:dokter_hp/data/local/app_database.dart';
import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Sinkronisasi riwayat lokal ke Supabase.
///
/// Hanya berjalan bila Supabase terkonfigurasi. Setiap baris yang
/// berhasil diunggah ditandai `synced`; bila gagal (misalnya tabel
/// belum ada di server), baris tetap `pending` dan dicoba lagi lain
/// waktu. Tidak pernah menggagalkan startup dan tidak pernah menghapus
/// data lokal.
///
/// Nama tabel server mengikuti nama tabel lokal: `health_checks` dan
/// `wifi_reports`. Tim backend menyediakan tabel tersebut (folder
/// supabase/ di luar tanggung jawab aplikasi ini).
class SupabaseSyncService {
  SupabaseSyncService({required this.database});

  final AppDatabase database;

  /// Unggah semua baris pending. Mengembalikan jumlah baris yang
  /// berhasil disinkronkan.
  Future<int> syncPending() async {
    if (!AppConfig.isSupabaseConfigured) return 0;
    var berhasil = 0;
    try {
      final client = Supabase.instance.client;
      final checks = await database.healthChecksAktif();
      for (final item in checks) {
        if (item.syncStatus == 'synced') continue;
        try {
          await client.from('health_checks').upsert({
            'id': item.id,
            'score': item.score,
            'category': item.category,
            'summary': item.summary,
            'created_at': item.createdAt.toIso8601String(),
            'updated_at': item.updatedAt.toIso8601String(),
          });
          await _tandaiCheck(item.id);
          berhasil++;
        } catch (_) {
          // Satu baris gagal — lanjut ke baris berikutnya.
        }
      }
      final wifi = await database.wifiReportsAktif();
      for (final item in wifi) {
        if (item.syncStatus == 'synced') continue;
        try {
          await client.from('wifi_reports').upsert({
            'id': item.id,
            'ssid': item.ssid,
            'download_kbps': item.downloadKbps,
            'ping_ms': item.pingMs,
            'rssi_dbm': item.rssiDbm,
            'channel': item.channel,
            'recommendation': item.recommendation,
            'created_at': item.createdAt.toIso8601String(),
            'updated_at': item.updatedAt.toIso8601String(),
          });
          await _tandaiWifi(item.id);
          berhasil++;
        } catch (_) {
          // Satu baris gagal — lanjut ke baris berikutnya.
        }
      }
    } catch (_) {
      // Sinkronisasi gagal total — aplikasi tetap jalan mode lokal.
    }
    return berhasil;
  }

  Future<void> _tandaiCheck(String id) async {
    await (database.update(database.healthChecks)
          ..where((t) => t.id.equals(id)))
        .write(
      HealthChecksCompanion(
        syncStatus: const Value('synced'),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> _tandaiWifi(String id) async {
    await (database.update(database.wifiReports)
          ..where((t) => t.id.equals(id)))
        .write(
      WifiReportsCompanion(
        syncStatus: const Value('synced'),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}
