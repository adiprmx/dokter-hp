import 'package:drift/drift.dart';

/// Tabel riwayat pemeriksaan kesehatan HP.
class HealthChecks extends Table {
  TextColumn get id => text()();
  IntColumn get score => integer()();
  TextColumn get category => text()();
  TextColumn get summary => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  /// Soft-delete: baris tidak pernah dihapus permanen dari perangkat.
  DateTimeColumn get deletedAt => dateTime().nullable()();

  DateTimeColumn get updatedAt => dateTime()();

  /// Status sinkronisasi ke server: pending, synced, local_only.
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Tabel laporan pemeriksaan WiFi.
class WifiReports extends Table {
  TextColumn get id => text()();
  TextColumn get ssid => text().nullable()();
  RealColumn get downloadKbps => real().nullable()();
  IntColumn get pingMs => integer().nullable()();
  IntColumn get rssiDbm => integer().nullable()();
  IntColumn get channel => integer().nullable()();
  TextColumn get recommendation => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();

  @override
  Set<Column> get primaryKey => {id};
}
