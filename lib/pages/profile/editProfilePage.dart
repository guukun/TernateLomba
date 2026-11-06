import 'package:flutter/material.dart';

import '../../config/appTheme.dart';
import '../../widgets/appNotification.dart';
import '../../widgets/appConfirmDialog.dart';
import '../../services/api_service.dart';

class EditProfilePage extends StatefulWidget {
  final String username;
  final String token;
  final ValueChanged<String> onSave;

  const EditProfilePage({
    super.key,
    required this.username,
    required this.token,
    required this.onSave,
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
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
  // FORM STATE
  // ==========================================

  final _formKey = GlobalKey<FormState>();

  late final TextEditingController nameController;

  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool hidePassword = true;
  bool hideConfirmPassword = true;
  bool loading = false;

  @override
  void initState() {
    super.initState();

    nameController = TextEditingController(text: widget.username);
  }

  @override
  void dispose() {
    nameController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();

    super.dispose();
  }

  // ==========================================
  // NOTIFICATION
  // ==========================================

  void _showMessage(String message, {bool success = false}) {
    if (!mounted) return;

    AppNotification.show(
      context: context,
      title: success ? 'Berhasil!' : 'Terjadi Kesalahan',
      message: message,
      type: success ? NotificationType.success : NotificationType.error,
    );
  }

  // ==========================================
  // VALIDASI FORM
  // ==========================================

  bool _validateForm() {
    FocusScope.of(context).unfocus();

    return _formKey.currentState?.validate() ?? false;
  }

  // ==========================================
  // KONFIRMASI SIMPAN
  // ==========================================

  Future<void> _confirmSave() async {
    if (loading) return;

    if (!_validateForm()) return;

    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'Simpan perubahan?',
      message: 'Apakah kamu yakin ingin menyimpan perubahan profil ini?',
      confirmText: 'Simpan',
      cancelText: 'Batal',
      confirmColor: primary,
    );

    if (confirmed != true || !mounted) return;

    await save();
  }

  // ==========================================
  // UPDATE PROFILE
  // ==========================================

  Future<void> save() async {
    if (loading) return;

    if (!_validateForm()) return;

    if (widget.token.trim().isEmpty) {
      _showMessage('Token tidak tersedia. Silakan login kembali.');
      return;
    }

    final usernameBaru = nameController.text.trim();
    final passwordBaru = passwordController.text;
    final konfirmasi = confirmPasswordController.text;

    setState(() {
      loading = true;
    });

    try {
      final hasil = await ApiService.updateProfile(
        token: widget.token,
        username: usernameBaru,
        password: passwordBaru,
        passwordConfirmation: konfirmasi,
      );

      if (!mounted) return;

      final user = hasil['user'];

      if (user is! Map) {
        _showMessage('Respons Laravel tidak memiliki data user.');
        return;
      }

      final usernameHasil = user['username'];

      if (usernameHasil is! String || usernameHasil.trim().isEmpty) {
        _showMessage('Respons Laravel tidak memiliki username yang valid.');
        return;
      }

      // Perbarui username pada halaman induk.

      widget.onSave(usernameHasil);

      if (!mounted) return;

      final passwordBerubah = passwordBaru.isNotEmpty;

      _showMessage(
        passwordBerubah
            ? 'Username dan kata sandi berhasil diperbarui.'
            : (hasil['pesan'] ?? 'Profil berhasil diperbarui').toString(),
        success: true,
      );

      Navigator.of(context).pop();
    } catch (e) {
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  // ==========================================
  // DECORATION
  // ==========================================

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(23),
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
  // HEADER
  // ==========================================

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 17, 22, 28),
      decoration: const BoxDecoration(
        color: primaryDark,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Material(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(13),
                child: InkWell(
                  borderRadius: BorderRadius.circular(13),
                  onTap: loading ? null : () => Navigator.of(context).pop(),
                  child: const SizedBox(
                    width: 43,
                    height: 43,
                    child: Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                      size: 21,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 13),

              const Expanded(
                child: Text(
                  'Edit Profil',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
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

          const SizedBox(height: 25),

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
            'Kelola Profilmu',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Perbarui informasi akun dan jaga keamanan aksesmu.',
            style: TextStyle(
              color: Color(0xFFDCE6F0),
              fontSize: 12,
              height: 1.6,
            ),
          ),

          const SizedBox(height: 20),

          // Identitas akun
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: creamLight,
              borderRadius: BorderRadius.circular(19),
              border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: cream,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.person_outline_rounded,
                    color: primary,
                    size: 25,
                  ),
                ),

                const SizedBox(width: 13),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Username saat ini',
                        style: TextStyle(color: muted, fontSize: 11),
                      ),

                      const SizedBox(height: 5),

                      Text(
                        widget.username,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: textColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),

                const Icon(
                  Icons.verified_user_outlined,
                  color: primary,
                  size: 22,
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

  Widget _sectionHeading({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: cream,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: primary, size: 21),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: textColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                subtitle,
                style: const TextStyle(color: muted, fontSize: 11, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================
  // FIELD LABEL
  // ==========================================

  Widget _fieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Text(
        label,
        style: const TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  // ==========================================
  // INPUT DECORATION
  // ==========================================

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,

      hintStyle: const TextStyle(color: AppColors.muted, fontSize: 12),

      prefixIcon: Icon(icon, color: primary, size: 20),

      suffixIcon: suffix,

      filled: true,
      fillColor: creamLight,

      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 17),

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: borderColor),
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: borderColor),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: primary, width: 1.5),
      ),

      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: danger),
      ),

      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: danger, width: 1.5),
      ),
    );
  }

  // ==========================================
  // PASSWORD VISIBILITY
  // ==========================================

  Widget _passwordVisibilityButton({
    required bool hidden,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      onPressed: loading ? null : onPressed,
      tooltip: hidden ? 'Tampilkan password' : 'Sembunyikan password',
      icon: Icon(
        hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        color: muted,
        size: 20,
      ),
    );
  }

  // ==========================================
  // USERNAME FIELD
  // ==========================================

  Widget _buildUsernameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('Nama Pengguna'),

        TextFormField(
          controller: nameController,
          enabled: !loading,
          textInputAction: TextInputAction.next,
          textCapitalization: TextCapitalization.none,
          autocorrect: false,

          decoration: _inputDecoration(
            hint: 'Masukkan username',
            icon: Icons.person_outline_rounded,
          ),

          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Nama pengguna wajib diisi';
            }

            if (value.trim().length > 255) {
              return 'Nama pengguna maksimal 255 karakter';
            }

            return null;
          },
        ),

        const SizedBox(height: 7),

        const Text(
          'Username digunakan sebagai identitas akunmu.',
          style: TextStyle(color: muted, fontSize: 10),
        ),
      ],
    );
  }

  // ==========================================
  // PASSWORD FIELD
  // ==========================================

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('Password Baru'),

        TextFormField(
          controller: passwordController,
          enabled: !loading,
          obscureText: hidePassword,
          textInputAction: TextInputAction.next,
          autocorrect: false,

          decoration: _inputDecoration(
            hint: 'Masukkan password baru',
            icon: Icons.lock_outline_rounded,
            suffix: _passwordVisibilityButton(
              hidden: hidePassword,
              onPressed: () {
                setState(() {
                  hidePassword = !hidePassword;
                });
              },
            ),
          ),

          validator: (value) {
            if (value == null || value.isEmpty) {
              return null;
            }

            if (value.length < 8) {
              return 'Password minimal 8 karakter';
            }

            return null;
          },
        ),
      ],
    );
  }

  // ==========================================
  // CONFIRM PASSWORD FIELD
  // ==========================================

  Widget _buildConfirmPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('Konfirmasi Password Baru'),

        TextFormField(
          controller: confirmPasswordController,
          enabled: !loading,
          obscureText: hideConfirmPassword,
          textInputAction: TextInputAction.done,
          autocorrect: false,

          onFieldSubmitted: (_) {
            if (!loading) {
              _confirmSave();
            }
          },

          decoration: _inputDecoration(
            hint: 'Ulangi password baru',
            icon: Icons.lock_outline_rounded,
            suffix: _passwordVisibilityButton(
              hidden: hideConfirmPassword,
              onPressed: () {
                setState(() {
                  hideConfirmPassword = !hideConfirmPassword;
                });
              },
            ),
          ),

          validator: (value) {
            final confirmation = value ?? '';

            if (passwordController.text.isEmpty) {
              if (confirmation.isNotEmpty) {
                return 'Isi password baru terlebih dahulu';
              }

              return null;
            }

            if (confirmation.isEmpty) {
              return 'Konfirmasi password wajib diisi';
            }

            if (confirmation != passwordController.text) {
              return 'Password tidak sama';
            }

            return null;
          },
        ),
      ],
    );
  }

  // ==========================================
  // INFORMASI KEAMANAN
  // ==========================================

  Widget _buildSecurityInfo() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: creamLight,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: creamDark),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: primary, size: 20),

          SizedBox(width: 11),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Informasi Keamanan',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                SizedBox(height: 5),

                Text(
                  'Kosongkan kedua kolom password jika kamu hanya ingin mengubah username. Gunakan password minimal 8 karakter.',
                  style: TextStyle(color: muted, fontSize: 11, height: 1.6),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TOMBOL SIMPAN
  // ==========================================

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: loading ? null : _confirmSave,

        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: primary.withValues(alpha: 0.65),
          elevation: 0,

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),

        child: loading
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 19,
                    height: 19,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),

                  SizedBox(width: 11),

                  Text(
                    'Menyimpan perubahan...',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ],
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline_rounded, size: 20),

                  SizedBox(width: 9),

                  Text(
                    'Simpan Perubahan',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                  ),
                ],
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
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // HEADER IKUT TERSCROLL
                _buildHeader(),

                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 23, 20, 35),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // INFORMASI AKUN

                      _sectionHeading(
                        title: 'Informasi Akun',
                        subtitle: 'Perbarui identitas pengguna.',
                        icon: Icons.manage_accounts_outlined,
                      ),

                      const SizedBox(height: 17),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: _cardDecoration(),
                        child: _buildUsernameField(),
                      ),

                      const SizedBox(height: 25),

                      // KEAMANAN AKUN
                      _sectionHeading(
                        title: 'Keamanan Akun',
                        subtitle: 'Perbarui password untuk menjaga akun.',
                        icon: Icons.shield_outlined,
                      ),

                      const SizedBox(height: 17),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: _cardDecoration(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildPasswordField(),

                            const SizedBox(height: 22),

                            _buildConfirmPasswordField(),

                            const SizedBox(height: 22),

                            _buildSecurityInfo(),
                          ],
                        ),
                      ),

                      const SizedBox(height: 25),

                      // TOMBOL SIMPAN
                      _buildSaveButton(),

                      const SizedBox(height: 15),

                      const Center(
                        child: Text(
                          'TERNATE LOMBA • PENGELOLAAN AKUN',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: muted,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
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
      ),
    );
  }
}
