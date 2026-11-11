import 'package:dokter_hp/core/health_score.dart';
import 'package:dokter_hp/features/wifi_doctor/wifi_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('classifySpeed', () {
    test('di bawah 50 KB/detik = sangat lambat', () {
      // Kasus nyata pemicu proyek ini: 3,2 KB/detik.
      expect(classifySpeed(3.2), SpeedClass.sangatLambat);
      expect(classifySpeed(49.9), SpeedClass.sangatLambat);
    });

    test('50-199 = lambat', () {
      expect(classifySpeed(50), SpeedClass.lambat);
      expect(classifySpeed(199), SpeedClass.lambat);
    });

    test('200-999 = cukup', () {
      expect(classifySpeed(200), SpeedClass.cukup);
      expect(classifySpeed(999), SpeedClass.cukup);
    });

    test('1000-4999 = cepat', () {
      expect(classifySpeed(1000), SpeedClass.cepat);
    });

    test('5000 ke atas = sangat cepat', () {
      expect(classifySpeed(5000), SpeedClass.sangatCepat);
    });
  });

  group('recommendChannel', () {
    test('channel 1, 6, 11 sudah ideal', () {
      for (final ch in [1, 6, 11]) {
        expect(recommendChannel(ch), contains('sudah ideal'));
      }
    });

    test('channel lain disarankan pindah ke yang terdekat', () {
      expect(recommendChannel(3), contains('channel 1'));
      expect(recommendChannel(8), contains('channel 6'));
      expect(recommendChannel(13), contains('channel 11'));
    });

    test('channel tidak diketahui memberi penjelasan umum', () {
      expect(recommendChannel(null), contains('1, 6, atau 11'));
    });
  });

  group('channelFromFrequency', () {
    test('frekuensi 2,4 GHz', () {
      expect(channelFromFrequency(2412), 1);
      expect(channelFromFrequency(2437), 6);
      expect(channelFromFrequency(2462), 11);
      expect(channelFromFrequency(2484), 14);
    });

    test('frekuensi 5 GHz', () {
      expect(channelFromFrequency(5180), 36);
      expect(channelFromFrequency(5745), 149);
    });

    test('null dan frekuensi aneh = null', () {
      expect(channelFromFrequency(null), isNull);
      expect(channelFromFrequency(1000), isNull);
    });
  });

  group('signalLabel', () {
    test('ambang RSSI', () {
      expect(signalLabel(-40), 'Sangat bagus');
      expect(signalLabel(-55), 'Bagus');
      expect(signalLabel(-65), 'Cukup');
      expect(signalLabel(-80), 'Lemah');
      expect(signalLabel(null), 'Tidak diketahui');
    });
  });

  group('WifiCheckResult.recommendations', () {
    test('kecepatan sangat lambat memberi saran pindah dekat router', () {
      const hasil = WifiCheckResult(downloadKbps: 3.2);
      expect(
        hasil.recommendations.join(' '),
        contains('3.2 KB/detik'),
      );
    });

    test('hasil sehat tanpa masalah memberi pesan tidak ada masalah', () {
      const hasil = WifiCheckResult(
        downloadKbps: 10000,
        pingMs: 20,
        rssiDbm: -40,
      );
      expect(
        hasil.recommendations,
        ['Tidak ada masalah yang terdeteksi dari hasil ukur ini.'],
      );
    });

    test('latensi tinggi memberi saran', () {
      const hasil = WifiCheckResult(downloadKbps: 10000, pingMs: 300);
      expect(hasil.recommendations.join(' '), contains('300 ms'));
    });

    test('channel dari frekuensi dipakai di rekomendasi', () {
      const hasil = WifiCheckResult(
        downloadKbps: 10000,
        frequencyMhz: 2417,
      );
      expect(hasil.channel, 2);
      expect(hasil.channelRecommendation, contains('channel 1'));
    });
  });
}
