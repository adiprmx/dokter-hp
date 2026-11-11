import 'package:dokter_hp/features/auth/lock_gate.dart';
import 'package:dokter_hp/features/auth/pin_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// PIN palsu untuk test gerbang kunci: tidak menyentuh penyimpanan
/// aman perangkat sama sekali.
class PinServicePalsu extends PinService {
  PinServicePalsu({
    this.pinDiatur = false,
    this.pinBenar = '1234',
    this.bioAktif = false,
  });

  bool pinDiatur;
  String pinBenar;
  bool bioAktif;

  @override
  Future<bool> get pinSudahDiatur async => pinDiatur;

  @override
  Future<bool> periksaPin(String pin) async => pin == pinBenar;

  @override
  Future<bool> get biometrikAktif async => bioAktif;

  @override
  Future<bool> autentikasiBiometrik() async => false;
}

void main() {
  Future<void> pompaGerbang(
    WidgetTester tester,
    PinService pinService,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LockGate(
          pinService: pinService,
          child: const Text('Isi dashboard'),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('PIN belum diatur: dashboard langsung tampil tanpa kunci',
      (tester) async {
    await pompaGerbang(tester, PinServicePalsu(pinDiatur: false));
    expect(find.text('Isi dashboard'), findsOneWidget);
    expect(find.text('Dokter HP terkunci'), findsNothing);
  });

  testWidgets('PIN sudah diatur: layar kunci tampil, dashboard tertutup',
      (tester) async {
    await pompaGerbang(tester, PinServicePalsu(pinDiatur: true));
    expect(find.text('Dokter HP terkunci'), findsOneWidget);
    expect(find.text('Isi dashboard'), findsNothing);
    expect(find.text('Lupa PIN?'), findsOneWidget);
  });

  testWidgets('PIN salah ditolak, PIN benar membuka dashboard',
      (tester) async {
    await pompaGerbang(tester, PinServicePalsu(pinDiatur: true));

    await tester.enterText(find.byType(TextField), '0000');
    await tester.tap(find.text('Buka kunci'));
    await tester.pumpAndSettle();
    expect(find.textContaining('PIN salah'), findsOneWidget);
    expect(find.text('Isi dashboard'), findsNothing);

    await tester.enterText(find.byType(TextField), '1234');
    await tester.tap(find.text('Buka kunci'));
    await tester.pumpAndSettle();
    expect(find.text('Isi dashboard'), findsOneWidget);
    expect(find.text('Dokter HP terkunci'), findsNothing);
  });

  testWidgets('dialog Lupa PIN menjelaskan jalan pemulihan',
      (tester) async {
    await pompaGerbang(tester, PinServicePalsu(pinDiatur: true));
    await tester.tap(find.text('Lupa PIN?'));
    await tester.pumpAndSettle();
    expect(find.text('Lupa PIN?'), findsWidgets);
    expect(find.textContaining('Hapus data'), findsOneWidget);
    expect(
      find.textContaining('tidak ada jalan reset lewat server'),
      findsOneWidget,
    );
  });
}
