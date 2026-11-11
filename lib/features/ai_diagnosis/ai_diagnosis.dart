import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dokter_hp/core/app_config.dart';

/// Layanan diagnosis AI via Supabase Edge Function `ai-diagnose`.
///
/// Kunci Gemini TIDAK PERNAH ada di APK — kunci hanya tersimpan sebagai
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
        body: {
          'keluhan': keluhan,
          'data_perangkat': dataPerangkat,
        },
      );
      final data = respons.data;
      if (data is Map<String, dynamic>) {
        final jawaban = data['jawaban'] ?? data['diagnosis'] ?? data['hasil'];
        if (jawaban is String && jawaban.isNotEmpty) return jawaban;
      }
      if (data is String && data.isNotEmpty) return data;
      return 'Server tidak mengembalikan jawaban. Coba lagi.';
    } on FunctionException catch (e) {
      return 'Diagnosis AI gagal: ${e.details ?? e.reasonPhrase ?? e.status}';
    } catch (e) {
      return 'Diagnosis AI gagal: $e';
    }
  }
}

/// Layar Diagnosis AI: kirim keluhan + ringkasan data perangkat ke
/// Edge Function dan tampilkan jawabannya.
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

  @override
  void dispose() {
    _keluhanController.dispose();
    super.dispose();
  }

  Future<void> _kirim() async {
    final keluhan = _keluhanController.text.trim();
    if (keluhan.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tulis keluhan dulu.')),
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
        padding: const EdgeInsets.all(16),
        children: [
          if (!AppConfig.isSupabaseConfigured)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Mode lokal, belum tersambung ke server. Diagnosis AI '
                  'membutuhkan server Supabase dan belum bisa dipakai.',
                ),
              ),
            ),
          TextField(
            controller: _keluhanController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Jelaskan keluhan HP',
              hintText: 'Contoh: WiFi lemot padahal sinyal penuh',
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _memuat ? null : _kirim,
            icon: const Icon(Icons.psychology),
            label: Text(_memuat ? 'Meminta diagnosis...' : 'Minta diagnosis'),
          ),
          if (_memuat)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: LinearProgressIndicator(
                backgroundColor: Colors.black12,
                color: Colors.black,
              ),
            ),
          if (_jawaban != null) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(_jawaban!),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Jawaban AI adalah saran, bukan vonis pasti. Cocokkan dengan '
              'hasil ukur di Dokter WiFi dan dokter lainnya.',
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ],
      ),
    );
  }
}
