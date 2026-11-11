import 'dart:convert';

import 'package:dokter_hp/core/app_config.dart';
import 'package:dokter_hp/core/health_score.dart';
import 'package:dokter_hp/data/local/app_database.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Fungsi yang mengunggah satu baris ke satu tabel server.
///
/// Dipisah dari klien Supabase agar [SupabaseSyncService] bisa diuji
/// tanpa proyek Supabase live: test menyuntikkan pengunggah palsu yang
/// mencatat payload atau melempar galat sesuai skenario.
typedef PengunggahBaris = Future<void> Function(
  String tabel,
  Map<String, dynamic> baris,
);

/// Pemetaan kolom lokal (Drift) ke kolom server (Supabase).
///
/// Tabel server didefinisikan di `supabase/migrations/`:
///
/// * `health_checks`: `user_id` (uuid, NOT NULL), `skor` (0-100),
///   `ringkasan` (jsonb), `dibuat_pada`, `updated_at`, `deleted_at`,
///   `sync_status` (`pending` / `synced` / `failed`).
/// * `wifi_reports`: `user_id` (uuid, NOT NULL), `ssid`,
///   `kecepatan_koneksi_mbps` (numeric), `kekuatan_sinyal` (teks),
///   `channel`, `dns`, `ping_ms`, `rekomendasi`, `dibuat_pada`.
///
/// Dua hal yang sengaja TIDAK dikirim:
///
/// * `id` lokal (`hc-<microseconds>` / `wr-<microseconds>`) bukan UUID,
///   sedangkan kolom `id` server bertipe uuid. Mengirimnya membuat
///   Postgres menolak baris. Server membuat `id` sendiri
///   (`gen_random_uuid()`). Konsekuensinya: bila aplikasi tertutup
///   tepat setelah insert berhasil tetapi sebelum status lokal ditandai
///   `synced`, percobaan berikut dapat membuat baris ganda di server.
///   Risiko ini diterima untuk v1 karena data lokal tetap menjadi
///   sumber kebenaran untuk tampilan.
/// * `updated_at` dan `sync_status` tidak dikirim untuk `wifi_reports`
///   karena kolom itu tidak ada di tabel server. Untuk `health_checks`,
///   `updated_at` dibiarkan pada nilai default server (trigger
///   memperbaruinya saat update).
Map<String, dynamic> petakanHealthCheck(HealthCheck item, String userId) {
  return {
    'user_id': userId,
    'skor': item.score,
    'ringkasan': _ringkasanJson(item),
    'dibuat_pada': item.createdAt.toIso8601String(),
    'sync_status': 'synced',
  };
}

/// Ringkasan lokal adalah teks biasa (gabungan penjelasan komponen
/// skor), sedangkan kolom server `ringkasan` bertipe jsonb. Bila teks
/// kebetulan sudah berupa objek JSON, objek itu dipakai apa adanya;
/// bila tidak, teks dibungkus beserta kategorinya.
Map<String, dynamic> _ringkasanJson(HealthCheck item) {
  final teks = item.summary?.trim() ?? '';
  if (teks.isNotEmpty) {
    try {
      final hasil = jsonDecode(teks);
      if (hasil is Map<String, dynamic>) {
        return {
          ...hasil,
          'kategori': hasil['kategori'] ?? item.category,
        };
      }
    } on FormatException {
      // Bukan JSON: lanjut ke pembungkusan teks di bawah.
    }
  }
  return {
    if (teks.isNotEmpty) 'teks': teks,
    'kategori': item.category,
  };
}

Map<String, dynamic> petakanWifiReport(WifiReport item, String userId) {
  return {
    'user_id': userId,
    'ssid': item.ssid,
    // Kolom lokal bernama `downloadKbps` tetapi nilainya sebenarnya
    // KB/detik (lihat `WifiService.measureDownloadSpeed`: byte/detik
    // dibagi 1024). 1 Mbps = 128 KB/detik, jadi kecepatan Mbps adalah
    // nilai lokal dibagi 128.
    'kecepatan_koneksi_mbps':
        item.downloadKbps == null ? null : item.downloadKbps! / 128,
    // Server menyimpan label teks, bukan angka dBm. Tidak ada kolom
    // `rssi_dbm` di server.
    'kekuatan_sinyal':
        item.rssiDbm == null ? null : signalLabel(item.rssiDbm),
    'channel': item.channel,
    'ping_ms': item.pingMs,
    'rekomendasi': item.recommendation,
    'dibuat_pada': item.createdAt.toIso8601String(),
    // `dns` tidak disimpan di database lokal, jadi tidak dikirim
    // (kolom server boleh null).
  };
}

