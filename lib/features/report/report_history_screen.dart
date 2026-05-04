import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../shared/providers/report_providers.dart';
import '../../shared/providers/master_providers.dart';
import '../../shared/providers/auth_providers.dart';
import '../../shared/domain/models.dart';

class ReportHistoryScreen extends HookConsumerWidget {
  const ReportHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(myReportsProvider);
    final villagesAsync = ref.watch(villagesProvider);
    
    final selectedVillageId = useState<String?>(null);
    final selectedPosyanduId = useState<String?>(null);
    
    final posyandusAsync = selectedVillageId.value != null
        ? ref.watch(posyandusByVillageProvider(selectedVillageId.value!))
        : const AsyncValue.data(<Posyandu>[]);

    return Scaffold(
      backgroundColor: const Color(0xFFD4E6F1), // Light blue background
      body: SafeArea(
        child: Column(
          children: [
            // Custom App Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1F618D), Color(0xFF2980B9)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => context.pop(),
                    child: const Icon(Icons.menu, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset('assets/images/psn_logo_new.jpg', fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 8),
                  RichText(
                    text: TextSpan(
                      style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                      children: const [
                        TextSpan(text: 'SI KADER ', style: TextStyle(color: Colors.white)),
                        TextSpan(text: 'PSN', style: TextStyle(color: Color(0xFF82E0AA))),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Stack(
                    children: [
                      const Icon(Icons.notifications, color: Colors.white),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.white,
                    child: Image.asset('assets/images/avatar_kader.png'),
                  ),
                ],
              ),
            ),

            // Breadcrumbs
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Text('Beranda', style: GoogleFonts.outfit(color: Colors.blueGrey, fontSize: 12)),
                  const Icon(Icons.chevron_right, size: 14, color: Colors.blueGrey),
                  Text('Riwayat Laporan PSN', style: GoogleFonts.outfit(color: const Color(0xFF2C3E50), fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Filter Section
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'RIWAYAT LAPORAN PSN',
                            style: GoogleFonts.outfit(color: const Color(0xFF154360), fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Berikut adalah daftar laporan PSN yang sudah Anda kirim.',
                            style: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 12),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel(icon: Icons.location_on, label: 'Desa', color: Colors.blue),
                                    const SizedBox(height: 8),
                                    _buildDropdown(
                                      value: selectedVillageId.value,
                                      hint: 'Pilih Desa',
                                      items: villagesAsync.maybeWhen(
                                        data: (villages) => villages.map((v) => DropdownMenuItem(value: v.id, child: Text(v.name))).toList(),
                                        orElse: () => [],
                                      ),
                                      onChanged: (val) {
                                        selectedVillageId.value = val;
                                        selectedPosyanduId.value = null;
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel(
                                      iconWidget: Image.asset('assets/images/icon_posyandu.png', width: 18, height: 18),
                                      label: 'Posyandu',
                                    ),
                                    const SizedBox(height: 8),
                                    _buildDropdown(
                                      value: selectedPosyanduId.value,
                                      hint: 'Pilih Posyandu',
                                      items: posyandusAsync.maybeWhen(
                                        data: (posyandus) => posyandus.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))).toList(),
                                        orElse: () => [],
                                      ),
                                      onChanged: (val) => selectedPosyanduId.value = val,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Table Section
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: reportsAsync.when(
                        data: (reports) {
                          // Apply filters
                          final filteredReports = reports.where((r) {
                            if (selectedPosyanduId.value != null) {
                              return r.posyanduId == selectedPosyanduId.value;
                            }
                            // Note: Village filter is implicit via Posyandu filter in UI, 
                            // but if only Village is selected, we'd need to fetch or map.
                            // For now, let's keep it simple.
                            return true;
                          }).toList();

                          return Column(
                            children: [
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  headingRowColor: MaterialStateProperty.all(const Color(0xFFEBF5FB)),
                                  dataRowHeight: 60,
                                  columnSpacing: 20,
                                  columns: [
                                    _buildTableHeader('Tanggal\nPSN'),
                                    _buildTableHeader('Nama\nDesa'),
                                    _buildTableHeader('Nama\nPosyandu'),
                                    _buildTableHeader('Jumlah Rumah\nDiperiksa'),
                                    _buildTableHeader('Jumlah Rumah\nPositif Jentik'),
                                    _buildTableHeader('ABJ'),
                                    _buildTableHeader('Aksi'),
                                  ],
                                  rows: filteredReports.map((report) {
                                    final abj = ((report.housesInspected - report.housesPositive) / (report.housesInspected > 0 ? report.housesInspected : 1) * 100);
                                    return DataRow(
                                      cells: [
                                        DataCell(Text(DateFormat('d MMMM\nyyyy', 'id_ID').format(report.reportDate), style: GoogleFonts.outfit(fontSize: 11))),
                                        DataCell(Text(report.villageName ?? '-', style: GoogleFonts.outfit(fontSize: 11))),
                                        DataCell(Text(report.posyanduName ?? '-', style: GoogleFonts.outfit(fontSize: 11))),
                                        DataCell(Center(child: Text('${report.housesInspected}', style: GoogleFonts.outfit(fontSize: 11)))),
                                        DataCell(Center(child: Text('${report.housesPositive}', style: GoogleFonts.outfit(fontSize: 11)))),
                                        DataCell(Text('${abj.toStringAsFixed(1)}%', style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: abj >= 95 ? Colors.green : Colors.orange))),
                                        DataCell(
                                          OutlinedButton.icon(
                                            onPressed: () {},
                                            icon: const Icon(Icons.edit, size: 14),
                                            label: const Text('Edit Laporan', style: TextStyle(fontSize: 10)),
                                            style: OutlinedButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(horizontal: 8),
                                              side: const BorderSide(color: Colors.blue),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Menampilkan ${filteredReports.length} data dari ${reports.length} laporan',
                                      style: GoogleFonts.outfit(fontSize: 10, color: Colors.grey),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(4)),
                                      child: const Text('1', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Center(child: Text('Error: $e')),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Info Box
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEBF5FB),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info, color: Colors.blue, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Informasi', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFF154360))),
                                const SizedBox(height: 4),
                                Text(
                                  'Anda dapat mengedit laporan yang sudah dikirim selama belum diverifikasi oleh admin.',
                                  style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[700]),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  DataColumn _buildTableHeader(String label) {
    return DataColumn(
      label: Text(
        label,
        textAlign: TextAlign.center,
        style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF154360)),
      ),
    );
  }

  Widget _buildLabel({IconData? icon, Widget? iconWidget, required String label, Color? color}) {
    return Row(
      children: [
        if (iconWidget != null) iconWidget else Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF154360)),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String hint,
    required List<DropdownMenuItem<String>> items,
    required void Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, size: 18),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
