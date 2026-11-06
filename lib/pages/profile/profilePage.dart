import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../config/appTheme.dart';
import '../../widgets/appConfirmDialog.dart';
import '../../screens/auth/authScreen.dart';
import '../../services/api_service.dart';
import '../../widgets/appNotification.dart';
import 'editProfilePage.dart';

class ProfilePage extends StatefulWidget {
  final String username;
  final String role;
  final String token;
  final ValueChanged<String> onUsernameChanged;
  final VoidCallback onProfileChanged;

  const ProfilePage({
    super.key,
    required this.username,
    required this.role,
    required this.token,
    required this.onUsernameChanged,
    required this.onProfileChanged,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // ==========================================
  // APP THEME
  // ==========================================

  static const Color primary = AppColors.primary;
  static const Color primaryDark = AppColors.primaryDark;
  static const Color cream = AppColors.cream;
  static const Color creamLight = AppColors.creamLight;
  static const Color creamDark = AppColors.creamDark;
  static const Color background = AppColors.background;
  static const Color textColor = AppColors.navy;
  static const Color muted = AppColors.grey;
  static const Color borderColor = AppColors.fieldBorder;
  static const Color danger = AppColors.error;

  // ==========================================
  // STATE
  // ==========================================

  late String _username;

  String? _fotoProfilUrl;

  bool _isLoggingOut = false;
  bool _isUploadingFoto = false;
  bool _isAvatarHovered = false;

  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();

    _username = widget.username;

    _loadCurrentUser();
  }

  @override
  void didUpdateWidget(covariant ProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.username != widget.username) {
      _username = widget.username;
    }
  }

  // ==========================================
  // LOAD USER
  // ==========================================

  Future<void> _loadCurrentUser() async {
    try {
      final user = await ApiService.getCurrentUser(token: widget.token);

      if (!mounted) return;

      setState(() {
        _username = (user['username'] ?? _username).toString();

        final foto = user['foto_profil_url'];

        _fotoProfilUrl = foto == null || foto.toString().isEmpty
            ? null
            : foto.toString();
      });
    } catch (e) {
      debugPrint('Gagal memuat profil: $e');
    }
  }

  // ==========================================
  // UPLOAD FOTO PROFIL
  // ==========================================

