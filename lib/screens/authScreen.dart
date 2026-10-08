import 'dart:async';

import 'package:flutter/material.dart';

import '../appTheme.dart';
import '../service/api_service.dart';
import '../widgets/customTextfield.dart';
import '../widgets/customButton.dart';
import '../beranda/homePage.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();

  final _username = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  int _tab = 0;

  bool _hidePassword = true;
  bool _hideConfirm = true;
  bool _loading = false;

  bool get _isLogin => _tab == 0;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _changeTab(int value) {
    if (_loading || _tab == value) return;

    _formKey.currentState?.reset();

    setState(() {
      _tab = value;
    });
  }

  void _showMessage(String message, {bool success = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: success ? AppColors.green : Colors.red,
        content: Text(message),
      ),
    );
  }

  Future<void> _submit() async {
    // Mencegah permintaan ganda.
    if (_loading) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final isLogin = _isLogin;
    final username = _username.text.trim();
    final password = _password.text;
    final confirmation = _confirm.text;

    FocusScope.of(context).unfocus();

    setState(() {
      _loading = true;
    });

    try {
      final Map<String, dynamic> data;

      // Alamat API dan pengiriman HTTP diatur oleh ApiService.
      if (isLogin) {
        data = await ApiService.login(
          username,
          password,
        ).timeout(const Duration(seconds: 20));
      } else {
        data = await ApiService.register(
          username,
          password,
          confirmation,
        ).timeout(const Duration(seconds: 20));
      }

      if (!mounted) return;

      if (isLogin) {
  // Memastikan respons Laravel berisi token dan data pengguna.
  final token = data['token'];
  final user = data['user'];

  if (token is! String || token.isEmpty || user is! Map) {
    _showMessage(
      'Respons login tidak lengkap. '
      'Laravel harus mengirim token dan user.',
    );
    return;
  }

  _showMessage(
    (data['pesan'] ?? 'Login berhasil').toString(),
    success: true,
  );

  // Mengganti halaman login dengan halaman beranda.
  // Tombol kembali tidak akan membuka halaman login ini lagi.
  Navigator.of(context).pushReplacement(
    MaterialPageRoute(
      builder: (context) => HomePage(),
    ),
  );
} else {
  // Registrasi berhasil: kembali ke tab login.
  _showMessage(
    (data['pesan'] ?? 'Akun berhasil dibuat. Silakan masuk.')
        .toString(),
    success: true,
  );

  _formKey.currentState?.reset();
  _username.text = username;
  _password.clear();
  _confirm.clear();

  setState(() {
    _tab = 0;
    _hidePassword = true;
    _hideConfirm = true;
  });
}
    } on TimeoutException {
      _showMessage(
        'Server belum merespons dalam 20 detik. '
        'Periksa endpoint login/register dan koneksi database.',
      );
    } on FormatException {
      _showMessage(
        'Respons Laravel bukan JSON yang sesuai. '
        'Periksa URL API dan log Laravel.',
      );
    } catch (e) {
      // Menampilkan pesan error dari ApiService.
      final message = e.toString().replaceFirst('Exception: ', '');
      _showMessage(message);
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.navy,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _tabButton(String text, int index) {
    final active = _tab == index;

    return Expanded(
      child: GestureDetector(
        onTap: _loading ? null : () => _changeTab(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: Colors.black.withAlpha(20),
                      blurRadius: 6,
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: active ? AppColors.navy : AppColors.grey,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _passwordEye(bool hidden, VoidCallback tap) {
    return IconButton(
      onPressed: tap,
      icon: Icon(
        hidden
            ? Icons.visibility_outlined
            : Icons.visibility_off_outlined,
        color: AppColors.grey,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 24,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        'assets/logo/logo.png',
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Cari lomba? Gas!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.grey,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.tabBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        _tabButton('Masuk', 0),
                        _tabButton('Daftar', 1),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _label('Nama Pengguna'),
                  CustomTextField(
                    controller: _username,
                    hintText: 'Masukkan nama pengguna',
                    icon: Icons.person_outline,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Nama pengguna wajib diisi';
                      }

                      if (!_isLogin && v.trim().length > 255) {
                        return 'Nama pengguna maksimal 255 karakter';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _label('Password'),
                  CustomTextField(
                    controller: _password,
                    hintText: 'Masukkan password',
                    icon: Icons.lock_outline,
                    obscureText: _hidePassword,
                    suffixIcon: _passwordEye(
                      _hidePassword,
                      () {
                        setState(() {
                          _hidePassword = !_hidePassword;
                        });
                      },
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'Password wajib diisi';
                      }

                      if (!_isLogin && v.length < 8) {
                        return 'Password minimal 8 karakter';
                      }

                      return null;
                    },
                  ),
                  if (!_isLogin) ...[
                    const SizedBox(height: 16),
                    _label('Konfirmasi Password'),
                    CustomTextField(
                      controller: _confirm,
                      hintText: 'Ulangi password',
                      icon: Icons.lock_outline,
                      obscureText: _hideConfirm,
                      suffixIcon: _passwordEye(
                        _hideConfirm,
                        () {
                          setState(() {
                            _hideConfirm = !_hideConfirm;
                          });
                        },
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Konfirmasi password wajib diisi';
                        }

                        if (v != _password.text) {
                          return 'Password tidak sama';
                        }

                        return null;
                      },
                    ),
                  ],
                  const SizedBox(height: 26),
                  CustomButton(
                    text: _isLogin ? 'Masuk' : 'Daftar',
                    loading: _loading,
                    onPressed: _submit,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isLogin
                            ? 'Belum punya akun? '
                            : 'Sudah punya akun? ',
                        style: const TextStyle(
                          color: AppColors.grey,
                          fontSize: 12,
                        ),
                      ),
                      GestureDetector(
                        onTap: _loading
                            ? null
                            : () => _changeTab(_isLogin ? 1 : 0),
                        child: Text(
                          _isLogin ? 'Registrasi' : 'Masuk',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}