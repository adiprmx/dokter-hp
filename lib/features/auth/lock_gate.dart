import 'dart:async';

import 'package:flutter/material.dart';
import 'package:dokter_hp/features/auth/pin_service.dart';

/// Gerbang kunci aplikasi.
///
/// Dipasang di root aplikasi ([DokterHpApp]): bila PIN sudah diatur,
/// dashboard TIDAK tampil sebelum pengguna lolos kunci. Bila PIN
/// belum diatur, aplikasi langsung menampilkan dashboard tanpa
/// memaksa pengguna mengatur PIN; penawaran mengatur PIN ada di
/// halaman "Akun dan keamanan".
///
/// Jalur pemulihan bila PIN lupa didokumentasikan di layar kunci
/// (dialog "Lupa PIN?") dan di PRODUCT.md: PIN hanya tersimpan lokal
/// sebagai hash, jadi tidak ada jalan reset lewat server. Satu-satunya
/// pemulihan adalah menghapus data aplikasi lewat Pengaturan Android.
/// Riwayat yang sudah tersinkron ke Supabase tetap aman dan kembali
/// setelah masuk; riwayat lokal yang belum tersinkron akan hilang.
/// Karena itu gerbang ini tidak pernah mengunci akun Supabase pengguna:
/// akun dan data server tetap bisa diakses setelah masuk kembali.
class LockGate extends StatefulWidget {
  const LockGate({super.key, required this.child, PinService? pinService})
      : _pinService = pinService ?? const PinService();

  final Widget child;
  final PinService _pinService;

  @override
  State<LockGate> createState() => _LockGateState();
}

class _LockGateState extends State<LockGate> {
  bool _memuat = true;
  bool _terkunci = false;
  bool _biometrikAktif = false;

  @override
  void initState() {
    super.initState();
    _periksa();
  }

  Future<void> _periksa() async {
    var terkunci = false;
    var biometrikAktif = false;
    try {
      terkunci = await widget._pinService.pinSudahDiatur;
      if (terkunci) {
        biometrikAktif = await widget._pinService.biometrikAktif;
      }
    } catch (e) {
      // Galat teknis tidak boleh mengunci aplikasi: catat dan lanjut
      // tanpa kunci. PinService sendiri sudah fail-open, ini lapis
      // pertahanan kedua.
      debugPrint('[kunci] Tidak bisa memeriksa status PIN: $e');
      terkunci = false;
    }
    if (!mounted) return;
    setState(() {
      _memuat = false;
      _terkunci = terkunci;
      _biometrikAktif = biometrikAktif;
    });
    if (terkunci && biometrikAktif) {
      // Coba biometrik sekali saat aplikasi dibuka. Bila gagal atau
      // dibatalkan, pengguna tetap bisa memakai PIN di layar kunci.
      final berhasil = await widget._pinService.autentikasiBiometrik();
      if (!mounted) return;
      if (berhasil) {
        setState(() => _terkunci = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_memuat) {
      // Splash netral selagi status PIN diperiksa: isi dashboard
      // tidak boleh bocor sebelum kunci lolos.
      return const Scaffold(
        body: Center(child: Text('Dokter HP')),
      );
    }
    if (_terkunci) {
      return LockPage(
        pinService: widget._pinService,
        biometrikAktif: _biometrikAktif,
        onUnlock: () {
          if (!mounted) return;
          setState(() => _terkunci = false);
        },
      );
    }
    return widget.child;
  }
}

/// Layar kunci PIN.
///
/// Memanggil [PinService.periksaPin] dari alur nyata (bukan dari
/// pengaturan saja). Setelah 5 kali percobaan salah berturut-turut,
/// masukan dikunci 30 detik untuk memperlambat tebakan. Tombol
/// "Lupa PIN?" menjelaskan jalan pemulihan tanpa menyembunyikannya.
class LockPage extends StatefulWidget {
  const LockPage({
    super.key,
    required this.pinService,
    required this.biometrikAktif,
    required this.onUnlock,
  });

  final PinService pinService;
  final bool biometrikAktif;
  final VoidCallback onUnlock;

  @override
  State<LockPage> createState() => _LockPageState();
}

class _LockPageState extends State<LockPage> {
  static const _maksimalGagal = 5;
  static const _durasiKunci = Duration(seconds: 30);

  final _pinController = TextEditingController();
  int _gagal = 0;
  String? _pesanGalat;
  bool _memeriksa = false;
  DateTime? _terkunciSampai;
  Timer? _timerHitungMundur;

  bool get _terkunciSementara {
    final sampai = _terkunciSampai;
    return sampai != null && DateTime.now().isBefore(sampai);
  }

  int get _sisaDetikKunci {
    final sampai = _terkunciSampai;
    if (sampai == null) return 0;
    final sisa = sampai.difference(DateTime.now()).inSeconds + 1;
    return sisa > 0 ? sisa : 0;
  }

  @override
  void dispose() {
    _timerHitungMundur?.cancel();
    _pinController.dispose();
    super.dispose();
  }

  void _mulaiHitungMundur() {
    _timerHitungMundur?.cancel();
    _timerHitungMundur = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (!mounted) return;
        if (_terkunciSementara) {
          setState(() {});
        } else {
          _timerHitungMundur?.cancel();
          setState(() {
            _gagal = 0;
            _pesanGalat = null;
          });
        }
      },
    );
  }

