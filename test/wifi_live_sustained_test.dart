import 'dart:io';

import 'package:dokter_hp/data/local/app_database.dart';
import 'package:dokter_hp/features/wifi_doctor/wifi_cubit.dart';
import 'package:dokter_hp/features/wifi_doctor/wifi_doctor_page.dart';
import 'package:dokter_hp/features/wifi_doctor/wifi_service.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Server lokal untuk test: melayani file 1 MB di /1mb dan 100 KB di
/// /100kb, supaya tes bertahan dan probe live bisa jalan tanpa internet.
Future<HttpServer> _serverLokal() async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  server.listen((request) async {
    final ukuran = request.uri.path == '/100kb' ? 100 * 1024 : 1024 * 1024;
    request.response.headers.contentType = ContentType.binary;
    request.response.add(List<int>.filled(ukuran, 0));
    await request.response.close();
  });
  return server;
}

/// Override HttpClient polos: implementasi dasar [HttpOverrides]
/// mengembalikan HttpClient asli (bukan mock flutter_test).
class _HttpAsliOverrides extends HttpOverrides {}

/// Jalankan [body] dengan HttpClient asli: flutter_test mengganti
/// HttpClient global dengan mock yang selalu mengembalikan 400, jadi
/// tes yang butuh jaringan nyata (server lokal) harus keluar dari mock
/// itu. Dipakai di semua test yang menyentuh jaringan.
Future<T> _denganHttpAsli<T>(Future<T> Function() body) {
  return HttpOverrides.runWithHttpOverrides(body, _HttpAsliOverrides());
}

