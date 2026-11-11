import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dokter_hp/core/health_score.dart';
import 'package:dokter_hp/core/native/device_native.dart';
import 'package:network_info_plus/network_info_plus.dart';

/// Hasil pemeriksaan WiFi. Semua nilai berasal dari pengukuran nyata;
/// nilai yang tidak bisa diukur tetap null.
class WifiCheckResult {
  const WifiCheckResult({
    this.ssid,
    this.ipAddress,
    this.gateway,
    this.dnsServers = const [],
    this.rssiDbm,
    this.linkSpeedMbps,
    this.frequencyMhz,
    this.downloadKbps,
    this.pingMs,
    this.error,
  });

  final String? ssid;
  final String? ipAddress;
  final String? gateway;
  final List<String> dnsServers;
  final int? rssiDbm;
  final int? linkSpeedMbps;
  final int? frequencyMhz;
  final double? downloadKbps;
  final int? pingMs;
  final String? error;

  int? get channel => channelFromFrequency(frequencyMhz);
  String get signalText => signalLabel(rssiDbm);
  SpeedClass? get speedClass =>
      downloadKbps == null ? null : classifySpeed(downloadKbps!);

  String get channelRecommendation => recommendChannel(channel);

  /// Rekomendasi perbaikan berdasarkan hasil ukur.
  List<String> get recommendations {
    final daftar = <String>[];
    if (downloadKbps != null && downloadKbps! < 200) {
      daftar.add(
        'Kecepatan unduh hanya ${formatKbps(downloadKbps!)}. '
        'Coba pindah lebih dekat ke router, lalu uji lagi.',
      );
    }
    if (pingMs != null && pingMs! > 150) {
      daftar.add(
        'Latensi $pingMs ms tergolong tinggi. Tutup unduhan lain di '
        'jaringan yang sama, lalu uji lagi.',
      );
    }
    if (channel != null) {
      daftar.add(channelRecommendation);
    }
    if (rssiDbm != null && rssiDbm! < -70) {
      daftar.add(
        'Sinyal lemah ($rssiDbm dBm). Pindah lebih dekat ke router '
        'atau pertimbangkan penguat sinyal.',
      );
    }
    if (daftar.isEmpty) {
      daftar.add('Tidak ada masalah yang terdeteksi dari hasil ukur ini.');
    }
    return daftar;
  }
}

/// Layanan pemeriksaan WiFi: info jaringan, tes unduh, dan latensi.
class WifiDoctorService {
  WifiDoctorService({HttpClient? httpClient})
      : _httpClient = httpClient ?? HttpClient();

  final HttpClient _httpClient;

  /// URL file uji unduh (server publik). Dicoba berurutan sampai ada
  /// yang berhasil; semuanya file kecil agar hemat kuota.
  static const List<String> testUrls = [
    'https://speed.cloudflare.com/__down?bytes=1000000',
    'https://proof.ovh.net/files/1Mb.dat',
  ];

  static const Duration timeout = Duration(seconds: 15);

