import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import '../../shared/providers/report_providers.dart';
import '../../shared/domain/models.dart';

class ReportHistoryScreen extends ConsumerWidget {
  const ReportHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(myReportsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Laporan'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.refresh(myReportsProvider),
        child: reportsAsync.when(
          data: (reports) {
            if (reports.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 100),
                  Center(child: Text('Belum ada laporan yang dikirim.')),
                ],
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: reports.length,
              itemBuilder: (context, index) {
                final report = reports[index];
                return _ReportItem(report: report);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Center(child: Text('Gagal memuat data: $e')),
        ),
      ),
    );
  }
}

class _ReportItem extends StatelessWidget {
  final Report report;

  const _ReportItem({required this.report});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd MMMM yyyy', 'id_ID').format(report.reportDate);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dateStr,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                _StatusBadge(status: report.status),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _InfoTile(
                  label: 'Diperiksa',
                  value: '${report.housesInspected}',
                  icon: Icons.home,
                  color: Colors.blue,
                ),
                const SizedBox(width: 24),
                _InfoTile(
                  label: 'Positif',
                  value: '${report.housesPositive}',
                  icon: Icons.bug_report,
                  color: report.housesPositive > 0 ? Colors.red : Colors.green,
                ),
                const SizedBox(width: 24),
                _InfoTile(
                  label: 'ABJ',
                  value: '${((report.housesInspected - report.housesPositive) / (report.housesInspected > 0 ? report.housesInspected : 1) * 100).toStringAsFixed(1)}%',
                  icon: Icons.percent,
                  color: Colors.orange,
                ),
              ],
            ),
            if (report.notes != null && report.notes!.isNotEmpty) ...[
              const Divider(height: 24),
              Text(
                'Catatan:',
                style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.bold),
              ),
              Text(
                report.notes!,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _InfoTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ],
        ),
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: color),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    switch (status) {
      case 'submitted':
        color = Colors.blue;
        label = 'TERKIRIM';
        break;
      case 'verified':
        color = Colors.green;
        label = 'TERVERIFIKASI';
        break;
      case 'need_intervention':
        color = Colors.orange;
        label = 'BUTUH TINDAKAN';
        break;
      case 'completed':
        color = Colors.teal;
        label = 'SELESAI';
        break;
      default:
        color = Colors.grey;
        label = status.toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
