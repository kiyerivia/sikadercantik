import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../shared/domain/models.dart';
import '../../shared/providers/report_providers.dart';
import '../../shared/providers/admin_providers.dart';
import '../../shared/widgets/notification_badge.dart';

class ReportDetailScreen extends ConsumerWidget {
  final Report report;

  const ReportDetailScreen({super.key, required this.report});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final abj = ((report.housesInspected - report.housesPositive) / (report.housesInspected > 0 ? report.housesInspected : 1) * 100);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        leading: const BackButton(color: Colors.white),
        title: Text('Detail Laporan', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1F618D),
        elevation: 0,
          const NotificationBadge(),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section with Status
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFF1F618D),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                children: [
                  _buildStatusBadge(report.status),
                  const SizedBox(height: 16),
                  Text(
                    report.posyanduName ?? 'Posyandu Tidak Diketahui',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    report.villageName ?? '-',
                    style: GoogleFonts.outfit(fontSize: 16, color: Colors.white.withOpacity(0.8)),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(report.reportDate),
                    style: GoogleFonts.outfit(fontSize: 14, color: Colors.white.withOpacity(0.9)),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary Stats
                  Row(
                    children: [
                      _buildStatBox('Inspeksi', '${report.housesInspected}', Colors.blue),
                      const SizedBox(width: 12),
                      _buildStatBox('Positif', '${report.housesPositive}', Colors.red),
                      const SizedBox(width: 12),
                      _buildStatBox('ABJ', '${abj.toStringAsFixed(1)}%', abj >= 95 ? Colors.green : Colors.orange),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Report Content
                  _buildSectionTitle('CATATAN PEMERIKSAAN'),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                    ),
                    child: Text(
                      report.notes ?? 'Tidak ada catatan tambahan.',
                      style: GoogleFonts.outfit(fontSize: 14, color: Colors.blueGrey[800], height: 1.5),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Admin Actions
                  if (report.status == 'submitted') ...[
                    _buildSectionTitle('TINDAKAN ADMIN'),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.verified_user),
                        label: Text('VERIFIKASI DATA (OK)', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF27AE60),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => _handleUpdateStatus(context, ref, 'verified'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.assignment_late),
                        label: Text('BUTUH INTERVENSI / PSN ULANG', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.orange[800],
                          side: BorderSide(color: Colors.orange[800]!),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => _showInterventionDialog(context, ref),
                      ),
                    ),
                  ] else if (report.status == 'verified') ...[
                    Center(
                      child: Column(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 48),
                          const SizedBox(height: 8),
                          Text(
                            'Laporan sudah terverifikasi',
                            style: GoogleFonts.outfit(color: Colors.green, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[600], letterSpacing: 1.2),
    );
  }

  Widget _buildStatBox(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(value, style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(label, style: GoogleFonts.outfit(fontSize: 10, color: color.withOpacity(0.8), fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = Colors.grey;
    String label = status.toUpperCase();
    IconData icon = Icons.info;

    if (status == 'submitted') {
      color = Colors.orange;
      label = 'MENUNGGU VERIFIKASI';
      icon = Icons.pending;
    } else if (status == 'verified') {
      color = Colors.green;
      label = 'TERVERIFIKASI';
      icon = Icons.verified;
    } else if (status == 'need_intervention') {
      color = Colors.red;
      label = 'PERLU INTERVENSI';
      icon = Icons.warning;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Text(label, style: GoogleFonts.outfit(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
        ],
      ),
    );
  }

  Future<void> _handleUpdateStatus(BuildContext context, WidgetRef ref, String status) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Konfirmasi Verifikasi', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text('Apakah Anda yakin data ini sudah benar dan layak diverifikasi?', style: GoogleFonts.outfit()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('BATAL')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('YA, VERIFIKASI'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ref.read(reportRepositoryProvider).updateReportStatus(report.id, status);
      ref.invalidate(allReportsProvider);
      ref.invalidate(adminStatsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Laporan Berhasil Diverifikasi!'), backgroundColor: Colors.green),
        );
        context.pop();
      }
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showInterventionDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Instruksi Intervensi', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          maxLines: 4,
          style: GoogleFonts.outfit(),
          decoration: InputDecoration(
            hintText: 'Tuliskan instruksi atau alasan kenapa data ini perlu diperbaiki/PSN ulang...',
            hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('BATAL')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[800]),
            onPressed: () async {
              if (controller.text.isEmpty) return;
              
              // Simple loading indicator would be better but let's at least handle error
              try {
                await ref.read(reportRepositoryProvider).addIntervention(
                      reportId: report.id,
                      type: 'psn_ulang',
                      description: controller.text,
                    );
                ref.invalidate(allReportsProvider);
                ref.invalidate(adminStatsProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Instruksi berhasil dikirim!'), backgroundColor: Colors.green),
                  );
                  Navigator.pop(context); // Close dialog
                  context.pop(); // Close detail screen
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal mengirim instruksi: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('KIRIM INSTRUKSI'),
          ),
        ],
      ),
    );
  }
}
