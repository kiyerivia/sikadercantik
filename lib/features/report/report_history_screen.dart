import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../shared/providers/report_providers.dart';
import '../../shared/providers/master_providers.dart';
import '../../shared/providers/auth_providers.dart';
import '../../shared/widgets/notification_badge.dart';
import '../../shared/domain/models.dart';

class ReportHistoryScreen extends HookConsumerWidget {
  const ReportHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final villagesAsync = ref.watch(villagesProvider);
    
    final selectedVillageId = useState<String?>('all');
    final selectedPosyanduId = useState<String?>('all');

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
      backgroundColor: const Color(0xFFD4E6F1),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F618D),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                children: const [
                  TextSpan(
                    text: 'SI KADER ',
                    style: TextStyle(color: Colors.white),
                  ),
                  TextSpan(
                    text: 'PSN',
                    style: TextStyle(color: Color(0xFF82E0AA)),
                  ),
                ],
              ),
            ),
            Text(
              'RIWAYAT LAPORAN',
              style: GoogleFonts.outfit(
                color: Colors.white70,
                fontSize: 10,
                fontWeight: FontWeight.w500,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        actions: [
          const NotificationBadge(),
          const SizedBox(width: 12),
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
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // Breadcrumbs
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
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  // Filter Section
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.filter_list, color: Color(0xFF1F618D), size: 18),
                            const SizedBox(width: 8),
                            Text('FILTER DATA', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF1F618D), letterSpacing: 1)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildFilterDropdown(
                                label: 'Desa/Kelurahan',
                                value: selectedVillageId.value,
                                items: villagesAsync.maybeWhen(
                                  data: (list) => [
                                    const DropdownMenuItem(value: 'all', child: Text('Semua Desa')),
                                    ...list.map((v) => DropdownMenuItem(value: v.id, child: Text(v.name))),
                                  ],
                                  orElse: () => [const DropdownMenuItem(value: null, child: Text('Loading...'))],
                                ),
                                onChanged: (val) {
                                  selectedVillageId.value = val;
                                  selectedPosyanduId.value = 'all';
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildFilterDropdown(
                                label: 'Posyandu',
                                value: selectedPosyanduId.value,
                                items: posyandusAsync.maybeWhen(
                                  data: (list) => [
                                    const DropdownMenuItem(value: 'all', child: Text('Semua Posyandu')),
                                    ...list.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))),
                                  ],
                                  orElse: () => [const DropdownMenuItem(value: null, child: Text('Pilih Desa Dulu'))],
                                ),
                                onChanged: (val) => selectedPosyanduId.value = val,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Reports Table
                  reportsAsync.when(
                    data: (reports) {
                      final filtered = reports.where((r) {
                        final matchVillage = selectedVillageId.value == null || 
                                           selectedVillageId.value == 'all' || 
                                           r.villageId == selectedVillageId.value;
                        final matchPosyandu = selectedPosyanduId.value == null || 
                                            selectedPosyanduId.value == 'all' || 
                                            r.posyanduId == selectedPosyanduId.value;
                        return matchVillage && matchPosyandu;
                      }).toList();

                      if (filtered.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.symmetric(vertical: 60),
                          child: Column(
                            children: [
                              Icon(Icons.assignment_late_outlined, size: 64, color: Colors.blueGrey[200]),
                              const SizedBox(height: 16),
                              Text('Belum ada data laporan', style: GoogleFonts.outfit(color: Colors.blueGrey, fontSize: 16)),
                            ],
                          ),
                        );
                      }

                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              headingRowColor: WidgetStateProperty.all(const Color(0xFFF8F9F9)),
                              columnSpacing: 24,
                              showCheckboxColumn: false,
                              columns: [
                                DataColumn(label: _buildTableHeader('TANGGAL')),
                                DataColumn(label: _buildTableHeader('DESA')),
                                DataColumn(label: _buildTableHeader('POSYANDU')),
                                DataColumn(label: _buildTableHeader('INSPEKSI')),
                                DataColumn(label: _buildTableHeader('POSITIF')),
                                DataColumn(label: _buildTableHeader('ABJ')),
                                DataColumn(label: _buildTableHeader('STATUS')),
                                DataColumn(label: _buildTableHeader('AKSI')),
                              ],
                              rows: filtered.map((report) {
                                final abjValue = ((report.housesInspected - report.housesPositive) / (report.housesInspected > 0 ? report.housesInspected : 1) * 100);
                                return DataRow(
                                  onSelectChanged: (selected) {
                                    if (selected != null && selected) {
                                      _showReportSummaryDialog(context, report);
                                    }
                                  },
                                  cells: [
                                    DataCell(
                                      Row(
                                        children: [
                                          if (report.status == 'need_intervention')
                                            InkWell(
                                              onTap: () => _showInterventionDialog(context, report),
                                              child: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
                                            ),
                                          if (report.status == 'need_intervention')
                                            const SizedBox(width: 6),
                                          Text(DateFormat('dd/MM/yy').format(report.reportDate), style: GoogleFonts.outfit(fontSize: 13)),
                                        ],
                                      ),
                                    ),
                                    DataCell(Text(report.villageName ?? '-', style: GoogleFonts.outfit(fontSize: 13))),
                                    DataCell(Text(report.posyanduName ?? '-', style: GoogleFonts.outfit(fontSize: 13))),
                                    DataCell(Center(child: Text('${report.housesInspected}', style: GoogleFonts.outfit(fontSize: 13)))),
                                    DataCell(Center(child: Text('${report.housesPositive}', style: GoogleFonts.outfit(fontSize: 13, color: report.housesPositive > 0 ? Colors.red : null, fontWeight: report.housesPositive > 0 ? FontWeight.bold : null)))),
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: (abjValue >= 95 ? Colors.green : Colors.orange).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          '${abjValue.toStringAsFixed(1)}%',
                                          style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: abjValue >= 95 ? Colors.green[700] : Colors.orange[700]),
                                        ),
                                      ),
                                    ),
                                    DataCell(_buildStatusBadge(report.status)),
                                    DataCell(
                                      PopupMenuButton<String>(
                                        icon: const Icon(Icons.more_vert, color: Color(0xFF1F618D)),
                                        onSelected: (val) {
                                          if (val == 'edit') {
                                            context.push('/report-form', extra: report);
                                          } else if (val == 'detail') {
                                            _showReportSummaryDialog(context, report);
                                          }
                                        },
                                        itemBuilder: (context) => [
                                          const PopupMenuItem(value: 'detail', child: Text('Detail')),
                                          const PopupMenuItem(value: 'edit', child: Text('Edit')),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      );
                    },
                    loading: () => const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator())),
                    error: (e, s) => Center(child: Text('Error: $e')),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showInterventionDialog(BuildContext context, Report report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red),
            const SizedBox(width: 8),
            Text('Instruksi Perbaikan', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          report.latestIntervention ?? 'Silakan lakukan PSN ulang dan perbaiki data laporan.',
          style: GoogleFonts.outfit(),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('MENGERTI')),
        ],
      ),
    );
  }

  void _showReportSummaryDialog(BuildContext context, Report report) {
    final houses = <Map<String, String>>[];
    if (report.notes != null) {
      final blocks = report.notes!.split('--- KK');
      for (var block in blocks) {
        if (block.trim().isEmpty) continue;
        final data = <String, String>{};
        final lines = block.split('\n');
        for (var line in lines) {
          final t = line.trim();
          if (t.startsWith('Nama KK: ')) data['kk'] = t.substring(9);
          else if (t.startsWith('RT/RW: ')) {
            final parts = t.substring(7).split('/');
            if (parts.length == 2) {
              data['rt'] = parts[0];
              data['rw'] = parts[1];
            }
          } else if (t.startsWith('Tempat: ')) data['tempat'] = t.substring(8);
          else if (t.startsWith('Hasil: ')) data['hasil'] = t.substring(7);
        }
        if (data.isNotEmpty) houses.add(data);
      }
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Detail Laporan', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1F618D))),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
              const Divider(),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: houses.length,
                  itemBuilder: (context, index) {
                    final h = houses[index];
                    final isPositive = h['hasil'] == 'Ada Jentik';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isPositive ? Colors.red[50] : Colors.green[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isPositive ? Colors.red[100]! : Colors.green[100]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Data KK #${index + 1}', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: isPositive ? Colors.red : Colors.green, borderRadius: BorderRadius.circular(20)),
                                child: Text(isPositive ? 'Positif Jentik' : 'Negatif', style: GoogleFonts.outfit(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _buildDetailRow('KK', h['kk'] ?? '-'),
                          _buildDetailRow('RT/RW', '${h['rt'] ?? '-'}/${h['rw'] ?? '-'}'),
                          _buildDetailRow('Tempat', h['tempat'] ?? '-'),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1F618D), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  child: Text('TUTUP', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 60, child: Text(label, style: GoogleFonts.outfit(fontSize: 12, color: Colors.blueGrey, fontWeight: FontWeight.w500))),
          const Text(': ', style: TextStyle(fontSize: 12, color: Colors.blueGrey)),
          Expanded(child: Text(value, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildTableHeader(String label) {
    return Text(label, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF566573)));
  }

  Widget _buildStatusBadge(String status) {
    Color color = Colors.grey;
    String label = status.toUpperCase();
    if (status == 'submitted' || status == 'verified') {
      color = Colors.green; label = 'TERKIRIM';
    } else if (status == 'need_intervention') {
      color = Colors.red; label = 'PERLU PERBAIKAN';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.5), width: 0.5)),
      child: Text(label, style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
    );
  }

  Widget _buildFilterDropdown({required String label, required String? value, required List<DropdownMenuItem<String>> items, required Function(String?) onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.outfit(fontSize: 11, color: Colors.blueGrey, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(color: const Color(0xFFF8F9F9), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey[300]!)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: value,
              items: items,
              onChanged: onChanged,
              style: GoogleFonts.outfit(color: const Color(0xFF2C3E50), fontSize: 13),
              icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF1F618D)),
            ),
          ),
        ),
      ],
    );
  }
}
