import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

/// Layanan kunci aplikasi: PIN lokal dan biometrik.
///
/// PIN TIDAK PERNAH disimpan plaintext — yang disimpan hanya hash
/// SHA-256 dengan salt tetap per perangkat. Biometrik memakai
/// LocalAuthentication sistem dan tidak menyimpan data biometrik apa pun.
class PinService {
  PinService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _kunciHashPin = 'dokter_hp_pin_hash';
  static const _kunciSalt = 'dokter_hp_pin_salt';
  static const _kunciBiometrik = 'dokter_hp_biometrik_aktif';

  /// Buat salt acak sederhana dari waktu saat ini.
  String _buatSalt() {
    final sekarang = DateTime.now().microsecondsSinceEpoch;
    return sha256.convert(utf8.encode('dokter-hp-salt-$sekarang')).toString();
  }

  String _hashPin(String pin, String salt) {
    return sha256.convert(utf8.encode('$salt::$pin')).toString();
  }

  /// Simpan PIN baru sebagai hash. PIN minimal 4 digit angka.
  Future<bool> simpanPin(String pin) async {
    if (!_pinValid(pin)) return false;
    final salt = _buatSalt();
    await _storage.write(key: _kunciSalt, value: salt);
    await _storage.write(
      key: _kunciHashPin,
      value: _hashPin(pin, salt),
    );
    return true;
  }

  /// Periksa PIN yang dimasukkan.
  Future<bool> periksaPin(String pin) async {
    final hashTersimpan = await _storage.read(key: _kunciHashPin);
    final salt = await _storage.read(key: _kunciSalt);
    if (hashTersimpan == null || salt == null) return false;
    return _hashPin(pin, salt) == hashTersimpan;
  }

  /// Apakah PIN sudah diatur.
  Future<bool> get pinSudahDiatur async {
    final hash = await _storage.read(key: _kunciHashPin);
    return hash != null && hash.isNotEmpty;
  }

  /// Hapus PIN (dan matikan biometrik).
  Future<void> hapusPin() async {
    await _storage.delete(key: _kunciHashPin);
    await _storage.delete(key: _kunciSalt);
    await _storage.write(key: _kunciBiometrik, value: 'false');
  }

  bool _pinValid(String pin) {
    if (pin.length < 4 || pin.length > 8) return false;
    return RegExp(r'^[0-9]+$').hasMatch(pin);
  }

  /// Apakah perangkat mendukung biometrik.
  Future<bool> get biometrikTersedia async {
    try {
      final auth = LocalAuthentication();
      return await auth.canCheckBiometrics && await auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  /// Minta autentikasi biometrik sistem.
  Future<bool> autentikasiBiometrik() async {
    try {
      final auth = LocalAuthentication();
      return await auth.authenticate(
        localizedReason: 'Buka kunci Dokter HP dengan sidik jari atau wajah.',
        biometricOnly: true,
      );
    } catch (_) {
      return false;
    }
  }

  Future<bool> get biometrikAktif async {
    final nilai = await _storage.read(key: _kunciBiometrik);
    return nilai == 'true';
  }

  Future<void> aturBiometrik(bool aktif) async {
    await _storage.write(
      key: _kunciBiometrik,
      value: aktif ? 'true' : 'false',
    );
  }
}
