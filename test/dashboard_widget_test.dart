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
    await tester.pumpAndSettle();

    expect(find.text('Dokter HP'), findsWidgets);
    expect(find.text('Belum ada skor kesehatan'), findsOneWidget);
    expect(find.text('Diagnosis satu ketuk'), findsOneWidget);
    expect(
      find.text('Mode lokal. Diagnosis memakai data perangkat ini.'),
      findsOneWidget,
    );
    expect(find.text('Dokter WiFi'), findsOneWidget);
    // Sel grid di bawah lipatan baru dibangun setelah digulir.
    await tester.scrollUntilVisible(find.text('Dokter Baterai'), 200);
    expect(find.text('Dokter Baterai'), findsOneWidget);
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
    await tester.pumpAndSettle();

    await tester.tap(find.text('Diagnosis satu ketuk'));
    await tester.pump();
    // Diagnosis selesai (dengan data kosong di lingkungan tes, hasilnya
    // gagal jujur) atau masih berjalan. Yang penting tidak crash.
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Dokter HP'), findsWidgets);
  });

  testWidgets('ketuk kartu Dokter WiFi membuka halaman WiFi', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: DashboardPage(database: database)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Dokter WiFi'));
    await tester.pumpAndSettle();

    expect(find.text('Periksa WiFi sekarang'), findsOneWidget);
    expect(find.text('Belum ada hasil pemeriksaan WiFi'), findsOneWidget);
  });

  testWidgets('riwayat tersimpan tampil di kelompok pemeriksaan terakhir',
      (tester) async {
    final sekarang = DateTime.now();
    await database.simpanHealthCheck(
      HealthChecksCompanion.insert(
        id: 'hc-uji',
        score: 82,
        category: 'baik',
        createdAt: sekarang,
        updatedAt: sekarang,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(home: DashboardPage(database: database)),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Pemeriksaan terakhir'),
      200,
    );
    expect(find.text('Pemeriksaan terakhir'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Skor 82 (Baik)'), 200);
    expect(find.text('Skor 82 (Baik)'), findsOneWidget);
  });
}