void main() {
  group('SustainedTestResult.tentukanVerdict', () {
    test('bertahan: rata-rata di atas 1000 dan tidak ada sampel di bawah '
        '200 setelah detik ke-3', () {
      final samples = List<double>.filled(30, 2500);
      expect(
        SustainedTestResult.tentukanVerdict(samples),
        SustainedVerdict.bertahan,
      );
      final hasil = SustainedTestResult.dariSampel(samples);
      expect(hasil.verdict, SustainedVerdict.bertahan);
      expect(hasil.rataRataKbps, 2500);
      expect(hasil.terendahKbps, 2500);
      expect(hasil.tertinggiKbps, 2500);
      expect(hasil.samples.length, 30);
    });

    test('jatuh: mulai cepat lalu ada sampel di bawah 200 setelah '
        'detik ke-3', () {
      final samples = <double>[
        3000, 2800, 2600, 1500, 800, 150, 120, 90, 80, 70,
        60, 50, 40, 30, 20, 15, 10, 8, 5, 4,
        3, 2, 2, 1, 1, 1, 1, 1, 1, 1,
      ];
      expect(
        SustainedTestResult.tentukanVerdict(samples),
        SustainedVerdict.jatuh,
      );
      expect(
        SustainedTestResult.dariSampel(samples).verdict.label,
        'Kecepatan jatuh di tengah jalan',
      );
    });

    test('tidakStabil: rata-rata di bawah 1000 tanpa sampel jatuh', () {
      final samples = List<double>.filled(30, 500);
      expect(
        SustainedTestResult.tentukanVerdict(samples),
        SustainedVerdict.tidakStabil,
      );
      expect(
        SustainedTestResult.dariSampel(samples).verdict.label,
        'Kecepatan tidak stabil',
      );
    });

    test('tidakStabil: ada sampel jatuh tapi awal tidak pernah cepat', () {
      // Awal lambat (< 1000) dan ada sampel di bawah 200 setelah detik
      // ke-3: bukan "jatuh" karena tidak pernah mulai cepat.
      final samples = <double>[
        400, 350, 300, 250, 150, 100, 200, 300, 250, 150,
        100, 200, 300, 250, 150, 100, 200, 300, 250, 150,
        100, 200, 300, 250, 150, 100, 200, 300, 250, 150,
      ];
      expect(
        SustainedTestResult.tentukanVerdict(samples),
        SustainedVerdict.tidakStabil,
      );
    });

    test('sampel rendah pada detik 1-3 (masa pemanasan) tidak '
        'menggagalkan bertahan', () {
      final samples = <double>[
        100, 150, 120,
        ...List<double>.filled(27, 2500),
      ];
      expect(
        SustainedTestResult.tentukanVerdict(samples),
        SustainedVerdict.bertahan,
      );
    });

    test('batas: rata-rata tepat 1000 tetap bertahan', () {
      final samples = List<double>.filled(30, 1000);
      expect(
        SustainedTestResult.tentukanVerdict(samples),
        SustainedVerdict.bertahan,
      );
    });

    test('batas: sampel tepat 200 setelah detik ke-3 bukan jatuh', () {
      // Satu sampel tepat 200 (bukan di bawah 200) dan rata-rata di
      // atas 1000: tetap bertahan.
      final samples = List<double>.filled(30, 1030);
      samples[10] = 200;
      expect(
        SustainedTestResult.tentukanVerdict(samples),
        SustainedVerdict.bertahan,
      );
    });

    test('sampel kosong: verdict null dan factory menolak', () {
      expect(SustainedTestResult.tentukanVerdict([]), isNull);
      expect(
        () => SustainedTestResult.dariSampel([]),
        throwsArgumentError,
      );
    });

    test('getter min, rata-rata, dan maks dihitung dari sampel nyata', () {
      final hasil = SustainedTestResult.dariSampel([100, 2000, 3000]);
      expect(hasil.terendahKbps, 100);
      expect(hasil.tertinggiKbps, 3000);
      expect(hasil.rataRataKbps, closeTo(1700, 0.001));
    });
  });

  group('WifiDoctorService.measureSustainedSpeed', () {
    late HttpServer server;

    setUp(() async {
      server = await _serverLokal();
    });

    tearDown(() async {
      await server.close(force: true);
    });

    test('mencatat satu sampel per detik dari server lokal', () async {
      await _denganHttpAsli(() async {
        final service = WifiDoctorService();
        final detikTerlihat = <int>[];
        final hasil = await service.measureSustainedSpeed(
          durationSeconds: 3,
          urls: ['http://127.0.0.1:${server.port}/1mb'],
          onSample: (detik, kbps) => detikTerlihat.add(detik),
        );
        expect(hasil, isNotNull);
        expect(hasil!.samples.length, 3);
        expect(detikTerlihat, [1, 2, 3]);
        expect(hasil.rataRataKbps, greaterThan(0));
      });
    });

    test('cekBerhenti menghentikan tes dan mengembalikan sampel yang '
        'sudah ada', () async {
      await _denganHttpAsli(() async {
        final service = WifiDoctorService();
        var sampelPertama = false;
        final hasil = await service.measureSustainedSpeed(
          durationSeconds: 30,
          urls: ['http://127.0.0.1:${server.port}/1mb'],
          onSample: (detik, kbps) => sampelPertama = true,
          cekBerhenti: () => sampelPertama,
        );
        expect(hasil, isNotNull);
        expect(hasil!.samples.length, greaterThanOrEqualTo(1));
        expect(hasil.samples.length, lessThan(30));
      });
    });

    test('gagal total (tidak ada sampel) mengembalikan null, bukan angka '
        'palsu', () async {
      await _denganHttpAsli(() async {
        final service = WifiDoctorService();
        final hasil = await service.measureSustainedSpeed(
          durationSeconds: 2,
          urls: ['http://127.0.0.1:1/tidak-ada'],
        );
        expect(hasil, isNull);
      });
    });
  });

  group('WifiCubit pantau live', () {
    late HttpServer server;

    setUp(() async {
      server = await _serverLokal();
    });

    tearDown(() async {
      await server.close(force: true);
    });

    test('probe live memperbarui kecepatan dan close membatalkan timer',
        () async {
      await _denganHttpAsli(() async {
        final cubit = WifiCubit(
          liveProbeUrl: 'http://127.0.0.1:${server.port}/100kb',
        );
        cubit.alihkanPantauLive(true);
        await Future.delayed(const Duration(seconds: 3));
        expect(cubit.state.pantauLive, isTrue);
        expect(cubit.state.liveHasil?.downloadKbps, isNotNull);
        expect(cubit.state.liveHasil!.downloadKbps!, greaterThan(0));
        await cubit.close();
        expect(cubit.isClosed, isTrue);
        // Setelah ditutup, timer tidak boleh melempar saat tick berikutnya.
        await Future.delayed(const Duration(seconds: 3));
      });
    });

    test('mematikan pemantau live menghentikan pembaruan', () async {
      await _denganHttpAsli(() async {
        final cubit = WifiCubit(
          liveProbeUrl: 'http://127.0.0.1:${server.port}/100kb',
        );
        cubit.alihkanPantauLive(true);
        await Future.delayed(const Duration(seconds: 1));
        expect(cubit.state.pantauLive, isTrue);
        cubit.alihkanPantauLive(false);
        expect(cubit.state.pantauLive, isFalse);
        await cubit.close();
      });
    });
  });

  group('WifiDoctorPage kartu baru', () {
    late AppDatabase database;

    setUp(() {
      database = AppDatabase.forTesting(NativeDatabase.memory());
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

    testWidgets('tombol tes bertahan, sakelar pantau live, dan judul '
        'kartu panduan muncul', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: WifiDoctorPage(database: database)),
      );
      await tester.pump();

      // ListView membangun anak secara malas: tiap kartu di-scroll dulu
      // sampai terlihat, baru diperiksa. Urutan penting: teks kuota
      // diperiksa selagi kartu live masih terlihat, sebelum scroll
      // lebih jauh ke bawah membuangnya dari tree.
      await tester.scrollUntilVisible(find.text('Pantau live'), 200);
      await tester.pump();
      expect(find.text('Pantau live'), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);
      // Penjelasan kuota pemantau live tampil jujur di layar.
      expect(find.textContaining('600 KB per menit'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.widgetWithText(FilledButton, 'Tes bertahan 30 detik'),
        200,
      );
      await tester.pump();
      // Judul kartu + label tombol memakai teks yang sama.
      expect(find.text('Tes bertahan 30 detik'), findsWidgets);

      await tester.scrollUntilVisible(
        find.text('WiFi turun ke KB/detik? Cek dulu sebelum panik'),
        200,
      );
      await tester.pump();
      expect(
        find.text('WiFi turun ke KB/detik? Cek dulu sebelum panik'),
        findsOneWidget,
      );
      // Isi kartu panduan disalin kata per kata dari dokumen.
      expect(
        find.textContaining('Putar video 1080p selama 1 menit'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Lupakan jaringan, sambung ulang'),
        findsOneWidget,
      );
    });
  });
}
