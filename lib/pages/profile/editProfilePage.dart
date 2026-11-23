import '../../design_system/tl_playful.dart';

import 'package:flutter/material.dart';

import '../../config/appTheme.dart';
import '../../widgets/app_feedback.dart';
import '../../screens/auth/authScreen.dart';
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

    final passwordChanged = passwordController.text.isNotEmpty;
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: passwordChanged ? 'Ubah kata sandi?' : 'Simpan perubahan?',
      message: passwordChanged
          ? 'Yakin ingin mengganti kata sandi akun? Setelah berhasil disimpan, kamu akan keluar otomatis dan harus login kembali menggunakan kata sandi baru.'
          : 'Apakah kamu yakin ingin menyimpan perubahan username?',
      confirmText: passwordChanged ? 'Ubah Sandi' : 'Simpan',
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

      await AppNotification.show(
        context: context,
        title: 'Berhasil!',
        message: passwordBerubah
            ? 'Kata sandi berhasil diperbarui. Silakan masuk kembali demi keamanan akun.'
            : (hasil['pesan'] ?? 'Profil berhasil diperbarui').toString(),
        type: NotificationType.success,
      );
      if (!mounted) return;
      if (passwordBerubah) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthScreen()),
          (route) => false,
        );
      } else {
        Navigator.of(context).pop();
      }
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
      color: context.tl.surface,
      borderRadius: BorderRadius.circular(23),
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
  // HEADER
  // ==========================================

  Widget _buildHeader() => TLPlayful.pageHeader(
    context,
    title: 'Keep your\nprofile sharp.',
    description: 'Perbarui identitas dan keamanan akunmu di sini.',
    icon: Icons.manage_accounts_rounded,
    accent: context.tl.lavender,
    onBack: () {
      if (!loading) Navigator.of(context).pop();
    },
  );

  // ==========================================
  // SECTION HEADING
  // ==========================================

  Widget _sectionHeading({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final p = context.tl;
    return Row(
      children: [
        Container(
          width: 47,
          height: 47,
          decoration: BoxDecoration(
            color: p.lavender.withValues(alpha: .20),
            borderRadius: BorderRadius.circular(17),
          ),
          child: Icon(icon, color: p.lavender, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: p.navy,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                style: TextStyle(color: p.grey, fontSize: 12, height: 1.45),
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
      padding: EdgeInsets.only(bottom: 9),
      child: Text(
        label,
        style: TextStyle(
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

      hintStyle: TextStyle(color: context.tl.muted, fontSize: 12),

      prefixIcon: Icon(icon, color: primary, size: 20),

      suffixIcon: suffix,

      filled: true,
      fillColor: creamLight,

      contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 17),

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: borderColor),
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: borderColor),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: primary, width: 1.5),
      ),

      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: danger),
      ),

      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: danger, width: 1.5),
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

        SizedBox(height: 7),

        Text(
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
    final p = context.tl;
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: TLPlayful.card(context, tint: p.yellow, radius: 22),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: p.yellow.withValues(alpha: .18),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(Icons.lock_person_rounded, color: p.orange, size: 23),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tetap aman, tetap nyaman',
                  style: TextStyle(
                    color: p.navy,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Kosongkan kedua kolom kata sandi jika kamu hanya ingin mengubah username. Gunakan minimal 8 karakter untuk kata sandi baru.',
                  style: TextStyle(color: p.grey, fontSize: 11.5, height: 1.55),
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
            ? Row(
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
            : Row(
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
          physics: BouncingScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // HEADER IKUT TERSCROLL
                _buildHeader(),

                Padding(
                  padding: EdgeInsets.fromLTRB(20, 23, 20, 35),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // INFORMASI AKUN

                      _sectionHeading(
                        title: 'Informasi Akun',
                        subtitle: 'Perbarui identitas pengguna.',
                        icon: Icons.manage_accounts_outlined,
                      ),

                      SizedBox(height: 17),

                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(18),
                        decoration: _cardDecoration(),
                        child: _buildUsernameField(),
                      ),

                      SizedBox(height: 25),

                      // KEAMANAN AKUN
                      _sectionHeading(
                        title: 'Keamanan Akun',
                        subtitle: 'Perbarui password untuk menjaga akun.',
                        icon: Icons.shield_outlined,
                      ),

                      SizedBox(height: 17),

                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(18),
                        decoration: _cardDecoration(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildPasswordField(),

                            SizedBox(height: 22),

                            _buildConfirmPasswordField(),

                            SizedBox(height: 22),

                            _buildSecurityInfo(),
                          ],
                        ),
                      ),

                      SizedBox(height: 25),

                      // TOMBOL SIMPAN
                      _buildSaveButton(),

                      SizedBox(height: 15),

                      Center(
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
