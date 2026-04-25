import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import '../../shared/domain/models.dart';
import '../../shared/providers/report_providers.dart';
import '../../shared/providers/admin_providers.dart';

class ReportDetailScreen extends ConsumerWidget {
  final Report report;

  const ReportDetailScreen({super.key, required this.report});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail & Verifikasi'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoSection(context),
            const Divider(height: 48),
            _buildStatusSection(context),
            const SizedBox(height: 48),
            if (report.status == 'submitted') _buildActionButtons(context, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(report.reportDate),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 8),
        Text('ID Laporan: ${report.id}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        const SizedBox(height: 24),
        _DataRow(label: 'Rumah Diperiksa', value: '${report.housesInspected}'),
        _DataRow(label: 'Rumah Positif', value: '${report.housesPositive}', color: Colors.red),
        _DataRow(
          label: 'ABJ (Angka Bebas Jentik)',
          value: '${((report.housesInspected - report.housesPositive) / (report.housesInspected > 0 ? report.housesInspected : 1) * 100).toStringAsFixed(1)}%',
          color: Colors.blue,
        ),
        const SizedBox(height: 24),
        const Text('Catatan Kader:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(report.notes ?? '-', style: const TextStyle(fontSize: 16)),
      ],
    );
  }

  Widget _buildStatusSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Status Saat Ini:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.blue),
              const SizedBox(width: 12),
              Text(
                report.status.toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          onPressed: () => _handleUpdateStatus(context, ref, 'verified'),
          child: const Text('VERIFIKASI (OK)'),
        ),
        const SizedBox(height: 16),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 54),
            side: const BorderSide(color: Colors.orange),
            foregroundColor: Colors.orange,
          ),
          onPressed: () => _showInterventionDialog(context, ref),
          child: const Text('BUTUH INTERVENSI / PSN ULANG'),
        ),
      ],
    );
  }

  Future<void> _handleUpdateStatus(BuildContext context, WidgetRef ref, String status) async {
    try {
      await ref.read(reportRepositoryProvider).updateReportStatus(report.id, status);
      ref.invalidate(allReportsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status diperbarui ke $status')));
        Navigator.pop(context);
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
        title: const Text('Instruksi Intervensi'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Tuliskan instruksi untuk kader...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('BATAL')),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isEmpty) return;
              await ref.read(reportRepositoryProvider).addIntervention(
                    reportId: report.id,
                    type: 'psn_ulang',
                    description: controller.text,
                  );
              ref.invalidate(allReportsProvider);
              if (context.mounted) {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Close detail screen
              }
            },
            child: const Text('SIMPAN'),
          ),
        ],
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _DataRow({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[700])),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: color),
          ),
        ],
      ),
    );
  }
}
