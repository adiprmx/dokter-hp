import 'package:dokter_hp/data/local/app_database.dart';
import 'package:dokter_hp/data/sync/supabase_sync_service.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const userId = '11111111-2222-3333-4444-555555555555';
  final sekarang = DateTime.utc(2026, 11, 11, 10, 0, 0);

  group('petakanHealthCheck', () {
    test('memakai nama kolom server, bukan nama kolom lokal', () {
      final item = HealthCheck(
        id: 'hc-123',
        score: 82,
        category: 'baik',
        summary: 'Baterai 90%. Penyimpanan cukup.',
        createdAt: sekarang,
        updatedAt: sekarang,
        syncStatus: 'pending',
      );
      final hasil = petakanHealthCheck(item, userId);

      expect(hasil['user_id'], userId);
      expect(hasil['skor'], 82);
      expect(hasil['dibuat_pada'], sekarang.toIso8601String());
      expect(hasil['sync_status'], 'synced');
      // Nama kolom lokal tidak boleh muncul di payload server.
      expect(hasil.containsKey('score'), isFalse);
      expect(hasil.containsKey('category'), isFalse);
      expect(hasil.containsKey('summary'), isFalse);
      expect(hasil.containsKey('created_at'), isFalse);
      // Id lokal bukan UUID, jadi tidak dikirim: server membuat id.
      expect(hasil.containsKey('id'), isFalse);
      // Ringkasan teks dibungkus menjadi objek JSON untuk kolom jsonb.
      final ringkasan = hasil['ringkasan'] as Map<String, dynamic>;
      expect(ringkasan['teks'], 'Baterai 90%. Penyimpanan cukup.');
      expect(ringkasan['kategori'], 'baik');
    });

    test('ringkasan kosong tetap menghasilkan objek JSON yang valid', () {
      final item = HealthCheck(
        id: 'hc-124',
        score: 50,
        category: 'cukup',
        createdAt: sekarang,
        updatedAt: sekarang,
        syncStatus: 'pending',
      );
      final hasil = petakanHealthCheck(item, userId);
      final ringkasan = hasil['ringkasan'] as Map<String, dynamic>;
      expect(ringkasan['kategori'], 'cukup');
      expect(ringkasan.containsKey('teks'), isFalse);
    });
  });

  group('petakanWifiReport', () {
    test('memakai nama kolom server dan konversi satuan yang benar', () {
      final item = WifiReport(
        id: 'wr-123',
        ssid: 'WiFi ACHA',
        // Nilai lokal adalah KB/detik: 1280 KB/detik = 10 Mbps.
        downloadKbps: 1280,
        pingMs: 42,
        rssiDbm: -45,
        channel: 6,
        recommendation: 'Sinyal bagus.',
        createdAt: sekarang,
        updatedAt: sekarang,
        syncStatus: 'pending',
      );
      final hasil = petakanWifiReport(item, userId);

      expect(hasil['user_id'], userId);
      expect(hasil['ssid'], 'WiFi ACHA');
      expect(hasil['kecepatan_koneksi_mbps'], 10);
      expect(hasil['kekuatan_sinyal'], 'Sangat bagus');
      expect(hasil['channel'], 6);
      expect(hasil['ping_ms'], 42);
      expect(hasil['rekomendasi'], 'Sinyal bagus.');
      expect(hasil['dibuat_pada'], sekarang.toIso8601String());
      // Nama kolom lokal dan kolom yang tidak ada di server tidak
      // boleh muncul di payload.
      expect(hasil.containsKey('download_kbps'), isFalse);
      expect(hasil.containsKey('rssi_dbm'), isFalse);
      expect(hasil.containsKey('recommendation'), isFalse);
      expect(hasil.containsKey('updated_at'), isFalse);
      expect(hasil.containsKey('id'), isFalse);
    });

    test('nilai null tetap null, bukan angka karangan', () {
      final item = WifiReport(
        id: 'wr-124',
        createdAt: sekarang,
        updatedAt: sekarang,
        syncStatus: 'pending',
      );
      final hasil = petakanWifiReport(item, userId);
      expect(hasil['kecepatan_koneksi_mbps'], isNull);
      expect(hasil['kekuatan_sinyal'], isNull);
      expect(hasil['ssid'], isNull);
    });
  });

  group('SupabaseSyncService.syncPending', () {
    late AppDatabase database;

    setUp(() {
      database = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await database.close();
    });

    test('tanpa pengguna, tidak ada yang dikirim dan baris tetap pending',
        () async {
      await database.simpanHealthCheck(
        HealthChecksCompanion.insert(
          id: 'hc-1',
          score: 80,
          category: 'baik',
          createdAt: sekarang,
          updatedAt: sekarang,
        ),
      );
      var terkirim = 0;
      final layanan = SupabaseSyncService(
        database: database,
        pengunggah: (_, _) async {
          terkirim++;
        },
      );
      expect(await layanan.syncPending(), 0);
      expect(terkirim, 0);
      final baris = await database.healthChecksAktif();
      expect(baris.single.syncStatus, 'pending');
    });

    test('dengan pengguna, payload terkirim dan baris ditandai synced',
        () async {
      await database.simpanHealthCheck(
        HealthChecksCompanion.insert(
          id: 'hc-2',
          score: 80,
          category: 'baik',
          createdAt: sekarang,
          updatedAt: sekarang,
        ),
      );
      await database.simpanWifiReport(
        WifiReportsCompanion.insert(
          id: 'wr-2',
          ssid: const Value('WiFi ACHA'),
          downloadKbps: const Value(1280),
          rssiDbm: const Value(-45),
          channel: const Value(6),
          createdAt: sekarang,
          updatedAt: sekarang,
        ),
      );
      final terkirim = <String, Map<String, dynamic>>{};
      final layanan = SupabaseSyncService(
        database: database,
        userIdTetap: userId,
        pengunggah: (tabel, baris) async {
          terkirim[tabel] = baris;
        },
      );
      expect(await layanan.syncPending(), 2);
      expect(terkirim['health_checks']?['skor'], 80);
      expect(terkirim['health_checks']?['user_id'], userId);
      expect(terkirim['wifi_reports']?['kecepatan_koneksi_mbps'], 10);
      expect(terkirim['wifi_reports']?['user_id'], userId);
      expect(
        (await database.healthChecksAktif()).single.syncStatus,
        'synced',
      );
      expect(
        (await database.wifiReportsAktif()).single.syncStatus,
        'synced',
      );
    });

    test('baris yang gagal ditandai failed, baris lain tetap terkirim',
        () async {
      await database.simpanHealthCheck(
        HealthChecksCompanion.insert(
          id: 'hc-3',
          score: 80,
          category: 'baik',
          createdAt: sekarang,
          updatedAt: sekarang,
        ),
      );
      await database.simpanWifiReport(
        WifiReportsCompanion.insert(
          id: 'wr-3',
          ssid: const Value('WiFi ACHA'),
          createdAt: sekarang,
          updatedAt: sekarang,
        ),
      );
      final layanan = SupabaseSyncService(
        database: database,
        userIdTetap: userId,
        pengunggah: (tabel, _) async {
          if (tabel == 'health_checks') {
            throw Exception('simulasi galat server');
          }
        },
      );
      expect(await layanan.syncPending(), 1);
      expect(
        (await database.healthChecksAktif()).single.syncStatus,
        'failed',
      );
      expect(
        (await database.wifiReportsAktif()).single.syncStatus,
        'synced',
      );
      // Baris failed dicoba lagi pada sinkronisasi berikutnya.
      final layananUlang = SupabaseSyncService(
        database: database,
        userIdTetap: userId,
        pengunggah: (_, _) async {},
      );
      expect(await layananUlang.syncPending(), 1);
    });
  });
}
