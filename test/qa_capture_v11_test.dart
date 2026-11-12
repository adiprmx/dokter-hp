import 'dart:io';
import 'dart:ui' as ui;

import 'package:dokter_hp/core/theme.dart';
import 'package:dokter_hp/data/local/app_database.dart';
import 'package:dokter_hp/features/ai_diagnosis/ai_diagnosis.dart';
import 'package:dokter_hp/features/auth/auth_page.dart';
import 'package:dokter_hp/features/battery/battery_page.dart';
import 'package:dokter_hp/features/dashboard/dashboard_page.dart';
import 'package:dokter_hp/features/history/history_page.dart';
import 'package:dokter_hp/features/performance/performance_page.dart';
import 'package:dokter_hp/features/security/security_page.dart';
import 'package:dokter_hp/features/storage/storage_page.dart';
import 'package:dokter_hp/features/wifi_doctor/wifi_doctor_page.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Penangkap screenshot v1.1.0 dengan font Roboto dan ikon Material
/// ASLI (bukan font balok Ahem seperti golden test di
/// qa_screenshot_test.dart), untuk dokumentasi di docs/screenshots/.
///
/// Dijalankan EKSPLISIT, bukan bagian dari `flutter test` biasa:
///   flutter test --dart-define=QA_CAPTURE=true test/qa_capture_v11_test.dart
/// Tanpa flag itu semua test di sini di-skip dan tidak ada berkas yang
/// ditulis, jadi suite reguler tetap cepat dan tanpa efek samping.
///
/// Font dimuat dari cache SDK Flutter (bukan dari aset aplikasi:
/// aplikasi tetap memakai font sistem di perangkat, PRODUCT.md
/// bagian 8). Bila font tidak ditemukan, test tetap menangkap dengan
/// font Ahem dan mencetak peringatan; screenshot seperti itu hanya
/// membuktikan geometri/warna/hierarki, bukan keterbacaan teks.
///
/// Nilai yang tampil adalah nilai harness, dicatat sebagai nilai uji
/// (aturan 9 spesifikasi): level baterai 82 dari mock battery_plus,
/// info perangkat "QA Phone" dari mock device_info_plus, penyimpanan
/// null (tidak tersedia), daftar aplikasi kosong, database riwayat
/// kosong. Bukan data perangkat nyata dan bukan angka karangan untuk
/// keperluan tampilan.
void main() {
  const tangkap = bool.fromEnvironment('QA_CAPTURE');

  late AppDatabase database;
  var fontAsli = false;

  Future<ByteData> bacaFont(File berkas) async {
    final bytes = await berkas.readAsBytes();
    return ByteData.view(bytes.buffer);
  }

  setUpAll(() async {
    if (!tangkap) return;
    // Cari font Roboto + MaterialIcons di cache SDK Flutter.
    final kandidatRoot = <String?>[
      Platform.environment['FLUTTER_ROOT'],
      '/home/hatch/sdks/flutter',
    ];
    for (final root in kandidatRoot) {
      if (root == null) continue;
      final dir = Directory('$root/bin/cache/artifacts/material_fonts');
      final regular = File('${dir.path}/Roboto-Regular.ttf');
      final medium = File('${dir.path}/Roboto-Medium.ttf');
      final bold = File('${dir.path}/Roboto-Bold.ttf');
      final ikon = File('${dir.path}/MaterialIcons-Regular.otf');
      if (!regular.existsSync() ||
          !medium.existsSync() ||
          !bold.existsSync() ||
          !ikon.existsSync()) {
        continue;
      }
      final pemuatRoboto = FontLoader('Roboto')
        ..addFont(bacaFont(regular))
        ..addFont(bacaFont(medium))
        ..addFont(bacaFont(bold));
      await pemuatRoboto.load();
      final pemuatIkon = FontLoader('MaterialIcons')
        ..addFont(bacaFont(ikon));
      await pemuatIkon.load();
      fontAsli = true;
      return;
    }
    // ignore: avoid_print
    print(
      'PERINGATAN QA_CAPTURE: font Roboto/MaterialIcons tidak ditemukan, '
      'screenshot memakai font balok Ahem.',
    );
  });

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());

    // Mock channel yang sama seperti qa_screenshot_test.dart, ditambah
    // mock penyimpanan aman + local_auth untuk halaman Akun.
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
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/connectivity'),
      (call) async {
        if (call.method == 'check') return <String>['none'];
        return null;
      },
    );
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
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel(
        'plugins.it_nomads.com/flutter_secure_storage',
      ),
      (call) async => null,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/local_auth'),
      (call) async {
        switch (call.method) {
          case 'getAvailableBiometrics':
            return <String>[];
          case 'isDeviceSupported':
          case 'authenticate':
            return false;
          default:
            return null;
        }
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
      'plugins.it_nomads.com/flutter_secure_storage',
      'plugins.flutter.io/local_auth',
    ]) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(MethodChannel(name), null);
    }
    await database.close();
  });

  /// Tema harness: AppTheme.dark() dengan fontFamily Roboto ditambal
  /// ke slot-slot tema yang tidak dijangkau tipografi ThemeData.
  ///
  /// Mekanisme (dibuktikan probe 12 Nov 2026): ThemeData menerapkan
  /// fontFamily tipografi ke textTheme, jadi teks langsung mewarisi
  /// Roboto dari DefaultTextStyle ambient. Tetapi AppBar dan tombol
  /// menyisipkan DefaultTextStyle SENDIRI dari appBarTheme/buttonTheme
  /// yang menggantikan ambient; karena gaya-gaya itu tanpa fontFamily,
  /// judul AppBar dan label tombol jatuh ke font balok Ahem di
  /// lingkungan tes. Di HP nyata hal ini tidak terjadi karena font
  /// sistem Android adalah Roboto. Tambalan ini hanya meniru font
  /// sistem di harness; tidak satu pun token desain (ukuran, bobot,
  /// warna, spasi) berubah.
  ThemeData temaHarness() {
    final tema = AppTheme.dark();
    TextStyle keluarga(TextStyle? gaya) =>
        (gaya ?? const TextStyle()).apply(fontFamily: 'Roboto');
    ButtonStyle tambalTombol(ButtonStyle? gaya) {
      final terurai = gaya?.textStyle?.resolve(<WidgetState>{});
      return (gaya ?? const ButtonStyle()).copyWith(
        textStyle: WidgetStatePropertyAll(keluarga(terurai)),
      );
    }
    return tema.copyWith(
      appBarTheme: tema.appBarTheme.copyWith(
        titleTextStyle: keluarga(tema.appBarTheme.titleTextStyle),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: tambalTombol(tema.filledButtonTheme.style),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: tambalTombol(tema.outlinedButtonTheme.style),
      ),
      textButtonTheme: TextButtonThemeData(
        style: tambalTombol(tema.textButtonTheme.style),
      ),
      inputDecorationTheme: tema.inputDecorationTheme.copyWith(
        labelStyle: keluarga(tema.inputDecorationTheme.labelStyle),
        hintStyle: keluarga(tema.inputDecorationTheme.hintStyle),
      ),
      dialogTheme: tema.dialogTheme.copyWith(
        titleTextStyle: keluarga(tema.dialogTheme.titleTextStyle),
        contentTextStyle: keluarga(tema.dialogTheme.contentTextStyle),
      ),
      snackBarTheme: tema.snackBarTheme.copyWith(
        contentTextStyle: keluarga(tema.snackBarTheme.contentTextStyle),
      ),
    );
  }

  Future<void> tangkapLayar(
    WidgetTester tester,
    Widget halaman,
    String namaBerkas,
  ) async {
    // Ukuran layar HP 390x844 @2x, sama seperti screenshot lama.
    tester.view.physicalSize = const Size(780, 1688);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);
    final kunci = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: temaHarness(),
        home: RepaintBoundary(key: kunci, child: halaman),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 6));
    await tester.pump(const Duration(seconds: 2));
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(seconds: 2));
    });
    await tester.pump();
    try {
      await tester.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 10),
      );
    } on FlutterError {
      await tester.pump();
    }
    // toImage/toByteData adalah async engine (event loop nyata), jadi
    // WAJIB dibungkus runAsync: di dalam zona FakeAsync widget test,
    // Future-nya tidak pernah selesai dan test menggantung selamanya
    // (terbukti 12 Nov 2026: tangkap dashboard macet 8 menit di sini).
    final boundary =
        kunci.currentContext!.findRenderObject() as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final gambar = await boundary.toImage(pixelRatio: 2.0);
      final data = await gambar.toByteData(format: ui.ImageByteFormat.png);
      final berkas = File('docs/screenshots/$namaBerkas');
      await berkas.writeAsBytes(data!.buffer.asUint8List());
    });
    // ignore: avoid_print
    print(
      'QA_CAPTURE: $namaBerkas ditulis '
      '(${fontAsli ? 'font Roboto asli' : 'font Ahem'})',
    );
  }

  testWidgets(
    'tangkap: dashboard',
    (tester) async {
      await tangkapLayar(
        tester,
        DashboardPage(database: database),
        'dashboard-v11.png',
      );
    },
    skip: !tangkap,
    timeout: const Timeout(Duration(minutes: 2)),
  );

  testWidgets(
    'tangkap: dokter wifi',
    (tester) async {
      await tangkapLayar(
        tester,
        WifiDoctorPage(database: database),
        'wifi-v11.png',
      );
    },
    skip: !tangkap,
    timeout: const Timeout(Duration(minutes: 2)),
  );

  testWidgets(
    'tangkap: baterai',
    (tester) async {
      await tangkapLayar(tester, const BatteryPage(), 'baterai-v11.png');
    },
    skip: !tangkap,
    timeout: const Timeout(Duration(minutes: 2)),
  );

  testWidgets(
    'tangkap: penyimpanan',
    (tester) async {
      await tangkapLayar(
        tester,
        const StoragePage(),
        'penyimpanan-v11.png',
      );
    },
    skip: !tangkap,
    timeout: const Timeout(Duration(minutes: 2)),
  );

  testWidgets(
    'tangkap: performa',
    (tester) async {
      await tangkapLayar(
        tester,
        const PerformancePage(),
        'performa-v11.png',
      );
    },
    skip: !tangkap,
    timeout: const Timeout(Duration(minutes: 2)),
  );

  testWidgets(
    'tangkap: keamanan',
    (tester) async {
      await tangkapLayar(
        tester,
        const SecurityPage(),
        'keamanan-v11.png',
      );
    },
    skip: !tangkap,
    timeout: const Timeout(Duration(minutes: 2)),
  );

  testWidgets(
    'tangkap: riwayat',
    (tester) async {
      await tangkapLayar(
        tester,
        HistoryPage(database: database),
        'riwayat-v11.png',
      );
    },
    skip: !tangkap,
    timeout: const Timeout(Duration(minutes: 2)),
  );

  testWidgets(
    'tangkap: diagnosis ai',
    (tester) async {
      await tangkapLayar(
        tester,
        const AiDiagnosisPage(),
        'ai-diagnosis-v11.png',
      );
    },
    skip: !tangkap,
    timeout: const Timeout(Duration(minutes: 2)),
  );

  testWidgets(
    'tangkap: akun',
    (tester) async {
      await tangkapLayar(tester, const AuthPage(), 'akun-v11.png');
    },
    skip: !tangkap,
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
