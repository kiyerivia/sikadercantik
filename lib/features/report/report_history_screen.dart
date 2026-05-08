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
    final profileAsync = ref.watch(userProfileProvider);
    final villagesAsync = ref.watch(villagesProvider);
    
    final selectedVillageId = useState<String?>(null);
    final selectedPosyanduId = useState<String?>(null);

    final reportsAsync = profileAsync.maybeWhen(
      data: (profile) => profile?.role == 'admin' 
          ? ref.watch(allReportsProvider) 
          : ref.watch(myReportsProvider),
      orElse: () => const AsyncValue.loading(),
    );
    
    final posyandusAsync = selectedVillageId.value != null && selectedVillageId.value != 'all'
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
                    child: const Icon(Icons.arrow_back, color: Colors.white),
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
                  PopupMenuButton<String>(
                    onSelected: (val) async {
                      if (val == 'logout') {
                        await ref.read(authRepositoryProvider).signOut();
                        if (context.mounted) context.go('/login');
                      }
                    },
                    offset: const Offset(0, 50),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'logout',
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
                          Column(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel(icon: Icons.location_on, label: 'Desa', color: Colors.blue),
                                  const SizedBox(height: 8),
                                  _buildDropdown(
                                    key: ValueKey('village_history_${selectedVillageId.value}'),
                                    value: selectedVillageId.value,
                                    hint: villagesAsync.isLoading ? 'Memuat...' : 'Pilih Desa',
                                    onChanged: villagesAsync.isLoading ? null : (val) {
                                      selectedVillageId.value = val;
                                      selectedPosyanduId.value = 'all';
                                    },
                                    items: villagesAsync.maybeWhen(
                                      data: (villages) {
                                        final sorted = List<Village>.from(villages)
                                          ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
                                        final list = sorted.map((v) => DropdownMenuItem(value: v.id, child: Text(v.name, style: GoogleFonts.outfit(fontSize: 12)))).toList();
                                        list.insert(0, DropdownMenuItem(value: 'all', child: Text('Semua', style: GoogleFonts.outfit(fontSize: 12))));
                                        return list;
                                      },
                                      orElse: () => [DropdownMenuItem(value: 'all', child: Text('Semua', style: GoogleFonts.outfit(fontSize: 12)))],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel(
                                    iconWidget: Image.asset('assets/images/icon_posyandu.png', width: 18, height: 18),
                                    label: 'Posyandu',
                                  ),
                                  const SizedBox(height: 8),
                                  _buildDropdown(
                                    key: ValueKey('posyandu_history_${selectedVillageId.value}_${selectedPosyanduId.value}'),
                                    value: selectedPosyanduId.value,
                                    hint: posyandusAsync.isLoading ? 'Memuat...' : 'Pilih Posyandu',
                                    onChanged: (posyandusAsync.isLoading || (selectedVillageId.value == null || selectedVillageId.value == 'all')) ? null : (val) => selectedPosyanduId.value = val,
                                    items: posyandusAsync.maybeWhen(
                                      data: (posyandus) {
                                        final sorted = List<Posyandu>.from(posyandus)
                                          ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
                                        final list = sorted.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name, style: GoogleFonts.outfit(fontSize: 12)))).toList();
                                        list.insert(0, DropdownMenuItem(value: 'all', child: Text('Semua', style: GoogleFonts.outfit(fontSize: 12))));
                                        return list;
                                      },
                                      orElse: () => [DropdownMenuItem(value: 'all', child: Text('Semua', style: GoogleFonts.outfit(fontSize: 12)))],
                                    ),
                                  ),
                                ],
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
                            bool matchesVillage = true;
                            if (selectedVillageId.value != null && selectedVillageId.value != 'all') {
                              final village = villagesAsync.value?.firstWhere(
                                (v) => v.id == selectedVillageId.value,
                                orElse: () => Village(id: '', name: ''),
                              );
                              if (village?.name.isNotEmpty ?? false) {
                                matchesVillage = r.villageName?.trim().toLowerCase() == village?.name.trim().toLowerCase();
                              }
                            }
                            
                            bool matchesPosyandu = true;
                            if (selectedPosyanduId.value != null && selectedPosyanduId.value != 'all') {
                              matchesPosyandu = r.posyanduId == selectedPosyanduId.value;
                            }
                            
                            return matchesVillage && matchesPosyandu;
                          }).toList();

                          return Column(
                            children: [
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  headingRowColor: WidgetStateProperty.all(const Color(0xFFEBF5FB)),
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
                                        DataCell(Center(
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              if (report.status == 'need_intervention')
                                                const Padding(
                                                  padding: EdgeInsets.only(right: 4),
                                                  child: Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 14),
                                                ),
                                              Text(DateFormat('d MMM\nyyyy', 'id_ID').format(report.reportDate), textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 11, fontWeight: report.status == 'need_intervention' ? FontWeight.bold : FontWeight.normal, color: report.status == 'need_intervention' ? Colors.orange[900] : Colors.black)),
                                            ],
                                          ),
                                        )),
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
      label: Expanded(
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF154360)),
          ),
        ),
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
    Key? key,
    required String? value,
    required String hint,
    required List<DropdownMenuItem<String>> items,
    required void Function(String?)? onChanged,
  }) {
    final isDisabled = onChanged == null;
    return Container(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDisabled ? Colors.grey[100] : Colors.white,
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint, style: GoogleFonts.outfit(color: Colors.grey[400], fontSize: 12)),
          isExpanded: true,
          isDense: true,
          icon: isDisabled && hint == 'Memuat...' 
            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.keyboard_arrow_down, size: 18),
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
