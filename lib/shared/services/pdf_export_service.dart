import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../features/audit_log/audit_log_repository.dart';
import '../domain/models.dart';
import '../providers/admin_providers.dart';

class PdfExportService {
  static const List<String> monthNames = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember'
  ];

  static Future<Uint8List> generateOfficialAbjDocument({
    required int month,
    required int year,
    required List<VillageAbjDetail> villageDetails,
    required List<Report> reports,
    String officialSignatoryName = 'dr. H. Hendro Sutrisno, M.Kes',
    String officialSignatoryNip = '19750812 200212 1 003',
    String officialSignatoryTitle = 'Kepala Dinas Kesehatan Kab. Banyumas',
  }) async {
    final pdf = pw.Document();

    // Load official logo if available
    pw.MemoryImage? logoImage;
    try {
      final logoBytes = await rootBundle.load('assets/images/logo_dinas_banyumas.png');
      logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
    } catch (e) {
      debugPrint('PdfExportService: could not load logo: $e');
    }

    final monthStr = month == 0 ? 'Semua Bulan' : monthNames[month - 1];
    final yearStr = year == 0 ? 'Semua Periode Tahun' : '$year';
    final currentDateStr = DateFormat('d MMMM yyyy', 'id_ID').format(DateTime.now());
    final docNumber = '440/${month.toString().padLeft(2, '0')}${year > 0 ? (year % 100).toString().padLeft(2, '0') : "26"}/DINKES-P2M/ABJ/${DateTime.now().year}';

    // Summary calculations
    int totalInspected = 0;
    int totalPositive = 0;
    int totalFree = 0;

    for (final v in villageDetails) {
      totalInspected += v.totalInspected;
      totalPositive += v.totalPositive;
      totalFree += v.totalFree;
    }

    final double avgAbj = totalInspected > 0
        ? ((totalInspected - totalPositive) / totalInspected) * 100
        : 100.0;
    final int targetMetCount = villageDetails.where((v) => v.isTargetMet).length;
    final int targetFailedCount = villageDetails.where((v) => !v.isTargetMet).length;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 36),
        build: (pw.Context context) {
          return [
            // ── Kop Surat Resmi Dinas Kesehatan ──
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                if (logoImage != null)
                  pw.Container(
                    width: 58,
                    height: 58,
                    margin: const pw.EdgeInsets.only(right: 14),
                    child: pw.Image(logoImage),
                  ),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text(
                        'PEMERINTAH KABUPATEN BANYUMAS',
                        style: pw.TextStyle(
                          fontSize: 13,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      pw.Text(
                        'DINAS KESEHATAN KABUPATEN BANYUMAS',
                        style: pw.TextStyle(
                          fontSize: 15,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900,
                        ),
                      ),
                      pw.Text(
                        'SEKSI PENCEGAHAN DAN PENGENDALIAN PENYAKIT MENULAR (P2M)',
                        style: pw.TextStyle(
                          fontSize: 9.5,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Jl. Dr. Soeparno No. 24, Purwokerto • Telp: (0281) 632738 • Website: dinkes.banyumaskab.go.id',
                        style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            pw.SizedBox(height: 6),

            // Garis Pembatas Kop Surat Ganda (Thick + Thin)
            pw.Container(height: 2, color: PdfColors.black),
            pw.SizedBox(height: 1),
            pw.Container(height: 0.6, color: PdfColors.black),

            pw.SizedBox(height: 14),

            // ── Judul Surat Keputusan / Lembar Dokumen Resmi ──
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(
                    'LEMBAR PENGESAHAN HASIL EVALUASI EPIDEMIOLOGI',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      decoration: pw.TextDecoration.underline,
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'REKAPITULASI PEMERIKSAAN JENTIK & CAPAIAN ANGKA BEBAS JENTIK (ABJ)',
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue900,
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'Nomor Registrasi: $docNumber',
                    style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey800),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 12),

            // Keterangan Parameter Periode
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                border: pw.Border.all(color: PdfColors.grey300),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Wilayah Kerja: Wilayah Puskesmas Gumelar / Kab. Banyumas',
                      style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Periode Pemeriksaan: $monthStr $yearStr',
                      style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                ],
              ),
            ),

            pw.SizedBox(height: 12),

            // ── Ringkasan Indikator Kunci (KPI Box) ──
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.blue200),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                color: PdfColors.blue50,
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _buildPdfKpi('Rata-rata ABJ Wilayah', '${avgAbj.toStringAsFixed(1)}%',
                      avgAbj >= 95 ? PdfColors.green800 : PdfColors.red800),
                  _buildPdfKpi('Total Rumah Diperiksa', '$totalInspected Rumah', PdfColors.blue900),
                  _buildPdfKpi('Rumah Positif Jentik', '$totalPositive Rumah',
                      totalPositive > 0 ? PdfColors.red800 : PdfColors.grey800),
                  _buildPdfKpi('Desa Capai Target', '$targetMetCount dari ${villageDetails.length} Desa',
                      PdfColors.green800),
                ],
              ),
            ),

            pw.SizedBox(height: 14),

            // ── Tabel Rekapitulasi Desa ──
            pw.Text(
              'Tabel Capaian Angka Bebas Jentik per Desa:',
              style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 6),

            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: {
                0: const pw.FixedColumnWidth(24),
                1: const pw.FlexColumnWidth(3),
                2: const pw.FlexColumnWidth(2),
                3: const pw.FlexColumnWidth(2),
                4: const pw.FlexColumnWidth(2),
                5: const pw.FlexColumnWidth(2),
                6: const pw.FlexColumnWidth(2.5),
              },
              children: [
                // Header Row
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.blue100),
                  children: [
                    _buildPdfTableCell('No', isHeader: true, align: pw.TextAlign.center),
                    _buildPdfTableCell('Nama Desa/Kelurahan', isHeader: true),
                    _buildPdfTableCell('Rumah Diperiksa', isHeader: true, align: pw.TextAlign.right),
                    _buildPdfTableCell('Bebas Jentik', isHeader: true, align: pw.TextAlign.right),
                    _buildPdfTableCell('Positif Jentik', isHeader: true, align: pw.TextAlign.right),
                    _buildPdfTableCell('ABJ (%)', isHeader: true, align: pw.TextAlign.right),
                    _buildPdfTableCell('Status Target', isHeader: true, align: pw.TextAlign.center),
                  ],
                ),
                // Data Rows
                ...villageDetails.asMap().entries.map((entry) {
                  final idx = entry.key + 1;
                  final v = entry.value;
                  final statusText = v.isTargetMet
                      ? 'MEMENUHI (≥95%)'
                      : (v.isWarning ? 'WASPADA' : 'RAWAN JENTIK');
                  final statusColor = v.isTargetMet
                      ? PdfColors.green800
                      : (v.isWarning ? PdfColors.orange800 : PdfColors.red800);

                  return pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: idx % 2 == 0 ? PdfColors.grey50 : PdfColors.white,
                    ),
                    children: [
                      _buildPdfTableCell('$idx', align: pw.TextAlign.center),
                      _buildPdfTableCell(v.villageName, isBold: true),
                      _buildPdfTableCell('${v.totalInspected}', align: pw.TextAlign.right),
                      _buildPdfTableCell('${v.totalFree}', align: pw.TextAlign.right),
                      _buildPdfTableCell('${v.totalPositive}',
                          align: pw.TextAlign.right,
                          color: v.totalPositive > 0 ? PdfColors.red800 : PdfColors.grey800),
                      _buildPdfTableCell('${v.abj.toStringAsFixed(1)}%',
                          align: pw.TextAlign.right, isBold: true, color: statusColor),
                      _buildPdfTableCell(statusText,
                          align: pw.TextAlign.center, isBold: true, color: statusColor),
                    ],
                  );
                }),
                // Total Summary Row
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _buildPdfTableCell('', isHeader: true),
                    _buildPdfTableCell('TOTAL KESELURUHAN', isHeader: true),
                    _buildPdfTableCell('$totalInspected', isHeader: true, align: pw.TextAlign.right),
                    _buildPdfTableCell('$totalFree', isHeader: true, align: pw.TextAlign.right),
                    _buildPdfTableCell('$totalPositive',
                        isHeader: true,
                        align: pw.TextAlign.right,
                        color: totalPositive > 0 ? PdfColors.red800 : PdfColors.black),
                    _buildPdfTableCell('${avgAbj.toStringAsFixed(1)}%',
                        isHeader: true,
                        align: pw.TextAlign.right,
                        color: avgAbj >= 95 ? PdfColors.green800 : PdfColors.red800),
                    _buildPdfTableCell(
                        avgAbj >= 95 ? 'MEMENUHI TARGET' : 'DI BAWAH TARGET',
                        isHeader: true,
                        align: pw.TextAlign.center,
                        color: avgAbj >= 95 ? PdfColors.green800 : PdfColors.red800),
                  ],
                ),
              ],
            ),

            pw.SizedBox(height: 14),

            // ── Arahan Medis & Rekomendasi Epidemiologi Standar Kemenkes RI ──
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Catatan Evaluasi & Rekomendasi Program P2M Dinkes:',
                    style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Bullet(
                    text:
                        'Standar Nasional Angka Bebas Jentik (Kemenkes RI) adalah ≥ 95%. Terdapat $targetFailedCount desa yang memerlukan penguatan gerakan PSN 3M Plus serentak.',
                    style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey800),
                  ),
                  pw.Bullet(
                    text:
                        'Desa dengan capaian ABJ di bawah 85% wajib dilakukan Penyelidikan Epidemiologi (PE) serta pembagian larvasida/abatisasi selektif pada penampungan air sulit dikuras.',
                    style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey800),
                  ),
                  pw.Bullet(
                    text:
                        'Penguatan pendataan digital melalui SI KADER PSN dilaksanakan rutin setiap minggu demi pencegahan lonjakan kasus Demam Berdarah Dengue (DBD).',
                    style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey800),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 18),

            // ── Lembar Pengesahan & Tanda Tangan Resmi ──
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                // Digital Verification QR Code Info
                pw.Container(
                  width: 170,
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                    border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.BarcodeWidget(
                        barcode: pw.Barcode.qrCode(),
                        data: 'SIKADERCANTIK-DINKES-BANYUMAS-$docNumber',
                        width: 48,
                        height: 48,
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Keabsahan Dokumen Digital:',
                        style: pw.TextStyle(fontSize: 6.5, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        'Dokumen ini dicetak secara sah melalui SI KADER PSN Dinas Kesehatan Kab. Banyumas.',
                        style: const pw.TextStyle(fontSize: 6, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                ),

                // Kolom Tanda Tangan & Stempel Resmi
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text('Ditetapkan di: Purwokerto', style: const pw.TextStyle(fontSize: 8)),
                    pw.Text('Pada tanggal: $currentDateStr',
                        style: const pw.TextStyle(fontSize: 8)),
                    pw.SizedBox(height: 4),
                    pw.Text('Mengetahui / Mengesahkan,',
                        style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                    pw.Text(officialSignatoryTitle,
                        style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 46), // Space for digital signature / stamp
                    pw.Text(
                      officialSignatoryName,
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        decoration: pw.TextDecoration.underline,
                      ),
                    ),
                    pw.Text('NIP. $officialSignatoryNip',
                        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800)),
                  ],
                ),
              ],
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildPdfTableCell(
    String text, {
    bool isHeader = false,
    bool isBold = false,
    pw.TextAlign align = pw.TextAlign.left,
    PdfColor? color,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: isHeader ? 7.5 : 7,
          fontWeight: (isHeader || isBold) ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color ?? (isHeader ? PdfColors.blue900 : PdfColors.black),
        ),
      ),
    );
  }

  static pw.Widget _buildPdfKpi(String label, String value, PdfColor valueColor) {
    return pw.Column(
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
            color: valueColor,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
        ),
      ],
    );
  }

  static Future<bool> printOrShareOfficialReport({
    required int month,
    required int year,
    required List<VillageAbjDetail> villageDetails,
    required List<Report> reports,
    AuditLogRepository? auditRepo,
  }) async {
    try {
      final pdfBytes = await generateOfficialAbjDocument(
        month: month,
        year: year,
        villageDetails: villageDetails,
        reports: reports,
      );

      final monthStr = month == 0 ? 'Semua-Bulan' : monthNames[month - 1];
      final filename = 'SK-Rekapitulasi-ABJ-$monthStr-${year > 0 ? year : "SemuaTahun"}.pdf';

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
        name: filename,
      );

      // Audit Log
      if (auditRepo != null) {
        await auditRepo.logAction(
          actionType: 'ekspor_data',
          description: 'Mencetak / mengekspor dokumen resmi SK Rekapitulasi ABJ ($monthStr $year).',
          targetId: filename,
        );
      }

      return true;
    } catch (e) {
      debugPrint('PdfExportService: error printing PDF: $e');
      return false;
    }
  }
}
