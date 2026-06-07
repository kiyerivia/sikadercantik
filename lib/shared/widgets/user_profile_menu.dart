import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show FileOptions;
import '../providers/auth_providers.dart';
import '../domain/models.dart';
import '../../core/theme/app_theme.dart';
import '../../features/dashboard/map_providers.dart';

// ─────────────────────────────────────────────────────────
//  Helpers
// ─────────────────────────────────────────────────────────

String _getDefaultAvatarAsset(String role) {
  switch (role.toLowerCase()) {
    case 'kader':
      return 'assets/images/avatar_kader.png';
    case 'admin':
      return 'assets/images/admin_dashboard_illustration.png';
    case 'superadmin':
      return 'assets/images/superadmin_bg.png';
    default:
      return 'assets/images/avatar_kader.png';
  }
}

String _getRoleLabel(String role) {
  switch (role.toLowerCase()) {
    case 'kader':
      return 'Kader PSN';
    case 'admin':
      return 'Admin Puskesmas';
    case 'superadmin':
      return 'Superadmin Dinkes';
    default:
      return role;
  }
}

// ─────────────────────────────────────────────────────────
//  Main PopupMenu Widget
// ─────────────────────────────────────────────────────────

class UserProfileMenu extends ConsumerWidget {
  const UserProfileMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final posyandusAsync = ref.watch(posyanduListProvider);
    final currentUser = ref.watch(supabaseClientProvider).auth.currentUser;
    final email = currentUser?.email ?? '-';

