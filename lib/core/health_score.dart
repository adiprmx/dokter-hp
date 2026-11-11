// Logika skor kesehatan HP (0-100) dan klasifikasi hasil diagnosis.
//
// Semua fungsi di file ini murni (tanpa I/O) sehingga bisa diuji unit
// tanpa perangkat. Skor dihitung dari komponen yang datanya benar-benar
// tersedia; komponen tanpa data tidak dihitung dan tidak dipalsukan.

/// Kategori skor kesehatan.
enum HealthCategory { baik, cukup, buruk }

/// Hasil perhitungan skor beserta penjelasan per komponen.
class HealthScoreResult {
  const HealthScoreResult({
    required this.score,
    required this.category,
    required this.details,
  });

  /// Skor 0-100.
  final int score;
  final HealthCategory category;
  final Map<String, String> details;
}

/// Hitung skor kesehatan dari komponen yang tersedia.
///
/// Setiap parameter boleh null bila datanya tidak tersedia di perangkat;
/// komponen null dilewati dan bobot sisanya dinormalisasi ulang.
///
/// - [wifiKbps]: kecepatan unduh WiFi terukur (KB/detik).
/// - [batteryLevel]: persen baterai 0-100.
/// - [batteryHealth]: 'baik', 'cukup', atau 'buruk' bila diketahui.
/// - [storageFreePercent]: persen ruang kosong 0-100.
/// - [ramFreePercent]: persen RAM kosong 0-100.
/// - [securityIssues]: jumlah masalah keamanan yang ditemukan.
HealthScoreResult calculateHealthScore({
  double? wifiKbps,
  int? batteryLevel,
  String? batteryHealth,
  double? storageFreePercent,
  double? ramFreePercent,
  int? securityIssues,
}) {
  var totalBobot = 0.0;
  var totalNilai = 0.0;
  final details = <String, String>{};

  void tambah(double bobot, double nilai, String kunci, String penjelasan) {
    totalBobot += bobot;
    totalNilai += bobot * nilai.clamp(0, 100);
    details[kunci] = penjelasan;
  }

  if (wifiKbps != null) {
    final nilai = classifySpeed(wifiKbps).scoreValue;
    tambah(
      30,
      nilai,
      'wifi',
      'Kecepatan WiFi ${formatKbps(wifiKbps)} '
      '(${classifySpeed(wifiKbps).label}).',
    );
  }
  if (batteryLevel != null) {
    var nilai = batteryLevel.toDouble();
    if (batteryHealth == 'buruk') nilai *= 0.5;
    if (batteryHealth == 'cukup') nilai *= 0.8;
    tambah(
      25,
      nilai,
      'baterai',
      'Baterai $batteryLevel%.',
    );
  }
  if (storageFreePercent != null) {
    tambah(
      20,
      storageFreePercent,
      'penyimpanan',
      'Ruang kosong ${storageFreePercent.toStringAsFixed(0)}%.',
    );
  }
  if (ramFreePercent != null) {
    tambah(
      15,
      ramFreePercent,
      'performa',
      'RAM kosong ${ramFreePercent.toStringAsFixed(0)}%.',
    );
  }
  if (securityIssues != null) {
    final nilai = securityIssues == 0
        ? 100.0
        : (100 - securityIssues * 20).clamp(0, 100).toDouble();
    tambah(
      10,
      nilai,
      'keamanan',
      securityIssues == 0
          ? 'Tidak ada masalah keamanan yang ditemukan.'
          : '$securityIssues masalah keamanan ditemukan.',
    );
  }

  if (totalBobot == 0) {
    return const HealthScoreResult(
      score: 0,
      category: HealthCategory.buruk,
      details: {},
    );
  }
  final score = (totalNilai / totalBobot).round().clamp(0, 100);
  return HealthScoreResult(
    score: score,
    category: categoryForScore(score),
    details: details,
  );
}

/// Kategori untuk skor 0-100: >= 80 baik, 50-79 cukup, < 50 buruk.
HealthCategory categoryForScore(int score) {
  if (score >= 80) return HealthCategory.baik;
  if (score >= 50) return HealthCategory.cukup;
  return HealthCategory.buruk;
}

