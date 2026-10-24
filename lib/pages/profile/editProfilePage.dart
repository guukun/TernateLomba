import 'package:flutter/material.dart';

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
  static const Color primary = Color(0xFF3478E5);
  static const Color lightBlue = Color(0xFFEAF2FF);
  static const Color background = Color(0xFFF5F7FB);
  static const Color textColor = Color(0xFF202938);
  static const Color muted = Color(0xFF667085);
  static const Color borderColor = Color(0xFFE2E8F0);

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

  void _showMessage(String message, {bool success = false}) {
    if (!mounted) return;

    AppNotification.show(
      context: context,
      title: success ? 'Berhasil!' : 'Terjadi Kesalahan',
      message: message,
      type: success ? NotificationType.success : NotificationType.error,
    );
  }

  Future<void> _confirmSave() async {
    if (loading) return;

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

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

  // Memperbarui profil melalui Laravel.
  Future<void> save() async {
    if (loading) return;

    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (widget.token.trim().isEmpty) {
      _showMessage('Token tidak tersedia. Silakan login kembali.');
      return;
    }

    final usernameBaru = nameController.text.trim();
    final passwordBaru = passwordController.text;
    final konfirmasi = confirmPasswordController.text;

    FocusScope.of(context).unfocus();

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
            ? 'Kata sandi akunmu berhasil diperbarui.'
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: loading ? null : () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded, color: textColor),
        ),
        title: const Text(
          'Edit Profil',
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: false,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: borderColor),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 30),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // HEADER HALAMAN
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFEAF2FF), Color(0xFFDCE9FF)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(
                          Icons.manage_accounts_outlined,
                          color: primary,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 15),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Informasi Akun',
                              style: TextStyle(
                                color: textColor,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Perbarui username atau kata sandi akunmu.',
                              style: TextStyle(
                                color: muted,
                                fontSize: 12,
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 27),

                const Text(
                  'Data Profil',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 7),
                const Text(
                  'Masukkan informasi yang ingin kamu perbarui.',
                  style: TextStyle(color: muted, fontSize: 13, height: 1.6),
                ),

                const SizedBox(height: 19),

                // KARTU FORMULIR
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(19),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(23),
                    border: Border.all(color: borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF344054).withValues(alpha: 0.025),
                        blurRadius: 18,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _fieldLabel('Nama Pengguna'),
                      const SizedBox(height: 9),

                      TextFormField(
                        controller: nameController,
                        enabled: !loading,
                        textInputAction: TextInputAction.next,
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

                      const SizedBox(height: 23),

                      _fieldLabel('Password Baru'),
                      const SizedBox(height: 9),

                      TextFormField(
                        controller: passwordController,
                        enabled: !loading,
                        obscureText: hidePassword,
                        textInputAction: TextInputAction.next,
                        decoration: _inputDecoration(
                          hint: 'Kosongkan jika tidak diganti',
                          icon: Icons.lock_outline_rounded,
                          suffix: IconButton(
                            onPressed: loading
                                ? null
                                : () {
                                    setState(() {
                                      hidePassword = !hidePassword;
                                    });
                                  },
                            icon: Icon(
                              hidePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: muted,
                              size: 21,
                            ),
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

                      const SizedBox(height: 23),

                      _fieldLabel('Konfirmasi Password Baru'),
                      const SizedBox(height: 9),

                      TextFormField(
                        controller: confirmPasswordController,
                        enabled: !loading,
                        obscureText: hideConfirmPassword,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) {
                          if (!loading) _confirmSave();
                        },
                        decoration: _inputDecoration(
                          hint: 'Ulangi password baru',
                          icon: Icons.lock_outline_rounded,
                          suffix: IconButton(
                            onPressed: loading
                                ? null
                                : () {
                                    setState(() {
                                      hideConfirmPassword =
                                          !hideConfirmPassword;
                                    });
                                  },
                            icon: Icon(
                              hideConfirmPassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: muted,
                              size: 21,
                            ),
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

                      const SizedBox(height: 27),

                      Container(
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F9FC),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: primary,
                              size: 19,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Password tidak perlu diisi jika kamu hanya ingin mengubah username.',
                                style: TextStyle(
                                  color: muted,
                                  fontSize: 12,
                                  height: 1.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                // TOMBOL SIMPAN
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: loading ? null : _confirmSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      disabledBackgroundColor: primary.withValues(alpha: 0.65),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(17),
                      ),
                    ),
                    child: loading
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Menyimpan perubahan...',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_circle_outline_rounded,
                                size: 20,
                              ),
                              SizedBox(width: 9),
                              Text(
                                'Simpan Perubahan',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        color: textColor,
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF98A2B3), fontSize: 12),
      prefixIcon: Icon(icon, color: primary, size: 21),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFFAFBFD),
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
        borderSide: const BorderSide(color: Color(0xFFD92D20)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Color(0xFFD92D20), width: 1.5),
      ),
    );
  }
}
