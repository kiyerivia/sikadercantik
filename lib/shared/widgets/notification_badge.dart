import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../providers/report_providers.dart';
import '../providers/auth_providers.dart';
import '../domain/models.dart';

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
            _refreshProviders();
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
            _refreshProviders();
          },
        )
        .subscribe();
  }

  void _refreshProviders() {
    ref.invalidate(allReportsProvider);
    ref.invalidate(myReportsProvider);
    ref.invalidate(allInterventionsProvider);
    ref.invalidate(allAdminNotesProvider);
    ref.invalidate(intervenedReportIdsProvider);
    ref.invalidate(pendingVerificationCountProvider);
    ref.invalidate(interventionCountProvider);
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
    final roleClean = profile?.role.toLowerCase() ?? '';
    final isAdmin = roleClean == 'admin' || roleClean == 'superadmin' || roleClean.startsWith('admin') || roleClean.startsWith('superadmin');

    // Watch count
    final count = isAdmin 
        ? ref.watch(pendingVerificationCountProvider)
        : ref.watch(interventionCountProvider);

    // Watch if there are updated reports from kader
    final intervenedReportIds = ref.watch(intervenedReportIdsProvider);
    final allReports = ref.watch(allReportsProvider).value ?? [];
    final hasUpdatedByKader = isAdmin && allReports.any((r) => r.status == 'submitted' && intervenedReportIds.contains(r.id));

    Color badgeColor = Colors.red;
    if (isAdmin) {
      badgeColor = hasUpdatedByKader ? const Color(0xFF059669) : Colors.orange;
    }

    return InkWell(
      onTap: () {
        _refreshProviders();
        _showNotificationDialog(context, isAdmin);
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
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    count > 99 ? '99+' : '$count',
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

  void _showNotificationDialog(BuildContext context, bool isAdmin) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Notification',
      barrierColor: Colors.black.withValues(alpha: 0.25),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (ctx, anim1, anim2) {
        return Align(
          alignment: Alignment.topRight,
          child: Container(
            margin: const EdgeInsets.only(top: 56, right: 16),
            child: Material(
              color: Colors.transparent,
              child: _NotificationDialogContent(isAdmin: isAdmin),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.1, -0.05),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic)),
          child: FadeTransition(
            opacity: anim1,
            child: child,
          ),
        );
      },
    );
  }
}

class _NotificationDialogContent extends ConsumerStatefulWidget {
  final bool isAdmin;
  const _NotificationDialogContent({required this.isAdmin});

  @override
  ConsumerState<_NotificationDialogContent> createState() => _NotificationDialogContentState();
}

class _NotificationDialogContentState extends ConsumerState<_NotificationDialogContent> {
  int _selectedFilter = 0; // 0: Semua, 1: Filter A, 2: Filter B

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth < 420 ? screenWidth * 0.92 : 380.0;

    final allReportsAsync = ref.watch(allReportsProvider);
    final myReportsAsync = ref.watch(myReportsProvider);
    final intervenedReportIds = ref.watch(intervenedReportIdsProvider);
    final adminNotesAsync = ref.watch(allAdminNotesProvider);
    final adminNotes = adminNotesAsync.value ?? {};

    List<Report> rawList = [];
    if (widget.isAdmin) {
      rawList = allReportsAsync.value ?? [];
    } else {
      rawList = myReportsAsync.value ?? [];
    }

    // Process reports based on role
    List<Report> filteredList = [];
    int countTotal = 0;
    int countCategoryA = 0;
    int countCategoryB = 0;

    if (widget.isAdmin) {
      // Admin: focus on submitted reports (waiting verification), both new and edited
      final pendingReports = rawList.where((r) => r.status == 'submitted').toList();
      countTotal = pendingReports.length;
      final newReports = pendingReports.where((r) => !intervenedReportIds.contains(r.id)).toList();
      countCategoryA = newReports.length; // Baru
      final updatedReports = pendingReports.where((r) => intervenedReportIds.contains(r.id)).toList();
      countCategoryB = updatedReports.length; // Diperbarui Kader

      if (_selectedFilter == 0) {
        // Show pending first, then need_intervention
        filteredList = rawList.where((r) => r.status == 'submitted' || r.status == 'need_intervention').toList();
      } else if (_selectedFilter == 1) {
        filteredList = newReports;
      } else if (_selectedFilter == 2) {
        filteredList = updatedReports;
      }
    } else {
      // Kader: focus on need_intervention (need repair) and verified reports
      final needRepair = rawList.where((r) => r.status == 'need_intervention').toList();
      countCategoryA = needRepair.length; // Perlu Perbaikan
      final verifiedReports = rawList.where((r) => r.status == 'verified').toList();
      countCategoryB = verifiedReports.length; // Diverifikasi
      countTotal = countCategoryA;

      if (_selectedFilter == 0) {
        // Prioritize need_intervention first, then verified, then submitted
        filteredList = [
          ...needRepair,
          ...verifiedReports.take(10),
          ...rawList.where((r) => r.status == 'submitted').take(5),
        ];
      } else if (_selectedFilter == 1) {
        filteredList = needRepair;
      } else if (_selectedFilter == 2) {
        filteredList = verifiedReports;
      }
    }

