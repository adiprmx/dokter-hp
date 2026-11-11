import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dokter_hp/app.dart';
import 'package:dokter_hp/core/app_config.dart';
import 'package:dokter_hp/data/local/app_database.dart';
import 'package:dokter_hp/data/sync/supabase_sync_service.dart';

/// Batas waktu tiap langkah inisialisasi startup.
const _kInitTimeout = Duration(seconds: 20);

bool _supabaseReady = false;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Frame pertama digambar segera; init berat jalan di background.
  runApp(const _BootSplashApp());
  unawaited(_boot());
}

Future<void> _boot() async {
  final database = AppDatabase();
  final error = await _initApp();
  if (error != null) {
    // Supabase bersifat opsional: gagal terhubung BUKAN error fatal.
    // Aplikasi tetap jalan penuh dalam mode lokal.
    debugPrint('[startup] $error (lanjut mode lokal)');
  }
  runApp(DokterHpApp(database: database));
  // Sinkronisasi riwayat di background, tidak menahan tampilan dan
  // tidak pernah menggagalkan startup.
  unawaited(_syncRiwayat(database));
}

/// Sinkronisasi riwayat lokal ke Supabase bila terkonfigurasi.
Future<void> _syncRiwayat(AppDatabase database) async {
  try {
    await SupabaseSyncService(database: database).syncPending();
  } catch (_) {
    // Gagal sinkronisasi = tetap mode lokal, bukan error fatal.
  }
}

/// Inisialisasi startup. Mengembalikan pesan (Bahasa Indonesia) bila
/// Supabase gagal dihubungkan, null bila sukses atau bila aplikasi
/// berjalan mode lokal. Pesan ini HANYA dicatat ke log, kegagalan
/// Supabase tidak pernah memblokir aplikasi.
Future<String?> _initApp() async {
  if (_supabaseReady) return null;
  if (!AppConfig.isSupabaseConfigured) {
    debugPrint(
      '[startup] Mode lokal: SUPABASE_URL / SUPABASE_ANON_KEY belum diisi.',
    );
    return null;
  }
  try {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      publishableKey: AppConfig.supabaseAnonKey,
    ).timeout(_kInitTimeout);
    _supabaseReady = true;
  } on TimeoutException {
    debugPrint('[startup] Supabase.initialize timeout > $_kInitTimeout');
    return 'Sambungan ke server terlalu lama; lanjut mode lokal.';
  } catch (e) {
    debugPrint('[startup] Supabase.initialize gagal: $e');
    return 'Tidak bisa terhubung ke server; lanjut mode lokal.';
  }
  return null;
}

class _BootSplashApp extends StatelessWidget {
  const _BootSplashApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: PopScope(
        canPop: false,
        child: Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: Text(
              'Dokter HP',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
