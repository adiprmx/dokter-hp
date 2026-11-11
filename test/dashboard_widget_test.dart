import 'package:dokter_hp/data/local/app_database.dart';
import 'package:dokter_hp/features/dashboard/dashboard_page.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  testWidgets('dashboard menampilkan judul dan empty state jujur',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: DashboardPage(database: database)),
    );
    await tester.pump();

    expect(find.text('Dokter HP'), findsWidgets);
    expect(find.text('Belum ada data pemeriksaan'), findsOneWidget);
    expect(find.text('Diagnosis satu ketuk'), findsOneWidget);
    expect(find.textContaining('Mode lokal, belum tersambung ke server'),
        findsOneWidget);
    expect(find.text('Dokter WiFi'), findsOneWidget);
    expect(find.text('Dokter Baterai'), findsOneWidget);
    // Kartu di bawah lipatan baru dibangun ListView setelah digulir.
    await tester.scrollUntilVisible(
      find.text('Dokter Penyimpanan'),
      200,
    );
    expect(find.text('Dokter Penyimpanan'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Dokter Performa'), 200);
    expect(find.text('Dokter Performa'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Dokter Keamanan'), 200);
    expect(find.text('Dokter Keamanan'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Diagnosis AI'), 200);
    expect(find.text('Diagnosis AI'), findsOneWidget);
  });

  testWidgets('diagnosis satu ketuk berjalan tanpa crash di lingkungan tes',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: DashboardPage(database: database)),
    );
    await tester.pump();

    await tester.tap(find.text('Diagnosis satu ketuk'));
    await tester.pump();
    // Diagnosis selesai (dengan data kosong di lingkungan tes, hasilnya
    // gagal jujur) atau masih berjalan — yang penting tidak crash.
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Dokter HP'), findsWidgets);
  });

  testWidgets('ketuk kartu Dokter WiFi membuka halaman WiFi', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: DashboardPage(database: database)),
    );
    await tester.pump();

    await tester.tap(find.text('Dokter WiFi'));
    await tester.pumpAndSettle();

    expect(find.text('Periksa WiFi sekarang'), findsOneWidget);
    expect(find.text('Belum ada data pemeriksaan'), findsOneWidget);
  });
}
