import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dokter_hp/core/app_config.dart';
import 'package:dokter_hp/core/theme.dart';
import 'package:dokter_hp/core/widgets/common_widgets.dart';
import 'package:dokter_hp/features/auth/pin_service.dart';

/// Layar Akun dan Keamanan v1.1.0.
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
        const SnackBar(
          duration: Duration(seconds: 3),
          content: Text('Lanjutkan masuk lewat browser.'),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          duration: Duration(seconds: 3),
          content: Text('Masuk Google gagal. Coba lagi.'),
        ),
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
        duration: const Duration(seconds: 3),
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
        duration: const Duration(seconds: 3),
        content: Text(
          berhasil
              ? 'Biometrik berhasil dikenali.'
              : 'Biometrik gagal atau dibatalkan.',
        ),
      ),
    );
  }

  void _muatUlang() {
    setState(() {
      _memuat = true;
      _error = false;
    });
    _muat();
  }

  @override
  Widget build(BuildContext context) {
    final pengguna = _pengguna;
    return Scaffold(
      appBar: AppBar(title: const Text('Akun dan keamanan')),
      body: _memuat
          ? const LoadingSkeleton(
              label: 'Memuat pengaturan keamanan...',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBlock(width: 100, height: 17),
                  SizedBox(height: 16),
                  SkeletonBlock(height: 15),
                  SizedBox(height: 32),
                  SkeletonBlock(width: 120, height: 17),
                  SizedBox(height: 16),
                  SkeletonBlock(height: 56),
                  SizedBox(height: 32),
                  SkeletonBlock(width: 100, height: 17),
                  SizedBox(height: 16),
                  SkeletonBlock(height: 48),
                ],
              ),
            )
          : _error
              ? SingleChildScrollView(
                  padding: const EdgeInsets.all(AppTheme.pagePadding),
                  child: ErrorState(
                    title: 'Pengaturan tidak bisa dibaca',
                    message: 'Pengaturan keamanan di HP ini tidak bisa '
                        'dibaca saat ini. Coba muat ulang.',
                    onRetry: _muatUlang,
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.pagePadding,
                    AppTheme.pagePadding,
                    AppTheme.pagePadding,
                    AppTheme.bottomPadding,
                  ),
                  children: [
                    const SectionHeader(title: 'Akun', marginTop: 0),
                    if (!AppConfig.isSupabaseConfigured) ...[
                      const StatusChip(
                        label: 'Mode lokal',
                        icon: Icons.cloud_off,
                        tone: StatusTone.info,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Masuk Google belum tersedia sampai server '
                        'dikonfigurasi.',
                        style: AppTheme.body,
                      ),
                    ] else if (pengguna == null) ...[
                      const Text('Belum masuk.', style: AppTheme.body),
                      const SizedBox(height: 12),
                      PrimaryButton(
                        label: 'Masuk dengan Google',
                        leading: const _GoogleLogo(),
                        onPressed: _loginGoogle,
                      ),
                    ] else ...[
                      Text(
                        'Masuk sebagai ${pengguna.email ?? 'pengguna'}',
                        style: AppTheme.body,
                      ),
                      const SizedBox(height: 12),
                      SecondaryButton(
                        label: 'Keluar',
                        onPressed: _keluar,
                      ),
                    ],
                    const SectionHeader(title: 'PIN aplikasi'),
                    Text(
                      _pinSudahDiatur
                          ? 'PIN sudah diatur.'
                          : 'PIN belum diatur.',
                      style: AppTheme.body,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'PIN baru (4-8 digit angka)',
                      style: AppTheme.label,
                    ),
                    const SizedBox(height: 8),
                    _PinDigitField(controller: _pinController),
                    const SizedBox(height: 12),
                    PrimaryButton(
                      label: 'Simpan PIN',
                      onPressed: _simpanPin,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'PIN disimpan dalam bentuk yang tidak bisa dibaca '
                      'di HP ini. PIN asli tidak pernah disimpan.',
                      style: AppTheme.caption,
                    ),
                    const SizedBox(height: 12),
                    StatusStrip(
                      icon: Icons.info_outline,
                      iconColor: AppTheme.info,
                      text: _pinSudahDiatur
                          ? 'PIN yang sudah diatur akan diminta setiap '
                              'kali aplikasi dibuka. Bila PIN lupa dan '
                              'biometrik tidak aktif, satu-satunya jalan '
                              'pemulihan adalah menghapus data aplikasi '
                              'lewat Pengaturan Android (riwayat yang '
                              'sudah tersinkron ke server tetap aman).'
                          : 'PIN belum diatur, jadi aplikasi langsung '
                              'terbuka. Atur PIN di sini bila ingin '
                              'aplikasi terkunci setiap kali dibuka.',
                    ),
                    if (_pinSudahDiatur)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: AppTextButton(
                          label: 'Hapus PIN',
                          destructive: true,
                          onPressed: () async {
                            await _pinService.hapusPin();
                            await _muat();
                          },
                        ),
                      ),
                    const SectionHeader(title: 'Biometrik'),
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
                      const SizedBox(height: 4),
                      SecondaryButton(
                        label: 'Uji biometrik sekarang',
                        onPressed: _ujiBiometrik,
                      ),
                    ] else
                      const StatusStrip(
                        icon: Icons.fingerprint,
                        text: 'Perangkat ini tidak mendukung biometrik.',
                      ),
                    const SizedBox(height: 32),
                    Center(
                      child: Text(
                        'Dokter HP v${AppConfig.appVersion}',
                        style: AppTheme.caption.copyWith(
                          color: AppTheme.textFaint,
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}

/// Kolom PIN tersegmentasi: delapan kotak untuk maksimal 8 digit.
/// Tiap kotak tinggi 56; lebarnya menyesuaikan layar (delapan kotak
/// 48 px tidak muat di layar 390 px dengan padding 20).
///
/// Satu TextField tak terlihat menangkap ketikan dan membuka keyboard
/// angka; kotak-kotak hanya menampilkan titik per digit. Perilaku
/// validasi (4-8 digit angka) tidak berubah.
class _PinDigitField extends StatelessWidget {
  const _PinDigitField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'PIN baru, 4 sampai 8 digit angka',
      textField: true,
      child: SizedBox(
        height: 56,
        child: Stack(
          children: [
            ListenableBuilder(
              listenable: controller,
              builder: (context, _) {
                final pin = controller.text;
                return Row(
                  children: [
                    for (var i = 0; i < 8; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusChip,
                            ),
                            border: Border.all(
                              color: i < pin.length || i == pin.length
                                  ? AppTheme.accent
                                  : AppTheme.lineStrong,
                            ),
                          ),
                          child: i < pin.length
                              ? Center(
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      color: AppTheme.textPrimary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
            Positioned.fill(
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                maxLength: 8,
                showCursor: false,
                enableInteractiveSelection: false,
                autocorrect: false,
                enableSuggestions: false,
                style: const TextStyle(color: Colors.transparent),
                cursorColor: Colors.transparent,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  counterText: '',
                  filled: false,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Logo "G" Google empat warna, digambar dengan CustomPainter
/// (satu-satunya tempat warna brand pihak ketiga muncul).
class _GoogleLogo extends StatelessWidget {
  const _GoogleLogo();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(20, 20),
      painter: _GoogleLogoPainter(),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final tengah = Offset(size.width / 2, size.height / 2);
    final tebal = size.width * 0.2;
    final radius = size.width / 2 - tebal / 2 - 0.5;
    final kotak = Rect.fromCircle(center: tengah, radius: radius);
    final cat = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = tebal
      ..strokeCap = StrokeCap.butt;

    double rad(double derajat) => derajat * math.pi / 180;

    // Biru: sisi kanan, plus batang horizontal ke tengah.
    canvas.drawArc(
      kotak,
      rad(-60),
      rad(120),
      false,
      cat..color = const Color(0xFF4285F4),
    );
    // Hijau: bawah.
    canvas.drawArc(
      kotak,
      rad(60),
      rad(90),
      false,
      cat..color = const Color(0xFF34A853),
    );
    // Kuning: kiri bawah.
    canvas.drawArc(
      kotak,
      rad(150),
      rad(60),
      false,
      cat..color = const Color(0xFFFBBC05),
    );
    // Merah: kiri atas.
    canvas.drawArc(
      kotak,
      rad(210),
      rad(90),
      false,
      cat..color = const Color(0xFFEA4335),
    );
    // Batang biru dari tengah ke kanan.
    canvas.drawRect(
      Rect.fromLTWH(
        tengah.dx,
        tengah.dy - tebal / 2,
        radius + tebal / 2,
        tebal,
      ),
      Paint()..color = const Color(0xFF4285F4),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