    return profileAsync.when(
      data: (profile) {
        if (profile == null) return const SizedBox.shrink();

        final defaultAsset = _getDefaultAvatarAsset(profile.role);
        final hasCustomAvatar = profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty;

        return PopupMenuButton<String>(
          offset: const Offset(0, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          tooltip: 'Menu Akun',
          icon: CircleAvatar(
            radius: 20,
            backgroundColor: Colors.white,
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.transparent,
              backgroundImage: hasCustomAvatar
                  ? NetworkImage(profile.avatarUrl!) as ImageProvider
                  : AssetImage(defaultAsset),
            ),
          ),
          onSelected: (value) {
            switch (value) {
              case 'profile':
                showDialog(
                  context: context,
                  builder: (ctx) => ProfileDetailDialog(
                    profile: profile,
                    email: email,
                    posyandus: posyandusAsync.value,
                    onAvatarUpdated: () => ref.invalidate(userProfileProvider),
                  ),
                );
                break;
              case 'password':
                _showChangePasswordDialog(context);
                break;
              case 'help':
                _showHelpSupportDialog(context);
                break;
              case 'logout':
                ref.read(authRepositoryProvider).signOut();
                context.go('/login');
                break;
            }
          },
          itemBuilder: (context) => [
            // ── Header info
            PopupMenuItem<String>(
              enabled: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
                      backgroundImage: hasCustomAvatar
                          ? NetworkImage(profile.avatarUrl!) as ImageProvider
                          : AssetImage(defaultAsset),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            profile.fullName,
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryGreen.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _getRoleLabel(profile.role),
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                color: AppTheme.primaryGreen,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const PopupMenuDivider(),
            // ── Menu Items
            PopupMenuItem<String>(
              value: 'profile',
              child: Row(children: [
                const Icon(Icons.person_outline, size: 20, color: AppTheme.textDark),
                const SizedBox(width: 12),
                Text('Lihat Profil', style: GoogleFonts.outfit(fontSize: 14)),
              ]),
            ),
            PopupMenuItem<String>(
              value: 'password',
              child: Row(children: [
                const Icon(Icons.lock_outline, size: 20, color: AppTheme.textDark),
                const SizedBox(width: 12),
                Text('Ganti Password', style: GoogleFonts.outfit(fontSize: 14)),
              ]),
            ),
            PopupMenuItem<String>(
              value: 'help',
              child: Row(children: [
                const Icon(Icons.help_outline, size: 20, color: AppTheme.textDark),
                const SizedBox(width: 12),
                Text('Bantuan', style: GoogleFonts.outfit(fontSize: 14)),
              ]),
            ),
            const PopupMenuDivider(),
            PopupMenuItem<String>(
              value: 'logout',
              child: Row(children: [
                const Icon(Icons.logout, size: 20, color: Colors.red),
                const SizedBox(width: 12),
                Text(
                  'Keluar / Log Out',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ]),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (err, stack) => const SizedBox.shrink(),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Ganti Kata Sandi',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppTheme.textDark),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Kata Sandi Lama', prefixIcon: Icon(Icons.lock_outline)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Kata Sandi Baru', prefixIcon: Icon(Icons.lock_reset)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Konfirmasi Kata Sandi Baru', prefixIcon: Icon(Icons.check_circle_outline)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Fitur ubah kata sandi berhasil disimulasikan.'), backgroundColor: Colors.green),
              );
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showHelpSupportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Bantuan & Dukungan',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppTheme.textDark),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Aplikasi Si KADER Cantik',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryGreen),
            ),
            const SizedBox(height: 4),
            Text(
              'Sistem Informasi Kader Cepat & Akurat Tanggulangi Jentik',
              style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            const Text('Hubungi Admin Puskesmas atau Dinas Kesehatan jika menemui kendala teknis.'),
            const SizedBox(height: 12),
            Row(children: [
              const Icon(Icons.phone, size: 16, color: AppTheme.primaryBlue),
              const SizedBox(width: 8),
              Text('WhatsApp: +62 812-3456-7890', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 6),
            Row(children: [
              const Icon(Icons.email, size: 16, color: AppTheme.primaryBlue),
              const SizedBox(width: 8),
              Text('Email: support@sikadercantik.go.id', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
            ]),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup')),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  Profile Detail Dialog (StatefulWidget to handle photo change)
// ─────────────────────────────────────────────────────────

class ProfileDetailDialog extends ConsumerStatefulWidget {
  final Profile profile;
  final String email;
  final List<Posyandu>? posyandus;
  final VoidCallback onAvatarUpdated;

  const ProfileDetailDialog({
    super.key,
    required this.profile,
    required this.email,
    required this.posyandus,
    required this.onAvatarUpdated,
  });

  @override
  ConsumerState<ProfileDetailDialog> createState() => _ProfileDetailDialogState();
}

class _ProfileDetailDialogState extends ConsumerState<ProfileDetailDialog> {
  bool _isUploading = false;
  String? _currentAvatarUrl;

  @override
  void initState() {
    super.initState();
    _currentAvatarUrl = widget.profile.avatarUrl;
  }

  ImageProvider _resolveAvatar() {
    if (_currentAvatarUrl != null && _currentAvatarUrl!.isNotEmpty) {
      return NetworkImage(_currentAvatarUrl!);
    }
    return AssetImage(_getDefaultAvatarAsset(widget.profile.role));
  }

  Future<void> _pickAndUploadPhoto() async {
    // Tampilkan opsi pilihan
    final choice = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 16),
              child: Text(
                'Ubah Foto Profil',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFE3F2FD),
                child: Icon(Icons.photo_library_outlined, color: AppTheme.primaryBlue),
              ),
              title: Text('Pilih dari Galeri / Komputer', style: GoogleFonts.outfit()),
              onTap: () => Navigator.pop(ctx, 'gallery'),
            ),
            if (_currentAvatarUrl != null && _currentAvatarUrl!.isNotEmpty)
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFFFEBEE),
                  child: Icon(Icons.delete_outline, color: Colors.red),
                ),
                title: Text(
                  'Hapus Foto Profil',
                  style: GoogleFonts.outfit(color: Colors.red),
                ),
                onTap: () => Navigator.pop(ctx, 'delete'),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (choice == null) return;

    if (choice == 'delete') {
      await _deletePhoto();
      return;
    }

    // Pilih file gambar (file_picker 11+ uses static method)
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;

    setState(() => _isUploading = true);

    try {
      final supabase = ref.read(supabaseClientProvider);
      final userId = widget.profile.id;
      final ext = file.extension ?? 'jpg';
      final path = 'avatars/$userId.$ext';

      // Upload ke Supabase Storage (bucket: avatars)
      await supabase.storage.from('avatars').uploadBinary(
        path,
        file.bytes!,
        fileOptions: FileOptions(contentType: 'image/$ext', upsert: true),
      );

      // Ambil URL publik
      final publicUrl = supabase.storage.from('avatars').getPublicUrl(path);

      // Tambahkan cache-buster agar browser reload gambar baru
      final urlWithBust = '$publicUrl?t=${DateTime.now().millisecondsSinceEpoch}';

      // Update field avatar_url di tabel profiles
      await supabase
          .from('profiles')
          .update({'avatar_url': publicUrl})
          .eq('id', userId);

      setState(() {
        _currentAvatarUrl = urlWithBust;
        _isUploading = false;
      });

      // Refresh provider agar AppBar ikut update
      widget.onAvatarUpdated();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Foto profil berhasil diperbarui!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isUploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Gagal upload foto: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deletePhoto() async {
    setState(() => _isUploading = true);
    try {
      final supabase = ref.read(supabaseClientProvider);
      await supabase
          .from('profiles')
          .update({'avatar_url': null})
          .eq('id', widget.profile.id);

      setState(() {
        _currentAvatarUrl = null;
        _isUploading = false;
      });
      widget.onAvatarUpdated();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto profil dihapus.'), backgroundColor: Colors.orange),
        );
      }
    } catch (e) {
      setState(() => _isUploading = false);
    }
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.outfit(fontSize: 14, color: AppTheme.textDark, fontWeight: FontWeight.w600),
          ),
          const Divider(height: 12),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final posyandus = widget.posyandus;

    String instansi = 'Puskesmas Gumelar';
    if (profile.role.toLowerCase() == 'superadmin') {
      instansi = 'Dinas Kesehatan';
    } else if (profile.posyanduId != null && posyandus != null) {
      try {
        final match = posyandus.firstWhere((p) => p.id == profile.posyanduId);
        instansi = match.name;
      } catch (_) {}
    }

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.account_circle, color: AppTheme.primaryBlue),
          const SizedBox(width: 8),
          Text(
            'Profil Pengguna',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppTheme.textDark),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Avatar dengan tombol ganti foto
            Center(
              child: Stack(
                children: [
                  // Foto profil
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.primaryBlue.withOpacity(0.3),
                        width: 2.5,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 44,
                      backgroundColor: AppTheme.primaryBlue.withOpacity(0.08),
                      backgroundImage: _resolveAvatar(),
                      child: _isUploading
                          ? Container(
                              decoration: const BoxDecoration(
                                color: Colors.black38,
                                shape: BoxShape.circle,
                              ),
                              child: const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : null,
                    ),
                  ),
                  // Tombol kamera di sudut kanan bawah
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _isUploading ? null : _pickAndUploadPhoto,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            // Label klik untuk ganti foto
            Center(
              child: TextButton.icon(
                onPressed: _isUploading ? null : _pickAndUploadPhoto,
                icon: const Icon(Icons.edit, size: 14),
                label: Text(
                  'Ganti Foto Profil',
                  style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primaryBlue,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // ── Info Fields
            _buildInfoItem('Nama', profile.fullName),
            _buildInfoItem('Email User', widget.email),
            _buildInfoItem('Nama Instansi', instansi),
            _buildInfoItem('Peran / Role', _getRoleLabel(profile.role)),
            // Real-time GPS location
            RealtimeLocationSection(
              loadingWidget: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildInfoItem('Latitude', 'Mencari... 🔍'),
                  _buildInfoItem('Longitude', 'Mencari... 🔍'),
                ],
              ),
              errorBuilder: (ctx, error) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildInfoItem('Latitude', '$error ⚠️'),
                  _buildInfoItem('Longitude', '$error ⚠️'),
                ],
              ),
              builder: (ctx, lat, lng) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildInfoItem('Latitude', lat.toStringAsFixed(7)),
                  _buildInfoItem('Longitude', lng.toStringAsFixed(7)),
                ],
              ),
            ),
            if (profile.phoneNumber != null && profile.phoneNumber!.isNotEmpty)
              _buildInfoItem('Nomor HP', profile.phoneNumber!),
            const SizedBox(height: 12),
            // ID kecil
            Center(
              child: SelectableText(
                'ID Pengguna: ${profile.id}',
                style: GoogleFonts.outfit(fontSize: 9, color: Colors.grey[500]),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Tutup', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────
//  Real-time GPS Location Section
// ─────────────────────────────────────────────────────────

class RealtimeLocationSection extends StatefulWidget {
  final Widget Function(BuildContext context, double lat, double lng) builder;
  final Widget Function(BuildContext context, String error) errorBuilder;
  final Widget loadingWidget;

  const RealtimeLocationSection({
    super.key,
    required this.builder,
    required this.errorBuilder,
    required this.loadingWidget,
  });

  @override
  State<RealtimeLocationSection> createState() => _RealtimeLocationSectionState();
}

class _RealtimeLocationSectionState extends State<RealtimeLocationSection> {
  bool _permissionChecked = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() { _errorMessage = 'GPS Nonaktif'; _permissionChecked = true; });
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() { _errorMessage = 'Izin Ditolak'; _permissionChecked = true; });
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() { _errorMessage = 'Izin Diblokir'; _permissionChecked = true; });
        return;
      }
      setState(() => _permissionChecked = true);
    } catch (e) {
      setState(() { _errorMessage = 'Error: $e'; _permissionChecked = true; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_permissionChecked) return widget.loadingWidget;
    if (_errorMessage != null) return widget.errorBuilder(context, _errorMessage!);

    return StreamBuilder<Position>(
      stream: Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 0,
        ),
      ),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final pos = snapshot.data!;
          return widget.builder(context, pos.latitude, pos.longitude);
        } else if (snapshot.hasError) {
          return widget.errorBuilder(context, 'Gagal mengambil GPS');
        } else {
          return FutureBuilder<Position?>(
            future: Geolocator.getLastKnownPosition(),
            builder: (context, futureSnapshot) {
              if (futureSnapshot.hasData && futureSnapshot.data != null) {
                final pos = futureSnapshot.data!;
                return widget.builder(context, pos.latitude, pos.longitude);
              }
              return widget.loadingWidget;
            },
          );
        }
      },
    );
  }
}
