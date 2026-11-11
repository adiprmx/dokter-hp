import 'package:flutter/services.dart';

/// Jembatan ke API Android yang tidak disediakan paket publik.
///
/// Semua metode mengembalikan null bila tidak tersedia — pemanggil wajib
/// menampilkan kondisi jujur ("tidak tersedia"), bukan angka palsu.
class DeviceNative {
  DeviceNative._();

  static const _channel = MethodChannel('com.adiprmx.dokterhp/native');

  static Future<int?> wifiRssiDbm() async {
    try {
      return await _channel.invokeMethod<int>('wifiRssi');
    } catch (_) {
      return null;
    }
  }

  static Future<int?> wifiLinkSpeedMbps() async {
    try {
      return await _channel.invokeMethod<int>('wifiLinkSpeed');
    } catch (_) {
      return null;
    }
  }

  static Future<int?> wifiFrequencyMhz() async {
    try {
      return await _channel.invokeMethod<int>('wifiFrequency');
    } catch (_) {
      return null;
    }
  }

  static Future<List<String>> dnsServers() async {
    try {
      final hasil = await _channel.invokeMethod<List<dynamic>>('dnsServers');
      return hasil?.map((e) => e.toString()).toList() ?? const [];
    } catch (_) {
      return const [];
    }
  }

  /// Buka halaman pengaturan WiFi sistem (Android tidak mengizinkan
  /// aplikasi pihak ketiga menyambung ulang atau melupakan jaringan
  /// secara langsung sejak Android 10).
  static Future<bool> openWifiSettings() async {
    try {
      return await _channel.invokeMethod<bool>('openWifiSettings') ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<({int totalBytes, int freeBytes})?> storageInfo() async {
    try {
      final hasil =
          await _channel.invokeMethod<Map<dynamic, dynamic>>('storageInfo');
      if (hasil == null) return null;
      return (
        totalBytes: (hasil['totalBytes'] as int?) ?? 0,
        freeBytes: (hasil['freeBytes'] as int?) ?? 0,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<({int totalBytes, int freeBytes})?> memoryInfo() async {
    try {
      final hasil =
          await _channel.invokeMethod<Map<dynamic, dynamic>>('memoryInfo');
      if (hasil == null) return null;
      return (
        totalBytes: (hasil['totalBytes'] as int?) ?? 0,
        freeBytes: (hasil['freeBytes'] as int?) ?? 0,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<int?> cacheSizeBytes() async {
    try {
      return await _channel.invokeMethod<int>('cacheSizeBytes');
    } catch (_) {
      return null;
    }
  }

  /// Hapus file cache aplikasi sendiri. Tidak menyentuh foto, chat,
  /// atau file pengguna lainnya.
  static Future<bool> clearCache() async {
    try {
      return await _channel.invokeMethod<bool>('clearCache') ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<List<AppInfo>> installedApps() async {
    try {
      final hasil =
          await _channel.invokeMethod<List<dynamic>>('installedApps');
      if (hasil == null) return const [];
      return hasil.map((e) {
        final peta = e as Map<dynamic, dynamic>;
        return AppInfo(
          label: (peta['label'] as String?) ?? '',
          packageName: (peta['packageName'] as String?) ?? '',
          isSystem: (peta['isSystem'] as bool?) ?? false,
          installTimeMillis: (peta['installTimeMillis'] as int?) ?? 0,
          permissions: ((peta['permissions'] as List<dynamic>?) ?? const [])
              .map((p) => p.toString())
              .toList(),
        );
      }).toList();
    } catch (_) {
      return const [];
    }
  }
}

/// Info aplikasi terpasang dari PackageManager Android.
class AppInfo {
  const AppInfo({
    required this.label,
    required this.packageName,
    required this.isSystem,
    required this.installTimeMillis,
    required this.permissions,
  });

  final String label;
  final String packageName;
  final bool isSystem;
  final int installTimeMillis;
  final List<String> permissions;

  /// Jumlah izin berbahaya yang diminta aplikasi.
  int get dangerousPermissionCount => permissions
      .where((p) => _dangerousPermissions.contains(p))
      .length;

  static const _dangerousPermissions = {
    'android.permission.ACCESS_FINE_LOCATION',
    'android.permission.ACCESS_COARSE_LOCATION',
    'android.permission.CAMERA',
    'android.permission.RECORD_AUDIO',
    'android.permission.READ_CONTACTS',
    'android.permission.READ_SMS',
    'android.permission.SEND_SMS',
    'android.permission.READ_CALL_LOG',
    'android.permission.READ_EXTERNAL_STORAGE',
    'android.permission.READ_MEDIA_IMAGES',
    'android.permission.POST_NOTIFICATIONS',
    'android.permission.BODY_SENSORS',
  };
}
