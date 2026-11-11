import 'package:dokter_hp/data/local/app_database.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Pembuat laporan PDF dari riwayat pemeriksaan.
///
/// Laporan hanya berisi data yang benar-benar tercatat. Bila riwayat
/// kosong, laporan tidak dibuat — pemanggil menampilkan empty state.
class PdfReportService {
  PdfReportService({required this.database});

  final AppDatabase database;

  Future<void> bagikanLaporan() async {
    final riwayat = await database.healthChecksAktif();
    final wifi = await database.wifiReportsAktif();
    final dokumen = pw.Document();
    dokumen.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              'Laporan Dokter HP',
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.Text(
            'Dibuat: ${DateTime.now().toLocal()}',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.SizedBox(height: 16),
          pw.Text(
            'Riwayat pemeriksaan kesehatan',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          if (riwayat.isEmpty)
            pw.Text('Belum ada data pemeriksaan.')
          else
            pw.TableHelper.fromTextArray(
              headers: const ['Tanggal', 'Skor', 'Kategori'],
              data: riwayat
                  .map(
                    (item) => [
                      item.createdAt.toLocal().toString(),
                      '${item.score}',
                      item.category,
                    ],
                  )
                  .toList(),
            ),
          pw.SizedBox(height: 16),
          pw.Text(
            'Riwayat pemeriksaan WiFi',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          if (wifi.isEmpty)
            pw.Text('Belum ada data pemeriksaan WiFi.')
          else
            pw.TableHelper.fromTextArray(
              headers: const ['Tanggal', 'SSID', 'Unduh (KB/dtk)', 'Latensi'],
              data: wifi
                  .map(
                    (item) => [
                      item.createdAt.toLocal().toString(),
                      item.ssid ?? '-',
                      item.downloadKbps == null
                          ? '-'
                          : item.downloadKbps!.toStringAsFixed(1),
                      item.pingMs == null ? '-' : '${item.pingMs} ms',
                    ],
                  )
                  .toList(),
            ),
        ],
      ),
    );
    await Printing.sharePdf(
      bytes: await dokumen.save(),
      filename: 'laporan-dokter-hp.pdf',
    );
  }
}
