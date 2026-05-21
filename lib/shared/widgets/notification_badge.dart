import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/report_providers.dart';
import '../providers/auth_providers.dart';
import 'package:intl/intl.dart';

class NotificationBadge extends ConsumerStatefulWidget {
  final Color color;
  const NotificationBadge({super.key, this.color = Colors.white});

  @override
  ConsumerState<NotificationBadge> createState() => _NotificationBadgeState();
}

class _NotificationBadgeState extends ConsumerState<NotificationBadge> {
  RealtimeChannel? _reportsChannel;
  RealtimeChannel? _interventionsChannel;

  @override
  void initState() {
    super.initState();
    _initRealtime();
  }

  void _initRealtime() {
    _reportsChannel = Supabase.instance.client
        .channel('realtime:reports')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'reports',
          callback: (payload) {
            ref.invalidate(allReportsProvider);
            ref.invalidate(myReportsProvider);
            ref.invalidate(pendingVerificationCountProvider);
            ref.invalidate(interventionCountProvider);
          },
        )
        .subscribe();

    _interventionsChannel = Supabase.instance.client
        .channel('realtime:interventions')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'interventions',
          callback: (payload) {
            ref.invalidate(allReportsProvider);
            ref.invalidate(myReportsProvider);
            ref.invalidate(pendingVerificationCountProvider);
            ref.invalidate(interventionCountProvider);
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    if (_reportsChannel != null) Supabase.instance.client.removeChannel(_reportsChannel!);
    if (_interventionsChannel != null) Supabase.instance.client.removeChannel(_interventionsChannel!);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider).value;
    final isAdmin = profile?.role == 'admin' || profile?.role == 'superadmin';

    final count = isAdmin 
        ? ref.watch(pendingVerificationCountProvider)
        : ref.watch(interventionCountProvider);

    return InkWell(
      onTap: () {
        _showNotificationDialog(context, ref, isAdmin);
      },
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
              count > 0 ? Icons.notifications : Icons.notifications_outlined,
              color: widget.color,
              size: 24,
            ),
            if (count > 0)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isAdmin ? Colors.orange : Colors.red,
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

