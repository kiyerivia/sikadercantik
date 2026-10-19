import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:printing/printing.dart';
import '../../features/audit_log/audit_log_repository.dart';
import '../providers/admin_providers.dart';
import '../providers/report_providers.dart';
import '../services/pdf_export_service.dart';

class OfficialPdfExportDialog extends ConsumerStatefulWidget {
  final int initialMonth;
  final int initialYear;

  const OfficialPdfExportDialog({
    super.key,
    this.initialMonth = 0,
    this.initialYear = 0,
  });

  @override
  ConsumerState<OfficialPdfExportDialog> createState() =>
      _OfficialPdfExportDialogState();
}

class _OfficialPdfExportDialogState
    extends ConsumerState<OfficialPdfExportDialog> {
  late int _selectedMonth;
  late int _selectedYear;
  bool _isGenerating = false;

  final TextEditingController _nameController =
      TextEditingController(text: 'dr. H. Hendro Sutrisno, M.Kes');
  final TextEditingController _nipController =
      TextEditingController(text: '19750812 200212 1 003');
  final TextEditingController _titleController =
      TextEditingController(text: 'Kepala Dinas Kesehatan Kab. Banyumas');

  @override
  void initState() {
    super.initState();
    _selectedMonth = widget.initialMonth;
    _selectedYear = widget.initialYear;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nipController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final villageDetailsAsync = ref.watch(villageAbjDetailsProvider);
    final allReportsAsync = ref.watch(allReportsProvider);

    final currentYear = DateTime.now().year;
    final yearOptions = [
      {'val': 0, 'label': 'Semua Tahun'},
      ...List.generate(5, (i) => {'val': currentYear - 2 + i, 'label': '${currentYear - 2 + i}'}),
    ];

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 520,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2FE),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.picture_as_pdf_rounded,
                      color: Color(0xFF0284C7),
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cetak Laporan PDF Resmi (SK Dinas)',
                          style: GoogleFonts.outfit(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF10365F),
                          ),
                        ),
                        Text(
                          'Dokumen resmi siap cetak berlogo Pemkab Banyumas & pengesahan',
                          style: GoogleFonts.outfit(
                            fontSize: 11.5,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              const Divider(height: 24),

              // Filter Periode Row
              Text(
                '1. Periode Rekapitulasi Laporan:',
                style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  // Month Picker
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: _selectedMonth,
                          isExpanded: true,
                          items: [
                            const DropdownMenuItem(value: 0, child: Text('Semua Bulan')),
                            ...List.generate(
                              12,
                              (i) => DropdownMenuItem(
                                value: i + 1,
                                child: Text(PdfExportService.monthNames[i]),
                              ),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedMonth = val);
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Year Picker
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: _selectedYear,
                          isExpanded: true,
                          items: yearOptions.map((item) {
                            return DropdownMenuItem<int>(
                              value: item['val'] as int,
                              child: Text(item['label'] as String),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedYear = val);
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Signatory Customization
              Text(
                '2. Lembar Pengesahan & Pejabat Penandatangan:',
                style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              Text('Nama Lengkap & Gelar:',
                  style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey.shade600)),
              const SizedBox(height: 4),
              TextField(
                controller: _nameController,
                style: GoogleFonts.outfit(fontSize: 13),
                decoration: InputDecoration(
                  isDense: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
              ),

              const SizedBox(height: 8),

              Text('NIP Pejabat:',
                  style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey.shade600)),
              const SizedBox(height: 4),
              TextField(
                controller: _nipController,
                style: GoogleFonts.outfit(fontSize: 13),
                decoration: InputDecoration(
                  isDense: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
              ),

              const SizedBox(height: 8),

              Text('Jabatan Resmi:',
                  style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey.shade600)),
              const SizedBox(height: 4),
              TextField(
                controller: _titleController,
                style: GoogleFonts.outfit(fontSize: 13),
                decoration: InputDecoration(
                  isDense: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
              ),

              const SizedBox(height: 18),

              // Feature Highlights Banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified_user_outlined,
                        color: Color(0xFF0284C7), size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Format PDF otomatis menyertakan Kop Resmi Pemkab Banyumas, Rekapitulasi se-Kabupaten, Evaluasi Risiko, QR Code Keabsahan, dan Kolom Tanda Tangan.',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: const Color(0xFF334155),
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Batal',
                        style: GoogleFonts.outfit(color: Colors.grey)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: _isGenerating
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.print_rounded, size: 18),
                    label: Text(
                      _isGenerating ? 'Menyiapkan PDF...' : 'Cetak / Unduh PDF',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                    ),
                    onPressed: _isGenerating
                        ? null
                        : () async {
                            final messenger = ScaffoldMessenger.of(context);
                            final navigator = Navigator.of(context);
                            setState(() => _isGenerating = true);
                            try {
                              final villages = villageDetailsAsync.value ?? [];
                              final reports = allReportsAsync.value ?? [];
                              final auditRepo = ref.read(auditLogRepositoryProvider);

                              final filteredReports = reports.where((r) {
                                final matchMonth = _selectedMonth == 0 ||
                                    r.reportDate.month == _selectedMonth;
                                final matchYear = _selectedYear == 0 ||
                                    r.reportDate.year == _selectedYear;
                                return matchMonth && matchYear;
                              }).toList();

                              final pdfBytes =
                                  await PdfExportService.generateOfficialAbjDocument(
                                month: _selectedMonth,
                                year: _selectedYear,
                                villageDetails: villages,
                                reports: filteredReports,
                                officialSignatoryName: _nameController.text.trim(),
                                officialSignatoryNip: _nipController.text.trim(),
                                officialSignatoryTitle: _titleController.text.trim(),
                              );

                              final monthStr = _selectedMonth == 0
                                  ? 'Semua-Bulan'
                                  : PdfExportService.monthNames[_selectedMonth - 1];
                              final filename =
                                  'SK-Dinkes-ABJ-$monthStr-${_selectedYear > 0 ? _selectedYear : "Kumulatif"}.pdf';

                              await Printing.layoutPdf(
                                onLayout: (format) async => pdfBytes,
                                name: filename,
                              );

                              await auditRepo.logAction(
                                actionType: 'ekspor_data',
                                description:
                                    'Menerbitkan dan mencetak Dokumen SK Rekapitulasi ABJ ($monthStr $_selectedYear).',
                                targetId: filename,
                              );

                              navigator.pop();
                            } catch (e) {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text('Gagal membuat PDF: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            } finally {
                              if (mounted) {
                                setState(() => _isGenerating = false);
                              }
                            }
                          },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
