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
                  PopupMenuButton<void>(
                    onSelected: (_) async {
                      await ref.read(authRepositoryProvider).signOut();
                      if (context.mounted) context.go('/login');
                    },
                    offset: const Offset(0, 50),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: null,
                        child: Row(
                          children: [
                            const Icon(Icons.logout, color: Colors.red, size: 20),
                            const SizedBox(width: 12),
                            Text('Logout', style: GoogleFonts.outfit(color: Colors.red, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ],
                    child: const CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person, color: Color(0xFF1F618D), size: 20),
                    ),
                  ),
                ],
              ),
            ),

            // Breadcrumbs (Same as before)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => context.pop(),
                    child: Text('Beranda', style: GoogleFonts.outfit(color: Colors.blueGrey, fontSize: 12)),
                  ),
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
                    // Filter Section (Same as before)
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
                            return true;
                          }).toList();

                          return Column(
                            children: [
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  headingRowColor: MaterialStateProperty.all(const Color(0xFFEBF5FB)),
                                  dataRowHeight: 60,
                                  columnSpacing: 24,
                                  columns: [
                                    _buildTableHeader('Tanggal\nPSN'),
                                    _buildTableHeader('Nama\nDesa'),
                                    _buildTableHeader('Nama\nPosyandu'),
                                    _buildTableHeader('Rumah\nDiperiksa'),
                                    _buildTableHeader('Rumah\nPositif'),
                                    _buildTableHeader('ABJ'),
                                    _buildTableHeader('Aksi'),
                                  ],
                                  rows: filteredReports.map((report) {
                                    final abj = ((report.housesInspected - report.housesPositive) / (report.housesInspected > 0 ? report.housesInspected : 1) * 100);
                                    return DataRow(
                                      cells: [
                                        DataCell(Center(child: Text(DateFormat('d MMM\nyyyy', 'id_ID').format(report.reportDate), textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 11)))),
                                        DataCell(Center(child: Text(report.villageName ?? '-', textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 11)))),
                                        DataCell(Center(child: Text(report.posyanduName ?? '-', textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 11)))),
                                        DataCell(Center(child: Text('${report.housesInspected}', textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 11)))),
                                        DataCell(Center(child: Text('${report.housesPositive}', textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 11)))),
                                        DataCell(Center(child: Text('${abj.toStringAsFixed(1)}%', textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: abj >= 95 ? Colors.green : Colors.orange)))),
                                        DataCell(
                                          Center(
                                            child: PopupMenuButton<String>(
                                              icon: const Icon(Icons.more_vert, size: 20, color: Colors.blue),
                                              onSelected: (val) {
                                                if (val == 'edit') {
                                                  if (report.status == 'verified') {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      const SnackBar(
                                                        content: Text('Laporan sudah terverifikasi dan tidak dapat diedit'),
                                                        backgroundColor: Colors.orange,
                                                      ),
                                                    );
                                                  } else {
                                                    context.push('/report', extra: report);
                                                  }
                                                } else if (val == 'delete') {
                                                  _showDeleteConfirm(context, ref, report);
                                                }
                                              },
                                              itemBuilder: (context) => [
                                                PopupMenuItem(
                                                  value: 'edit',
                                                  child: Row(
                                                    children: [
                                                      Icon(Icons.edit, size: 18, color: report.status == 'verified' ? Colors.grey : Colors.blue),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        'Edit', 
                                                        style: GoogleFonts.outfit(
                                                          fontSize: 13, 
                                                          color: report.status == 'verified' ? Colors.grey : Colors.black,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                PopupMenuItem(
                                                  value: 'delete',
                                                  child: Row(
                                                    children: [
                                                      const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                                      const SizedBox(width: 8),
                                                      Text('Hapus', style: GoogleFonts.outfit(fontSize: 13, color: Colors.red)),
                                                    ],
                                                  ),
                                                ),
                                              ],
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

  Future<void> _showDeleteConfirm(BuildContext context, WidgetRef ref, Report report) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hapus Laporan?', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text('Apakah Anda yakin ingin menghapus laporan ini? Data yang dihapus tidak dapat dikembalikan.', style: GoogleFonts.outfit()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal', style: GoogleFonts.outfit(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Hapus', style: GoogleFonts.outfit(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(reportRepositoryProvider).deleteReport(report.id);
        ref.invalidate(myReportsProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Laporan berhasil dihapus'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menghapus: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }
}