  Future<void> _pickAndUploadFoto() async {
    if (_isUploadingFoto) return;

    try {
      final foto = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1200,
      );

      if (foto == null || !mounted) return;

      setState(() {
        _isUploadingFoto = true;
      });

      final response = await ApiService.uploadFotoProfil(
        token: widget.token,
        foto: foto,
      );

      final dynamic user = response['user'];

      final dynamic fotoUrl = user is Map ? user['foto_profil_url'] : null;

      if (!mounted) return;

      setState(() {
        _fotoProfilUrl = fotoUrl == null || fotoUrl.toString().isEmpty
            ? null
            : fotoUrl.toString();

        _isUploadingFoto = false;
      });

      AppNotification.show(
        context: context,
        title: 'Foto Profil Diperbarui',
        message: 'Foto profil berhasil diperbarui.',
        type: NotificationType.success,
      );

      widget.onProfileChanged();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isUploadingFoto = false;
      });

      AppNotification.show(
        context: context,
        title: 'Upload Gagal',
        message:
            'Gagal mengunggah foto: '
            '${e.toString().replaceFirst('Exception: ', '')}',
        type: NotificationType.error,
      );
    }
  }

  // ==========================================
  // INITIAL AVATAR
  // ==========================================

  String _initials(String name) {
    final value = name.trim();

    if (value.isEmpty) return 'U';

    final parts = value.split(RegExp(r'\s+'));

    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  Widget _initialAvatar() {
    return Container(
      color: primary,
      alignment: Alignment.center,
      child: Text(
        _initials(_username),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 30,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildProfileAvatar() {
    final fotoUrl = _fotoProfilUrl;

    return MouseRegion(
      onEnter: (_) {
        setState(() => _isAvatarHovered = true);
      },
      onExit: (_) {
        setState(() => _isAvatarHovered = false);
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isUploadingFoto ? null : _pickAndUploadFoto,
          borderRadius: BorderRadius.circular(25),
          child: Container(
            width: 86,
            height: 86,
            decoration: BoxDecoration(
              color: primary,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: cream, width: 3),
              boxShadow: [
                BoxShadow(
                  color: primary.withValues(alpha: 0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (fotoUrl != null && fotoUrl.isNotEmpty)
                    Image.network(
                      fotoUrl,
                      key: ValueKey(fotoUrl),
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _initialAvatar(),
                    )
                  else
                    _initialAvatar(),

                  AnimatedOpacity(
                    opacity: _isAvatarHovered || _isUploadingFoto ? 1 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: Container(
                      color: primaryDark.withValues(alpha: 0.65),
                      alignment: Alignment.center,
                      child: _isUploadingFoto
                          ? const SizedBox(
                              width: 25,
                              height: 25,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.camera_alt_rounded,
                              color: Colors.white,
                              size: 27,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // UPDATE USERNAME
  // ==========================================

  void _updateUsername(String usernameBaru) {
    if (!mounted) return;

    setState(() {
      _username = usernameBaru;
    });

    widget.onUsernameChanged(usernameBaru);
  }

  // ==========================================
  // EDIT PROFILE
  // ==========================================

  Future<void> _openEditProfile() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditProfilePage(
          username: _username,
          token: widget.token,
          onSave: _updateUsername,
        ),
      ),
    );
  }

  // ==========================================
  // LOGOUT
  // ==========================================

  Future<void> _logout() async {
    if (_isLoggingOut) return;

    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'Keluar dari akun?',
      message: 'Kamu perlu masuk kembali untuk mengakses akunmu.',
      confirmText: 'Keluar',
      cancelText: 'Batal',
      confirmColor: primary,
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _isLoggingOut = true;
    });

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return const PopScope(
          canPop: false,
          child: Center(
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(20)),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: primary, strokeWidth: 3),
                    SizedBox(height: 18),
                    Text(
                      'Sedang keluar...',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    try {
      await ApiService.logout(token: widget.token);

      if (!mounted) return;

      Navigator.of(context, rootNavigator: true).pop();

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthScreen()),
        (route) => false,
      );
    } catch (_) {
      if (!mounted) return;

      Navigator.of(context, rootNavigator: true).pop();

      setState(() {
        _isLoggingOut = false;
      });

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: const Text('Logout gagal. Silakan coba lagi.'),
            backgroundColor: danger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
    }
  }

  // ==========================================
  // CARD DECORATION
  // ==========================================

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: borderColor),
      boxShadow: [
        BoxShadow(
          color: primaryDark.withValues(alpha: 0.035),
          blurRadius: 16,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }

  // ==========================================
  // HEADER PROFILE
  // ==========================================

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 28, 22, 30),
      decoration: const BoxDecoration(
        color: primaryDark,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  color: Colors.white,
                  size: 23,
                ),
              ),

              const SizedBox(width: 12),

              const Expanded(
                child: Text(
                  'TERNATE LOMBA',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: cream,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'AKUN',
                  style: TextStyle(
                    color: primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 27),

          const Text(
            'PENGATURAN AKUN',
            style: TextStyle(
              color: cream,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Profil Saya',
            style: TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.7,
            ),
          ),

          const SizedBox(height: 7),

          const Text(
            'Kelola informasi dan pengaturan akunmu.',
            style: TextStyle(
              color: Color(0xFFDCE6F0),
              fontSize: 13,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 23),

          // Kartu identitas
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: creamLight,
              borderRadius: BorderRadius.circular(23),
              border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                _buildProfileAvatar(),

                const SizedBox(width: 15),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _username,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: cream,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.role,
                          style: const TextStyle(
                            color: primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        'Ketuk foto untuk mengganti avatar',
                        style: TextStyle(color: muted, fontSize: 10),
                      ),
                    ],
                  ),
                ),

                const Icon(
                  Icons.verified_user_outlined,
                  color: primary,
                  size: 24,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // SECTION HEADING
  // ==========================================

  Widget _sectionHeading(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Text(
        title,
        style: const TextStyle(
          color: muted,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.3,
        ),
      ),
    );
  }

  // ==========================================
  // MENU ROW
  // ==========================================

  Widget _menuRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(19),
        hoverColor: cream,
        splashColor: creamDark.withValues(alpha: 0.3),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 17),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: cream,
                  borderRadius: BorderRadius.circular(15),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: primary, size: 23),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: textColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: muted,
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(Icons.chevron_right_rounded, color: muted, size: 23),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // MENU AKUN
  // ==========================================

  Widget _buildAccountMenu() {
    return Container(
      decoration: _cardDecoration(),
      child: _menuRow(
        icon: Icons.manage_accounts_outlined,
        title: 'Edit Profil',
        subtitle: 'Ubah username dan kata sandi',
        onTap: _openEditProfile,
      ),
    );
  }

  // ==========================================
  // LOGOUT BUTTON
  // ==========================================

  Widget _buildLogoutButton() {
    return Material(
      color: const Color(0xFFFFF0EF),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: _isLoggingOut ? null : _logout,
        borderRadius: BorderRadius.circular(20),
        hoverColor: const Color(0xFFFFE4E1),
        child: Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF8DAD7)),
          ),
          child: Row(
            children: [
              const Icon(Icons.logout_rounded, color: danger, size: 22),

              const SizedBox(width: 14),

              Expanded(
                child: Text(
                  _isLoggingOut ? 'Sedang keluar...' : 'Keluar dari Akun',
                  style: const TextStyle(
                    color: danger,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),

              const Icon(Icons.chevron_right_rounded, color: danger, size: 23),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // BUILD
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,

      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // HEADER

              _buildHeader(),

              // MENU
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 27, 20, 130),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeading('PENGATURAN AKUN'),

                    _buildAccountMenu(),

                    const SizedBox(height: 28),

                    _sectionHeading('SESI AKUN'),

                    _buildLogoutButton(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
