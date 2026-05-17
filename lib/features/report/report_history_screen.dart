import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../shared/providers/report_providers.dart';
import '../../shared/providers/auth_providers.dart';
import '../../shared/widgets/notification_badge.dart';
import '../../shared/domain/models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReportHistoryScreen extends HookConsumerWidget {
  const ReportHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final isAdmin = profileAsync.maybeWhen(data: (p) => p?.role == 'admin', orElse: () => false);
    
    final selectedMonth = useState<String>('Semua');
    final selectedYear = useState<String>('Semua');
    final searchQuery = useState<String>('');
    final scrollController = useScrollController();
    final tempNotes = useRef<Map<String, String>>({});
    final savingLocks = useRef<Map<String, bool>>({});

    final reportsAsync = profileAsync.maybeWhen(
      data: (profile) => profile?.role == 'admin' 
          ? ref.watch(allReportsProvider) 
          : ref.watch(myReportsProvider),
      orElse: () => const AsyncValue.loading(),
    );

    final adminNotesAsync = ref.watch(allAdminNotesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFD4E6F1),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F618D),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              clipBehavior: Clip.antiAlias,
              child: Image.asset('assets/images/psn_logo_new.jpg', fit: BoxFit.cover),
            ),
            const SizedBox(width: 10),
            Column(
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
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text('DATA MONITORING LAPORAN PSN', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF154360))),
                    const SizedBox(height: 4),
                    Text('Berikut adalah data laporan PSN yang dikirim oleh kader.', style: GoogleFonts.outfit(fontSize: 13, color: Colors.blueGrey)),
                    const SizedBox(height: 24),

                    // Filters
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isMobile = constraints.maxWidth < 600;
                        
                        final puskesmasWidget = Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.domain, color: Colors.blueGrey, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Pilih Puskesmas', style: GoogleFonts.outfit(fontSize: 10, color: Colors.grey[500])),
                                    Text('Puskesmas Gumelar', style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF2C3E50), fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );

                        final bulanWidget = Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, color: Colors.blueGrey, size: 18),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Pilih Bulan', style: GoogleFonts.outfit(fontSize: 10, color: Colors.grey[500])),
                                    SizedBox(
                                      width: double.infinity,
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          value: selectedMonth.value,
                                          isDense: true,
                                          isExpanded: true,
                                          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey, size: 18),
                                          style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF2C3E50), fontWeight: FontWeight.w500),
                                          onChanged: (val) { if(val!=null) selectedMonth.value = val; },
                                          items: ['Semua','Januari','Februari','Maret','April','Mei','Juni','Juli','Agustus','September','Oktober','November','Desember']
                                            .map<DropdownMenuItem<String>>((e) => DropdownMenuItem(value: e, child: Text(e, overflow: TextOverflow.ellipsis))).toList(),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );

                        final tahunWidget = Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_month, color: Colors.blueGrey, size: 18),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Pilih Tahun', style: GoogleFonts.outfit(fontSize: 10, color: Colors.grey[500])),
                                    SizedBox(
                                      width: double.infinity,
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          value: selectedYear.value,
                                          isDense: true,
                                          isExpanded: true,
                                          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey, size: 18),
                                          style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF2C3E50), fontWeight: FontWeight.w500),
                                          onChanged: (val) { if(val!=null) selectedYear.value = val; },
                                          items: ['Semua','2024','2025','2026','2027'].map<DropdownMenuItem<String>>((e) => DropdownMenuItem(value: e, child: Text(e, overflow: TextOverflow.ellipsis))).toList(),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );

                        if (isMobile) {
                          return Column(
                            children: [
                              puskesmasWidget,
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(child: bulanWidget),
                                  const SizedBox(width: 12),
                                  Expanded(child: tahunWidget),
                                ],
                              ),
                            ],
                          );
                        } else {
                          return Row(
                            children: [
                              Expanded(child: puskesmasWidget),
                              const SizedBox(width: 16),
                              Expanded(child: bulanWidget),
                              const SizedBox(width: 16),
                              Expanded(child: tahunWidget),
                            ],
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Search
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            onChanged: (val) => searchQuery.value = val,
                            decoration: InputDecoration(
                              hintText: 'Ketik untuk mencari...',
                              hintStyle: GoogleFonts.outfit(color: Colors.grey[400], fontSize: 13),
                              prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.search, size: 18, color: Colors.white),
                          label: Text('Cari', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w500)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1976D2),
                            minimumSize: const Size(120, 54), // Override infinity width global theme
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Table
                    reportsAsync.when(
                      data: (reports) {
                        var filtered = reports;
                        
                        // Month filter
                        if (selectedMonth.value != 'Semua') {
                          final monthIndex = ['Januari','Februari','Maret','April','Mei','Juni','Juli','Agustus','September','Oktober','November','Desember'].indexOf(selectedMonth.value) + 1;
                          filtered = filtered.where((r) => r.reportDate.month == monthIndex).toList();
                        }
                        
                        // Year filter
                        if (selectedYear.value != 'Semua') {
                          filtered = filtered.where((r) => r.reportDate.year.toString() == selectedYear.value).toList();
                        }
                        
                        // Search filter
                        if (searchQuery.value.isNotEmpty) {
                          filtered = filtered.where((r) => 
                            (r.villageName ?? '').toLowerCase().contains(searchQuery.value.toLowerCase()) ||
                            (r.posyanduName ?? '').toLowerCase().contains(searchQuery.value.toLowerCase())
                          ).toList();
                        }
                        
                        return Column(
                          children: [
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[200]!),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Scrollbar(
                                  controller: scrollController,
                                  thumbVisibility: true,
                                  trackVisibility: true,
                                  thickness: 8,
                                  child: SingleChildScrollView(
                                    controller: scrollController,
                                    scrollDirection: Axis.horizontal,
                                  child: DataTable(
                                    showCheckboxColumn: false,
                                    headingRowColor: WidgetStateProperty.all(const Color(0xFFF4F6F9)),
                                    columnSpacing: 20,
                                    dataRowMinHeight: 50,
                                    dataRowMaxHeight: 60,
                                    headingTextStyle: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF154360)),
                                    columns: [
                                      const DataColumn(label: Text('No')),
                                      const DataColumn(label: Text('Tanggal PSN')),
                                      const DataColumn(label: Text('Nama Desa')),
                                      const DataColumn(label: Text('Posyandu')),
                                      const DataColumn(label: Text('Rumah Diperiksa'), numeric: true),
                                      const DataColumn(label: Text('Positif Jentik'), numeric: true),
                                      const DataColumn(label: Text('ABJ')),
                                      const DataColumn(label: Text('Aksi')),
                                      if (isAdmin) const DataColumn(label: Text('Intervensi')),
                                      if (isAdmin) const DataColumn(label: Text('Keterangan')),
                                      if (isAdmin) const DataColumn(label: Text('Hapus')),
                                    ],
                                    rows: filtered.asMap().entries.map<DataRow>((entry) {
                                      final index = entry.key;
                                      final report = entry.value;
                                      final abjValue = ((report.housesInspected - report.housesPositive) / (report.housesInspected > 0 ? report.housesInspected : 1) * 100);
                                      final isSudah = report.status == 'verified';
                                      
                                      final adminNote = adminNotesAsync.maybeWhen(
                                        data: (map) => map[report.id],
                                        orElse: () => null,
                                      );
                                      
                                      return DataRow(
                                        color: WidgetStateProperty.all(index % 2 == 0 ? Colors.white : const Color(0xFFF8F9F9)),
                                        onSelectChanged: (_) => _showReportSummaryDialog(context, ref, report, isAdmin),
                                        cells: [
                                          DataCell(Text('${index + 1}', style: GoogleFonts.outfit(fontSize: 12, color: Colors.blueGrey))),
                                          DataCell(Text(DateFormat('dd MMMM yyyy').format(report.reportDate), style: GoogleFonts.outfit(fontSize: 12, color: Colors.blueGrey))),
                                          DataCell(Text(report.villageName ?? '-', style: GoogleFonts.outfit(fontSize: 12, color: Colors.blueGrey))),
                                          DataCell(Text(report.posyanduName ?? '-', style: GoogleFonts.outfit(fontSize: 12, color: Colors.blueGrey))),
                                          DataCell(Text('${report.housesInspected}', style: GoogleFonts.outfit(fontSize: 12, color: Colors.blueGrey))),
                                          DataCell(Text('${report.housesPositive}', style: GoogleFonts.outfit(fontSize: 12, color: Colors.blueGrey))),
                                          DataCell(Text('${abjValue.toStringAsFixed(1)}%', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: abjValue >= 95 ? Colors.green[600] : Colors.orange[600]))),
                                          DataCell(
                                            OutlinedButton.icon(
                                              onPressed: () => context.push('/report', extra: report),
                                              icon: const Icon(Icons.edit, size: 14, color: Color(0xFF1976D2)),
                                              label: Text('Edit Laporan', textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 10, color: const Color(0xFF1976D2))),
                                              style: OutlinedButton.styleFrom(
                                                side: const BorderSide(color: Color(0xFF1976D2)),
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                              ),
                                            ),
                                          ),
                                          if (isAdmin)
                                            DataCell(
                                              Container(
                                                height: 28,
                                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                                decoration: BoxDecoration(
                                                  border: Border.all(color: isSudah ? Colors.green : Colors.red),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: DropdownButtonHideUnderline(
                                                  child: DropdownButton<String>(
                                                    value: isSudah ? 'Sudah' : 'Belum',
                                                    isDense: true,
                                                    icon: const Icon(Icons.keyboard_arrow_down, size: 14, color: Colors.grey),
                                                    items: ['Belum', 'Sudah'].map((e) => DropdownMenuItem(value: e, child: Text(e, style: GoogleFonts.outfit(fontSize: 11, color: e == 'Sudah' ? Colors.green : Colors.red)))).toList(),
                                                    onChanged: (val) async {
                                                      if (val == 'Sudah' && !isSudah) {
                                                        await Supabase.instance.client.from('reports').update({'status': 'verified'}).eq('id', report.id);
                                                        ref.invalidate(allReportsProvider);
                                                      } else if (val == 'Belum' && isSudah) {
                                                        await Supabase.instance.client.from('reports').update({'status': 'submitted'}).eq('id', report.id);
                                                        ref.invalidate(allReportsProvider);
                                                      }
                                                    },
                                                  ),
                                                ),
                                              ),
                                            ),
                                          if (isAdmin)
                                            DataCell(
                                              Builder(
                                                builder: (context) {
                                                  Future<void> saveNote(String val) async {
                                                    if (savingLocks.value[report.id] == true) return;
                                                    if (val == (adminNote ?? '')) return;
                                                    if (val == '-' && (adminNote == null || adminNote.trim().isEmpty)) return;
                                                    
                                                    savingLocks.value[report.id] = true;
                                                    try {
                                                      await Supabase.instance.client.from('interventions').delete().eq('report_id', report.id).eq('type', 'kunjungan_rumah');
                                                      if (val.trim().isNotEmpty && val.trim() != '-') {
                                                        await Supabase.instance.client.from('interventions').insert({
                                                          'report_id': report.id,
                                                          'type': 'kunjungan_rumah',
                                                          'description': val.trim(),
                                                          'admin_id': Supabase.instance.client.auth.currentUser!.id,
                                                        });
                                                      }
                                                      ref.invalidate(allAdminNotesProvider);
                                                      if (context.mounted) {
                                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Catatan berhasil disimpan!'), backgroundColor: Colors.green, duration: Duration(seconds: 2)));
                                                      }
                                                    } catch (e) {
                                                      if (context.mounted) {
                                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e'), backgroundColor: Colors.red, duration: const Duration(seconds: 4)));
                                                      }
                                                    } finally {
                                                      Future.delayed(const Duration(milliseconds: 500), () {
                                                        savingLocks.value[report.id] = false;
                                                      });
                                                    }
                                                  }

                                                  return SizedBox(
                                                    width: 150,
                                                    child: Focus(
                                                      onFocusChange: (hasFocus) async {
                                                        if (!hasFocus && tempNotes.value.containsKey(report.id)) {
                                                          await saveNote(tempNotes.value[report.id]!);
                                                        }
                                                      },
                                                      child: TextFormField(
                                                        initialValue: (adminNote == null || adminNote.trim().isEmpty) ? '-' : adminNote,
                                                        style: GoogleFonts.outfit(fontSize: 11, color: Colors.blueGrey),
                                                        textInputAction: TextInputAction.done,
                                                        onChanged: (val) => tempNotes.value[report.id] = val,
                                                        decoration: InputDecoration(
                                                          hintText: 'Ketik lalu klik luar...',
                                                          hintStyle: TextStyle(fontSize: 11, color: Colors.grey[400]),
                                                          isDense: true,
                                                          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                                          border: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(4)),
                                                          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(4)),
                                                          focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Color(0xFF1976D2)), borderRadius: BorderRadius.circular(4)),
                                                        ),
                                                        onFieldSubmitted: (val) async {
                                                          await saveNote(val);
                                                        },
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                          if (isAdmin)
                                            DataCell(
                                              IconButton(
                                                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                                onPressed: () {
                                                  showDialog(
                                                    context: context,
                                                    builder: (context) => AlertDialog(
                                                      title: Text('Konfirmasi Hapus', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                                                      content: Text('Apakah Anda yakin ingin menghapus data laporan ini?', style: GoogleFonts.outfit()),
                                                      actionsAlignment: MainAxisAlignment.end,
                                                      actions: [
                                                        ElevatedButton(
                                                          onPressed: () async {
                                                            Navigator.pop(context);
                                                            try {
                                                              await ref.read(reportRepositoryProvider).deleteReport(report.id);
                                                              ref.invalidate(allReportsProvider);
                                                              if (context.mounted) {
                                                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Laporan berhasil dihapus!'), backgroundColor: Colors.green));
                                                              }
                                                            } catch (e) {
                                                              if (context.mounted) {
                                                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menghapus: $e'), backgroundColor: Colors.red));
                                                              }
                                                            }
                                                          },
                                                          style: ElevatedButton.styleFrom(
                                                            backgroundColor: Colors.red,
                                                            minimumSize: const Size(80, 40),
                                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                          ),
                                                          child: Text('Hapus', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                                                        ),
                                                        const SizedBox(width: 8),
                                                        TextButton(
                                                          onPressed: () => Navigator.pop(context),
                                                          style: TextButton.styleFrom(
                                                            minimumSize: const Size(80, 40),
                                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                          ),
                                                          child: Text('Batal', style: GoogleFonts.outfit(color: Colors.blueGrey, fontWeight: FontWeight.bold)),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Menampilkan ${filtered.length} data dari ${reports.length} laporan', style: GoogleFonts.outfit(fontSize: 12, color: Colors.blueGrey)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(color: const Color(0xFF1976D2), borderRadius: BorderRadius.circular(4)),
                                  child: Text('1', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                      loading: () => const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator())),
                      error: (e, s) => Center(child: Text('Error: $e')),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Bottom Info
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F8FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[100]!),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Color(0xFF1976D2), shape: BoxShape.circle),
                  child: const Icon(Icons.info_outline, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Informasi', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF154360))),
                      const SizedBox(height: 4),
                      Text('Data diperbarui secara otomatis berdasarkan laporan PSN kader. Pastikan intervensi dilakukan untuk meningkatkan capaian ABJ.', style: GoogleFonts.outfit(fontSize: 12, color: Colors.blueGrey)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showReportSummaryDialog(BuildContext context, WidgetRef ref, Report report, bool isAdmin) {
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
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
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
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F8FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[100]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(width: 80, child: Text('Tanggal', style: GoogleFonts.outfit(fontSize: 12, color: Colors.blueGrey, fontWeight: FontWeight.w500))),
                        const Text(': ', style: TextStyle(fontSize: 12, color: Colors.blueGrey)),
                        Expanded(child: Text(DateFormat('dd MMMM yyyy').format(report.reportDate), style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold))),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(width: 80, child: Text('Desa', style: GoogleFonts.outfit(fontSize: 12, color: Colors.blueGrey, fontWeight: FontWeight.w500))),
                        const Text(': ', style: TextStyle(fontSize: 12, color: Colors.blueGrey)),
                        Expanded(child: Text(report.villageName ?? '-', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold))),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(width: 80, child: Text('Posyandu', style: GoogleFonts.outfit(fontSize: 12, color: Colors.blueGrey, fontWeight: FontWeight.w500))),
                        const Text(': ', style: TextStyle(fontSize: 12, color: Colors.blueGrey)),
                        Expanded(child: Text(report.posyanduName ?? '-', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold))),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(width: 80, child: Text('Diperiksa', style: GoogleFonts.outfit(fontSize: 12, color: Colors.blueGrey, fontWeight: FontWeight.w500))),
                        const Text(': ', style: TextStyle(fontSize: 12, color: Colors.blueGrey)),
                        Expanded(child: Text('${report.housesInspected} Rumah', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold))),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(width: 80, child: Text('Positif Jentik', style: GoogleFonts.outfit(fontSize: 12, color: Colors.blueGrey, fontWeight: FontWeight.w500))),
                        const Text(': ', style: TextStyle(fontSize: 12, color: Colors.blueGrey)),
                        Expanded(child: Text('${report.housesPositive} Rumah', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: report.housesPositive > 0 ? Colors.red : Colors.green))),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(width: 80, child: Text('Status', style: GoogleFonts.outfit(fontSize: 12, color: Colors.blueGrey, fontWeight: FontWeight.w500))),
                        const Text(': ', style: TextStyle(fontSize: 12, color: Colors.blueGrey)),
                        Expanded(child: Text(report.status == 'verified' ? 'TERKIRIM' : (report.status == 'need_intervention' ? 'PERLU PERBAIKAN' : 'MENUNGGU VERIFIKASI'), style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold))),
                      ],
                    ),
                  ],
                ),
              ),
              if (report.status == 'need_intervention') ...[
                Consumer(
                  builder: (context, ref, child) {
                    final interventionsAsync = ref.watch(interventionsByReportProvider(report.id));
                    return interventionsAsync.when(
                      data: (items) {
                        if (items.isEmpty) return const SizedBox.shrink();
                        final latest = items.first;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.warning_rounded, color: Colors.orange.shade800, size: 16),
                                  const SizedBox(width: 6),
                                  Text('CATATAN PERBAIKAN DARI ADMIN:', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.orange.shade900)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(latest['description'] ?? '-', style: GoogleFonts.outfit(fontSize: 13, color: Colors.orange.shade900, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        );
                      },
                      loading: () => const Padding(padding: EdgeInsets.only(bottom: 16), child: LinearProgressIndicator()),
                      error: (e, _) => const SizedBox.shrink(),
                    );
                  },
                ),
              ],
              Text('Data Detail KK:', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF154360))),
              const SizedBox(height: 8),
              Flexible(
                child: houses.isEmpty 
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Column(
                          children: [
                            Icon(Icons.notes_outlined, color: Colors.grey[400], size: 48),
                            const SizedBox(height: 12),
                            Text(
                              'Data detail KK tidak tersedia untuk laporan ini.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
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
              if (isAdmin) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.assignment_late, color: Colors.white, size: 18),
                    label: Text('MINTA PERBAIKAN LAPORAN', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade800,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      Navigator.pop(context); // Tutup popup summary
                      _showInterventionNoteDialog(context, ref, report);
                    },
                  ),
                ),
                const SizedBox(height: 8),
              ],
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1F618D), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  child: Text('TUTUP', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showInterventionNoteDialog(BuildContext context, WidgetRef ref, Report report) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            const SizedBox(width: 10),
            Expanded(child: Text('Permintaan Perbaikan Laporan', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Kirimkan catatan perbaikan kepada kader terkait laporan di ${report.posyanduName ?? report.villageName ?? "fasilitas ini"}.', style: GoogleFonts.outfit(fontSize: 13, color: Colors.blueGrey)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 4,
              style: GoogleFonts.outfit(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Tuliskan bagian mana yang salah dan apa yang harus diperbaiki oleh kader...',
                hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('BATAL', style: GoogleFonts.outfit(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade800, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () async {
              if (controller.text.trim().isEmpty) return;
              final desc = controller.text.trim();
              Navigator.pop(context); // Tutup modal input
              
              try {
                await ref.read(reportRepositoryProvider).addIntervention(
                  reportId: report.id,
                  type: 'psn_ulang',
                  description: desc,
                );
                ref.invalidate(allReportsProvider);
                ref.invalidate(myReportsProvider);
                ref.invalidate(allAdminNotesProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Permintaan perbaikan berhasil dikirim ke kader!'), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal mengirim permintaan: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: Text('KIRIM PERMINTAAN', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
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

}
