import '../../widgets/app_feedback.dart';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../config/appTheme.dart';
import '../../design_system/tl_playful.dart';
import '../../screens/auth/authScreen.dart';
import '../../services/api_service.dart';
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

  Color get primary => context.tl.primary;
  Color get primaryDark => context.tl.primaryDark;
  Color get cream => context.tl.cream;
  Color get creamLight => context.tl.creamLight;
  Color get creamDark => context.tl.creamDark;
  Color get background => context.tl.background;
  Color get textColor => context.tl.navy;
  Color get muted => context.tl.grey;
  Color get borderColor => context.tl.fieldBorder;
  Color get danger => context.tl.error;

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
        style: TextStyle(
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
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: Offset(0, 5),
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
                    duration: Duration(milliseconds: 180),
                    child: Container(
                      color: primaryDark.withValues(alpha: 0.65),
                      alignment: Alignment.center,
                      child: _isUploadingFoto
                          ? SizedBox(
                              width: 25,
                              height: 25,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
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

    AppPopup.loading(context, message: 'Sedang keluar...');

    try {
      await ApiService.logout(token: widget.token);

      if (!mounted) return;

      Navigator.of(context, rootNavigator: true).pop();

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => AuthScreen()),
        (route) => false,
      );
    } catch (_) {
      if (!mounted) return;

      Navigator.of(context, rootNavigator: true).pop();

      setState(() {
        _isLoggingOut = false;
      });

      AppNotification.message(
        context,
        'Logout gagal. Silakan coba lagi.',
        type: NotificationType.error,
      );
    }
  }

  // ==========================================
  // CARD DECORATION
  // ==========================================

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: context.tl.surface,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: borderColor),
      boxShadow: [
        BoxShadow(
          color: primaryDark.withValues(alpha: 0.035),
          blurRadius: 16,
          offset: Offset(0, 5),
        ),
      ],
    );
  }

  // ==========================================
  // HEADER PROFILE
  // ==========================================

  Widget _buildHeader() {
    final p = context.tl;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 23, 18, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset(
                'assets/Logo.png',
                width: 35,
                height: 35,
                errorBuilder: (_, _, _) =>
                    Icon(Icons.emoji_events_rounded, color: p.orange, size: 32),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  'TERNATELOMBA  /  PROFILE',
                  style: TextStyle(
                    fontSize: 10.5,
                    letterSpacing: 1.25,
                    fontWeight: FontWeight.w900,
                    color: p.navy,
                  ),
                ),
              ),
              TLPlayful.statusPill(
                context,
                'ACCOUNT',
                p.orange,
                icon: Icons.stars_rounded,
              ),
            ],
          ),
          const SizedBox(height: 23),
          Text(
            'Your space.\nYour progress.',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 28,
              height: 1.05,
              letterSpacing: -1.15,
              color: p.navy,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Identitas dan pengaturan untuk tetap fokus pada tujuanmu.',
            style: TextStyle(fontSize: 12.5, height: 1.4, color: p.grey),
          ),
          const SizedBox(height: 19),
          Container(
            decoration: TLPlayful.card(context, radius: 29),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                Positioned(
                  right: -23,
                  top: -35,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: p.cream.withValues(alpha: .45),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(17, 19, 17, 19),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _buildProfileAvatar(),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _username,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: p.navy,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -.5,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TLPlayful.statusPill(
                                  context,
                                  widget.role,
                                  p.mint,
                                  icon: Icons.verified_rounded,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 17),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: p.surface.withValues(alpha: .75),
                          borderRadius: BorderRadius.circular(17),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.camera_alt_rounded,
                              color: p.primary,
                              size: 19,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Ketuk avatar untuk memperbarui foto profil',
                                style: TextStyle(
                                  color: p.grey,
                                  height: 1.3,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
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
      padding: EdgeInsets.only(bottom: 13),
      child: Text(
        title,
        style: TextStyle(
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
    final p = context.tl;
    final accent = title.contains('Bantuan')
        ? p.mint
        : title.contains('Tentang')
        ? p.orange
        : title.contains('Profil')
        ? p.coral
        : p.lavender;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(23),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(13, 14, 12, 14),
          child: Row(
            children: [
              Container(
                height: 53,
                width: 53,
                decoration: BoxDecoration(
                  color: Color.alphaBlend(
                    accent.withValues(alpha: .17),
                    p.surface,
                  ),
                  borderRadius: BorderRadius.circular(19),
                ),
                child: Icon(icon, color: accent, size: 25),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: p.navy,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11.5,
                        height: 1.35,
                        color: p.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: p.fieldBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.arrow_outward_rounded,
                  color: p.navy,
                  size: 17,
                ),
              ),
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
      child: Column(
        children: [
          _menuRow(
            icon: Icons.manage_accounts_outlined,
            title: 'Edit Profil',
            subtitle: 'Ubah username dan kata sandi',
            onTap: _openEditProfile,
          ),
        ],
      ),
    );
  }

  Widget _menuDivider() => Padding(
    padding: EdgeInsets.symmetric(horizontal: 18),
    child: Divider(height: 1, thickness: 1, color: borderColor),
  );

  Widget _buildHelpMenu() {
    return Container(
      decoration: _cardDecoration(),
      child: Column(
        children: [
          _menuRow(
            icon: Icons.help_outline_rounded,
            title: 'Pusat Bantuan',
            subtitle: 'Panduan dan pertanyaan umum',
            onTap: _showHelp,
          ),
          _menuDivider(),
          _menuRow(
            icon: Icons.info_outline_rounded,
            title: 'Tentang TernateLomba',
            subtitle: 'Informasi aplikasi dan versi',
            onTap: _showAbout,
          ),
        ],
      ),
    );
  }

  Future<void> _showInfoSheet({
    required String title,
    required IconData icon,
    required Widget content,
  }) async {
    await AppPopup.show<void>(
      context: context,
      title: title,
      icon: icon,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(2, 3, 2, 18),
        child: content,
      ),
    );
  }

  Widget _infoLine(String title, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(
              title,
              style: TextStyle(
                color: muted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: textColor,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _faqItem(String question, String answer) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.symmetric(horizontal: 14, vertical: 3),
        childrenPadding: EdgeInsets.fromLTRB(14, 0, 14, 16),
        iconColor: primary,
        collapsedIconColor: muted,
        title: Text(
          question,
          style: TextStyle(
            color: textColor,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              answer,
              style: TextStyle(color: muted, fontSize: 12, height: 1.6),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showHelp() => _showInfoSheet(
    title: 'Pusat Bantuan',
    icon: Icons.help_outline_rounded,
    content: Container(
      decoration: _cardDecoration(),
      child: Column(
        children: [
          _faqItem(
            'Bagaimana mencari lomba?',
            'Buka Beranda atau Jelajahi Lomba. Gunakan kolom pencarian dan filter kategori untuk menemukan lomba.',
          ),
          _menuDivider(),
          _faqItem(
            'Bagaimana cara mengikuti lomba?',
            'Pilih lomba, baca detail dan persyaratannya, lalu isi formulir pendaftaran jika pendaftaran masih dibuka.',
          ),
          _menuDivider(),
          _faqItem(
            'Bagaimana membuat lomba?',
            'Buka Lomba Saya, ketuk tombol Ajukan Lomba, lalu lengkapi setiap tahap formulir. Pengajuan akan diperiksa administrator.',
          ),
          _menuDivider(),
          _faqItem(
            'Di mana saya melihat status lomba?',
            'Buka Lomba Saya untuk melihat lomba yang diikuti dan dibuat, serta status pengajuan atau pendaftaran.',
          ),
          _menuDivider(),
          _faqItem(
            'Bagaimana menggunakan chat?',
            'Buka tab Chat pada navigasi utama, lalu pilih percakapan lomba yang tersedia untuk akunmu.',
          ),
          _menuDivider(),
          _faqItem(
            'Bagaimana mengganti foto profil?',
            'Buka Profil, kemudian ketuk foto profil untuk memilih gambar baru dari galeri.',
          ),
        ],
      ),
    ),
  );

  Future<void> _showAbout() => _showInfoSheet(
    title: 'Tentang TernateLomba',
    icon: Icons.info_outline_rounded,
    content: Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: cream,
              borderRadius: BorderRadius.circular(17),
            ),
            child: Icon(Icons.emoji_events_rounded, size: 30, color: primary),
          ),
          SizedBox(height: 16),
          Text(
            'TernateLomba',
            style: TextStyle(
              color: textColor,
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 9),
          Text(
            'TernateLomba adalah platform informasi lomba yang membantu pengguna menemukan, mengikuti, dan mengajukan lomba dalam satu aplikasi.',
            style: TextStyle(color: muted, fontSize: 13, height: 1.65),
          ),
          SizedBox(height: 18),
          Divider(color: borderColor),
          _infoLine('Versi aplikasi', '1.0.0+1'),
        ],
      ),
    ),
  );

  // ==========================================
  // LOGOUT BUTTON
  // ==========================================

  Widget _buildLogoutButton() {
    return Material(
      color: context.tl.statusBadBg,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: _isLoggingOut ? null : _logout,
        borderRadius: BorderRadius.circular(20),
        hoverColor: context.tl.statusBadBg,
        child: Container(
          padding: EdgeInsets.all(17),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: context.tl.statusBadBg),
          ),
          child: Row(
            children: [
              Icon(Icons.logout_rounded, color: danger, size: 22),

              SizedBox(width: 14),

              Expanded(
                child: Text(
                  _isLoggingOut ? 'Sedang keluar...' : 'Keluar dari Akun',
                  style: TextStyle(
                    color: danger,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),

              Icon(Icons.chevron_right_rounded, color: danger, size: 23),
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
          physics: BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // HEADER

              _buildHeader(),
              // MENU
              Padding(
                padding: EdgeInsets.fromLTRB(20, 27, 20, 130),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeading('PENGATURAN AKUN'),

                    _buildAccountMenu(),

                    SizedBox(height: 28),

                    _sectionHeading('BANTUAN & INFORMASI'),

                    _buildHelpMenu(),

                    SizedBox(height: 28),

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
