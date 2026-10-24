import 'package:flutter/material.dart';

import 'package:image_picker/image_picker.dart';

import '../../widgets/appConfirmDialog.dart';
import '../../screens/auth/authScreen.dart';
import '../../services/api_service.dart';
import 'editProfilePage.dart';
import '../../widgets/appNotification.dart';

import 'historyRegistrationPage.dart';

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
  static const Color primary = Color(0xFF3478E5);
  static const Color background = Color(0xFFF4F7FC);
  static const Color textColor = Color(0xFF202938);
  static const Color muted = Color(0xFF667085);
  static const Color borderColor = Color(0xFFE8EDF4);
  static const Color danger = Color(0xFFD92D20);

  late String _username;
  bool _isLoggingOut = false;

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

  final ImagePicker _imagePicker = ImagePicker();
  String? _fotoProfilUrl;
  bool _isUploadingFoto = false;
  bool _isAvatarHovered = false;

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
      // Jika profil gagal diambil, avatar inisial tetap ditampilkan.
      debugPrint('Gagal memuat profil: $e');
    }
  }

  Future<void> _pickAndUploadFoto() async {
    if (_isUploadingFoto) return;

    try {
      final foto = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1200,
      );

      // Pengguna membatalkan pemilihan foto.
      if (foto == null || !mounted) return;

      setState(() {
        _isUploadingFoto = true;
      });

      final response = await ApiService.uploadFotoProfil(
        token: widget.token,
        foto: foto,
      );

      debugPrint('RESPONS UPLOAD FOTO: $response');

      final dynamic user = response['user'];
      final dynamic fotoUrl = user is Map ? user['foto_profil_url'] : null;

      debugPrint('URL FOTO DARI LARAVEL: $fotoUrl');

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

  Widget _buildProfileAvatar() {
    final fotoUrl = _fotoProfilUrl;

    return MouseRegion(
      onEnter: (_) {
        setState(() => _isAvatarHovered = true);
      },
      onExit: (_) {
        setState(() => _isAvatarHovered = false);
      },
      child: Semantics(
        button: true,
        label: 'Ubah foto profil',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _isUploadingFoto ? null : _pickAndUploadFoto,
            borderRadius: BorderRadius.circular(25),
            child: Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                color: primary,
                borderRadius: BorderRadius.circular(25),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (fotoUrl != null && fotoUrl.isNotEmpty)
                      Image.network(
                        fotoUrl,
                        key: ValueKey(fotoUrl),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _initialAvatar();
                        },
                      )
                    else
                      _initialAvatar(),

                    AnimatedOpacity(
                      opacity: _isAvatarHovered || _isUploadingFoto ? 1 : 0,
                      duration: const Duration(milliseconds: 180),
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.42),
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
      ),
    );
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

  String _initials(String name) {
    final value = name.trim();

    if (value.isEmpty) return 'U';

    final parts = value.split(RegExp(r'\s+'));

    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  void _updateUsername(String usernameBaru) {
    if (!mounted) return;

    setState(() {
      _username = usernameBaru;
    });

    widget.onUsernameChanged(usernameBaru);
  }

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

  void _openHistory() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const HistoryRegistrationPage()));
  }

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
              // HEADER: mengikuti gaya halaman Lomba Saya
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(22, 28, 22, 28),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFE0ECFF), Color(0xFFF4F7FC)],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(36),
                    bottomRight: Radius.circular(36),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Akun Kamu',
                      style: TextStyle(
                        color: primary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Profil Saya',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Kelola akun dan aktivitasmu.',
                      style: TextStyle(color: muted, fontSize: 15),
                    ),
                    const SizedBox(height: 24),

                    // Kartu identitas di dalam header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.82),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: Row(
                        children: [
                          Container(
                            // Kartu identitas luar
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.82),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.white,
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              children: [
                                _buildProfileAvatar(),
                                // Username
                                // Role
                              ],
                            ),
                          ),

                          const SizedBox(width: 14),
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
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEAF2FF),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    widget.role,
                                    style: const TextStyle(
                                      color: primary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.person_outline_rounded,
                            color: primary,
                            size: 25,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // MENU: tetap tiga fitur yang sudah ada
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 26, 20, 125),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'AKUN',
                      style: TextStyle(
                        color: muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(23),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        children: [
                          _menuRow(
                            icon: Icons.person_outline_rounded,
                            title: 'Edit Profil',
                            subtitle: 'Username dan kata sandi',
                            onTap: _openEditProfile,
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 76),
                            child: Divider(height: 1, color: borderColor),
                          ),
                          _menuRow(
                            icon: Icons.history_rounded,
                            title: 'Riwayat Pendaftaran',
                            subtitle: 'Aktivitas pendaftaran lomba',
                            onTap: _openHistory,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      'SESI AKUN',
                      style: TextStyle(
                        color: muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Material(
                      color: const Color(0xFFFFF0EF),
                      borderRadius: BorderRadius.circular(20),
                      child: InkWell(
                        onTap: _isLoggingOut ? null : _logout,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFF8DAD7)),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.logout_rounded,
                                color: Color(0xFFD92D20),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  _isLoggingOut ? 'Sedang keluar...' : 'Keluar',
                                  style: const TextStyle(
                                    color: Color(0xFFD92D20),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: Color(0xFFD92D20),
                              ),
                            ],
                          ),
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
    );
  }

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
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 17),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF2FF),
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
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF98A2B3),
                size: 23,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
