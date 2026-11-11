import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

import 'tables.dart';

part 'app_database.g.dart';

/// Database lokal (Drift + SQLite) untuk riwayat pemeriksaan.
///
/// Seluruh data tersimpan di perangkat. Sinkronisasi ke Supabase hanya
/// terjadi bila Supabase terkonfigurasi; tanpa itu status tetap
/// `local_only` dan aplikasi tetap berfungsi penuh.
@DriftDatabase(tables: [HealthChecks, WifiReports])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  static LazyDatabase _openConnection() {
    return LazyDatabase(() async {
      // sqlite3_flutter_libs wajib diinisialisasi sebelum membuka database
      // di Android (menyediakan library SQLite bawaan).
      await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'dokter_hp.sqlite'));
      return NativeDatabase(file);
    });
  }

  Future<List<HealthCheck>> healthChecksAktif() {
    return (select(healthChecks)
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  Future<List<WifiReport>> wifiReportsAktif() {
    return (select(wifiReports)
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  Future<int> simpanHealthCheck(HealthChecksCompanion data) {
    return into(healthChecks).insert(data);
  }

  Future<int> simpanWifiReport(WifiReportsCompanion data) {
    return into(wifiReports).insert(data);
  }

  Future<bool> hapusHealthCheck(String id) {
    return (update(healthChecks)..where((t) => t.id.equals(id))).write(
      HealthChecksCompanion(deletedAt: Value(DateTime.now())),
    ).then((count) => count > 0);
  }

  Future<bool> hapusWifiReport(String id) {
    return (update(wifiReports)..where((t) => t.id.equals(id))).write(
      WifiReportsCompanion(deletedAt: Value(DateTime.now())),
    ).then((count) => count > 0);
  }
}
