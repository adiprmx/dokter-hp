/// Konfigurasi aplikasi.
///
/// Supabase bersifat OPSIONAL. Bila `--dart-define` SUPABASE_URL dan
/// SUPABASE_ANON_KEY tidak diisi, aplikasi berjalan penuh dalam mode lokal:
/// semua diagnosis memakai data perangkat dan database lokal (Drift).
/// Tidak ada data palsu yang ditampilkan sebagai data server.
class AppConfig {
  AppConfig._();

  static const String appName = 'Dokter HP';
  static const String appVersion = '1.1.0';

  /// URL proyek Supabase, diisi lewat `--dart-define=SUPABASE_URL=...`.
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  /// Kunci anon/publishable Supabase, diisi lewat
  /// `--dart-define=SUPABASE_ANON_KEY=...`.
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  /// Benar bila kedua nilai Supabase terisi.
  static bool get isSupabaseConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  /// Nama Edge Function untuk diagnosis AI (tanpa kunci apa pun di APK).
  static const String aiDiagnoseFunction = 'ai-diagnose';

  /// Deep link callback login Google via Supabase Auth.
  static const String googleOAuthRedirect = 'dokterhp://login-callback';
}
