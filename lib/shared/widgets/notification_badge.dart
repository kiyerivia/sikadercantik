import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../providers/report_providers.dart';

class NotificationBadge extends ConsumerWidget {
  final Color color;
  const NotificationBadge({super.key, this.color = Colors.white});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(interventionCountProvider);
    final reportsAsync = ref.watch(myReportsProvider);

    return InkWell(
      onTap: () {
        _showNotificationDialog(context, ref);
      },
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
              count > 0 ? Icons.notifications : Icons.notifications_outlined,
              color: color,
              size: 24,
            ),
            if (count > 0)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showNotificationDialog(BuildContext context, WidgetRef ref) {
    final reports = ref.read(myReportsProvider).maybeWhen(
          data: (list) => list.where((r) => r.status == 'need_intervention').toList(),
          orElse: () => [],
        );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.notifications_active, color: Colors.orange),
            const SizedBox(width: 12),
            Text('Pemberitahuan', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: reports.isEmpty
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_outline, size: 48, color: Colors.green[200]),
                    const SizedBox(height: 16),
                    Text(
                      'Tidak ada notifikasi baru.\nSemua laporan Anda sudah aman!',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(color: Colors.grey[600]),
                    ),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Anda memiliki ${reports.length} laporan yang memerlukan intervensi/perbaikan:',
                      style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey[800]),
                    ),
                    const SizedBox(height: 16),
                    ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: reports.length,
                        separatorBuilder: (context, index) => const Divider(),
                        itemBuilder: (context, index) {
                          final report = reports[index];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: Colors.orange[50],
                              child: const Icon(Icons.edit_note, color: Colors.orange),
                            ),
                            title: Text(
                              report.posyanduName ?? 'Laporan PSN',
                              style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              'Klik untuk memperbaiki data ini',
                              style: GoogleFonts.outfit(fontSize: 12, color: Colors.blue),
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              context.push('/report-form', extra: report);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Tutup', style: GoogleFonts.outfit(color: Colors.grey)),
          ),
          if (reports.isNotEmpty)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1F618D),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.pop(context);
                context.push('/history');
              },
              child: const Text('Lihat Semua Riwayat'),
            ),
        ],
      ),
    );
  }
}