    return Container(
      width: dialogWidth,
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.72),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: widget.isAdmin ? const Color(0xFF10365F) : const Color(0xFF2E7D32),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    widget.isAdmin ? Icons.notifications_active : Icons.campaign_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.isAdmin ? 'Notifikasi Laporan Masuk' : 'Pemberitahuan Laporan',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        widget.isAdmin
                            ? '$countTotal laporan menunggu verifikasi'
                            : (countCategoryA > 0
                                ? '$countCategoryA laporan perlu perbaikan segera'
                                : 'Semua data laporan aman'),
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
                  tooltip: 'Segarkan data',
                  onPressed: () {
                    ref.invalidate(allReportsProvider);
                    ref.invalidate(myReportsProvider);
                    ref.invalidate(allInterventionsProvider);
                    ref.invalidate(allAdminNotesProvider);
                  },
                ),
                InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, size: 16, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),

          // Filter Tabs
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                _buildFilterChip(
                  label: 'Semua',
                  index: 0,
                  count: widget.isAdmin ? countTotal : rawList.length,
                ),
                const SizedBox(width: 6),
                _buildFilterChip(
                  label: widget.isAdmin ? 'Baru' : 'Perlu Revisi',
                  index: 1,
                  count: countCategoryA,
                  highlightColor: widget.isAdmin ? Colors.blue : Colors.red,
                ),
                const SizedBox(width: 6),
                _buildFilterChip(
                  label: widget.isAdmin ? 'Diperbarui' : 'Diverifikasi',
                  index: 2,
                  count: countCategoryB,
                  highlightColor: const Color(0xFF059669),
                ),
              ],
            ),
          ),

          // List Items
          Flexible(
            child: filteredList.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_outline_rounded,
                          size: 40,
                          color: Colors.green.shade300,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.isAdmin
                              ? (_selectedFilter == 1
                                  ? 'Tidak ada laporan baru.'
                                  : (_selectedFilter == 2
                                      ? 'Belum ada laporan yang diperbarui kader.'
                                      : 'Semua laporan sudah terverifikasi.'))
                              : (_selectedFilter == 1
                                  ? 'Tidak ada data yang harus diperbaiki.'
                                  : 'Belum ada notifikasi.'),
                          style: GoogleFonts.outfit(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    itemCount: filteredList.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final report = filteredList[index];
                      final isRepairedByKader = widget.isAdmin &&
                          report.status == 'submitted' &&
                          intervenedReportIds.contains(report.id);
                      final isNewReport = widget.isAdmin &&
                          report.status == 'submitted' &&
                          !intervenedReportIds.contains(report.id);
                      final isNeedIntervention = report.status == 'need_intervention';
                      final isVerified = report.status == 'verified';

                      final adminNote = adminNotes[report.id];
                      final timeFormatted = DateFormat('EEE, d MMM • HH:mm', 'id_ID').format(report.createdAt);

                      return _buildNotificationCard(
                        context: context,
                        ref: ref,
                        report: report,
                        isRepairedByKader: isRepairedByKader,
                        isNewReport: isNewReport,
                        isNeedIntervention: isNeedIntervention,
                        isVerified: isVerified,
                        adminNote: adminNote,
                        timeFormatted: timeFormatted,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required int index,
    required int count,
    Color? highlightColor,
  }) {
    final isSelected = _selectedFilter == index;
    final color = highlightColor ?? (widget.isAdmin ? const Color(0xFF10365F) : const Color(0xFF2E7D32));

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedFilter = index;
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade300,
            ),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? Colors.white : Colors.grey.shade700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.25)
                        : (highlightColor ?? color).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : (highlightColor ?? color),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard({
    required BuildContext context,
    required WidgetRef ref,
    required Report report,
    required bool isRepairedByKader,
    required bool isNewReport,
    required bool isNeedIntervention,
    required bool isVerified,
    required String? adminNote,
    required String timeFormatted,
  }) {
    // Styling attributes based on event type
    Color cardBg;
    Color borderColor;
    Color iconBg;
    Color iconColor;
    IconData iconData;
    String badgeLabel;
    Color badgeBg;
    Color badgeTextColor;
    String descriptionText;

    if (widget.isAdmin) {
      if (isRepairedByKader) {
        cardBg = const Color(0xFFF0FDF4);
        borderColor = const Color(0xFF86EFAC);
        iconBg = const Color(0xFFDCFCE7);
        iconColor = const Color(0xFF059669);
        iconData = Icons.published_with_changes_rounded;
        badgeLabel = 'DIEDIT / DIPERBARUI KADER';
        badgeBg = const Color(0xFF059669);
        badgeTextColor = Colors.white;
        descriptionText = 'Kader telah memperbaiki laporan ini. Silakan tinjau dan verifikasi ulang.';
      } else if (isNewReport) {
        cardBg = const Color(0xFFF0F9FF);
        borderColor = const Color(0xFFBAE6FD);
        iconBg = const Color(0xFFE0F2FE);
        iconColor = const Color(0xFF0284C7);
        iconData = Icons.mark_email_unread_rounded;
        badgeLabel = 'LAPORAN BARU';
        badgeBg = const Color(0xFF0284C7);
        badgeTextColor = Colors.white;
        descriptionText = report.housesPositive > 0
            ? 'Laporan baru: ${report.housesPositive} rumah positif jentik. Menunggu verifikasi.'
            : 'Laporan baru: Bebas jentik (ABJ 100%). Menunggu verifikasi.';
      } else if (isNeedIntervention) {
        cardBg = const Color(0xFFFFFBEB);
        borderColor = const Color(0xFFFDE68A);
        iconBg = const Color(0xFFFEF3C7);
        iconColor = const Color(0xFFD97706);
        iconData = Icons.hourglass_top_rounded;
        badgeLabel = 'MENUNGGU REVISI KADER';
        badgeBg = const Color(0xFFD97706);
        badgeTextColor = Colors.white;
        descriptionText = 'Instruksi perbaikan telah dikirim. Menunggu kader memperbarui data.';
      } else {
        cardBg = Colors.grey.shade50;
        borderColor = Colors.grey.shade200;
        iconBg = Colors.grey.shade200;
        iconColor = Colors.grey.shade600;
        iconData = Icons.check_circle_rounded;
        badgeLabel = 'TERVERIFIKASI';
        badgeBg = Colors.grey.shade400;
        badgeTextColor = Colors.white;
        descriptionText = 'Laporan telah diverifikasi.';
      }
    } else {
      // Kader Perspective
      if (isNeedIntervention) {
        cardBg = const Color(0xFFFFF1F2);
        borderColor = const Color(0xFFFECDD3);
        iconBg = const Color(0xFFFFE4E6);
        iconColor = const Color(0xFFE11D48);
        iconData = Icons.edit_note_rounded;
        badgeLabel = 'PERLU PERBAIKAN DATA';
        badgeBg = const Color(0xFFE11D48);
        badgeTextColor = Colors.white;
        descriptionText = (adminNote != null && adminNote.isNotEmpty)
            ? 'Instruksi Admin: "$adminNote"'
            : 'Admin meminta pengecekan dan perbaikan pada data laporan ini.';
      } else if (isVerified) {
        cardBg = const Color(0xFFF0FDF4);
        borderColor = const Color(0xFFBBF7D0);
        iconBg = const Color(0xFFDCFCE7);
        iconColor = const Color(0xFF16A34A);
        iconData = Icons.verified_rounded;
        badgeLabel = 'TELAH DIVERIFIKASI';
        badgeBg = const Color(0xFF16A34A);
        badgeTextColor = Colors.white;
        descriptionText = 'Laporan Anda telah diperiksa dan disetujui oleh Admin/Superadmin.';
      } else {
        cardBg = const Color(0xFFF8FAFC);
        borderColor = Colors.grey.shade200;
        iconBg = const Color(0xFFE2E8F0);
        iconColor = const Color(0xFF475569);
        iconData = Icons.schedule_rounded;
        badgeLabel = 'MENUNGGU VERIFIKASI';
        badgeBg = const Color(0xFF475569);
        badgeTextColor = Colors.white;
        descriptionText = 'Laporan telah dikirim. Sedang menunggu antrean verifikasi admin.';
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: InkWell(
        onTap: () {
          Navigator.pop(context); // Close notification dialog
          if (widget.isAdmin) {
            context.push('/report-detail', extra: report);
          } else {
            if (isNeedIntervention) {
              // Direct kader to edit form to fix data immediately
              context.push('/report', extra: report);
            } else {
              context.push('/history');
            }
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badge & Time Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      badgeLabel,
                      style: GoogleFonts.outfit(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: badgeTextColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  Text(
                    timeFormatted,
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Title & Icon Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(iconData, color: iconColor, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${report.posyanduName ?? 'Posyandu'} • ${report.villageName ?? '-'}',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          descriptionText,
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: isNeedIntervention
                                ? Colors.red.shade900
                                : (isRepairedByKader
                                    ? Colors.green.shade900
                                    : Colors.black87.withValues(alpha: 0.7)),
                            fontWeight: (isNeedIntervention || isRepairedByKader)
                                ? FontWeight.w600
                                : FontWeight.normal,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Action button row
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (!widget.isAdmin && isNeedIntervention) ...[
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        backgroundColor: const Color(0xFFE11D48),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        minimumSize: const Size(0, 28),
                      ),
                      icon: const Icon(Icons.edit, size: 13),
                      label: Text(
                        'Perbaiki Sekarang',
                        style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        context.push('/report', extra: report);
                      },
                    ),
                  ] else ...[
                    Row(
                      children: [
                        Text(
                          widget.isAdmin ? 'Tinjau Laporan' : 'Lihat Detail',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: widget.isAdmin ? const Color(0xFF0284C7) : const Color(0xFF16A34A),
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 10,
                          color: widget.isAdmin ? const Color(0xFF0284C7) : const Color(0xFF16A34A),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