  Future<void> _periksa() async {
    if (_memeriksa || _terkunciSementara) return;
    final pin = _pinController.text.trim();
    if (pin.isEmpty) {
      setState(() => _pesanGalat = 'Masukkan PIN terlebih dahulu.');
      return;
    }
    setState(() {
      _memeriksa = true;
      _pesanGalat = null;
    });
    final cocok = await widget.pinService.periksaPin(pin);
    if (!mounted) return;
    if (cocok) {
      widget.onUnlock();
      return;
    }
    final gagal = _gagal + 1;
    setState(() {
      _memeriksa = false;
      _gagal = gagal;
      _pinController.clear();
      if (gagal >= _maksimalGagal) {
        _terkunciSampai = DateTime.now().add(_durasiKunci);
        _pesanGalat = 'Terlalu banyak percobaan salah. '
            'Coba lagi setelah ${_durasiKunci.inSeconds} detik.';
        _mulaiHitungMundur();
      } else {
        _pesanGalat =
            'PIN salah. Percobaan ke $gagal dari $_maksimalGagal.';
      }
    });
  }

  Future<void> _cobaBiometrik() async {
    final berhasil = await widget.pinService.autentikasiBiometrik();
    if (!mounted) return;
    if (berhasil) {
      widget.onUnlock();
    } else {
      setState(
        () => _pesanGalat = 'Biometrik gagal atau dibatalkan. Pakai PIN.',
      );
    }
  }

  Future<void> _tampilkanPemulihan() async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lupa PIN?'),
        content: const Text(
          'PIN hanya tersimpan di HP ini dan tidak ada jalan reset '
          'lewat server. Untuk membuka aplikasi lagi, hapus data '
          'aplikasi lewat Pengaturan Android > Aplikasi > Dokter HP > '
          'Penyimpanan > Hapus data, lalu buka kembali aplikasi dan '
          'atur PIN baru.\n\n'
          'Riwayat yang sudah tersinkron ke server tetap aman dan '
          'kembali setelah Anda masuk. Riwayat lokal yang belum '
          'tersinkron akan hilang. Akun Anda tidak terkunci: setelah '
          'hapus data, Anda tetap bisa masuk dengan akun yang sama.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Tombol kembali tidak boleh melewati layar kunci.
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.lock, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Dokter HP terkunci',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Masukkan PIN untuk membuka aplikasi.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _pinController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 8,
                  enabled: !_terkunciSementara,
                  decoration: InputDecoration(
                    labelText: 'PIN (4-8 digit angka)',
                    counterText: '',
                    errorText: _pesanGalat,
                  ),
                  onSubmitted: (_) => _periksa(),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed:
                      (_memeriksa || _terkunciSementara) ? null : _periksa,
                  child: _memeriksa
                      ? const Text('Memeriksa...')
                      : _terkunciSementara
                          ? Text(
                              'Terkunci. Coba lagi dalam $_sisaDetikKunci detik.',
                            )
                          : const Text('Buka kunci'),
                ),
                if (widget.biometrikAktif) ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _cobaBiometrik,
                    icon: const Icon(Icons.fingerprint),
                    label: const Text('Buka dengan biometrik'),
                  ),
                ],
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _tampilkanPemulihan,
                  child: const Text('Lupa PIN?'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
