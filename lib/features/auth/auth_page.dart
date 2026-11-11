import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dokter_hp/core/app_config.dart';
import 'package:dokter_hp/core/theme.dart';
import 'package:dokter_hp/core/widgets/common_widgets.dart';
import 'package:dokter_hp/features/auth/pin_service.dart';

/// Layar Akun dan Keamanan.
///
/// - Login Google via Supabase: hanya bila Supabase terkonfigurasi.
///   Mode lokal menampilkan kondisi jujur dan menyembunyikan tombol login.
/// - PIN lokal: disimpan sebagai hash SHA-256, tidak pernah plaintext.
/// - Biometrik: lewat autentikasi sistem (local_auth).
class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _pinService = PinService();
  final _pinController = TextEditingController();
  bool _pinSudahDiatur = false;
  bool _biometrikTersedia = false;
  bool _biometrikAktif = false;
  bool _memuat = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _muat();
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _muat() async {
    // Batas 30 detik: bila pembacaan penyimpanan aman macet, layar
    // menampilkan status galat dengan tombol "Coba lagi", bukan
    // spinner selamanya.
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
      final pin = await _pinService.pinSudahDiatur;
      final tersedia = await _pinService.biometrikTersedia;
      final aktif = await _pinService.biometrikAktif;
      if (!mounted) return;
      setState(() {
        _pinSudahDiatur = pin;
        _biometrikTersedia = tersedia;
        _biometrikAktif = aktif;
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

  User? get _pengguna {
    if (!AppConfig.isSupabaseConfigured) return null;
    try {
      return Supabase.instance.client.auth.currentUser;
    } catch (_) {
      return null;
    }
  }

  Future<void> _loginGoogle() async {
    try {
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: AppConfig.googleOAuthRedirect,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lanjutkan masuk lewat browser.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masuk Google gagal. Coba lagi.')),
      );
    }
  }

  Future<void> _keluar() async {
    await Supabase.instance.client.auth.signOut();
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _simpanPin() async {
    final pin = _pinController.text.trim();
    final berhasil = await _pinService.simpanPin(pin);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          berhasil
              ? 'PIN berhasil disimpan.'
              : 'PIN tidak valid. Gunakan 4-8 digit angka.',
        ),
      ),
    );
    if (berhasil) {
      _pinController.clear();
      await _muat();
    }
  }

  Future<void> _ujiBiometrik() async {
    final berhasil = await _pinService.autentikasiBiometrik();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          berhasil
              ? 'Biometrik berhasil dikenali.'
              : 'Biometrik gagal atau dibatalkan.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pengguna = _pengguna;
    return Scaffold(
      appBar: AppBar(title: const Text('Akun dan keamanan')),
      body: _memuat
          ? const LoadingState(label: 'Memuat pengaturan keamanan...')
          : _error
              ? ErrorState(
                  title: 'Pengaturan tidak bisa dibaca',
                  message: 'Pengaturan keamanan di HP ini tidak bisa '
                      'dibaca saat ini. Coba muat ulang.',
                  onRetry: () {
                    setState(() {
                      _memuat = true;
                      _error = false;
                    });
                    _muat();
                  },
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
                          'Akun',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        if (!AppConfig.isSupabaseConfigured)
                          const Text(
                            'Mode lokal, belum tersambung ke server. '
                            'Masuk Google belum tersedia sampai server '
                            'dikonfigurasi.',
                          )
                        else if (pengguna == null) ...[
                          const Text('Belum masuk.'),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: _loginGoogle,
                            icon: const Icon(Icons.login),
                            label: const Text('Masuk dengan Google'),
                          ),
                        ] else ...[
                          Text('Masuk sebagai ${pengguna.email ?? 'pengguna'}'),
                          const SizedBox(height: 12),
                          OutlinedButton(
                            onPressed: _keluar,
                            child: const Text('Keluar'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PIN aplikasi',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _pinSudahDiatur
                              ? 'PIN sudah diatur.'
                              : 'PIN belum diatur.',
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _pinController,
                          keyboardType: TextInputType.number,
                          obscureText: true,
                          maxLength: 8,
                          decoration: const InputDecoration(
                            labelText: 'PIN baru (4-8 digit angka)',
                            counterText: '',
                          ),
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _simpanPin,
                          child: const Text('Simpan PIN'),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'PIN disimpan dalam bentuk yang tidak bisa dibaca '
                          'di HP ini. PIN asli tidak pernah disimpan.',
                          style: TextStyle(color: AppTheme.mutedGrey),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _pinSudahDiatur
                              ? 'PIN yang sudah diatur akan diminta setiap '
                                  'kali aplikasi dibuka. Bila PIN lupa dan '
                                  'biometrik tidak aktif, satu-satunya jalan '
                                  'pemulihan adalah menghapus data aplikasi '
                                  'lewat Pengaturan Android (riwayat yang '
                                  'sudah tersinkron ke server tetap aman).'
                              : 'PIN belum diatur, jadi aplikasi langsung '
                                  'terbuka. Atur PIN di sini bila ingin '
                                  'aplikasi terkunci setiap kali dibuka.',
                          style: const TextStyle(color: AppTheme.mutedGrey),
                        ),
                        if (_pinSudahDiatur)
                          TextButton(
                            onPressed: () async {
                              await _pinService.hapusPin();
                              await _muat();
                            },
                            child: const Text('Hapus PIN'),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Biometrik',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _biometrikTersedia
                              ? 'Perangkat ini mendukung biometrik.'
                              : 'Perangkat ini tidak mendukung biometrik.',
                        ),
                        if (_biometrikTersedia) ...[
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Buka kunci dengan biometrik'),
                            value: _biometrikAktif,
                            onChanged: (nilai) async {
                              await _pinService.aturBiometrik(nilai);
                              await _muat();
                            },
                          ),
                          FilledButton(
                            onPressed: _ujiBiometrik,
                            child: const Text('Uji biometrik sekarang'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