/// Label Bahasa Indonesia untuk kategori.
extension HealthCategoryLabel on HealthCategory {
  String get label {
    switch (this) {
      case HealthCategory.baik:
        return 'Baik';
      case HealthCategory.cukup:
        return 'Cukup';
      case HealthCategory.buruk:
        return 'Perlu perhatian';
    }
  }
}

/// Klasifikasi kecepatan unduh WiFi.
enum SpeedClass { sangatLambat, lambat, cukup, cepat, sangatCepat }

extension SpeedClassInfo on SpeedClass {
  String get label {
    switch (this) {
      case SpeedClass.sangatLambat:
        return 'Sangat lambat';
      case SpeedClass.lambat:
        return 'Lambat';
      case SpeedClass.cukup:
        return 'Cukup';
      case SpeedClass.cepat:
        return 'Cepat';
      case SpeedClass.sangatCepat:
        return 'Sangat cepat';
    }
  }

  /// Nilai 0-100 untuk komponen skor WiFi.
  double get scoreValue {
    switch (this) {
      case SpeedClass.sangatLambat:
        return 10;
      case SpeedClass.lambat:
        return 35;
      case SpeedClass.cukup:
        return 60;
      case SpeedClass.cepat:
        return 85;
      case SpeedClass.sangatCepat:
        return 100;
    }
  }
}

/// Klasifikasi kecepatan unduh dalam KB/detik.
///
/// Ambang: < 50 sangat lambat, < 200 lambat, < 1000 cukup,
/// < 5000 cepat, sisanya sangat cepat.
SpeedClass classifySpeed(double kbps) {
  if (kbps < 50) return SpeedClass.sangatLambat;
  if (kbps < 200) return SpeedClass.lambat;
  if (kbps < 1000) return SpeedClass.cukup;
  if (kbps < 5000) return SpeedClass.cepat;
  return SpeedClass.sangatCepat;
}

/// Format kecepatan: KB/detik di bawah 1024, MB/detik di atasnya.
String formatKbps(double kbps) {
  if (kbps >= 1024) {
    return '${(kbps / 1024).toStringAsFixed(2)} MB/detik';
  }
  return '${kbps.toStringAsFixed(1)} KB/detik';
}

/// Rekomendasi channel 2,4 GHz berdasarkan channel yang sedang dipakai.
///
/// Di pita 2,4 GHz hanya channel 1, 6, dan 11 yang tidak saling tumpang
/// tindih. Bila channel sekarang bukan salah satunya, sarankan yang
/// terdekat dari ketiganya.
String recommendChannel(int? currentChannel) {
  if (currentChannel == null) {
    return 'Channel tidak diketahui. Di pita 2,4 GHz, gunakan channel 1, '
        '6, atau 11 karena ketiganya tidak saling tumpang tindih.';
  }
  if (currentChannel == 1 || currentChannel == 6 || currentChannel == 11) {
    return 'Channel $currentChannel sudah ideal (1, 6, dan 11 adalah '
        'channel 2,4 GHz yang tidak saling tumpang tindih).';
  }
  final terdekat = [1, 6, 11].reduce(
    (a, b) =>
        (currentChannel - a).abs() < (currentChannel - b).abs() ? a : b,
  );
  return 'Channel $currentChannel bertumpang tindih dengan channel lain. '
      'Pindah ke channel $terdekat di pengaturan router.';
}

/// Nomor channel dari frekuensi MHz (2,4 GHz dan 5 GHz).
int? channelFromFrequency(int? frequencyMhz) {
  if (frequencyMhz == null) return null;
  if (frequencyMhz >= 2412 && frequencyMhz <= 2484) {
    if (frequencyMhz == 2484) return 14;
    return (frequencyMhz - 2407) ~/ 5;
  }
  if (frequencyMhz >= 5170 && frequencyMhz <= 5825) {
    return (frequencyMhz - 5000) ~/ 5;
  }
  return null;
}

/// Label kekuatan sinyal dari RSSI dBm.
String signalLabel(int? rssiDbm) {
  if (rssiDbm == null) return 'Tidak diketahui';
  if (rssiDbm >= -50) return 'Sangat bagus';
  if (rssiDbm >= -60) return 'Bagus';
  if (rssiDbm >= -70) return 'Cukup';
  return 'Lemah';
}
