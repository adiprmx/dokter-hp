import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dokter_hp/core/app_config.dart';
import 'package:dokter_hp/core/theme.dart';
import 'package:dokter_hp/core/widgets/common_widgets.dart';

/// Layanan diagnosis AI via Supabase Edge Function `ai-diagnose`.
///
/// Kunci Gemini TIDAK PERNAH ada di APK, kunci hanya tersimpan sebagai
/// secret di sisi server Supabase. Bila Supabase belum terkonfigurasi,
/// layanan mengembalikan pesan jujur dan fitur tidak dipalsukan.
class AiDiagnosisService {
  Future<String> mintaDiagnosis({
    required String keluhan,
    required Map<String, dynamic> dataPerangkat,
  }) async {
    if (!AppConfig.isSupabaseConfigured) {
      return 'Diagnosis AI belum tersedia: aplikasi berjalan dalam mode '
          'lokal dan belum tersambung ke server.';
    }
    try {
      final respons = await Supabase.instance.client.functions.invoke(
        AppConfig.aiDiagnoseFunction,
        // Nama field WAJIB cocok dengan Edge Function ai-diagnose
        // (supabase/functions/ai-diagnose/index.ts): `gejala` dan
        // `hasil_pemeriksaan`. Sebelum perbaikan ini Dart mengirim
        // `keluhan`/`data_perangkat` sehingga function selalu menolak
        // dengan 400 "Kolom 'gejala' wajib diisi".
        body: {
          'gejala': keluhan,
          'hasil_pemeriksaan': dataPerangkat,
        },
      );
      final data = respons.data;
      if (data is Map<String, dynamic>) {
        final jawaban = data['jawaban'] ?? data['diagnosis'] ?? data['hasil'];
        if (jawaban is String && jawaban.isNotEmpty) return jawaban;
      }
      if (data is String && data.isNotEmpty) return data;
      return 'Server tidak mengembalikan jawaban. Coba lagi.';
    } on FunctionException catch (_) {
      return 'Diagnosis AI gagal. Coba lagi.';
    } catch (_) {
      return 'Diagnosis AI gagal. Coba lagi.';
    }
  }
}

/// Layar Diagnosis AI v1.1.0: kirim keluhan + ringkasan data perangkat
/// ke Edge Function dan tampilkan jawabannya.
class AiDiagnosisPage extends StatefulWidget {
  const AiDiagnosisPage({super.key});

  @override
  State<AiDiagnosisPage> createState() => _AiDiagnosisPageState();
}

class _AiDiagnosisPageState extends State<AiDiagnosisPage> {
  final _keluhanController = TextEditingController();
  final _service = AiDiagnosisService();
  String? _jawaban;
  bool _memuat = false;

  bool get _jawabanGagal =>
      _jawaban != null &&
      (_jawaban!.startsWith('Diagnosis AI gagal') ||
          _jawaban!.startsWith('Server tidak mengembalikan jawaban'));

  @override
  void dispose() {
    _keluhanController.dispose();
    super.dispose();
  }

  Future<void> _kirim() async {
    final keluhan = _keluhanController.text.trim();
    if (keluhan.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          duration: Duration(seconds: 3),
          content: Text('Tulis keluhan dulu.'),
        ),
      );
      return;
    }
    setState(() {
      _memuat = true;
      _jawaban = null;
    });
    final jawaban = await _service.mintaDiagnosis(
      keluhan: keluhan,
      dataPerangkat: const {},
    );
    if (!mounted) return;
    setState(() {
      _jawaban = jawaban;
      _memuat = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Diagnosis AI')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.pagePadding,
          AppTheme.pagePadding,
          AppTheme.pagePadding,
          AppTheme.bottomPadding,
        ),
        children: [
          if (!AppConfig.isSupabaseConfigured) ...[
            const StatusStrip(
              icon: Icons.cloud_off,
              text: 'Mode lokal, belum tersambung ke server. Diagnosis '
                  'AI membutuhkan server Supabase dan belum bisa dipakai.',
            ),
            const SizedBox(height: 20),
          ],
          const Text('Keluhan HP', style: AppTheme.label),
          const SizedBox(height: 8),
          TextField(
            controller: _keluhanController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Contoh: WiFi lemot padahal sinyal penuh',
            ),
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: _memuat ? 'Meminta diagnosis' : 'Minta diagnosis',
            icon: Icons.psychology,
            onPressed: _memuat ? null : _kirim,
          ),
          if (_memuat) ...[
            const SizedBox(height: 16),
            const LinearProgressIndicator(),
            const SizedBox(height: 8),
            Text(
              'Meminta diagnosis...',
              style: AppTheme.body.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ],
          if (_jawaban != null) ...[
            const SizedBox(height: 24),
            if (_jawabanGagal)
              ErrorState(
                title: 'Diagnosis AI gagal',
                message: _jawaban!.startsWith('Server tidak mengembalikan')
                    ? _jawaban!
                    : 'Periksa sambungan internet, lalu coba lagi.',
                onRetry: _kirim,
              )
            else ...[
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Saran diagnosis',
                      style: AppTheme.section,
                    ),
                    const SizedBox(height: 12),
                    Text(_jawaban!, style: AppTheme.body),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const StatusStrip(
                icon: Icons.info_outline,
                iconColor: AppTheme.info,
                text: 'Jawaban AI adalah saran, bukan vonis pasti. '
                    'Cocokkan dengan hasil ukur di Dokter WiFi dan '
                    'dokter lainnya.',
              ),
            ],
          ],
        ],
      ),
    );
  }
}
