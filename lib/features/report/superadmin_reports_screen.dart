import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../shared/widgets/notification_badge.dart';
import '../../shared/providers/auth_providers.dart';
import '../../shared/providers/master_providers.dart';

class SuperAdminReportsScreen extends ConsumerStatefulWidget {
  const SuperAdminReportsScreen({super.key});

  @override
  ConsumerState<SuperAdminReportsScreen> createState() => _SuperAdminReportsScreenState();
}

class _SuperAdminReportsScreenState extends ConsumerState<SuperAdminReportsScreen> {
  String? selectedBulan;
  String? selectedTahun;
  String? selectedKecamatan;
  String? selectedDesa;
  String? selectedPosyandu;

  @override
  Widget build(BuildContext context) {
    final villagesAsync = ref.watch(villagesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FA), // Light bluish background
      appBar: AppBar(
        backgroundColor: const Color(0xFF10365F),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(
                'assets/images/psn_logo_new.jpg',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.bug_report, color: Colors.red, size: 20),
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      height: 1.1,
                    ),
                    children: const [
                      TextSpan(
                        text: 'SI KADER ',
                        style: TextStyle(color: Colors.white),
                      ),
                      TextSpan(
                        text: 'PSN',
                        style: TextStyle(color: Color(0xFF68B744)),
                      ),
                    ],
                  ),
                ),
                Text(
                  'REKAP & LAPORAN',
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
                    Text(
                      'Logout',
                      style: GoogleFonts.outfit(
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            child: const CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: Color(0xFF10365F), size: 20),
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
                  child: Text(
                    'Beranda',
                    style: GoogleFonts.outfit(
                      color: Colors.blueGrey,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  size: 14,
                  color: Colors.blueGrey,
                ),
                Text(
                  'Rekap & Laporan PSN',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF10365F),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rekap & Laporan PSN',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF10365F),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
            Text(
              'Unduh dan cetak rekap laporan PSN, capaian ABJ, dan laporan lainnya.',
              style: GoogleFonts.outfit(
                color: const Color(0xFF10365F).withOpacity(0.6),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),

            // Filter Form
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildDropdown(
                          icon: Icons.calendar_today_outlined,
                          label: 'Bulan',
                          value: selectedBulan,
                          items: [
                            'Semua', 'Januari', 'Februari', 'Maret', 'April',
                            'Mei', 'Juni', 'Juli', 'Agustus', 'September',
                            'Oktober', 'November', 'Desember'
                          ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                          onChanged: (val) => setState(() => selectedBulan = val),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildDropdown(
                          icon: Icons.calendar_view_month_outlined,
                          label: 'Tahun',
                          value: selectedTahun,
                          items: ['Semua', '2023', '2024', '2025', '2026'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                          onChanged: (val) => setState(() => selectedTahun = val),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDropdown(
                          icon: Icons.location_on_outlined,
                          label: 'Kecamatan',
                          value: selectedKecamatan,
                          items: ['Gumelar', 'Semua'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                          onChanged: (val) => setState(() => selectedKecamatan = val),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: villagesAsync.when(
                          data: (villages) {
                            final gumelarVillages = [
                              'cilangkap', 'cihonje', 'paningkaban', 'karangkemojing',
                              'gancang', 'kedungurang', 'gumelar', 'tlaga', 'samudra', 'samudra kulon',
                            ];
                            final gumelarOnly = villages
                                .where((v) => gumelarVillages.contains(v.name.trim().toLowerCase()))
                                .toList();
                            return _buildDropdown(
                              icon: Icons.home_work_outlined,
                              label: 'Desa',
                              value: selectedDesa,
                              items: [
                                const DropdownMenuItem(value: 'Semua', child: Text('Semua')),
                                ...gumelarOnly.map((v) => DropdownMenuItem(value: v.id, child: Text(v.name))),
                              ],
                              onChanged: (val) {
                                setState(() {
                                  selectedDesa = val;
                                  selectedPosyandu = null; // Reset posyandu when desa changes
                                });
                              },
                            );
                          },
                          loading: () => _buildDropdown(
                            icon: Icons.home_work_outlined,
                            label: 'Desa',
                            value: 'Semua',
                            items: const [DropdownMenuItem(value: 'Semua', child: Text('Memuat...'))],
                            onChanged: null,
                          ),
                          error: (e, s) => _buildDropdown(
                            icon: Icons.home_work_outlined,
                            label: 'Desa',
                            value: 'Semua',
                            items: const [DropdownMenuItem(value: 'Semua', child: Text('Error'))],
                            onChanged: null,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  (selectedDesa == null || selectedDesa == 'Semua')
                      ? _buildDropdown(
                          icon: Icons.people_outline,
                          label: 'Posyandu',
                          value: 'Semua',
                          items: const [DropdownMenuItem(value: 'Semua', child: Text('Semua'))],
                          onChanged: null,
                        )
                      : ref.watch(posyandusByVillageProvider(selectedDesa!)).when(
                          data: (posyandus) {
                            return _buildDropdown(
                              icon: Icons.people_outline,
                              label: 'Posyandu',
                              value: selectedPosyandu,
                              items: [
                                const DropdownMenuItem(value: 'Semua', child: Text('Semua')),
                                ...posyandus.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))),
                              ],
                              onChanged: (val) => setState(() => selectedPosyandu = val),
                            );
                          },
                          loading: () => _buildDropdown(
                            icon: Icons.people_outline,
                            label: 'Posyandu',
                            value: 'Semua',
                            items: const [DropdownMenuItem(value: 'Semua', child: Text('Memuat...'))],
                            onChanged: null,
                          ),
                          error: (e, s) => _buildDropdown(
                            icon: Icons.people_outline,
                            label: 'Posyandu',
                            value: 'Semua',
                            items: const [DropdownMenuItem(value: 'Semua', child: Text('Error'))],
                            onChanged: null,
                          ),
                        ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Info Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F8FA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFF29B6F6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.info_outline, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Informasi',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF10365F),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Pilih filter untuk menampilkan laporan sesuai kebutuhan.\nJika tidak memilih filter, laporan akan menampilkan semua data.',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF10365F).withOpacity(0.7),
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Table Section
            Text(
              'File Laporan Rekap PSN',
              style: GoogleFonts.outfit(
                color: const Color(0xFF10365F),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Table Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F8FA),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                      border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.2))),
                    ),
                    child: Row(
                      children: [
                        SizedBox(width: 32, child: _headerText('No.')),
                        Expanded(flex: 2, child: _headerText('Nama Laporan')),
                        Expanded(flex: 3, child: _headerText('Deskripsi')),
                        SizedBox(width: 60, child: _headerText('Format')),
                        SizedBox(width: 90, child: Center(child: _headerText('Aksi'))),
                      ],
                    ),
                  ),
                  // Table Rows
                  _buildTableRow(
                    no: '1',
                    nama: 'Rekap Laporan PSN',
                    deskripsi: 'Rekap seluruh laporan PSN dari semua kader',
                  ),
                  _buildTableRow(
                    no: '2',
                    nama: 'Rekap Rumah Positif Jentik',
                    deskripsi: 'Rekap rumah positif jentik per wilayah',
                  ),
                  _buildTableRow(
                    no: '3',
                    nama: 'Rekap Intervensi',
                    deskripsi: 'Rekap status intervensi rumah positif jentik',
                  ),
                  _buildTableRow(
                    no: '4',
                    nama: 'Capaian ABJ per Wilayah',
                    deskripsi: 'Rekap capaian ABJ per puskesmas/kecamatan',
                  ),
                  _buildTableRow(
                    no: '5',
                    nama: 'Rekap Laporan PSN per Kader',
                    deskripsi: 'Rekap jumlah laporan per kader',
                  ),
                  _buildTableRow(
                    no: '6',
                    nama: 'Rekap Kunjungan Kader',
                    deskripsi: 'Rekap kunjungan kader per wilayah',
                    isLast: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Pagination
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Menampilkan 6 jenis laporan',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF10365F).withOpacity(0.6),
                    fontSize: 13,
                  ),
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFF29B6F6),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '1',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Catatan Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F8FA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF29B6F6).withOpacity(0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFF29B6F6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.description_outlined, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Catatan',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF10365F),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'File laporan dalam format Excel (.xlsx) dapat dibuka menggunakan Microsoft Excel atau aplikasi sejenis.',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF10365F).withOpacity(0.7),
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
      ),
      ],
      ),
    );
  }

  Widget _buildDropdown({
    required IconData icon,
    required String label,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required void Function(String?)? onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.outfit(
                  color: Colors.grey[600],
                  fontSize: 11,
                ),
              ),
            ],
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value ?? (items.isNotEmpty ? items.first.value : null),
              isDense: true,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
              style: GoogleFonts.outfit(
                color: const Color(0xFF10365F),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              items: items,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerText(String text) {
    return Text(
      text,
      style: GoogleFonts.outfit(
        color: const Color(0xFF10365F),
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildTableRow({
    required String no,
    required String nama,
    required String deskripsi,
    bool isLast = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        border: isLast ? null : Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.2))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 32,
            child: Text(
              no,
              style: GoogleFonts.outfit(
                color: const Color(0xFF10365F),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              nama,
              style: GoogleFonts.outfit(
                color: const Color(0xFF10365F),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              deskripsi,
              style: GoogleFonts.outfit(
                color: const Color(0xFF10365F).withOpacity(0.7),
                fontSize: 12,
              ),
            ),
          ),
          SizedBox(
            width: 60,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Excel',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  color: const Color(0xFF2E7D32), // Green text
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 90,
            child: Container(
              alignment: Alignment.centerRight,
              child: Material(
                color: const Color(0xFF68B744), // Green button
                borderRadius: BorderRadius.circular(6),
                child: InkWell(
                  onTap: () {
                    // TODO: Implement download
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.download, color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          'Unduh',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
