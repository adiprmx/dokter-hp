import 'package:dokter_hp/core/theme.dart';
import 'package:dokter_hp/core/widgets/common_widgets.dart';
import 'package:dokter_hp/data/local/app_database.dart';
import 'package:dokter_hp/features/auth/auth_page.dart';
import 'package:dokter_hp/features/history/history_page.dart';
import 'package:dokter_hp/features/performance/performance_page.dart';
import 'package:dokter_hp/features/security/security_page.dart';
import 'package:dokter_hp/features/storage/storage_page.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Test widget rancang ulang v1.1.0: komponen bersama dan layar yang
/// dirancang ulang (Riwayat, Akun, Keamanan, Penyimpanan, Performa).
void main() {
  Future<void> pompaKomponen(WidgetTester tester, Widget anak) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(body: anak),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('komponen bersama', () {
    testWidgets('MeterGauge menampilkan angka, satuan, dan chip',
        (tester) async {
      await pompaKomponen(
        tester,
        MeterGauge(
          fraction: 0.82,
          displayValue: '82',
          displayUnit: '/ 100',
          chip: const StatusChip(
            label: 'Baik',
            icon: Icons.check,
            tone: StatusTone.success,
          ),
          semanticsLabel: 'Skor kesehatan 82 dari 100, Baik',
        ),
      );

      expect(find.text('82'), findsOneWidget);
      expect(find.text('/ 100'), findsOneWidget);
      expect(find.text('Baik'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
      expect(find.text('100'), findsOneWidget);
    });

    testWidgets('MeterGauge kosong menampilkan teks kosong, bukan angka',
        (tester) async {
      await pompaKomponen(
        tester,
        const MeterGauge(
          fraction: null,
          displayValue: '',
          emptyText: 'Tidak tersedia di perangkat ini',
          size: MeterSize.compact,
          label: 'Suhu perangkat',
        ),
      );

      expect(find.text('Tidak tersedia di perangkat ini'), findsOneWidget);
      expect(find.text('Suhu perangkat'), findsOneWidget);
    });

    testWidgets('StatRow menampilkan label di kiri dan nilai di kanan',
        (tester) async {
      await pompaKomponen(
        tester,
        const StatRow(label: 'Alamat IP', value: '192.168.1.7'),
      );

      expect(find.text('Alamat IP'), findsOneWidget);
      expect(find.text('192.168.1.7'), findsOneWidget);
    });

    testWidgets('StatusChip menampilkan ikon dan teks', (tester) async {
      await pompaKomponen(
        tester,
        const StatusChip(
          label: 'Perlu perhatian',
          icon: Icons.warning_amber,
          tone: StatusTone.danger,
        ),
      );

      expect(find.text('Perlu perhatian'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber), findsOneWidget);
    });

    testWidgets('LiveChip menampilkan teks Live', (tester) async {
      // LiveChip berdenyut tanpa henti, jadi pumpAndSettle tidak
      // pernah selesai: pakai pump biasa.
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: const Scaffold(body: LiveChip()),
        ),
      );
      await tester.pump();
      expect(find.text('Live'), findsOneWidget);
    });

    testWidgets('StatusChip tidak melebar selebar parent di ListView',
        (tester) async {
      // Regresi QA v1.1.0: chip yang diletakkan langsung di Column atau
      // ListView sempat jadi selebar layar (Container tanpa lebar
      // melebar ke parent), terbukti di layar Akun: chip "Mode lokal"
      // tampil sebagai bar selebar layar, bukan chip kecil seperti
      // spesifikasi bagian 4.3. Yang diukur adalah Container latar
      // chip (bagian yang terlihat), bukan kotak widgetnya: kotaknya
      // memang selebar parent tapi transparan.
      tester.view.physicalSize = const Size(780, 1688);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: Scaffold(
            body: ListView(
              children: const [
                StatusChip(
                  label: 'Mode lokal',
                  icon: Icons.cloud_off,
                  tone: StatusTone.info,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final latar = find.descendant(
        of: find.byType(StatusChip),
        matching: find.byType(Container),
      );
      expect(latar, findsOneWidget);
      final lebar = tester.getSize(latar).width;
      expect(lebar, lessThan(200));
      expect(lebar, greaterThan(50));
    });

    testWidgets('LiveChip tidak melebar selebar parent di ListView',
        (tester) async {
      // LiveChip berdenyut tanpa henti, jadi pumpAndSettle tidak
      // pernah selesai: pakai pump biasa. Descendant Container ada
      // dua (latar chip dan titik denyut); yang pertama dalam urutan
      // tree adalah latar chip.
      tester.view.physicalSize = const Size(780, 1688);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: Scaffold(
            body: ListView(
              children: const [LiveChip()],
            ),
          ),
        ),
      );
      await tester.pump();

      final latar = find.descendant(
        of: find.byType(LiveChip),
        matching: find.byType(Container),
      );
      final lebar = tester.getSize(latar.first).width;
      expect(lebar, lessThan(200));
      expect(lebar, greaterThan(30));
    });

    testWidgets('EmptyState menampilkan judul, pesan, dan aksi',
        (tester) async {
      var ditekan = false;
      await pompaKomponen(
        tester,
        EmptyState(
          icon: Icons.wifi,
          title: 'Belum ada hasil pemeriksaan WiFi',
          message: 'Ketuk Periksa WiFi sekarang untuk mengukur.',
          actions: [
            PrimaryButton(
              label: 'Periksa WiFi sekarang',
              onPressed: () => ditekan = true,
            ),
          ],
        ),
      );

      expect(find.text('Belum ada hasil pemeriksaan WiFi'), findsOneWidget);
      await tester.tap(find.text('Periksa WiFi sekarang'));
      expect(ditekan, isTrue);
    });

    testWidgets('ErrorState menampilkan judul dan tombol Coba lagi',
        (tester) async {
      var ditekan = false;
      await pompaKomponen(
        tester,
        ErrorState(
          title: 'Diagnosis gagal',
          message: 'Tidak ada data perangkat yang bisa dibaca saat ini.',
          onRetry: () => ditekan = true,
        ),
      );

      expect(find.text('Diagnosis gagal'), findsOneWidget);
      expect(find.text('Coba lagi'), findsOneWidget);
      await tester.tap(find.text('Coba lagi'));
      expect(ditekan, isTrue);
    });

    testWidgets('StatusStrip menampilkan teks', (tester) async {
      await pompaKomponen(
        tester,
        const StatusStrip(
          icon: Icons.cloud_off,
          text: 'Mode lokal. Diagnosis memakai data perangkat ini.',
        ),
      );

      expect(
        find.text('Mode lokal. Diagnosis memakai data perangkat ini.'),
        findsOneWidget,
      );
    });

    testWidgets('SectionHeader menampilkan judul', (tester) async {
      await pompaKomponen(
        tester,
        const SectionHeader(title: 'Pemeriksaan terakhir'),
      );

      expect(find.text('Pemeriksaan terakhir'), findsOneWidget);
    });
  });

  group('riwayat linimasa', () {
    late AppDatabase database;

    setUp(() {
      database = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await database.close();
    });

    testWidgets('entri kesehatan dan WiFi bergabung satu linimasa',
        (tester) async {
      final sekarang = DateTime.now();
      final kemarin = sekarang.subtract(const Duration(days: 1));
      await database.simpanHealthCheck(
        HealthChecksCompanion.insert(
          id: 'hc-uji',
          score: 82,
          category: 'baik',
          createdAt: sekarang,
          updatedAt: sekarang,
        ),
      );
      await database.simpanWifiReport(
        WifiReportsCompanion.insert(
          id: 'wr-uji',
          ssid: const Value('ACHA'),
          downloadKbps: const Value(1234.5),
          createdAt: kemarin,
          updatedAt: kemarin,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(home: HistoryPage(database: database)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hari ini'), findsOneWidget);
      expect(find.text('Kemarin'), findsOneWidget);
      expect(find.text('Skor 82 (Baik)'), findsOneWidget);
      expect(find.text('ACHA'), findsOneWidget);
      expect(find.text('1.21 MB/detik'), findsOneWidget);
    });

    testWidgets('riwayat kosong menampilkan dua tombol aksi',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: HistoryPage(database: database)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Belum ada riwayat pemeriksaan'), findsOneWidget);
      expect(find.text('Jalankan diagnosis'), findsOneWidget);
      expect(find.text('Periksa WiFi'), findsOneWidget);
      // Tombol bagikan PDF disembunyikan bila riwayat kosong.
      expect(find.byIcon(Icons.share), findsNothing);
    });
  });

  group('akun', () {
    setUp(() {
      // Mock penyimpanan aman: baca mengembalikan null (PIN belum
      // diatur), tulis berhasil. Tanpa mock, tulis PIN melempar
      // MissingPluginException dan test gagal.
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel(
          'plugins.it_nomads.com/flutter_secure_storage',
        ),
        (call) async => null,
      );
      // Mock local_auth (implementasi MethodChannel di lingkungan
      // tes): tanpa mock ini, panggilan getAvailableBiometrics
      // menggantung dan halaman Akun jatuh ke status galat setelah
      // batas 30 detik. Di perangkat nyata channel ini dijawab
      // plugin, jadi ini hanya soal lingkungan tes.
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
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel(
          'plugins.it_nomads.com/flutter_secure_storage',
        ),
        null,
      );
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/local_auth'),
        null,
      );
    });

    testWidgets('mode lokal menampilkan chip, kelompok, dan kaki versi',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: AuthPage()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mode lokal'), findsOneWidget);
      expect(find.text('PIN aplikasi'), findsOneWidget);
      expect(find.text('PIN belum diatur.'), findsOneWidget);
      expect(find.text('Biometrik'), findsOneWidget);
      // scrollUntilVisible tidak bisa dipakai di sini: TextField PIN
      // punya Scrollable internal sendiri, jadi ada dua Scrollable.
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();
      expect(
        find.text('Perangkat ini tidak mendukung biometrik.'),
        findsOneWidget,
      );
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();
      expect(find.text('Dokter HP v1.1.0'), findsOneWidget);
    });

    testWidgets('kolom digit PIN menerima angka dan menyimpan PIN',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: AuthPage()),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '1234');
      await tester.pump();
      await tester.tap(find.text('Simpan PIN'));
      await tester.pump();
      await tester.pump();

      expect(find.text('PIN berhasil disimpan.'), findsOneWidget);
    });
  });

  group('keamanan', () {
    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('com.adiprmx.dokterhp/native'),
        (call) async {
          if (call.method == 'installedApps') {
            return <dynamic>[
              <String, dynamic>{
                'label': 'Aplikasi Boros',
                'packageName': 'com.contoh.boros',
                'isSystem': false,
                'installTimeMillis': 1700000000000,
                'permissions': <String>[
                  'android.permission.ACCESS_FINE_LOCATION',
                  'android.permission.CAMERA',
                  'android.permission.RECORD_AUDIO',
                  'android.permission.READ_CONTACTS',
                  'android.permission.READ_SMS',
                ],
              },
              <String, dynamic>{
                'label': 'Aplikasi Aman',
                'packageName': 'com.contoh.aman',
                'isSystem': false,
                'installTimeMillis': 1700000000000,
                'permissions': <String>['android.permission.INTERNET'],
              },
            ];
          }
          return null;
        },
      );
    });

    tearDown(() async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('com.adiprmx.dokterhp/native'),
        null,
      );
    });

    testWidgets('ringkasan dan baris aplikasi dengan angka izin',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: SecurityPage()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Aplikasi terpasang'), findsOneWidget);
      expect(find.text('Perlu ditinjau'), findsWidgets);
      // Aplikasi Boros tampil di dua kelompok (tinjau dan semua).
      expect(find.text('Aplikasi Boros'), findsWidgets);
      expect(find.text('Aplikasi Aman'), findsOneWidget);
      expect(find.text('Tinjau'), findsOneWidget);
      expect(find.text('5'), findsWidgets);
      expect(find.text('izin'), findsWidgets);
    });
  });

  group('penyimpanan', () {
    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('com.adiprmx.dokterhp/native'),
        (call) async {
          switch (call.method) {
            case 'storageInfo':
              return <String, dynamic>{
                'totalBytes': 68719476736,
                'freeBytes': 12884901888,
              };
            case 'cacheSizeBytes':
              return 1048576;
            default:
              return null;
          }
        },
      );
    });

    tearDown(() async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('com.adiprmx.dokterhp/native'),
        null,
      );
    });

    testWidgets('angka utama adalah ruang kosong', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: StoragePage()),
      );
      await tester.pumpAndSettle();

      expect(find.text('12.0'), findsOneWidget);
      expect(find.text('GB kosong'), findsOneWidget);
      expect(find.text('Bersihkan cache'), findsOneWidget);
    });
  });

  group('performa', () {
    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('com.adiprmx.dokterhp/native'),
        (call) async => null,
      );
    });

    tearDown(() async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('com.adiprmx.dokterhp/native'),
        null,
      );
    });

    testWidgets('performa menampilkan skeleton saat memuat di tes',
        (tester) async {
      // Di lingkungan widget test, pembacaan /proc/stat tidak pernah
      // selesai tanpa injeksi (alasan di PerformancePage._muat), jadi
      // halaman ini tetap di status memuat, sama seperti golden QA
      // yang juga menangkap status memuat. Yang diuji di sini adalah
      // skeleton-nya, bukan isi meternya.
      await tester.pumpWidget(
        const MaterialApp(home: PerformancePage()),
      );
      await tester.pump();

      expect(find.text('Memuat data performa...'), findsOneWidget);
      expect(find.byType(SkeletonBlock), findsWidgets);
    });
  });
}
