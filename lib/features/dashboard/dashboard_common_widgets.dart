import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../shared/domain/models.dart';
import '../../shared/widgets/notification_badge.dart';
import '../../shared/widgets/user_profile_menu.dart';
import '../../shared/services/location_service.dart';
import '../../core/theme/app_theme.dart';

// ─────────────────────────────────────────────────────────
//  Dashboard Hero Section (Adaptive for Desktop & Mobile)
// ─────────────────────────────────────────────────────────

class DashboardHeroSection extends StatelessWidget {
  final String greetingTitle;
  final String greetingSubtitle;
  final AsyncValue<String> locationAsync;
  final String statusLabel;
  final Color statusColor;
  final IconData statusIcon;
  final VoidCallback onStatusTap;

  const DashboardHeroSection({
    super.key,
    required this.greetingTitle,
    required this.greetingSubtitle,
    required this.locationAsync,
    required this.statusLabel,
    required this.statusColor,
    required this.statusIcon,
    required this.onStatusTap,
  });

  Widget _buildGreetingContent(
    AsyncValue<String> locationAsync, {
    bool isDesktop = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          greetingTitle,
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            color: const Color(0xFF10365F),
            fontSize: isDesktop ? 17 : 14.5,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          greetingSubtitle,
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            color: const Color(0xFF4A5568),
            fontSize: isDesktop ? 11.5 : 9.5,
            height: 1.25,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 5),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.location_on,
              color: const Color(0xFF10365F),
              size: isDesktop ? 15 : 12,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: locationAsync.when(
                data: (loc) => Text(
                  loc,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF10365F),
                    fontSize: isDesktop ? 11 : 9.5,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                loading: () => Text(
                  'Mencari lokasi...',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF718096),
                    fontSize: isDesktop ? 11 : 9.5,
                  ),
                ),
                error: (_, _) => Text(
                  LocationService.defaultLocation,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF10365F),
                    fontSize: isDesktop ? 11 : 9.5,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildJentikButtonContent(
    BuildContext context, {
    bool isDesktop = false,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onStatusTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 14 : 6,
            vertical: isDesktop ? 12 : 8,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(isDesktop ? 6 : 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border:
                      Border.all(color: const Color(0xFF4FC3F7), width: 1.5),
                ),
                child: Image.asset(
                  'assets/images/icon_mosquito_blue.png',
                  width: isDesktop ? 34 : 26,
                  height: isDesktop ? 34 : 26,
                  fit: BoxFit.contain,
                ),
              ),
              SizedBox(width: isDesktop ? 10 : 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Jentik Nyamuk',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF10365F),
                        fontSize: isDesktop ? 14.5 : 12.5,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            statusLabel,
                            style: GoogleFonts.outfit(
                              color: statusColor,
                              fontSize: isDesktop ? 13 : 11.5,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Icon(
                          statusIcon,
                          color: statusColor,
                          size: isDesktop ? 17 : 13,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 2),
              Icon(
                Icons.chevron_right,
                color: const Color(0xFF0288D1),
                size: isDesktop ? 22 : 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderContent({bool isDesktop = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 28 : 24,
        vertical: isDesktop ? 14 : 12,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/logo_dinas_banyumas.png',
                height: isDesktop ? 36 : 38,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                    const SizedBox.shrink(),
              ),
              SizedBox(width: isDesktop ? 12 : 10),
              Text(
                'SiKader Cantik',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: isDesktop ? 18 : 21,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const NotificationBadge(),
              SizedBox(width: isDesktop ? 14 : 12),
              const UserProfileMenu(),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1000;
    final isTablet = screenWidth >= 650 && screenWidth < 1000;
    final horizontalPadding = isDesktop ? 32.0 : (isTablet ? 24.0 : 16.0);

    if (screenWidth < 768) {
      // ── HP / MOBILE MODE (Symmetrical, proportionally fitted) ──
      const double baseWidth = 640.0;
      const double heroHeight = 350.0;
      final scale = screenWidth / baseWidth;

      return SizedBox(
        width: screenWidth,
        height: heroHeight * scale,
        child: FittedBox(
          fit: BoxFit.contain,
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: baseWidth,
            height: heroHeight,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                // Layer 1: Background spans full width at the top
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 300,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                    child: Image.asset(
                      'assets/images/background_dashboard.png',
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                    ),
                  ),
                ),

                // Layer 2: Curved Header Bar
                Positioned(
                  top: 0,
                  left: 58,
                  right: 58,
                  height: 115,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned.fill(
                        child: Image.asset(
                          'assets/images/header.png',
                          fit: BoxFit.fill,
                        ),
                      ),
                      Positioned.fill(
                        child: _buildHeaderContent(isDesktop: false),
                      ),
                    ],
                  ),
                ),

                // Layer 3: Shape White Card
                Positioned(
                  bottom: 0,
                  left: 24,
                  right: 24,
                  height: 136,
                  child: Image.asset(
                    'assets/images/shape_white.png',
                    fit: BoxFit.fill,
                  ),
                ),

                // Layer 4: Left Greeting
                Positioned(
                  left: 42,
                  bottom: 16,
                  width: 200,
                  height: 104,
                  child: _buildGreetingContent(locationAsync, isDesktop: false),
                ),

                // Layer 5: Right Jentik Button
                Positioned(
                  right: 42,
                  bottom: 16,
                  width: 200,
                  height: 104,
                  child: _buildJentikButtonContent(context, isDesktop: false),
                ),

                // Layer 6: Center Emblem Logo
                Positioned(
                  bottom: 8,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Image.asset(
                      'assets/images/logo_sikadercantik_new.png',
                      width: 185,
                      height: 185,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // ── WINDOWS / DESKTOP MODE (Full width adaptation) ──
    const double heroHeight = 400.0;

    return SizedBox(
      width: double.infinity,
      height: heroHeight,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          // Layer 1: Background spans 100% full width
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 330,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
              child: Image.asset(
                'assets/images/background_dashboard.png',
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            ),
          ),

          // Layer 2: Header at the top
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Center(
              child: SizedBox(
                width: 720,
                height: 90,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned.fill(
                      child: Image.asset(
                        'assets/images/header.png',
                        fit: BoxFit.fill,
                      ),
                    ),
                    Positioned.fill(
                      child: _buildHeaderContent(isDesktop: true),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Layer 3: Shape White spans horizontally full width with horizontalPadding
          Positioned(
            bottom: 0,
            left: horizontalPadding,
            right: horizontalPadding,
            height: 138,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/shape_white.png',
                    fit: BoxFit.fill,
                    centerSlice: const Rect.fromLTRB(80, 30, 597, 118),
                  ),
                ),
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Left Greeting Content
                        Expanded(
                          child: Align(
                            alignment: Alignment.center,
                            child: _buildGreetingContent(
                              locationAsync,
                              isDesktop: true,
                            ),
                          ),
                        ),
                        // Center reserved slot for Logo
                        const SizedBox(width: 230),
                        // Right Jentik Button
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 300),
                              child: _buildJentikButtonContent(
                                context,
                                isDesktop: true,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Layer 4: Center Emblem Logo
          Positioned(
            bottom: 6,
            left: 0,
            right: 0,
            child: Center(
              child: Image.asset(
                'assets/images/logo_sikadercantik_new.png',
                width: 230,
                height: 230,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  Quick Action Card (Modern Light Blue Themed Card)
// ─────────────────────────────────────────────────────────

class QuickActionCard extends StatelessWidget {
  final String? iconAsset;
  final Widget? iconWidget;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final double iconWidth;
  final double iconHeight;

  const QuickActionCard({
    super.key,
    this.iconAsset,
    this.iconWidget,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconWidth = 40,
    this.iconHeight = 40,
  }) : assert(iconAsset != null || iconWidget != null);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFE8F4FD),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFBCE0FD), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1976D2).withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                height: 44,
                child: Center(
                  child: iconAsset != null
                      ? Image.asset(
                          iconAsset!,
                          width: iconWidth,
                          height: iconHeight,
                          fit: BoxFit.contain,
                        )
                      : iconWidget!,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: GoogleFonts.outfit(
                  color: const Color(0xFF10365F),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.outfit(
                  color: const Color(0xFFE65100),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  ABJ Trend Chart Card (Target >= 95%)
// ─────────────────────────────────────────────────────────

class _AbjPoint {
  final String label;
  final String fullLabel;
  final double abj;
  final int inspected;
  final int positive;

  _AbjPoint({
    required this.label,
    required this.fullLabel,
    required this.abj,
    required this.inspected,
    required this.positive,
  });
}

List<_AbjPoint> _computeAbjPoints(List<Report> reports) {
  if (reports.isEmpty) return [];

  final Map<String, List<Report>> grouped = {};
  for (final r in reports) {
    final key =
        '${r.reportDate.year}-${r.reportDate.month.toString().padLeft(2, '0')}';
    grouped.putIfAbsent(key, () => []).add(r);
  }

  const monthNames = [
    '',
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agt',
    'Sep',
    'Okt',
    'Nov',
    'Des'
  ];
  const fullMonthNames = [
    '',
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember'
  ];

  final sortedKeys = grouped.keys.toList()..sort();

  if (sortedKeys.length == 1) {
    final Map<String, List<Report>> dayGrouped = {};
    for (final r in reports) {
      final dayKey =
          '${r.reportDate.year}-${r.reportDate.month.toString().padLeft(2, '0')}-${r.reportDate.day.toString().padLeft(2, '0')}';
      dayGrouped.putIfAbsent(dayKey, () => []).add(r);
    }
    final sortedDays = dayGrouped.keys.toList()..sort();
    return sortedDays.map((dKey) {
      final parts = dKey.split('-');
      final day = int.parse(parts[2]);
      final month = int.parse(parts[1]);
      int inspected = 0;
      int positive = 0;
      for (final r in dayGrouped[dKey]!) {
        inspected += r.housesInspected;
        positive += r.housesPositive;
      }
      final free = (inspected - positive).clamp(0, inspected);
      final abj = inspected > 0 ? (free / inspected * 100) : 100.0;
      return _AbjPoint(
        label: '$day ${monthNames[month]}',
        fullLabel: '$day ${fullMonthNames[month]} ${parts[0]}',
        abj: abj,
        inspected: inspected,
        positive: positive,
      );
    }).toList();
  }

  final recentKeys = sortedKeys.length > 8
      ? sortedKeys.sublist(sortedKeys.length - 8)
      : sortedKeys;

  return recentKeys.map((key) {
    final parts = key.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);

    int inspected = 0;
    int positive = 0;
    for (final r in grouped[key]!) {
      inspected += r.housesInspected;
      positive += r.housesPositive;
    }
    final free = (inspected - positive).clamp(0, inspected);
    final abj = inspected > 0 ? (free / inspected * 100) : 100.0;

    return _AbjPoint(
      label: monthNames[month],
      fullLabel: '${fullMonthNames[month]} $year',
      abj: abj,
      inspected: inspected,
      positive: positive,
    );
  }).toList();
}

class AbjTrendChartCard extends StatelessWidget {
  final AsyncValue<List<Report>> allReportsAsync;

  const AbjTrendChartCard({super.key, required this.allReportsAsync});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header: Icon + Title + Target Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE1F5FE),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.show_chart_rounded,
                  color: Color(0xFF0288D1),
                  size: 17,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Tren Capaian ABJ',
                      style: GoogleFonts.outfit(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF10365F),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Akumulasi semua laporan',
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        color: const Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFA5D6A7)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle_outline_rounded,
                      size: 11,
                      color: Color(0xFF2E7D32),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      'Target ≥95%',
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2E7D32),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Chart Body (Compact height: 125px)
          SizedBox(
            height: 125,
            child: allReportsAsync.when(
              data: (reports) {
                final points = _computeAbjPoints(reports);
                if (points.isEmpty) {
                  return Center(
                    child: Text(
                      'Belum ada data laporan untuk grafik',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF94A3B8),
                        fontSize: 12,
                      ),
                    ),
                  );
                }

                final minX = 0.0;
                final maxX =
                    (points.length - 1).toDouble().clamp(1.0, 100.0);

                return LineChart(
                  LineChartData(
                    minY: 0,
                    maxY: 105,
                    minX: minX,
                    maxX: maxX,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 50,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: const Color(0xFFF1F5F9),
                        strokeWidth: 1.0,
                        dashArray: [4, 4],
                      ),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: const Border(
                        bottom:
                            BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
                        left: BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
                        top: BorderSide.none,
                        right: BorderSide.none,
                      ),
                    ),
                    extraLinesData: ExtraLinesData(
                      horizontalLines: [
                        HorizontalLine(
                          y: 95,
                          color:
                              const Color(0xFF2E7D32).withValues(alpha: 0.6),
                          strokeWidth: 1.2,
                          dashArray: [5, 4],
                          label: HorizontalLineLabel(
                            show: true,
                            alignment: Alignment.topRight,
                            padding: const EdgeInsets.only(right: 4, bottom: 1),
                            style: GoogleFonts.outfit(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF2E7D32),
                            ),
                            labelResolver: (line) => 'Target 95%',
                          ),
                        ),
                      ],
                    ),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 32,
                          interval: 50,
                          getTitlesWidget: (value, meta) {
                            if (value > 100) return const SizedBox.shrink();
                            return Text(
                              '${value.toInt()}%',
                              style: GoogleFonts.outfit(
                                fontSize: 9.5,
                                color: const Color(0xFF94A3B8),
                                fontWeight: FontWeight.w600,
                              ),
                            );
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 22,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            final idx = value.round();
                            if (idx >= 0 &&
                                idx < points.length &&
                                (value - idx).abs() < 0.15) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  points[idx].label,
                                  style: GoogleFonts.outfit(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                    ),
                    lineTouchData: LineTouchData(
                      enabled: true,
                      handleBuiltInTouches: true,
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipColor: (spot) => const Color(0xFF10365F),
                        tooltipBorderRadius: BorderRadius.circular(8),
                        tooltipPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((spot) {
                            final idx = spot.x.round();
                            final p = idx >= 0 && idx < points.length
                                ? points[idx]
                                : null;
                            final label = p?.fullLabel ?? '';
                            return LineTooltipItem(
                              '$label\n',
                              GoogleFonts.outfit(
                                color: Colors.white70,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w500,
                              ),
                              children: [
                                TextSpan(
                                  text: 'ABJ: ${spot.y.toStringAsFixed(1)}%',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            );
                          }).toList();
                        },
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: List.generate(
                          points.length,
                          (i) => FlSpot(i.toDouble(), points[i].abj),
                        ),
                        isCurved: true,
                        curveSmoothness: 0.25,
                        preventCurveOverShooting: true,
                        color: const Color(0xFF0288D1),
                        barWidth: 2.6,
                        isStrokeCapRound: true,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) {
                            final isTargetMet = spot.y >= 95;
                            return FlDotCirclePainter(
                              radius: 3.5,
                              color: Colors.white,
                              strokeWidth: 2.0,
                              strokeColor: isTargetMet
                                  ? const Color(0xFF2E7D32)
                                  : const Color(0xFF0288D1),
                            );
                          },
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              const Color(0xFF0288D1).withValues(alpha: 0.20),
                              const Color(0xFF0288D1).withValues(alpha: 0.01),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
              loading: () => const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              error: (_, _) => Center(
                child: Text(
                  'Gagal memuat data grafik',
                  style: GoogleFonts.outfit(
                    color: Colors.red.shade400,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Keterangan di bawah diagram
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFEDF2F7)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 10,
                  height: 2.5,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0288D1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Grafik Angka Bebas Jentik',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF10365F),
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  Kader Detailed Bar Chart Card (Diagram Batang Rincian Pemeriksaan)
// ─────────────────────────────────────────────────────────

class _BarChartDetailItem {
  final String key;
  final String label;
  final String fullLabel;
  final int inspected;
  final int positive;
  final int free;
  final double abj;

  _BarChartDetailItem({
    required this.key,
    required this.label,
    required this.fullLabel,
    required this.inspected,
    required this.positive,
    required this.free,
    required this.abj,
  });
}

List<_BarChartDetailItem> _computeBarMonthlyItems(List<Report> reports) {
  if (reports.isEmpty) return [];

  final Map<String, List<Report>> grouped = {};
  for (final r in reports) {
    final key =
        '${r.reportDate.year}-${r.reportDate.month.toString().padLeft(2, '0')}';
    grouped.putIfAbsent(key, () => []).add(r);
  }

  const monthNames = [
    '',
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agt',
    'Sep',
    'Okt',
    'Nov',
    'Des'
  ];
  const fullMonthNames = [
    '',
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember'
  ];

  final sortedKeys = grouped.keys.toList()..sort();

  if (sortedKeys.length == 1) {
    final Map<String, List<Report>> dayGrouped = {};
    for (final r in reports) {
      final dayKey =
          '${r.reportDate.year}-${r.reportDate.month.toString().padLeft(2, '0')}-${r.reportDate.day.toString().padLeft(2, '0')}';
      dayGrouped.putIfAbsent(dayKey, () => []).add(r);
    }
    final sortedDays = dayGrouped.keys.toList()..sort();
    return sortedDays.map((dKey) {
      final parts = dKey.split('-');
      final day = int.parse(parts[2]);
      final month = int.parse(parts[1]);
      int inspected = 0;
      int positive = 0;
      for (final r in dayGrouped[dKey]!) {
        inspected += r.housesInspected;
        positive += r.housesPositive;
      }
      final free = (inspected - positive).clamp(0, inspected);
      final abj = inspected > 0 ? (free / inspected * 100) : 100.0;
      return _BarChartDetailItem(
        key: dKey,
        label: '$day ${monthNames[month]}',
        fullLabel: '$day ${fullMonthNames[month]} ${parts[0]}',
        inspected: inspected,
        positive: positive,
        free: free,
        abj: abj,
      );
    }).toList();
  }

  final bool hasMultipleYears =
      sortedKeys.map((k) => k.split('-')[0]).toSet().length > 1;

  return sortedKeys.map((key) {
    final parts = key.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);

    int inspected = 0;
    int positive = 0;
    for (final r in grouped[key]!) {
      inspected += r.housesInspected;
      positive += r.housesPositive;
    }
    final free = (inspected - positive).clamp(0, inspected);
    final abj = inspected > 0 ? (free / inspected * 100) : 100.0;

    final shortYear =
        year.toString().length >= 4 ? year.toString().substring(2) : '$year';
    final label =
        hasMultipleYears ? "${monthNames[month]} '$shortYear" : monthNames[month];

    return _BarChartDetailItem(
      key: key,
      label: label,
      fullLabel: '${fullMonthNames[month]} $year',
      inspected: inspected,
      positive: positive,
      free: free,
      abj: abj,
    );
  }).toList();
}

List<_BarChartDetailItem> _computeBarPosyanduItems(List<Report> reports) {
  if (reports.isEmpty) return [];

  final Map<String, List<Report>> grouped = {};
  for (final r in reports) {
    final pName = (r.posyanduName != null && r.posyanduName!.trim().isNotEmpty)
        ? r.posyanduName!.trim()
        : (r.villageName != null && r.villageName!.trim().isNotEmpty
            ? r.villageName!.trim()
            : 'Posyandu Lainnya');
    grouped.putIfAbsent(pName, () => []).add(r);
  }

  final sortedNames = grouped.keys.toList()..sort();
  return sortedNames.map((name) {
    int inspected = 0;
    int positive = 0;
    for (final r in grouped[name]!) {
      inspected += r.housesInspected;
      positive += r.housesPositive;
    }
    final free = (inspected - positive).clamp(0, inspected);
    final abj = inspected > 0 ? (free / inspected * 100) : 100.0;
    return _BarChartDetailItem(
      key: name,
      label: name,
      fullLabel: name,
      inspected: inspected,
      positive: positive,
      free: free,
      abj: abj,
    );
  }).toList();
}

typedef DetailedBarChartCard = KaderDetailedBarChartCard;

class KaderDetailedBarChartCard extends StatefulWidget {
  final AsyncValue<List<Report>> allReportsAsync;

  const KaderDetailedBarChartCard({super.key, required this.allReportsAsync});

  @override
  State<KaderDetailedBarChartCard> createState() =>
      _KaderDetailedBarChartCardState();
}

class _KaderDetailedBarChartCardState
    extends State<KaderDetailedBarChartCard> {
  static const List<String> _monthNames = [
    'Semua Bulan',
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  bool _isAbjMode = false; // false = Jumlah Rumah, true = Nilai ABJ %
  bool _groupByPosyandu = false; // false = Bulanan, true = Per Posyandu
  int _selectedYear = 0; // 0 = Semua Tahun
  int _selectedMonth = 0; // 0 = Semua Bulan
  bool _showTable = false; // Toggle view table
  int? _touchedGroupIndex;

  String _getPeriodBadgeText() {
    if (_selectedYear == 0 && _selectedMonth == 0) {
      return 'Semua Tahun';
    } else if (_selectedYear != 0 && _selectedMonth != 0) {
      return '${_monthNames[_selectedMonth]} $_selectedYear';
    } else if (_selectedYear != 0) {
      return 'Tahun $_selectedYear';
    } else {
      return _monthNames[_selectedMonth];
    }
  }

  String _getPeriodSubtitle() {
    if (_selectedYear == 0 && _selectedMonth == 0) {
      return 'Akumulasi semua laporan';
    } else if (_selectedYear != 0 && _selectedMonth != 0) {
      return 'Periode ${_monthNames[_selectedMonth]} $_selectedYear';
    } else if (_selectedYear != 0) {
      return 'Periode Tahun $_selectedYear';
    } else {
      return 'Periode Bulan ${_monthNames[_selectedMonth]}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: widget.allReportsAsync.when(
        data: (reports) {
          if (reports.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Text(
                  'Belum ada data laporan untuk diagram batang',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF94A3B8),
                    fontSize: 12,
                  ),
                ),
              ),
            );
          }

          final availableYears = reports
              .map((r) => r.reportDate.year)
              .toSet()
              .toList()
            ..sort((a, b) => b.compareTo(a));

          final filteredReports = reports.where((r) {
            final matchYear =
                _selectedYear == 0 || r.reportDate.year == _selectedYear;
            final matchMonth =
                _selectedMonth == 0 || r.reportDate.month == _selectedMonth;
            return matchYear && matchMonth;
          }).toList();

          final monthlyItems = _computeBarMonthlyItems(filteredReports);
          final posyanduItems = _computeBarPosyanduItems(filteredReports);
          final allPosyandus = reports
              .map((r) => (r.posyanduName != null && r.posyanduName!.trim().isNotEmpty)
                  ? r.posyanduName!.trim()
                  : (r.villageName != null && r.villageName!.trim().isNotEmpty
                      ? r.villageName!.trim()
                      : 'Posyandu Lainnya'))
              .toSet();
          final hasMultiplePosyandus = allPosyandus.length > 1;

          final items = (_groupByPosyandu && hasMultiplePosyandus)
              ? posyanduItems
              : monthlyItems;

          int totalInspected = 0;
          int totalPositive = 0;
          for (final item in items) {
            totalInspected += item.inspected;
            totalPositive += item.positive;
          }
          final int totalFree =
              (totalInspected - totalPositive).clamp(0, totalInspected);
          final double overallAbj = totalInspected > 0
              ? (totalFree / totalInspected * 100)
              : 0.0;
          final double freePct = totalInspected > 0
              ? (totalFree / totalInspected * 100)
              : 0.0;
          final double posPct = totalInspected > 0
              ? (totalPositive / totalInspected * 100)
              : 0.0;
          final bool isOverallTargetMet =
              totalInspected > 0 && overallAbj >= 95.0;

          final screenWidth = MediaQuery.of(context).size.width;
          final isDesktop = screenWidth >= 900;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Row
              _buildHeader(hasMultiplePosyandus, availableYears),

              const SizedBox(height: 14),

              // KPI Summary Badges
              _buildKpiSummary(
                totalInspected: totalInspected,
                totalFree: totalFree,
                totalPositive: totalPositive,
                freePct: freePct,
                posPct: posPct,
                overallAbj: overallAbj,
                isOverallTargetMet: isOverallTargetMet,
              ),

              const SizedBox(height: 16),

              // Bar Chart Body (Scrollable horizontally if data spans many periods/years)
              LayoutBuilder(
                builder: (context, constraints) {
                  if (items.isEmpty) {
                    return Container(
                      height: 180,
                      width: double.infinity,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.bar_chart_rounded,
                            size: 38,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tidak ada data pada periode yang dipilih',
                            style: GoogleFonts.outfit(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Coba pilih bulan atau tahun lainnya',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final double barWidth = isDesktop ? 60.0 : 46.0;
                  final double minRequiredWidth = items.length * barWidth;
                  final bool needsScroll = minRequiredWidth > constraints.maxWidth;

                  final chartWidget = SizedBox(
                    width: needsScroll ? minRequiredWidth : constraints.maxWidth,
                    height: isDesktop ? 220 : 190,
                    child: _buildBarChart(items, isDesktop),
                  );

                  if (needsScroll) {
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: chartWidget,
                    );
                  }
                  return chartWidget;
                },
              ),

              if (items.isNotEmpty) ...[
                const SizedBox(height: 12),

                // Legend
                _buildLegend(),

                const SizedBox(height: 14),

                // Table Toggle Button
                _buildTableToggleButton(items),

                // Expandable Detail Table
                if (_showTable) ...[
                  const SizedBox(height: 12),
                  _buildDetailTable(items, totalInspected, totalFree,
                      totalPositive, overallAbj, isOverallTargetMet),
                ],
              ],
            ],
          );
        },
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 36.0),
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            child: Text(
              'Gagal memuat data diagram: $err',
              style: GoogleFonts.outfit(
                color: Colors.red.shade400,
                fontSize: 11.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
      bool hasMultiplePosyandus, List<int> availableYears) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 780;

        final titleRow = Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: const Color(0xFFE0F2FE),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.bar_chart_rounded,
                color: Color(0xFF0284C7),
                size: 19,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          'Diagram Detail Pemeriksaan Jentik',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF10365F),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F2FE),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFBAE6FD)),
                        ),
                        child: Text(
                          _getPeriodBadgeText(),
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0284C7),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    _isAbjMode
                        ? 'Capaian persentase ABJ • ${_getPeriodSubtitle()}'
                        : 'Rumah bebas vs positif jentik • ${_getPeriodSubtitle()}',
                    style: GoogleFonts.outfit(
                      fontSize: 10.5,
                      color: const Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        );

        final controlsRow = Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            // Year Selector
            if (availableYears.isNotEmpty)
              Container(
                height: 30,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _selectedYear,
                    isDense: true,
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 16,
                      color: Color(0xFF0288D1),
                    ),
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF10365F),
                    ),
                    items: [
                      const DropdownMenuItem(
                          value: 0, child: Text('Semua Tahun')),
                      ...availableYears.map(
                        (y) => DropdownMenuItem(
                            value: y, child: Text('$y')),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedYear = val);
                    },
                  ),
                ),
              ),

            // Month Selector
            Container(
              height: 30,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _selectedMonth,
                  isDense: true,
                  icon: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: Color(0xFF0288D1),
                  ),
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF10365F),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: 0,
                      child: Text('Semua Bulan'),
                    ),
                    for (int m = 1; m <= 12; m++)
                      DropdownMenuItem(
                        value: m,
                        child: Text(_monthNames[m]),
                      ),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedMonth = val);
                  },
                ),
              ),
            ),

            _buildModeToggle(),

            if (hasMultiplePosyandus) ...[
              ChoiceChip(
                label: Text(
                  'Per Periode',
                  style: GoogleFonts.outfit(
                    fontSize: 10.5,
                    fontWeight: !_groupByPosyandu
                        ? FontWeight.bold
                        : FontWeight.w500,
                    color: !_groupByPosyandu
                        ? const Color(0xFF0284C7)
                        : const Color(0xFF64748B),
                  ),
                ),
                selected: !_groupByPosyandu,
                selectedColor: const Color(0xFFE0F2FE),
                backgroundColor: const Color(0xFFF1F5F9),
                side: BorderSide(
                  color: !_groupByPosyandu
                      ? const Color(0xFF7DD3FC)
                      : Colors.transparent,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                visualDensity: VisualDensity.compact,
                onSelected: (val) {
                  if (val) setState(() => _groupByPosyandu = false);
                },
              ),
              ChoiceChip(
                label: Text(
                  'Per Posyandu',
                  style: GoogleFonts.outfit(
                    fontSize: 10.5,
                    fontWeight: _groupByPosyandu
                        ? FontWeight.bold
                        : FontWeight.w500,
                    color: _groupByPosyandu
                        ? const Color(0xFF0284C7)
                        : const Color(0xFF64748B),
                  ),
                ),
                selected: _groupByPosyandu,
                selectedColor: const Color(0xFFE0F2FE),
                backgroundColor: const Color(0xFFF1F5F9),
                side: BorderSide(
                  color: _groupByPosyandu
                      ? const Color(0xFF7DD3FC)
                      : Colors.transparent,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                visualDensity: VisualDensity.compact,
                onSelected: (val) {
                  if (val) setState(() => _groupByPosyandu = true);
                },
              ),
            ],
          ],
        );

        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleRow,
              const SizedBox(height: 10),
              controlsRow,
            ],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: titleRow),
            const SizedBox(width: 12),
            controlsRow,
          ],
        );
      },
    );
  }

  Widget _buildModeToggle() {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () => setState(() => _isAbjMode = false),
            borderRadius: BorderRadius.circular(7),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: !_isAbjMode ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(7),
                boxShadow: !_isAbjMode
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.home_outlined,
                    size: 13,
                    color: !_isAbjMode
                        ? const Color(0xFF10365F)
                        : const Color(0xFF64748B),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Rumah',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight:
                          !_isAbjMode ? FontWeight.bold : FontWeight.w500,
                      color: !_isAbjMode
                          ? const Color(0xFF10365F)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ),
          InkWell(
            onTap: () => setState(() => _isAbjMode = true),
            borderRadius: BorderRadius.circular(7),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: _isAbjMode ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(7),
                boxShadow: _isAbjMode
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.percent_rounded,
                    size: 13,
                    color: _isAbjMode
                        ? const Color(0xFF10365F)
                        : const Color(0xFF64748B),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'ABJ %',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight:
                          _isAbjMode ? FontWeight.bold : FontWeight.w500,
                      color: _isAbjMode
                          ? const Color(0xFF10365F)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiSummary({
    required int totalInspected,
    required int totalFree,
    required int totalPositive,
    required double freePct,
    required double posPct,
    required double overallAbj,
    required bool isOverallTargetMet,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 560;
        final cardWidth = isSmall
            ? (constraints.maxWidth - 8) / 2
            : (constraints.maxWidth - 24) / 4;

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildKpiCard(
              title: 'Diperiksa',
              value: '$totalInspected',
              subtitle: 'Total Rumah',
              icon: Icons.home_work_outlined,
              accentColor: const Color(0xFF0284C7),
              bgColor: const Color(0xFFF0F9FF),
              borderColor: const Color(0xFFBAE6FD),
              width: cardWidth,
            ),
            _buildKpiCard(
              title: 'Bebas Jentik',
              value: '$totalFree',
              subtitle: totalInspected > 0
                  ? '${freePct.toStringAsFixed(1)}% Aman'
                  : '-',
              icon: Icons.check_circle_outline_rounded,
              accentColor: const Color(0xFF16A34A),
              bgColor: const Color(0xFFF0FDF4),
              borderColor: const Color(0xFFBBF7D0),
              width: cardWidth,
            ),
            _buildKpiCard(
              title: 'Positif Jentik',
              value: '$totalPositive',
              subtitle: totalInspected > 0
                  ? '${posPct.toStringAsFixed(1)}% Jentik'
                  : '-',
              icon: Icons.bug_report_outlined,
              accentColor: const Color(0xFFDC2626),
              bgColor: const Color(0xFFFEF2F2),
              borderColor: const Color(0xFFFECACA),
              width: cardWidth,
            ),
            _buildKpiCard(
              title: 'Rata-rata ABJ',
              value: totalInspected > 0
                  ? '${overallAbj.toStringAsFixed(1)}%'
                  : '-',
              subtitle: totalInspected == 0
                  ? 'Belum ada data'
                  : (isOverallTargetMet
                      ? 'Target ≥95% Terpenuhi'
                      : 'Waspada <95%'),
              icon: isOverallTargetMet
                  ? Icons.verified_rounded
                  : (totalInspected == 0
                      ? Icons.info_outline_rounded
                      : Icons.warning_amber_rounded),
              accentColor: totalInspected == 0
                  ? const Color(0xFF64748B)
                  : (isOverallTargetMet
                      ? const Color(0xFF16A34A)
                      : const Color(0xFFEA580C)),
              bgColor: totalInspected == 0
                  ? const Color(0xFFF8FAFC)
                  : (isOverallTargetMet
                      ? const Color(0xFFF0FDF4)
                      : const Color(0xFFFFF7ED)),
              borderColor: totalInspected == 0
                  ? const Color(0xFFE2E8F0)
                  : (isOverallTargetMet
                      ? const Color(0xFFBBF7D0)
                      : const Color(0xFFFED7AA)),
              width: cardWidth,
            ),
          ],
        );
      },
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required Color bgColor,
    required Color borderColor,
    required double width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: accentColor),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF10365F),
                    height: 1.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF475569),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.outfit(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w500,
                    color: accentColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(List<_BarChartDetailItem> items, bool isDesktop) {
    if (_isAbjMode) {
      return _buildAbjBarChart(items, isDesktop);
    } else {
      return _buildHousesBarChart(items, isDesktop);
    }
  }

  Widget _buildHousesBarChart(
      List<_BarChartDetailItem> items, bool isDesktop) {
    int maxVal = 0;
    for (final it in items) {
      if (it.free > maxVal) maxVal = it.free;
      if (it.positive > maxVal) maxVal = it.positive;
    }
    final double maxY = maxVal <= 0 ? 10.0 : (maxVal * 1.25).ceilToDouble();
    final double interval = (maxY / 4).clamp(1.0, 100000.0);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        minY: 0,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: interval,
          getDrawingHorizontalLine: (val) => FlLine(
            color: const Color(0xFFF1F5F9),
            strokeWidth: 1.0,
            dashArray: [4, 4],
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: const Border(
            bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
            left: BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
            top: BorderSide.none,
            right: BorderSide.none,
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: interval,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: GoogleFonts.outfit(
                    fontSize: 9.5,
                    color: const Color(0xFF94A3B8),
                    fontWeight: FontWeight.w600,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx >= 0 &&
                    idx < items.length &&
                    (value - idx).abs() < 0.2) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 5.0),
                    child: Text(
                      items[idx].label,
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
        barTouchData: BarTouchData(
          enabled: true,
          touchCallback: (event, response) {
            if (response != null && response.spot != null) {
              setState(() {
                _touchedGroupIndex = response.spot!.touchedBarGroupIndex;
              });
            } else {
              setState(() {
                _touchedGroupIndex = null;
              });
            }
          },
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => const Color(0xFF10365F),
            tooltipBorderRadius: BorderRadius.circular(10),
            tooltipPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              if (groupIndex < 0 || groupIndex >= items.length) return null;
              final item = items[groupIndex];
              return BarTooltipItem(
                '${item.fullLabel}\n',
                GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                children: [
                  TextSpan(
                    text: '🟢 Bebas Jentik: ${item.free} rumah\n',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF4ADE80),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(
                    text: '🔴 Positif Jentik: ${item.positive} rumah\n',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFFF87171),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(
                    text:
                        'Diperiksa: ${item.inspected} | ABJ: ${item.abj.toStringAsFixed(1)}%',
                    style: GoogleFonts.outfit(
                      color: Colors.white70,
                      fontSize: 10,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        barGroups: List.generate(items.length, (i) {
          final item = items[i];
          final isHighlighted = _touchedGroupIndex == i;
          final rodWidth = isDesktop ? 15.0 : 9.5;

          return BarChartGroupData(
            x: i,
            barsSpace: isDesktop ? 6 : 4,
            barRods: [
              // Bebas Jentik Rod (Green)
              BarChartRodData(
                toY: item.free.toDouble(),
                color: isHighlighted
                    ? const Color(0xFF059669)
                    : const Color(0xFF10B981),
                width: rodWidth,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(5)),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: maxY,
                  color: const Color(0xFFF8FAFC),
                ),
              ),
              // Positif Jentik Rod (Red)
              BarChartRodData(
                toY: item.positive.toDouble(),
                color: isHighlighted
                    ? const Color(0xFFDC2626)
                    : const Color(0xFFEF4444),
                width: rodWidth,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(5)),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: maxY,
                  color: const Color(0xFFF8FAFC),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildAbjBarChart(List<_BarChartDetailItem> items, bool isDesktop) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        minY: 0,
        maxY: 105,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 25,
          getDrawingHorizontalLine: (val) => FlLine(
            color: const Color(0xFFF1F5F9),
            strokeWidth: 1.0,
            dashArray: [4, 4],
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: const Border(
            bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
            left: BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
            top: BorderSide.none,
            right: BorderSide.none,
          ),
        ),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: 95,
              color: const Color(0xFF2E7D32).withValues(alpha: 0.7),
              strokeWidth: 1.2,
              dashArray: [5, 4],
              label: HorizontalLineLabel(
                show: true,
                alignment: Alignment.topRight,
                padding: const EdgeInsets.only(right: 4, bottom: 2),
                style: GoogleFonts.outfit(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2E7D32),
                ),
                labelResolver: (_) => 'Target 95%',
              ),
            ),
          ],
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: 25,
              getTitlesWidget: (value, meta) {
                if (value > 100) return const SizedBox.shrink();
                return Text(
                  '${value.toInt()}%',
                  style: GoogleFonts.outfit(
                    fontSize: 9.5,
                    color: const Color(0xFF94A3B8),
                    fontWeight: FontWeight.w600,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx >= 0 &&
                    idx < items.length &&
                    (value - idx).abs() < 0.2) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 5.0),
                    child: Text(
                      items[idx].label,
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
        barTouchData: BarTouchData(
          enabled: true,
          touchCallback: (event, response) {
            if (response != null && response.spot != null) {
              setState(() {
                _touchedGroupIndex = response.spot!.touchedBarGroupIndex;
              });
            } else {
              setState(() {
                _touchedGroupIndex = null;
              });
            }
          },
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => const Color(0xFF10365F),
            tooltipBorderRadius: BorderRadius.circular(10),
            tooltipPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              if (groupIndex < 0 || groupIndex >= items.length) return null;
              final item = items[groupIndex];
              final isTargetMet = item.abj >= 95.0;
              return BarTooltipItem(
                '${item.fullLabel}\n',
                GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                children: [
                  TextSpan(
                    text: 'ABJ: ${item.abj.toStringAsFixed(1)}% ',
                    style: GoogleFonts.outfit(
                      color: isTargetMet
                          ? const Color(0xFF4ADE80)
                          : const Color(0xFFF87171),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text:
                        isTargetMet ? '(Target Terpenuhi)\n' : '(Waspada)\n',
                    style: GoogleFonts.outfit(
                      color: isTargetMet
                          ? const Color(0xFF4ADE80)
                          : const Color(0xFFF87171),
                      fontSize: 10.5,
                    ),
                  ),
                  TextSpan(
                    text:
                        'Diperiksa: ${item.inspected} | Bebas: ${item.free} | Positif: ${item.positive}',
                    style: GoogleFonts.outfit(
                      color: Colors.white70,
                      fontSize: 10,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        barGroups: List.generate(items.length, (i) {
          final item = items[i];
          final isTargetMet = item.abj >= 95.0;
          final isHighlighted = _touchedGroupIndex == i;
          final rodWidth = isDesktop ? 22.0 : 14.0;

          final rodColor = isTargetMet
              ? (isHighlighted
                  ? const Color(0xFF059669)
                  : const Color(0xFF10B981))
              : (isHighlighted
                  ? const Color(0xFFDC2626)
                  : const Color(0xFFEF4444));

          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: item.abj,
                color: rodColor,
                width: rodWidth,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(5)),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: 100,
                  color: const Color(0xFFF1F5F9),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFEDF2F7)),
      ),
      child: _isAbjMode
          ? Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 14,
              runSpacing: 4,
              children: [
                _buildLegendItem(
                    const Color(0xFF10B981), 'Target Tercapai (≥95%)'),
                _buildLegendItem(
                    const Color(0xFFEF4444), 'Di Bawah Target (<95%)'),
                _buildLegendLineItem(
                    const Color(0xFF2E7D32), 'Garis Target Kemenkes'),
              ],
            )
          : Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 4,
              children: [
                _buildLegendItem(
                    const Color(0xFF10B981), 'Rumah Bebas Jentik'),
                _buildLegendItem(
                    const Color(0xFFEF4444), 'Rumah Positif Jentik'),
              ],
            ),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          text,
          style: GoogleFonts.outfit(
            fontSize: 10.5,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF334155),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendLineItem(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 2.5,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          text,
          style: GoogleFonts.outfit(
            fontSize: 10.5,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF334155),
          ),
        ),
      ],
    );
  }

  Widget _buildTableToggleButton(List<_BarChartDetailItem> items) {
    return InkWell(
      onTap: () => setState(() => _showTable = !_showTable),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: _showTable
              ? const Color(0xFFEFF6FF)
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _showTable
                ? const Color(0xFFBFDBFE)
                : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.table_chart_rounded,
              size: 15,
              color: _showTable
                  ? const Color(0xFF1D4ED8)
                  : const Color(0xFF475569),
            ),
            const SizedBox(width: 6),
            Text(
              _showTable
                  ? 'Sembunyikan Rincian Angka Tabel'
                  : 'Lihat Rincian Angka Tabel (${items.length} Data)',
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: _showTable
                    ? const Color(0xFF1D4ED8)
                    : const Color(0xFF475569),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              _showTable
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: _showTable
                  ? const Color(0xFF1D4ED8)
                  : const Color(0xFF475569),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailTable(
    List<_BarChartDetailItem> items,
    int totalInspected,
    int totalFree,
    int totalPositive,
    double overallAbj,
    bool isOverallTargetMet,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor:
                WidgetStateProperty.all(const Color(0xFFF1F5F9)),
            headingTextStyle: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
            dataTextStyle: GoogleFonts.outfit(
              fontSize: 11,
              color: const Color(0xFF334155),
            ),
            horizontalMargin: 12,
            columnSpacing: 16,
            headingRowHeight: 38,
            dataRowMinHeight: 36,
            dataRowMaxHeight: 38,
            columns: const [
              DataColumn(label: Text('Periode/Wilayah')),
              DataColumn(label: Text('Diperiksa'), numeric: true),
              DataColumn(label: Text('Bebas Jentik'), numeric: true),
              DataColumn(label: Text('Positif Jentik'), numeric: true),
              DataColumn(label: Text('ABJ (%)'), numeric: true),
              DataColumn(label: Text('Status')),
            ],
            rows: [
              ...items.map((it) {
                final isMet = it.abj >= 95.0;
                return DataRow(
                  cells: [
                    DataCell(Text(it.fullLabel,
                        style: const TextStyle(fontWeight: FontWeight.w600))),
                    DataCell(Text('${it.inspected}')),
                    DataCell(Text('${it.free}',
                        style: const TextStyle(
                            color: Color(0xFF16A34A),
                            fontWeight: FontWeight.bold))),
                    DataCell(Text('${it.positive}',
                        style: const TextStyle(
                            color: Color(0xFFDC2626),
                            fontWeight: FontWeight.bold))),
                    DataCell(Text('${it.abj.toStringAsFixed(1)}%',
                        style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: isMet
                              ? const Color(0xFFDCFCE7)
                              : const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isMet ? 'Aman' : 'Waspada',
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isMet
                                ? const Color(0xFF16A34A)
                                : const Color(0xFFDC2626),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }),
              // Total Row
              DataRow(
                color: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                cells: [
                  DataCell(Text('Total Keseluruhan',
                      style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A)))),
                  DataCell(Text('$totalInspected',
                      style: const TextStyle(fontWeight: FontWeight.bold))),
                  DataCell(Text('$totalFree',
                      style: const TextStyle(
                          color: Color(0xFF16A34A),
                          fontWeight: FontWeight.bold))),
                  DataCell(Text('$totalPositive',
                      style: const TextStyle(
                          color: Color(0xFFDC2626),
                          fontWeight: FontWeight.bold))),
                  DataCell(Text('${overallAbj.toStringAsFixed(1)}%',
                      style: const TextStyle(fontWeight: FontWeight.bold))),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: isOverallTargetMet
                            ? const Color(0xFFDCFCE7)
                            : const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isOverallTargetMet ? 'Target Terpenuhi' : 'Waspada',
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isOverallTargetMet
                              ? const Color(0xFF16A34A)
                              : const Color(0xFFDC2626),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  Reusable Summary Item for Reports Statistics
// ─────────────────────────────────────────────────────────

class DashboardStatItem extends StatelessWidget {
  final String val;
  final String label;
  final IconData icon;
  final Color color;

  const DashboardStatItem({
    super.key,
    required this.val,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                val,
                style: GoogleFonts.outfit(
                  color: AppTheme.textDark,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.outfit(
                  color: AppTheme.textDark.withValues(alpha: 0.6),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
