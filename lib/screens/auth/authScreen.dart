import 'dart:async';

import 'package:flutter/material.dart';

import '../../widgets/appNotification.dart';
import '../../config/appTheme.dart';
import '../../services/api_service.dart';
import '../../widgets/customTextfield.dart';
import '../../widgets/customButton.dart';
import '../../navigation/mainPage.dart';

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
      _hidePassword = true;
      _hideConfirm = true;
    });
  }

  void _showMessage(String message, {bool success = false}) {
    if (!mounted) return;

    AppNotification.show(
      context: context,
      title: success ? 'Berhasil!' : 'Login Gagal',
      message: message,
      type: success ? NotificationType.success : NotificationType.error,
    );
  }

  Future<void> _submit() async {
    if (_loading) return;

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

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

      if (isLogin) {
        // Login tanpa mengirim role.
        data = await ApiService.login(
          username,
          password,
        ).timeout(const Duration(seconds: 20));
      } else {
        // Role akun baru ditetapkan oleh Laravel.
        data = await ApiService.register(
          username,
          password,
          confirmation,
        ).timeout(const Duration(seconds: 20));
      }

      if (!mounted) return;

      if (isLogin) {
        final token = data['token'];
        final user = data['user'];

        if (token is! String || token.isEmpty) {
          _showMessage('Token login dari Laravel tidak ditemukan.');
          return;
        }

        if (user is! Map) {
          _showMessage('Data pengguna dari Laravel tidak ditemukan.');
          return;
        }

        final usernameLogin = user['username']?.toString().trim() ?? '';

        // Normalisasi role agar tidak sensitif huruf kapital.
        final roleLogin = user['role']?.toString().trim().toLowerCase() ?? '';

        // Ketiga role TernateLomba diperbolehkan login.
        const allowedRoles = {'user', 'penyelenggara', 'administrator'};

        if (!allowedRoles.contains(roleLogin)) {
          _showMessage('Role akun tidak valid. Hubungi administrator.');
          return;
        }

        if (usernameLogin.isEmpty) {
          _showMessage('Username dari database tidak valid.');
          return;
        }

        // Login berhasil.
        // Dashboard khusus Administrator akan dibuat terpisah.
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => MainPage(
              username: usernameLogin,
              role: roleLogin,
              token: token,
            ),
          ),
        );
      } else {
        _showMessage(
          (data['pesan'] ?? 'Akun berhasil dibuat. Silakan masuk.').toString(),
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
        'Server tidak merespons. '
        'Pastikan Laravel dan MySQL berjalan.',
      );
    } on FormatException {
      _showMessage('Respons Laravel bukan JSON yang sesuai.');
    } catch (e) {
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
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
      padding: const EdgeInsets.only(bottom: 8),
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
      child: Semantics(
        button: true,
        selected: active,
        child: InkWell(
          onTap: _loading ? null : () => _changeTab(index),
          borderRadius: BorderRadius.circular(13),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: BoxDecoration(
              color: active ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(13),
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: AppColors.navy.withValues(alpha: 0.06),
                        blurRadius: 9,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Text(
                text,
                style: TextStyle(
                  color: active ? AppColors.primary : AppColors.grey,
                  fontSize: 13,
                  fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _passwordEye(bool hidden, VoidCallback onTap) {
    return IconButton(
      tooltip: hidden ? 'Tampilkan password' : 'Sembunyikan password',
      onPressed: _loading ? null : onTap,
      icon: Icon(
        hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        color: AppColors.grey,
        size: 21,
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 88,
      height: 88,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: AppColors.fieldBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.09),
            blurRadius: 22,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.asset('assets/logo/logo.png', fit: BoxFit.contain),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 25, 22, 30),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // LOGO DAN PENGANTAR
                  Center(child: _buildLogo()),
                  const SizedBox(height: 19),

                  const Text(
                    'TernateLomba',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.navy,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                    ),
                  ),

                  const SizedBox(height: 7),

                  const Text(
                    'Cari lomba? Gas!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.grey, fontSize: 13),
                  ),

                  const SizedBox(height: 28),

                  // KARTU AUTENTIKASI
                  Container(
                    padding: const EdgeInsets.all(21),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(color: AppColors.fieldBorder),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.navy.withValues(alpha: 0.035),
                          blurRadius: 22,
                          offset: const Offset(0, 7),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            _isLogin ? 'Selamat datang!' : 'Buat akun baru',
                            style: const TextStyle(
                              color: AppColors.navy,
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                            ),
                          ),

                          const SizedBox(height: 7),

                          Text(
                            _isLogin ? 'Masuk untuk menemukan peluang lomba.' : 'Daftar untuk mulai menjelajahi TernateLomba.',
                            style: const TextStyle(
                              color: AppColors.grey,
                              fontSize: 12,
                              height: 1.6,
                            ),
                          ),

                          const SizedBox(height: 23),

                          // TAB MASUK / DAFTAR
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.tabBg,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                _tabButton('Masuk', 0),
                                _tabButton('Daftar', 1),
                              ],
                            ),
                          ),

                          const SizedBox(height: 23),

                          // USERNAME
                          _label('Nama Pengguna'),

                          CustomTextField(
                            controller: _username,
                            hintText: 'Masukkan nama pengguna',
                            icon: Icons.person_outline_rounded,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Nama pengguna wajib diisi';
                              }

                              if (!_isLogin && value.trim().length > 255) {
                                return 'Nama pengguna maksimal 255 karakter';
                              }

                              return null;
                            },
                          ),

                          const SizedBox(height: 17),

                          // PASSWORD
                          _label('Password'),

                          CustomTextField(
                            controller: _password,
                            hintText: 'Masukkan password',
                            icon: Icons.lock_outline_rounded,
                            obscureText: _hidePassword,
                            suffixIcon: _passwordEye(_hidePassword, () {
                              setState(() {
                                _hidePassword = !_hidePassword;
                              });
                            }),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Password wajib diisi';
                              }

                              if (!_isLogin && value.length < 8) {
                                return 'Password minimal 8 karakter';
                              }

                              return null;
                            },
                          ),

                          // KONFIRMASI PASSWORD
                          if (!_isLogin) ...[
                            const SizedBox(height: 17),

                            _label('Konfirmasi Password'),

                            CustomTextField(
                              controller: _confirm,
                              hintText: 'Ulangi password',
                              icon: Icons.lock_outline_rounded,
                              obscureText: _hideConfirm,
                              suffixIcon: _passwordEye(_hideConfirm, () {
                                setState(() {
                                  _hideConfirm = !_hideConfirm;
                                });
                              }),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Konfirmasi password wajib diisi';
                                }

                                if (value != _password.text) {
                                  return 'Password tidak sama';
                                }

                                return null;
                              },
                            ),
                          ],

                          const SizedBox(height: 25),

                          // TOMBOL SUBMIT
                          CustomButton(
                            text: _isLogin ? 'Masuk' : 'Daftar',
                            loading: _loading,
                            onPressed: _submit,
                          ),

                          const SizedBox(height: 20),

                          // PINDAH TAB
                          Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
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
                                  _isLogin ? 'Daftar sekarang' : 'Masuk',
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  const Text(
                    'PUSAT INFO LOMBA & PRESTASI MALUKU UTARA',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 9,
                      letterSpacing: 1.1,
                      fontWeight: FontWeight.w700,
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
}