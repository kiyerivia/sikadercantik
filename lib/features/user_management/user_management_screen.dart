import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../shared/domain/models.dart';
import '../../shared/providers/master_providers.dart';
import '../../shared/widgets/notification_badge.dart';
import '../../shared/widgets/user_profile_menu.dart';
import 'user_management_repository.dart';

class UserManagementScreen extends ConsumerStatefulWidget {
  const UserManagementScreen({super.key});

  @override
  ConsumerState<UserManagementScreen> createState() =>
      _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen> {
  String _searchQuery = '';
  String _selectedRoleFilter = 'all'; // 'all', 'admin', 'kader'
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(allManagedUsersProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        leading: const BackButton(color: Colors.white),
        backgroundColor: const Color(0xFF10365F),
        elevation: 0,
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.manage_accounts_rounded,
                  color: Colors.white, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Manajemen Pengguna & RBAC',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Tata Kelola Akun Admin Puskesmas & Kader PSN',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            tooltip: 'Segarkan data',
            onPressed: () => ref.invalidate(allManagedUsersProvider),
          ),
          const NotificationBadge(),
          const SizedBox(width: 6),
          const UserProfileMenu(),
          const SizedBox(width: 12),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF10365F),
        icon: const Icon(Icons.person_add_rounded, color: Colors.white),
        label: Text(
          'Tambah Petugas Baru',
          style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold, color: Colors.white),
        ),
        onPressed: () => _showAddUserDialog(context),
      ),
      body: usersAsync.when(
        data: (users) {
          final totalCount = users.length;
          final adminCount =
              users.where((u) => u.role.toLowerCase().contains('admin')).length;
          final kaderCount =
              users.where((u) => u.role.toLowerCase().contains('kader')).length;
          final activeCount = users.where((u) => u.isActive).length;

          final filteredUsers = users.where((u) {
            final role = u.role.toLowerCase();
            if (_selectedRoleFilter == 'admin' && !role.contains('admin')) {
              return false;
            }
            if (_selectedRoleFilter == 'kader' && !role.contains('kader')) {
              return false;
            }

            if (_searchQuery.isNotEmpty) {
              final query = _searchQuery.toLowerCase();
              final matchName = u.fullName.toLowerCase().contains(query);
              final matchEmail = (u.email ?? '').toLowerCase().contains(query);
              final matchPhone =
                  (u.phoneNumber ?? '').toLowerCase().contains(query);
              final matchPosyandu =
                  (u.posyanduName ?? '').toLowerCase().contains(query);
              final matchVillage =
                  (u.villageName ?? '').toLowerCase().contains(query);
              return matchName ||
                  matchEmail ||
                  matchPhone ||
                  matchPosyandu ||
                  matchVillage;
            }
            return true;
          }).toList();

          return Column(
            children: [
              // KPI Statistics Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                child: Row(
                  children: [
                    _buildKpiCard(
                      label: 'Total Petugas',
                      value: '$totalCount',
                      icon: Icons.people_alt_rounded,
                      color: const Color(0xFF0284C7),
                    ),
                    const SizedBox(width: 8),
                    _buildKpiCard(
                      label: 'Admin Puskesmas',
                      value: '$adminCount',
                      icon: Icons.admin_panel_settings_rounded,
                      color: const Color(0xFF7C3AED),
                    ),
                    const SizedBox(width: 8),
                    _buildKpiCard(
                      label: 'Kader PSN',
                      value: '$kaderCount',
                      icon: Icons.health_and_safety_rounded,
                      color: const Color(0xFF16A34A),
                    ),
                    const SizedBox(width: 8),
                    _buildKpiCard(
                      label: 'Status Aktif',
                      value: '$activeCount',
                      icon: Icons.check_circle_rounded,
                      color: const Color(0xFF059669),
                    ),
                  ],
                ),
              ),

              // Search Bar & Filter Chips
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) =>
                        setState(() => _searchQuery = val.trim()),
                    style: GoogleFonts.outfit(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Cari nama kader, email, nomor HP, atau desa...',
                      hintStyle: GoogleFonts.outfit(
                          fontSize: 13, color: Colors.grey.shade400),
                      prefixIcon: const Icon(Icons.search_rounded,
                          size: 20, color: Color(0xFF64748B)),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Filter Chips
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _buildFilterChip('all', 'Semua ($totalCount)'),
                    const SizedBox(width: 8),
                    _buildFilterChip('admin', 'Admin Puskesmas ($adminCount)'),
                    const SizedBox(width: 8),
                    _buildFilterChip('kader', 'Kader PSN ($kaderCount)'),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // User Cards List
              Expanded(
                child: filteredUsers.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.person_search_rounded,
                                  size: 54, color: Colors.grey.shade300),
                              const SizedBox(height: 12),
                              Text(
                                'Tidak ada petugas yang cocok',
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Coba gunakan kata kunci lain.',
                                style: GoogleFonts.outfit(
                                    fontSize: 12, color: Colors.grey.shade500),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                        itemCount: filteredUsers.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final user = filteredUsers[index];
                          return _buildUserCard(context, user);
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Gagal memuat pengguna: $e')),
      ),
    );
  }

  Widget _buildKpiCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF10365F),
              ),
            ),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 9.5,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF64748B),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String id, String label) {
    final isSelected = _selectedRoleFilter == id;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedRoleFilter = id),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF10365F) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF10365F)
                  : const Color(0xFFCBD5E1),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Colors.white : const Color(0xFF475569),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(BuildContext context, Profile user) {
    final role = user.role.toLowerCase();
    final isSuperAdmin = role.contains('superadmin');
    final isAdmin = role.contains('admin') && !isSuperAdmin;
    final isKader = role.contains('kader');

    Color roleColor;
    Color roleBg;
    String roleLabel;

    if (isSuperAdmin) {
      roleColor = const Color(0xFF10365F);
      roleBg = const Color(0xFFE0E7FF);
      roleLabel = 'SUPER ADMIN DINKES';
    } else if (isAdmin) {
      roleColor = const Color(0xFF7C3AED);
      roleBg = const Color(0xFFEDE9FE);
      roleLabel = 'ADMIN PUSKESMAS';
    } else {
      roleColor = const Color(0xFF16A34A);
      roleBg = const Color(0xFFDCFCE7);
      roleLabel = 'KADER PSN';
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: user.isActive
              ? const Color(0xFFE2E8F0)
              : Colors.red.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Avatar, Name, Role Tag, Active Status
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: roleBg,
                  backgroundImage: (!isSuperAdmin && !isAdmin)
                      ? const AssetImage('assets/images/icon_profil.png')
                      : null,
                  child: (isSuperAdmin || isAdmin)
                      ? Icon(
                          isSuperAdmin
                              ? Icons.shield_rounded
                              : Icons.admin_panel_settings_rounded,
                          color: roleColor,
                          size: 24,
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              user.fullName,
                              style: GoogleFonts.outfit(
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: roleBg,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              roleLabel,
                              style: GoogleFonts.outfit(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: roleColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        user.email ?? 'kader@posyandu.id',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                // Active status pill
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: user.isActive
                        ? const Color(0xFFDCFCE7)
                        : const Color(0xFFFFE4E6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: user.isActive
                          ? const Color(0xFF86EFAC)
                          : const Color(0xFFFECDD3),
                    ),
                  ),
                  child: Text(
                    user.isActive ? 'AKTIF' : 'NONAKTIF',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: user.isActive
                          ? const Color(0xFF16A34A)
                          : const Color(0xFFE11D48),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Posyandu & Kontak info box
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.home_work_outlined,
                      size: 15, color: Color(0xFF64748B)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      isSuperAdmin
                          ? 'Wilayah: Seluruh Kabupaten Banyumas'
                          : (user.posyanduName != null
                              ? '${user.posyanduName} • Desa ${user.villageName ?? "-"}'
                              : 'Puskesmas Gumelar'),
                      style: GoogleFonts.outfit(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF334155),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.phone_outlined,
                      size: 14, color: Color(0xFF64748B)),
                  const SizedBox(width: 4),
                  Text(
                    user.phoneNumber ?? '-',
                    style: GoogleFonts.outfit(
                      fontSize: 11.5,
                      color: const Color(0xFF475569),
                    ),
                  ),
                ],
              ),
            ),

            // Action Buttons
            if (!isSuperAdmin) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Pindahkan Posyandu button (for Kader)
                  if (isKader) ...[
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF0284C7)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.swap_horiz_rounded,
                          size: 15, color: Color(0xFF0284C7)),
                      label: Text(
                        'Pindah Posyandu',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0284C7),
                        ),
                      ),
                      onPressed: () => _showReassignPosyanduDialog(context, user),
                    ),
                    const SizedBox(width: 8),
                  ],

                  // Reset Sandi button
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFD97706)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      minimumSize: Size.zero,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.lock_reset_rounded,
                        size: 15, color: Color(0xFFD97706)),
                    label: Text(
                      'Reset Sandi',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFD97706),
                      ),
                    ),
                    onPressed: () => _showResetPasswordDialog(context, user),
                  ),

                  const SizedBox(width: 8),

                  // Toggle Status button
                  IconButton(
                    icon: Icon(
                      user.isActive
                          ? Icons.block_rounded
                          : Icons.check_circle_outline_rounded,
                      color: user.isActive ? Colors.red : Colors.green,
                      size: 20,
                    ),
                    tooltip: user.isActive ? 'Nonaktifkan Akun' : 'Aktifkan Akun',
                    onPressed: () async {
                      await ref
                          .read(userManagementRepositoryProvider)
                          .updateUserStatus(
                            userId: user.id,
                            isActive: !user.isActive,
                          );
                      ref.invalidate(allManagedUsersProvider);
                    },
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showReassignPosyanduDialog(BuildContext context, Profile user) {
    String? selectedVillageId;
    String? selectedPosyanduId = user.posyanduId;
    String selectedPosyanduName = user.posyanduName ?? '';
    String selectedVillageName = user.villageName ?? '';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final villages = ref.watch(villagesProvider).value ?? [];
          final allPosyandus = ref.watch(allPosyandusProvider).value ?? [];

          final availablePosyandus = selectedVillageId == null
              ? allPosyandus
              : allPosyandus.where((p) => true).toList(); // posyandus by village

          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.swap_horiz_rounded,
                    color: Color(0xFF0284C7), size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Pengalihan Tugas Posyandu',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF10365F),
                    ),
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Petugas: ${user.fullName}',
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  Text(
                    'Posyandu Saat Ini: ${user.posyanduName ?? "-"} (Desa ${user.villageName ?? "-"})',
                    style: GoogleFonts.outfit(
                        fontSize: 11.5, color: Colors.grey.shade600),
                  ),
                  const Divider(height: 20),

                  Text('Pilih Desa Baru:',
                      style: GoogleFonts.outfit(
                          fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedVillageId,
                        isExpanded: true,
                        hint: Text('Pilih Desa',
                            style: GoogleFonts.outfit(fontSize: 13)),
                        items: villages
                            .map((v) => DropdownMenuItem(
                                value: v.id,
                                child: Text('Desa ${v.name}',
                                    style: GoogleFonts.outfit(fontSize: 13))))
                            .toList(),
                        onChanged: (val) {
                          setDialogState(() {
                            selectedVillageId = val;
                            if (val != null) {
                              selectedVillageName =
                                  villages.firstWhere((v) => v.id == val).name;
                            }
                          });
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text('Pilih Unit Posyandu Baru:',
                      style: GoogleFonts.outfit(
                          fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedPosyanduId,
                        isExpanded: true,
                        hint: Text('Pilih Posyandu',
                            style: GoogleFonts.outfit(fontSize: 13)),
                        items: availablePosyandus
                            .map((p) => DropdownMenuItem(
                                value: p.id,
                                child: Text(p.name,
                                    style: GoogleFonts.outfit(fontSize: 13))))
                            .toList(),
                        onChanged: (val) {
                          setDialogState(() {
                            selectedPosyanduId = val;
                            if (val != null) {
                              selectedPosyanduName = availablePosyandus
                                  .firstWhere((p) => p.id == val)
                                  .name;
                            }
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Batal',
                    style: GoogleFonts.outfit(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  if (selectedPosyanduId == null) return;
                  Navigator.pop(ctx);

                  await ref
                      .read(userManagementRepositoryProvider)
                      .updateUserPosyandu(
                        userId: user.id,
                        posyanduId: selectedPosyanduId!,
                        posyanduName: selectedPosyanduName,
                        villageName: selectedVillageName.isNotEmpty
                            ? selectedVillageName
                            : (user.villageName ?? 'Gumelar'),
                      );

                  ref.invalidate(allManagedUsersProvider);

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: const Color(0xFF15803D),
                        content: Text(
                          'Kader ${user.fullName} berhasil dialihkan ke $selectedPosyanduName!',
                          style: GoogleFonts.outfit(),
                        ),
                      ),
                    );
                  }
                },
                child: Text('Simpan Pengalihan',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showResetPasswordDialog(BuildContext context, Profile user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.lock_reset_rounded, color: Color(0xFFD97706), size: 24),
            const SizedBox(width: 10),
            Text('Reset Sandi Akun?',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Instruksi reset sandi akan dikirimkan ke email terdaftar: ${user.email ?? "-"}.\nPetugas dapat mengatur kata sandi baru untuk masuk ke aplikasi.',
          style: GoogleFonts.outfit(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: GoogleFonts.outfit(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD97706)),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(userManagementRepositoryProvider).resetPassword(
                    email: user.email ?? 'kader@posyandu.id',
                    userName: user.fullName,
                  );

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: const Color(0xFFD97706),
                    content: Text(
                      'Tautan reset sandi berhasil dikirim ke ${user.email}!',
                      style: GoogleFonts.outfit(),
                    ),
                  ),
                );
              }
            },
            child: Text('Kirim Reset Sandi',
                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showAddUserDialog(BuildContext context) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passController = TextEditingController(text: 'Kader123!');
    final phoneController = TextEditingController();
    String selectedRole = 'kader';
    String? selectedPosyanduId;
    String selectedPosyanduName = '';
    String selectedVillageName = '';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final posyandus = ref.watch(allPosyandusProvider).value ?? [];

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE0F2FE),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_add_rounded,
                      color: Color(0xFF0284C7), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Buat Akun Petugas Baru',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF10365F),
                        ),
                      ),
                      Text(
                        'Pendaftaran Admin Puskesmas atau Kader PSN',
                        style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: SizedBox(
                width: 440,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Peran Petugas
                    Text('Peran Petugas (Role):',
                        style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => setDialogState(() => selectedRole = 'kader'),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: selectedRole == 'kader'
                                    ? const Color(0xFFDCFCE7)
                                    : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: selectedRole == 'kader'
                                      ? const Color(0xFF16A34A)
                                      : const Color(0xFFCBD5E1),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Kader PSN',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: selectedRole == 'kader'
                                      ? const Color(0xFF16A34A)
                                      : const Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: InkWell(
                            onTap: () => setDialogState(() => selectedRole = 'admin'),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: selectedRole == 'admin'
                                    ? const Color(0xFFEDE9FE)
                                    : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: selectedRole == 'admin'
                                      ? const Color(0xFF7C3AED)
                                      : const Color(0xFFCBD5E1),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Admin Puskesmas',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: selectedRole == 'admin'
                                      ? const Color(0xFF7C3AED)
                                      : const Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Nama Lengkap
                    Text('Nama Lengkap:',
                        style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameController,
                      style: GoogleFonts.outfit(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Contoh: Sri Wahyuni, A.Md.Keb',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Email Login
                    Text('Alamat Email (Akun Masuk):',
                        style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: GoogleFonts.outfit(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Contoh: sri.wahyuni@posyandu.id',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Password Awal
                    Text('Kata Sandi Awal:',
                        style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: passController,
                      style: GoogleFonts.outfit(fontSize: 13),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Nomor Handphone / WhatsApp
                    Text('Nomor WhatsApp / HP:',
                        style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      style: GoogleFonts.outfit(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Contoh: 081234567890',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),

                    if (selectedRole == 'kader') ...[
                      const SizedBox(height: 12),
                      Text('Penugasan Posyandu:',
                          style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedPosyanduId,
                            isExpanded: true,
                            hint: Text('Pilih Unit Posyandu',
                                style: GoogleFonts.outfit(fontSize: 13)),
                            items: posyandus
                                .map((p) => DropdownMenuItem(
                                    value: p.id,
                                    child: Text(p.name,
                                        style: GoogleFonts.outfit(fontSize: 13))))
                                .toList(),
                            onChanged: (val) {
                              setDialogState(() {
                                selectedPosyanduId = val;
                                if (val != null) {
                                  final match =
                                      posyandus.firstWhere((p) => p.id == val);
                                  selectedPosyanduName = match.name;
                                  selectedVillageName = 'Gumelar';
                                }
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Batal', style: GoogleFonts.outfit(color: Colors.grey)),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10365F),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.check, size: 16),
                label: Text('Daftarkan Akun',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                onPressed: () async {
                  final name = nameController.text.trim();
                  final email = emailController.text.trim();
                  final pass = passController.text.trim();
                  final phone = phoneController.text.trim();

                  if (name.isEmpty || email.isEmpty || pass.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Nama, email, dan sandi harus diisi!'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  Navigator.pop(ctx);

                  await ref.read(userManagementRepositoryProvider).createUser(
                        fullName: name,
                        email: email,
                        password: pass,
                        role: selectedRole,
                        posyanduId: selectedPosyanduId,
                        posyanduName: selectedPosyanduName.isNotEmpty
                            ? selectedPosyanduName
                            : (selectedRole == 'admin' ? 'Puskesmas Gumelar' : null),
                        villageName: selectedVillageName.isNotEmpty
                            ? selectedVillageName
                            : (selectedRole == 'admin' ? 'Gumelar' : null),
                        phoneNumber: phone.isNotEmpty ? phone : null,
                      );

                  ref.invalidate(allManagedUsersProvider);

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: const Color(0xFF15803D),
                        content: Text(
                          'Akun petugas $name berhasil didaftarkan!',
                          style: GoogleFonts.outfit(),
                        ),
                      ),
                    );
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
