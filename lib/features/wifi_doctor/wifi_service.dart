import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dokter_hp/core/health_score.dart';
import 'package:dokter_hp/core/native/device_native.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

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
    this.ssidPerluIzinLokasi = false,
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

  /// True bila nama WiFi tidak bisa dibaca karena izin lokasi belum
  /// diberikan. Layar bisa menampilkan "izinkan lokasi untuk
  /// menampilkan nama WiFi", bukan sekadar "Tidak tersedia".
  final bool ssidPerluIzinLokasi;

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

/// Hasil tes bertahan 30 detik: satu angka kecepatan (KB/detik) per detik.
class SustainedTestResult {
  SustainedTestResult._({required this.samples, required this.verdict});

  /// Buat hasil dari daftar sampel. Melempar [ArgumentError] bila daftar
  /// kosong: tes tanpa satu pun sampel tidak punya verdict, dan pemanggil
  /// ([WifiDoctorService.measureSustainedSpeed]) mengembalikan null
  /// daripada angka palsu.
  factory SustainedTestResult.dariSampel(List<double> samples) {
    final verdict = tentukanVerdict(samples);
    if (verdict == null) {
      throw ArgumentError(
        'Tes bertahan tanpa sampel tidak punya verdict.',
      );
    }
    return SustainedTestResult._(
      samples: List<double>.unmodifiable(samples),
      verdict: verdict,
    );
  }

  /// Aturan verdict (ditulis juga sebagai test di
  /// test/wifi_live_sustained_test.dart):
  ///
  /// - `bertahan`: rata-rata sampel >= 1000 KB/detik DAN tidak ada sampel
  ///   di bawah 200 KB/detik setelah detik ke-3.
  /// - `jatuh`: ada sampel di bawah 200 KB/detik setelah detik ke-3,
  ///   padahal rata-rata tiga sampel pertama >= 1000 KB/detik (mulai
  ///   cepat lalu jatuh di tengah jalan).
  /// - `tidakStabil`: semua kondisi lain.
  ///
  /// "Setelah detik ke-3" berarti sampel detik ke-4 dan seterusnya
  /// (indeks 3 ke atas): tiga detik pertama adalah masa pemanasan dan
  /// dikecualikan dari pemeriksaan jatuh. Sampel kosong mengembalikan
  /// null, bukan verdict.
  static SustainedVerdict? tentukanVerdict(List<double> samples) {
    if (samples.isEmpty) return null;
    final rataRata =
        samples.reduce((a, b) => a + b) / samples.length;
    final setelahDetikKetiga = samples.length > 3
        ? samples.sublist(3)
        : const <double>[];
    final adaJatuh = setelahDetikKetiga.any((s) => s < 200);
    if (!adaJatuh && rataRata >= 1000) {
      return SustainedVerdict.bertahan;
    }
    final awal = samples.take(3).reduce((a, b) => a + b) /
        samples.take(3).length;
    if (adaJatuh && awal >= 1000) {
      return SustainedVerdict.jatuh;
    }
    return SustainedVerdict.tidakStabil;
  }

  /// Kecepatan tiap detik (KB/detik), satu angka per detik.
  final List<double> samples;

  final SustainedVerdict verdict;

  double get rataRataKbps =>
      samples.reduce((a, b) => a + b) / samples.length;

  double get terendahKbps =>
      samples.reduce((a, b) => a < b ? a : b);

  double get tertinggiKbps =>
      samples.reduce((a, b) => a > b ? a : b);
}

/// Verdict tes bertahan 30 detik.
enum SustainedVerdict { bertahan, jatuh, tidakStabil }

extension SustainedVerdictLabel on SustainedVerdict {
  /// Label sehari-hari untuk layar.
  String get label {
    switch (this) {
      case SustainedVerdict.bertahan:
        return 'Kecepatan bertahan';
      case SustainedVerdict.jatuh:
        return 'Kecepatan jatuh di tengah jalan';
      case SustainedVerdict.tidakStabil:
        return 'Kecepatan tidak stabil';
    }
  }

