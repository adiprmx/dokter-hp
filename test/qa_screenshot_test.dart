import 'package:dokter_hp/data/local/app_database.dart';
import 'package:dokter_hp/features/battery/battery_page.dart';
import 'package:dokter_hp/features/dashboard/dashboard_page.dart';
import 'package:dokter_hp/features/history/history_page.dart';
import 'package:dokter_hp/features/performance/performance_page.dart';
import 'package:dokter_hp/features/security/security_page.dart';
import 'package:dokter_hp/features/storage/storage_page.dart';
import 'package:dokter_hp/features/wifi_doctor/wifi_doctor_page.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tes screenshot QA (bukan golden penanda regresi visual ketat):
/// menghasilkan PNG tiap layar utama di test/goldens/qa-*.png, yang
/// kemudian disalin ke docs/screenshots/qa-*.png.
///
/// Semua channel platform di-mock agar layar me-render kondisi
/// "tidak ada data perangkat" yang jujur, bukan angka palsu.
/// Dijalankan dengan `flutter test --update-goldens` untuk membuat
/// berkasnya, lalu `flutter test` biasa untuk memastikan hasilnya
/// stabil (deterministik).
void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());

    // Channel native aplikasi (MainActivity): tidak ada data perangkat
    // di lingkungan tes — kembalikan null/kosong, sesuai kontrak
    // "null = tidak tersedia" di MainActivity.kt.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.adiprmx.dokterhp/native'),
      (call) async {
        switch (call.method) {
          case 'dnsServers':
          case 'installedApps':
            return <dynamic>[];
          case 'cacheSizeBytes':
            return 0;
          case 'openWifiSettings':
          case 'clearCache':
            return true;
          default:
            return null;
        }
      },
    );

    // connectivity_plus: tidak tersambung ke jaringan apa pun.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/connectivity'),
      (call) async {
        if (call.method == 'check') return <String>['none'];
        return null;
      },
    );

    // battery_plus: level 82, bukan mode hemat daya. Stream status
    // baterai memakai EventChannel 'charging': mock 'listen' agar
    // stream diam (tanpa mock, aktivasi stream melempar
    // MissingPluginException dan tes gagal). Halaman memakai timeout
    // 5 detik internalnya dan tetap menampilkan data level.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/battery'),
      (call) async {
        if (call.method == 'getBatteryLevel') return 82;
        if (call.method == 'isInBatterySaveMode') return false;
        return null;
      },
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/charging'),
      (call) async => null,
    );

    // device_info_plus: info perangkat contoh yang konsisten.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/device_info'),
      (call) async {
        if (call.method == 'getAndroidDeviceInfo') {
          return <String, dynamic>{
            'version': <String, dynamic>{
              'sdkInt': 34,
              'release': '14',
              'codename': 'REL',
              'incremental': 'qa-test',
              'previewSdkInt': 0,
              'securityPatch': '2024-01-05',
              'baseOS': '',
            },
            'board': 'qa-board',
            'bootloader': 'qa-bootloader',
            'brand': 'QA',
            'device': 'qa-device',
            'display': 'qa-display',
            'fingerprint': 'qa-fingerprint',
            'hardware': 'qa-hardware',
            'host': 'qa-host',
            'id': 'qa-id',
            'manufacturer': 'QA',
            'model': 'QA Phone',
            'product': 'qa-product',
            'supported32BitAbis': <String>[],
            'supported64BitAbis': <String>[],
            'supportedAbis': <String>[],
            'tags': 'qa-tags',
            'type': 'qa-type',
            'isPhysicalDevice': false,
            'systemFeatures': <String>[],
            'serialNumber': 'qa-serial',
          };
        }
        return null;
      },
    );
  });

  tearDown(() async {
    for (final name in <String>[
      'com.adiprmx.dokterhp/native',
      'dev.fluttercommunity.plus/connectivity',
      'dev.fluttercommunity.plus/battery',
      'dev.fluttercommunity.plus/charging',
      'dev.fluttercommunity.plus/device_info',
    ]) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(MethodChannel(name), null);
    }
    await database.close();
  });

  Future<void> ambilScreenshot(
    WidgetTester tester,
    Widget halaman,
    String namaGolden,
  ) async {
    // Ukuran layar HP 390x844 @2x.
    tester.view.physicalSize = const Size(780, 1688);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(home: halaman));
    await tester.pump();
    // Beri waktu untuk pemuatan async (baterai memakai timeout 5 detik,
    // performa membaca /proc/stat dua kali dengan jeda 1 detik).
    await tester.pump(const Duration(seconds: 6));
    await tester.pump(const Duration(seconds: 2));
    // Operasi file nyata (/proc/stat, /sys/class/thermal) hanya selesai
    // di event loop nyata; jalankan jeda nyata lewat runAsync agar
    // halaman Performa sempat selesai memuat sebelum screenshot.
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(seconds: 2));
    });
    await tester.pump();
    // pumpAndSettle bisa gagal bila indikator loading tak berujung
    // masih berputar (misalnya data perangkat tak kunjung tiba);
    // screenshot tetap diambil apa adanya dan dicatat di laporan QA.
    try {
      await tester.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 10),
      );
    } on FlutterError {
      await tester.pump();
    }
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/$namaGolden'),
    );
  }

  testWidgets('screenshot: dashboard', (tester) async {
    await ambilScreenshot(
      tester,
      DashboardPage(database: database),
      'qa-dashboard.png',
    );
  });

  testWidgets('screenshot: dokter wifi', (tester) async {
    await ambilScreenshot(
      tester,
      WifiDoctorPage(database: database),
      'qa-wifi.png',
    );
  });

  testWidgets('screenshot: baterai', (tester) async {
    await ambilScreenshot(
      tester,
      const BatteryPage(),
      'qa-baterai.png',
    );
  });

  testWidgets('screenshot: penyimpanan', (tester) async {
    await ambilScreenshot(
      tester,
      const StoragePage(),
      'qa-penyimpanan.png',
    );
  });

  testWidgets('screenshot: performa', (tester) async {
    await ambilScreenshot(
      tester,
      const PerformancePage(),
      'qa-performa.png',
    );
  });

  testWidgets('screenshot: keamanan', (tester) async {
    await ambilScreenshot(
      tester,
      const SecurityPage(),
      'qa-keamanan.png',
    );
  });

  testWidgets('screenshot: riwayat', (tester) async {
    await ambilScreenshot(
      tester,
      HistoryPage(database: database),
      'qa-riwayat.png',
    );
  });
}
