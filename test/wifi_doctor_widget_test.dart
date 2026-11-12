import 'package:dokter_hp/data/local/app_database.dart';
import 'package:dokter_hp/features/wifi_doctor/wifi_doctor_page.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    // Mock channel connectivity_plus: perangkat tidak tersambung ke
    // jaringan apa pun. Tanpa mock, panggilan channel yang tidak
    // terdaftar menggantung di lingkungan widget test.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/connectivity'),
      (call) async {
        if (call.method == 'check') return <String>['none'];
        return null;
      },
    );
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/connectivity'),
      null,
    );
    await database.close();
  });

  testWidgets('halaman WiFi menampilkan empty state jujur sebelum periksa',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: WifiDoctorPage(database: database)),
    );
    await tester.pump();

    expect(find.text('Dokter WiFi'), findsOneWidget);
    expect(find.text('Periksa WiFi sekarang'), findsOneWidget);
    expect(find.text('Belum ada hasil pemeriksaan WiFi'), findsOneWidget);
    expect(
      find.text('Hasil dari perangkat ini, bukan angka contoh.'),
      findsOneWidget,
    );
  });

  testWidgets(
      'tanpa sambungan WiFi, pemeriksaan gagal dengan pesan jujur',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: WifiDoctorPage(database: database)),
    );
    await tester.pump();

    // Di lingkungan tes tidak ada platform channel Connectivity, jadi
    // pemeriksaan dianggap tidak tersambung dan gagal secara jujur.
    await tester.tap(find.text('Periksa WiFi sekarang'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(
      find.textContaining('tidak tersambung ke WiFi'),
      findsOneWidget,
    );
  });

  testWidgets('panel live, tes bertahan, dan panduan tampil sebelum periksa',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: WifiDoctorPage(database: database)),
    );
    await tester.pump();

    await tester.scrollUntilVisible(find.text('Pantau live'), 200);
    expect(find.text('Pantau live'), findsOneWidget);
    // 'Tes bertahan 30 detik' muncul dua kali (judul bagian dan
    // tombol), jadi gulir ke yang pertama.
    await tester.scrollUntilVisible(
      find.text('Tes bertahan 30 detik').first,
      200,
    );
    expect(find.text('Tes bertahan 30 detik'), findsWidgets);
    await tester.scrollUntilVisible(
      find.text('WiFi turun ke KB/detik? Cek dulu sebelum panik'),
      200,
    );
    expect(
      find.text('WiFi turun ke KB/detik? Cek dulu sebelum panik'),
      findsOneWidget,
    );
    // Teks panduan verbatim dari docs/panduan-wifi-turun.md.
    expect(
      find.text(
        'Putar video 1080p selama 1 menit sambil memperhatikan angka kecepatan.',
      ),
      findsOneWidget,
    );
  });
}