  /// Penjelasan satu kalimat tentang arti verdict.
  String get penjelasan {
    switch (this) {
      case SustainedVerdict.bertahan:
        return 'Kecepatan tetap cepat selama tes berjalan, WiFi bekerja '
            'normal saat dipakai terus.';
      case SustainedVerdict.jatuh:
        return 'Kecepatan mulai cepat lalu jatuh di tengah jalan, ada '
            'sesuatu yang menahan kecepatan saat dipakai.';
      case SustainedVerdict.tidakStabil:
        return 'Kecepatan naik turun selama tes, belum bisa dipastikan '
            'sehat atau bermasalah.';
    }
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

  /// URL probe ringan pemantau live: file 100 KB. Dipakai paling sering
  /// tiap 10 detik, jadi pemakaian datanya sekitar 600 KB per menit
  /// (100 KB x 6 probe).
  static const String liveProbeUrl =
      'https://speed.cloudflare.com/__down?bytes=100000';

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
  ///
  /// SSID dan gateway dibaca lewat channel native dulu (WifiManager /
  /// DhcpInfo), baru fallback ke network_info_plus bila native
  /// mengembalikan null. Sebelum membaca SSID, izin lokasi runtime
  /// diminta: Android 10+ menahan nama WiFi tanpa izin itu. Bila izin
  /// ditolak, SSID tetap null secara jujur dan flag
  /// [WifiCheckResult.ssidPerluIzinLokasi] disetel true.
  Future<WifiCheckResult> collectNetworkInfo() async {
    final izinLokasi = await _mintaIzinLokasi();
    final info = NetworkInfo();
    String? ssid;
    String? ip;
    String? gateway;
    try {
      ssid = bersihkanSsid(await DeviceNative.wifiSsid());
      ssid ??= bersihkanSsid(
        await info
            .getWifiName()
            .timeout(const Duration(seconds: 5), onTimeout: () => null),
      );
      ip = await info
          .getWifiIP()
          .timeout(const Duration(seconds: 5), onTimeout: () => null);
      gateway = await DeviceNative.wifiGatewayIp();
      gateway ??= await info
          .getWifiGatewayIP()
          .timeout(const Duration(seconds: 5), onTimeout: () => null);
    } catch (_) {
      // API jaringan tidak tersedia, nilai tetap null dan ditampilkan
      // sebagai "tidak tersedia", bukan ditebak.
    }
    final dns = cleanDnsServers(await DeviceNative.dnsServers());
    final rssi = await DeviceNative.wifiRssiDbm();
    final linkSpeed = await DeviceNative.wifiLinkSpeedMbps();
    final frequency = await DeviceNative.wifiFrequencyMhz();
    return WifiCheckResult(
      ssid: ssid,
      ipAddress: ip,
      gateway: gateway,
      dnsServers: dns,
      rssiDbm: rssi,
      linkSpeedMbps: linkSpeed,
      frequencyMhz: frequency,
      ssidPerluIzinLokasi: !izinLokasi,
    );
  }

  /// Minta izin lokasi saat aplikasi dipakai (Android 10+ butuh ini
  /// untuk membaca SSID). Mengembalikan true bila diizinkan. Bila
  /// plugin tidak tersedia (mis. saat tes unit), dianggap tidak
  /// diizinkan agar SSID tidak pernah ditampilkan dari tebakan.
  Future<bool> _mintaIzinLokasi() async {
    try {
      final status = await Permission.locationWhenInUse.request();
      return status.isGranted;
    } catch (_) {
      return false;
    }
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
        // Mikrodetik, bukan milidetik: unduhan file kecil di koneksi
        // cepat bisa selesai di bawah 1 ms, dan milidetik bulat akan
        // menganggapnya 0 detik lalu membuang hasil yang valid.
        final detik = stopwatch.elapsedMicroseconds / 1000000;
        if (detik <= 0 || totalBytes == 0) continue;
        return totalBytes / detik / 1024;
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  /// Tes bertahan: unduh berulang file uji 1 MB selama [durationSeconds]
  /// detik dan catat kecepatan tiap detik (KB/detik).
  ///
  /// Mengembalikan [SustainedTestResult] berisi satu sampel per detik,
  /// atau null bila tidak satu pun sampel berhasil dicatat (tes gagal
  /// total. Jangan tampilkan angka palsu). [onSample] dipanggil tiap
  /// detik dengan nomor detik (mulai dari 1) dan kecepatan detik itu.
  /// Bila [cekBerhenti] mengembalikan true, tes berhenti; sampel yang
  /// sudah ada tetap dikembalikan sebagai hasil.
  Future<SustainedTestResult?> measureSustainedSpeed({
    int durationSeconds = 30,
    void Function(int detik, double kbpsPerDetik)? onSample,
    bool Function()? cekBerhenti,
    List<String>? urls,
  }) async {
    final samples = <double>[];
    final stopwatch = Stopwatch()..start();
    var totalByte = 0;
    var bytePadaSampelSebelumnya = 0;
    var batasDetikBerikutnya = const Duration(seconds: 1);
    var berhenti = false;

    while (!berhenti && samples.length < durationSeconds) {
      var unduhanBerhasil = false;
      for (final url in urls ?? testUrls) {
        if (berhenti || samples.length >= durationSeconds) break;
        if (cekBerhenti?.call() == true) {
          berhenti = true;
          break;
        }
        try {
          final request = await _httpClient
              .getUrl(Uri.parse(url))
              .timeout(timeout);
          final response = await request.close().timeout(timeout);
          if (response.statusCode != 200) continue;
          unduhanBerhasil = true;
          await for (final chunk in response.timeout(timeout)) {
            totalByte += chunk.length;
            while (stopwatch.elapsed >= batasDetikBerikutnya &&
                samples.length < durationSeconds) {
              final kbps = (totalByte - bytePadaSampelSebelumnya) / 1024;
              samples.add(kbps);
              onSample?.call(samples.length, kbps);
              bytePadaSampelSebelumnya = totalByte;
              batasDetikBerikutnya += const Duration(seconds: 1);
            }
            if (samples.length >= durationSeconds ||
                cekBerhenti?.call() == true) {
              break;
            }
          }
          if (samples.length >= durationSeconds ||
              cekBerhenti?.call() == true) {
            berhenti = true;
            break;
          }
        } catch (_) {
          continue;
        }
      }
      if (berhenti) break;
      if (!unduhanBerhasil) {
        // Semua URL gagal pada putaran ini: jaringan mungkin mati. Jeda
        // singkat sebelum mencoba lagi agar tidak menembak tanpa henti.
        if (stopwatch.elapsed >= Duration(seconds: durationSeconds)) {
          break;
        }
        await Future.delayed(const Duration(milliseconds: 500));
      }
      if (stopwatch.elapsed >= Duration(seconds: durationSeconds)) break;
      if (cekBerhenti?.call() == true) break;
    }
    stopwatch.stop();
    if (samples.isEmpty) return null;
    return SustainedTestResult.dariSampel(samples);
  }

  /// Latensi HTTP (round-trip request kecil). Ini BUKAN ping ICMP ,
  /// aplikasi pihak ketiga tidak bisa mengirim ICMP mentah di Android ,
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
        ssidPerluIzinLokasi: info.ssidPerluIzinLokasi,
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
      ssidPerluIzinLokasi: info.ssidPerluIzinLokasi,
    );
  }