  /// Apakah perangkat saat ini tersambung ke WiFi.
  ///
  /// Diberi timeout 5 detik: bila platform channel macet, pemeriksaan
  /// gagal secara jujur daripada menggantung selamanya.
  Future<bool> isWifiConnected() async {
    try {
      final hasil = await Connectivity()
          .checkConnectivity()
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () => <ConnectivityResult>[],
          );
      return hasil.contains(ConnectivityResult.wifi);
    } catch (_) {
      return false;
    }
  }

  /// Info jaringan saat ini (SSID, IP, gateway, DNS, sinyal, channel).
  Future<WifiCheckResult> collectNetworkInfo() async {
    final info = NetworkInfo();
    String? ssid;
    String? ip;
    String? gateway;
    try {
      ssid = await info
          .getWifiName()
          .timeout(const Duration(seconds: 5), onTimeout: () => null);
      ip = await info
          .getWifiIP()
          .timeout(const Duration(seconds: 5), onTimeout: () => null);
      gateway = await info
          .getWifiGatewayIP()
          .timeout(const Duration(seconds: 5), onTimeout: () => null);
    } catch (_) {
      // API jaringan tidak tersedia — nilai tetap null dan ditampilkan
      // sebagai "tidak tersedia", bukan ditebak.
    }
    final dns = await DeviceNative.dnsServers();
    final rssi = await DeviceNative.wifiRssiDbm();
    final linkSpeed = await DeviceNative.wifiLinkSpeedMbps();
    final frequency = await DeviceNative.wifiFrequencyMhz();
    return WifiCheckResult(
      ssid: _bersihkanSsid(ssid),
      ipAddress: ip,
      gateway: gateway,
      dnsServers: dns,
      rssiDbm: rssi,
      linkSpeedMbps: linkSpeed,
      frequencyMhz: frequency,
    );
  }

  /// Tes kecepatan unduh: unduh file kecil, ukur byte per detik.
  /// Mengembalikan KB/detik, atau null bila semua URL gagal.
  Future<double?> measureDownloadSpeed({List<String>? urls}) async {
    for (final url in urls ?? testUrls) {
      try {
        final request = await _httpClient
            .getUrl(Uri.parse(url))
            .timeout(timeout);
        final response = await request.close().timeout(timeout);
        if (response.statusCode != 200) continue;
        var totalBytes = 0;
        final stopwatch = Stopwatch()..start();
        await for (final chunk in response.timeout(timeout)) {
          totalBytes += chunk.length;
        }
        stopwatch.stop();
        final detik = stopwatch.elapsedMilliseconds / 1000;
        if (detik <= 0 || totalBytes == 0) continue;
        return totalBytes / detik / 1024;
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  /// Latensi HTTP (round-trip request kecil). Ini BUKAN ping ICMP —
  /// aplikasi pihak ketiga tidak bisa mengirim ICMP mentah di Android —
  /// dan labelnya di layar menyebut "latensi HTTP" secara jujur.
  Future<int?> measureLatency() async {
    try {
      final stopwatch = Stopwatch()..start();
      final request = await _httpClient
          .getUrl(Uri.parse('https://www.google.com/generate_204'))
          .timeout(timeout);
      final response = await request.close().timeout(timeout);
      await response.drain<void>();
      stopwatch.stop();
      return stopwatch.elapsedMilliseconds;
    } catch (_) {
      return null;
    }
  }

  /// Pemeriksaan lengkap: info jaringan + tes unduh + latensi.
  Future<WifiCheckResult> runFullCheck({
    void Function(String tahap)? onProgress,
  }) async {
    onProgress?.call('Membaca info jaringan...');
    final info = await collectNetworkInfo();
    onProgress?.call('Mengukur kecepatan unduh...');
    final kecepatan = await measureDownloadSpeed();
    onProgress?.call('Mengukur latensi...');
    final latensi = await measureLatency();
    if (kecepatan == null && latensi == null) {
      return WifiCheckResult(
        ssid: info.ssid,
        ipAddress: info.ipAddress,
        gateway: info.gateway,
        dnsServers: info.dnsServers,
        rssiDbm: info.rssiDbm,
        linkSpeedMbps: info.linkSpeedMbps,
        frequencyMhz: info.frequencyMhz,
        error:
            'Tes kecepatan gagal. Periksa sambungan internet, lalu coba lagi.',
      );
    }
    return WifiCheckResult(
      ssid: info.ssid,
      ipAddress: info.ipAddress,
      gateway: info.gateway,
      dnsServers: info.dnsServers,
      rssiDbm: info.rssiDbm,
      linkSpeedMbps: info.linkSpeedMbps,
      frequencyMhz: info.frequencyMhz,
      downloadKbps: kecepatan,
      pingMs: latensi,
    );
  }

  static String? _bersihkanSsid(String? ssid) {
    if (ssid == null) return null;
    var bersih = ssid.trim();
    if (bersih.startsWith('"') && bersih.endsWith('"') && bersih.length > 1) {
      bersih = bersih.substring(1, bersih.length - 1);
    }
    if (bersih.isEmpty || bersih == '<unknown ssid>') return null;
    return bersih;
  }
}