/// Sinkronisasi riwayat lokal ke Supabase.
///
/// Hanya berjalan bila Supabase terkonfigurasi DAN pengguna sudah
/// masuk. Bila pengguna belum masuk, semua baris dibiarkan `pending`
/// dan tidak ada percobaan kirim sama sekali, karena policy RLS
/// (`auth.uid() = user_id`) dan kolom `user_id` NOT NULL pasti
/// menolak insert tanpa pengguna.
///
/// Kegagalan TIDAK PERNAH ditelan diam-diam: setiap kegagalan dicatat
/// dengan `debugPrint` beserta id baris dan pesannya, dan baris yang
/// gagal ditandai `failed` agar terlihat di status sinkronisasi.
/// Baris `failed` tetap dicoba lagi pada sinkronisasi berikutnya
/// (hanya baris `synced` yang dilewati). Data lokal tidak pernah
/// dihapus oleh sinkronisasi.
class SupabaseSyncService {
  SupabaseSyncService({
    required this.database,
    PengunggahBaris? pengunggah,
    String? userIdTetap,
  })  : _pengunggah = pengunggah,
        _userIdTetap = userIdTetap;

  final AppDatabase database;

  /// Pengunggah yang dipakai. Bila null, dipakai klien Supabase asli.
  final PengunggahBaris? _pengunggah;

  /// Id pengguna yang dipakai bila diisi. Hanya untuk test: jalur
  /// produksi selalu membaca id dari sesi Supabase yang sedang aktif.
  final String? _userIdTetap;

  Future<void> _unggahKeSupabase(
    String tabel,
    Map<String, dynamic> baris,
  ) async {
    // `insert`, bukan `upsert`: id server dibuat oleh server sendiri,
    // jadi tidak ada kunci konflik yang bisa dipakai untuk upsert.
    await Supabase.instance.client.from(tabel).insert(baris);
  }

  /// Unggah semua baris pending. Mengembalikan jumlah baris yang
  /// berhasil disinkronkan.
  Future<int> syncPending() async {
    final pengunggah = _pengunggah ?? _unggahKeSupabase;
    if (_pengunggah == null && !AppConfig.isSupabaseConfigured) {
      debugPrint(
        '[sync] Supabase belum dikonfigurasi, sinkronisasi dilewati.',
      );
      return 0;
    }

    final String? userId;
    if (_userIdTetap != null) {
      userId = _userIdTetap;
    } else if (_pengunggah != null) {
      // Jalur test tanpa sesi Supabase: tanpa id tetap, tidak ada
      // pengguna yang bisa dikirim.
      userId = null;
    } else {
      try {
        userId = Supabase.instance.client.auth.currentUser?.id;
      } catch (e) {
        debugPrint('[sync] Tidak bisa membaca sesi pengguna: $e');
        return 0;
      }
    }
    if (userId == null || userId.isEmpty) {
      debugPrint(
        '[sync] Pengguna belum masuk, sinkronisasi ditunda. '
        'Baris tetap berstatus pending dan tidak ada data yang dikirim.',
      );
      return 0;
    }

    var berhasil = 0;
    try {
      final checks = await database.healthChecksAktif();
      for (final item in checks) {
        if (item.syncStatus == 'synced') continue;
        try {
          await pengunggah(
            'health_checks',
            petakanHealthCheck(item, userId),
          );
          await _tandaiCheck(item.id, 'synced');
          berhasil++;
        } catch (e) {
          debugPrint(
            '[sync] health_checks ${item.id} gagal disinkronkan: $e',
          );
          await _tandaiCheck(item.id, 'failed');
        }
      }
      final wifi = await database.wifiReportsAktif();
      for (final item in wifi) {
        if (item.syncStatus == 'synced') continue;
        try {
          await pengunggah(
            'wifi_reports',
            petakanWifiReport(item, userId),
          );
          await _tandaiWifi(item.id, 'synced');
          berhasil++;
        } catch (e) {
          debugPrint(
            '[sync] wifi_reports ${item.id} gagal disinkronkan: $e',
          );
          await _tandaiWifi(item.id, 'failed');
        }
      }
    } catch (e) {
      debugPrint('[sync] Sinkronisasi gagal total: $e');
    }
    return berhasil;
  }

  Future<void> _tandaiCheck(String id, String status) async {
    await (database.update(database.healthChecks)
          ..where((t) => t.id.equals(id)))
        .write(
      HealthChecksCompanion(
        syncStatus: Value(status),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> _tandaiWifi(String id, String status) async {
    await (database.update(database.wifiReports)
          ..where((t) => t.id.equals(id)))
        .write(
      WifiReportsCompanion(
        syncStatus: Value(status),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}