  /// Bersihkan SSID mentah dari Android: buang tanda kutip pembungkus
  /// (`"ACHA"` -> ACHA) dan anggap `"<unknown ssid>"` sebagai tidak ada.
  static String? bersihkanSsid(String? ssid) {
    if (ssid == null) return null;
    var bersih = ssid.trim();
    if (bersih.startsWith('"') && bersih.endsWith('"') && bersih.length > 1) {
      bersih = bersih.substring(1, bersih.length - 1);
    }
    if (bersih.isEmpty || bersih == '<unknown ssid>') return null;
    return bersih;
  }

  /// Saring daftar server DNS mentah: buang string kosong, entri yang
  /// mengandung "%" (zone id, mis. fe80::1%wlan0), entri dengan karakter
  /// di luar alamat IP (mis. fe80::1wlan0), dan alamat link-local
  /// IPv6 fe80::/10. Hanya IPv4 valid dan IPv6 global yang lolos.
  /// Fungsi murni, dipakai untuk semua sumber DNS.
  static List<String> cleanDnsServers(List<String> servers) {
    final bersih = <String>[];
    for (final entri in servers) {
      final alamat = entri.trim();
      if (alamat.isEmpty) continue;
      if (alamat.contains('%')) continue;
      if (!RegExp(r'^[0-9a-fA-F:.]+$').hasMatch(alamat)) continue;
      if (alamat.contains(':') && _alamatLinkLocalIpv6(alamat)) continue;
      bersih.add(alamat);
    }
    return bersih;
  }

  /// True bila alamat IPv6 termasuk blok link-local fe80::/10
  /// (grup 16-bit pertama fe80 sampai febf).
  static bool _alamatLinkLocalIpv6(String alamat) {
    final grupPertama = alamat.split(':').first;
    if (grupPertama.isEmpty) return false;
    final nilai = int.tryParse(grupPertama, radix: 16);
    if (nilai == null) return false;
    return (nilai & 0xffc0) == 0xfe80;
  }
}