  void _showNotificationDialog(BuildContext context, WidgetRef ref, bool isAdmin) {
    final reports = isAdmin
        ? ref.read(allReportsProvider).maybeWhen(
              data: (list) => list.take(15).toList(),
              orElse: () => [],
            )
        : ref.read(myReportsProvider).maybeWhen(
              data: (list) => list.where((r) => r.status == 'need_intervention').toList(),
              orElse: () => [],
            );

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Notification',
      barrierColor: Colors.black.withOpacity(0.05),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return Align(
          alignment: Alignment.topRight,
          child: Container(
            margin: const EdgeInsets.only(top: 60, right: 20),
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 300,
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10)),
                  ],
                  border: Border.all(color: Colors.blue[50]!),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isAdmin ? Colors.blue[50] : Colors.orange[50],
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isAdmin ? Icons.assignment_late : Icons.notifications_active, 
                            color: isAdmin ? Colors.blue[800] : Colors.orange, 
                            size: 20
                          ),
                          const SizedBox(width: 10),
                          Text(
                            isAdmin ? 'Laporan Baru' : 'Pemberitahuan',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold, 
                              fontSize: 16, 
                              color: isAdmin ? Colors.blue[900] : Colors.orange[900]
                            ),
                          ),
                          const Spacer(),
                          InkWell(
                            onTap: () => Navigator.pop(context),
                            child: Icon(Icons.close, size: 18, color: isAdmin ? Colors.blue[300] : Colors.orange[300]),
                          ),
                        ],
                      ),
                    ),
                    
                    // List
                    Flexible(
                      child: reports.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle_outline, size: 32, color: Colors.green[200]),
                                  const SizedBox(height: 12),
                                  Text(
                                    isAdmin ? 'Tidak ada laporan baru.' : 'Semua laporan aman!',
                                    style: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 13),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              padding: const EdgeInsets.all(8),
                              itemCount: reports.length,
                              separatorBuilder: (context, index) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                  final report = reports[index];
                                  final interventionsAsync = ref.watch(interventionsByReportProvider(report.id));
                                  final hasRevision = interventionsAsync.maybeWhen(
                                    data: (list) => list.any((item) => item['type'] == 'psn_ulang'),
                                    orElse: () => false,
                                  );

                                  final isUnread = isAdmin ? report.status == 'submitted' : true;
                                  final abjValue = ((report.housesInspected - report.housesPositive) / (report.housesInspected > 0 ? report.housesInspected : 1) * 100);
                                  final timeFormatted = DateFormat('EEE, dd MMM • HH:mm', 'id_ID').format(report.createdAt);
                                  
                                  String subtitleText;
                                  if (isAdmin) {
                                    if (hasRevision && report.status == 'submitted') {
                                      subtitleText = 'Laporan sudah diperbaiki kader. Silakan verifikasi ulang.';
                                    } else {
                                      subtitleText = report.housesPositive > 0 
                                          ? 'Terdapat ${report.housesPositive} rumah positif jentik (ABJ: ${abjValue.toStringAsFixed(1)}%)'
                                          : 'Laporan aman (ABJ: ${abjValue.toStringAsFixed(1)}%)';
                                    }
                                  } else {
                                    subtitleText = 'Silakan cek dan lakukan instruksi perbaikan dari admin';
                                  }

                                  final isRepaired = isAdmin && hasRevision && report.status == 'submitted';
                                
                                return Container(
                                  decoration: BoxDecoration(
                                    color: isRepaired 
                                        ? Colors.green.withOpacity(0.08)
                                        : (isUnread ? Colors.blue.withOpacity(0.05) : Colors.transparent),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: ListTile(
                                    dense: true,
                                    leading: CircleAvatar(
                                      radius: 14,
                                      backgroundColor: isRepaired 
                                          ? Colors.green[100]
                                          : (isUnread ? (isAdmin ? Colors.blue[100] : Colors.orange[100]) : Colors.grey[200]),
                                      child: Icon(
                                        isRepaired 
                                            ? Icons.done_all 
                                            : (isAdmin ? Icons.rate_review : Icons.edit), 
                                        size: 14, 
                                        color: isRepaired 
                                            ? Colors.green[800]
                                            : (isUnread ? (isAdmin ? Colors.blue : Colors.orange) : Colors.grey[500])
                                      ),
                                    ),
                                    title: Text(
                                      '${report.posyanduName ?? 'Laporan'} (${report.villageName ?? '-'})',
                                      style: GoogleFonts.outfit(
                                        fontSize: 13, 
                                        fontWeight: isUnread ? FontWeight.bold : FontWeight.w500,
                                        color: isUnread ? Colors.black87 : Colors.grey[700],
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 2),
                                        Text(
                                          subtitleText,
                                          style: GoogleFonts.outfit(
                                            fontSize: 11, 
                                            color: isRepaired ? Colors.green[800] : (isUnread ? Colors.blue : Colors.grey[500]),
                                            fontWeight: isRepaired ? FontWeight.w600 : (isUnread ? FontWeight.normal : FontWeight.normal),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(Icons.access_time, size: 10, color: Colors.grey[500]),
                                            const SizedBox(width: 4),
                                            Text(
                                              timeFormatted,
                                              style: GoogleFonts.outfit(fontSize: 10, color: Colors.grey[500]),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    trailing: isUnread 
                                        ? Container(
                                            width: 8,
                                            height: 8,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: isRepaired ? Colors.green : Colors.blue,
                                            ),
                                          )
                                        : null,
                                    onTap: () {
                                      if (isAdmin && report.status == 'submitted') {
                                        ref.read(reportRepositoryProvider).updateReportStatus(report.id, 'verified').then((_) {
                                          ref.invalidate(allReportsProvider);
                                        });
                                      }
                                      Navigator.pop(context);
                                      if (isAdmin) {
                                        context.push('/report-detail', extra: report);
                                      } else {
                                        context.push('/report', extra: report);
                                      }
                                    },
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.2, -0.1),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOutBack)),
          child: FadeTransition(
            opacity: anim1,
            child: child,
          ),
        );
      },
    );
  }
}
