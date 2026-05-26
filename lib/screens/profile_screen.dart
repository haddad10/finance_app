import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/dot_grid_painter.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = context.watch<ThemeProvider>();
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('PROFILE VIBE', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w900, letterSpacing: 2)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          children: [
            // Avatar Section
            Center(
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: () => _showPhotoPicker(context, auth),
                    child: Hero(
                      tag: 'profile_avatar',
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 4),
                          boxShadow: [
                            BoxShadow(color: AppColors.primary.withOpacity(0.2), blurRadius: 25, offset: const Offset(0, 10))
                          ],
                        ),
                        child: ClipOval(
                          child: _buildAvatar(auth),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => _showPhotoPicker(context, auth),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: colors.bg, width: 3),
                        ),
                        child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              auth.user?.username ?? 'User',
              style: TextStyle(color: colors.textPrimary, fontSize: 24, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              auth.user?.email ?? 'email@example.com',
              style: TextStyle(color: colors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 40),

            // Settings Card
            Container(
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: colors.border.withOpacity(0.5)),
              ),
              child: Column(
                children: [
                  _ProfileItem(
                    icon: theme.isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                    title: 'Mode Gelap',
                    subtitle: theme.isDarkMode ? 'Lunar Mode 🔥' : 'Solar Mode ✨',
                    trailing: Switch(
                      value: theme.isDarkMode,
                      onChanged: (_) => theme.toggleTheme(),
                      activeColor: AppColors.primary,
                    ),
                  ),
                  const _Divider(),
                  _ProfileItem(
                    icon: Icons.edit_note_rounded,
                    title: 'Edit Profil',
                    onTap: () => _showEditProfileDialog(context, auth),
                  ),
                  const _Divider(),
                  _ProfileItem(
                    icon: Icons.security_rounded,
                    title: 'Keamanan',
                    onTap: () => _showComingSoon(context, 'Security Mode'),
                  ),
                  const _Divider(),
                  _ProfileItem(
                    icon: Icons.notifications_active_rounded,
                    title: 'Notifikasi',
                    onTap: () => _showComingSoon(context, 'Push Alerts'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            
            // Logout Button
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () async {
                  await auth.logout();
                  if (context.mounted) Navigator.pop(context);
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  foregroundColor: AppColors.expense,
                ),
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Keluar Aplikasi', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sabar ya Sayang, fitur $feature lagi digodok! 👨‍🍳🔥'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primary,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, AuthProvider auth) {
    final nameCtrl = TextEditingController(text: auth.user?.username);
    final emailCtrl = TextEditingController(text: auth.user?.email);
    final colors = AppColors.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 32,
        ),
        decoration: BoxDecoration(
          color: colors.bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('EDIT PROFIL', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1)),
            const SizedBox(height: 24),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Username', hintText: 'Mau dipanggil apa?'),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: emailCtrl,
              decoration: const InputDecoration(labelText: 'Email', hintText: 'Email lo yang aktif'),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: () async {
                  final success = await auth.updateProfile(
                    username: nameCtrl.text.trim(),
                    email: emailCtrl.text.trim(),
                  );
                  if (context.mounted) {
                    Navigator.pop(context);
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Profil berhasil diupdate! 🤙✨')),
                      );
                    }
                  }
                },
                child: const Text('SIMPAN PERUBAHAN', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _showPhotoPicker(BuildContext context, AuthProvider auth) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final colors = AppColors.of(ctx);
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
          decoration: BoxDecoration(
            color: colors.bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'GANTI FOTO PROFIL',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1),
              ),
              const SizedBox(height: 24),
              // Kamera
              _PhotoOption(
                icon: Icons.camera_alt_rounded,
                label: 'Ambil dari Kamera',
                color: AppColors.primary,
                onTap: () async {
                  Navigator.pop(ctx);
                  await _pickImage(context, auth, ImageSource.camera);
                },
              ),
              const SizedBox(height: 12),
              // Galeri
              _PhotoOption(
                icon: Icons.photo_library_rounded,
                label: 'Pilih dari Galeri',
                color: AppColors.income,
                onTap: () async {
                  Navigator.pop(ctx);
                  await _pickImage(context, auth, ImageSource.gallery);
                },
              ),
              const SizedBox(height: 12),
              // Hapus foto
              if (auth.user?.photoUrl != null && auth.user!.photoUrl!.isNotEmpty)
                _PhotoOption(
                  icon: Icons.delete_outline_rounded,
                  label: 'Hapus Foto',
                  color: AppColors.expense,
                  onTap: () async {
                    Navigator.pop(ctx);
                    await auth.saveLocalPhoto('');
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(BuildContext context, AuthProvider auth, ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? picked = await picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 512,
        maxHeight: 512,
      );

      if (picked == null) return;

      // Simpan ke lokal (persisten)
      await auth.saveLocalPhoto(picked.path);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Foto profil diperbarui! 🔥✨'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.primary,
            margin: const EdgeInsets.all(20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Gagal ambil foto, coba lagi ya! 😅'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.expense,
            margin: const EdgeInsets.all(20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          ),
        );
      }
    }
  }
}

class _ProfileItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _ProfileItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: AppColors.primary.withOpacity(0.08),
        highlightColor: AppColors.primary.withOpacity(0.04),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(color: colors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
              trailing ?? Icon(Icons.chevron_right_rounded, color: colors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) {
    return Divider(color: AppColors.of(context).border, height: 1);
  }
}

// ─── Helper: build avatar berdasarkan local file atau inisial ─────────────────

Widget _buildAvatar(AuthProvider auth) {
  final photo = auth.user?.photoUrl;
  if (photo != null && photo.isNotEmpty) {
    // Cek apakah path lokal (file system) atau URL
    if (photo.startsWith('/') || photo.startsWith('file://')) {
      return Image.file(File(photo), fit: BoxFit.cover, errorBuilder: (_, __, ___) => _initials(auth));
    } else {
      return Image.network(photo, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _initials(auth));
    }
  }
  return _initials(auth);
}

Widget _initials(AuthProvider auth) {
  return Container(
    color: AppColors.primary,
    child: Center(
      child: Text(
        (auth.user?.username ?? 'U').substring(0, 1).toUpperCase(),
        style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w900),
      ),
    ),
  );
}

// ─── Widget pilihan foto (kamera / galeri / hapus) ────────────────────────────

class _PhotoOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _PhotoOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Text(
                label,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              Icon(Icons.arrow_forward_ios_rounded, color: colors.textMuted, size: 14),
            ],
          ),
        ),
      ),
    );
  }
}
