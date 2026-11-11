import 'package:dokter_hp/core/health_score.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('categoryForScore', () {
    test('80 ke atas = baik', () {
      expect(categoryForScore(80), HealthCategory.baik);
      expect(categoryForScore(100), HealthCategory.baik);
    });

    test('50-79 = cukup', () {
      expect(categoryForScore(50), HealthCategory.cukup);
      expect(categoryForScore(79), HealthCategory.cukup);
    });

    test('di bawah 50 = buruk', () {
      expect(categoryForScore(49), HealthCategory.buruk);
      expect(categoryForScore(0), HealthCategory.buruk);
    });
  });

  group('calculateHealthScore', () {
    test('tanpa komponen apa pun = skor 0', () {
      final hasil = calculateHealthScore();
      expect(hasil.score, 0);
      expect(hasil.details, isEmpty);
    });

    test('semua komponen sempurna = skor 100', () {
      final hasil = calculateHealthScore(
        wifiKbps: 10000,
        batteryLevel: 100,
        storageFreePercent: 100,
        ramFreePercent: 100,
        securityIssues: 0,
      );
      expect(hasil.score, 100);
      expect(hasil.category, HealthCategory.baik);
    });

    test('komponen null dilewati, bobot dinormalisasi ulang', () {
      // Hanya baterai 100% -> skor tetap 100 walau komponen lain kosong.
      final hasil = calculateHealthScore(batteryLevel: 100);
      expect(hasil.score, 100);
    });

    test('baterai buruk menurunkan nilai baterai', () {
      final buruk = calculateHealthScore(
        batteryLevel: 100,
        batteryHealth: 'buruk',
      );
      expect(buruk.score, 50);
      final baik = calculateHealthScore(
        batteryLevel: 100,
        batteryHealth: 'baik',
      );
      expect(baik.score, 100);
    });

    test('masalah keamanan menurunkan skor', () {
      final hasil = calculateHealthScore(securityIssues: 5);
      expect(hasil.score, 0);
      final satu = calculateHealthScore(securityIssues: 1);
      expect(satu.score, 80);
    });

    test('skor selalu dalam 0-100', () {
      final hasil = calculateHealthScore(
        wifiKbps: -5,
        batteryLevel: 200,
        storageFreePercent: 300,
        ramFreePercent: -10,
        securityIssues: -1,
      );
      expect(hasil.score, greaterThanOrEqualTo(0));
      expect(hasil.score, lessThanOrEqualTo(100));
    });
  });

  group('formatKbps', () {
    test('di bawah 1024 tampil KB/detik', () {
      expect(formatKbps(50), '50.0 KB/detik');
    });

    test('1024 ke atas tampil MB/detik', () {
      expect(formatKbps(2048), '2.00 MB/detik');
    });
  });
}
