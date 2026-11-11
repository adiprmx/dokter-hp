import 'package:dokter_hp/features/wifi_doctor/wifi_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WifiDoctorService.cleanDnsServers', () {
    test('kasus nyata dari HP owner: hanya DNS valid yang lolos', () {
      // Bukti 12 Nov 2026: DNS tampil "fe80::1wlan0, 1.1.1.1, 8.8.8.8".
      expect(
        WifiDoctorService.cleanDnsServers(
          ['fe80::1wlan0', '1.1.1.1', '8.8.8.8'],
        ),
        ['1.1.1.1', '8.8.8.8'],
      );
    });

    test('alamat link-local fe80::/10 dibuang', () {
      expect(WifiDoctorService.cleanDnsServers(['fe80::1']), isEmpty);
      expect(WifiDoctorService.cleanDnsServers(['fe80::1%wlan0']), isEmpty);
      expect(WifiDoctorService.cleanDnsServers(['febf::1234']), isEmpty);
      expect(WifiDoctorService.cleanDnsServers(['FE80::ABCD']), isEmpty);
    });

    test('string kosong dan entri berkarakter non-IP dibuang', () {
      expect(WifiDoctorService.cleanDnsServers(['']), isEmpty);
      expect(WifiDoctorService.cleanDnsServers(['   ']), isEmpty);
      expect(WifiDoctorService.cleanDnsServers(['fe80::1wlan0']), isEmpty);
      expect(WifiDoctorService.cleanDnsServers(['dns-rumah']), isEmpty);
    });

    test('IPv4 valid dan IPv6 global lolos', () {
      expect(
        WifiDoctorService.cleanDnsServers(['1.1.1.1', '8.8.8.8', '192.168.1.1']),
        ['1.1.1.1', '8.8.8.8', '192.168.1.1'],
      );
      expect(
        WifiDoctorService.cleanDnsServers(['2001:4860:4860::8888']),
        ['2001:4860:4860::8888'],
      );
    });

    test('spasi di sekitar alamat dipangkas', () {
      expect(
        WifiDoctorService.cleanDnsServers(['  8.8.4.4  ']),
        ['8.8.4.4'],
      );
    });
  });

  group('WifiDoctorService.bersihkanSsid', () {
    test('tanda kutip pembungkus dibuang', () {
      expect(WifiDoctorService.bersihkanSsid('"ACHA"'), 'ACHA');
    });

    test('SSID polos tidak berubah', () {
      expect(WifiDoctorService.bersihkanSsid('ACHA'), 'ACHA');
    });

    test('<unknown ssid> berarti tidak ada', () {
      expect(WifiDoctorService.bersihkanSsid('<unknown ssid>'), isNull);
      expect(WifiDoctorService.bersihkanSsid('"<unknown ssid>"'), isNull);
    });

    test('null dan kosong berarti tidak ada', () {
      expect(WifiDoctorService.bersihkanSsid(null), isNull);
      expect(WifiDoctorService.bersihkanSsid(''), isNull);
      expect(WifiDoctorService.bersihkanSsid('   '), isNull);
    });
  });

  group('WifiCheckResult.ssidPerluIzinLokasi', () {
    test('default false agar pemakaian lama tidak berubah', () {
      const hasil = WifiCheckResult(ssid: 'ACHA');
      expect(hasil.ssidPerluIzinLokasi, isFalse);
    });

    test('bisa disetel true bila izin lokasi ditolak', () {
      const hasil = WifiCheckResult(ssidPerluIzinLokasi: true);
      expect(hasil.ssidPerluIzinLokasi, isTrue);
      expect(hasil.ssid, isNull);
    });
  });
}
