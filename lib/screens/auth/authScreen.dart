import 'dart:async';

import 'package:flutter/material.dart';

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
  // =====================================================
  // FORM
  // =====================================================

  // Key untuk melakukan validasi seluruh form.
  final _formKey = GlobalKey<FormState>();

  // Controller username.
  final _username = TextEditingController();

  // Controller password.
  final _password = TextEditingController();

  // Controller konfirmasi password.
  final _confirm = TextEditingController();

  // 0 = Login
  // 1 = Register
  int _tab = 0;

  // Password disembunyikan secara default.
  bool _hidePassword = true;

  // Konfirmasi password disembunyikan secara default.
  bool _hideConfirm = true;

  // Menandakan proses login/register sedang berlangsung.
  bool _loading = false;

  // Jika tab = 0 berarti sedang berada di halaman login.
  bool get _isLogin => _tab == 0;

  // =====================================================
  // DISPOSE
  // =====================================================

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    _confirm.dispose();

    super.dispose();
  }

  // =====================================================
  // PINDAH TAB LOGIN / REGISTER
  // =====================================================

  void _changeTab(int value) {
    // Tidak boleh pindah tab ketika loading.
    if (_loading) return;

    // Jika tab yang dipilih sama dengan tab sekarang.
    if (_tab == value) return;

    // Reset pesan validasi.
    _formKey.currentState?.reset();

    setState(() {
      _tab = value;

      // Password kembali disembunyikan.
      _hidePassword = true;
      _hideConfirm = true;
    });
  }

  // =====================================================
  // MENAMPILKAN PESAN
  // =====================================================

  void _showMessage(
    String message, {
    bool success = false,
  }) {
    if (!mounted) return;

    // Menghilangkan SnackBar sebelumnya.
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    // Menampilkan pesan.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor:
            success ? AppColors.green : Colors.red,
        content: Text(message),
      ),
    );
  }

  // =====================================================
  // LOGIN / REGISTER
  // =====================================================

  Future<void> _submit() async {
    // Jangan kirim request berkali-kali.
    if (_loading) return;

    // Validasi seluruh field.
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    // Mengetahui apakah sedang login atau register.
    final isLogin = _isLogin;

    // Ambil input pengguna.
    final username = _username.text.trim();
    final password = _password.text;
    final confirmation = _confirm.text;

    // Menutup keyboard.
    FocusScope.of(context).unfocus();

    // Aktifkan loading.
    setState(() {
      _loading = true;
    });

    try {
      final Map<String, dynamic> data;

      // =================================================
      // LOGIN KE LARAVEL + MYSQL
      // =================================================

      if (isLogin) {
        data = await ApiService.login(
          username,
          password,
        ).timeout(
          const Duration(seconds: 20),
        );
      }

      // =================================================
      // REGISTER KE LARAVEL + MYSQL
      // =================================================

      else {
        data = await ApiService.register(
          username,
          password,
          confirmation,
        ).timeout(
          const Duration(seconds: 20),
        );
      }

      // Pastikan widget masih aktif.
      if (!mounted) return;

      // =================================================
      // JIKA LOGIN BERHASIL
      // =================================================

      if (isLogin) {
        // Mengambil token Sanctum dari Laravel.
        final token = data['token'];

        // Mengambil data user dari Laravel.
        final user = data['user'];

        // Pastikan token tersedia.
        if (token is! String || token.isEmpty) {
          _showMessage(
            'Token login dari Laravel tidak ditemukan.',
          );

          return;
        }

        // Pastikan data user tersedia.
        if (user is! Map) {
          _showMessage(
            'Data pengguna dari Laravel tidak ditemukan.',
          );

          return;
        }

        // Username berasal dari database.
        final usernameLogin =
            user['username']?.toString() ?? '';

        // Role berasal dari database.
        final roleLogin =
            user['role']?.toString() ?? '';

        // Pastikan username valid.
        if (usernameLogin.trim().isEmpty) {
          _showMessage(
            'Username dari database tidak valid.',
          );

          return;
        }

        // Pastikan role valid.
        if (roleLogin.trim().isEmpty) {
          _showMessage(
            'Role dari database tidak valid.',
          );

          return;
        }

        // Tampilkan pesan berhasil.
        _showMessage(
          (data['pesan'] ?? 'Login berhasil').toString(),
          success: true,
        );

        // =================================================
        // PINDAH KE MAIN PAGE
        // =================================================

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => MainPage(
              username: usernameLogin,
              role: roleLogin,
              token: token,
            ),
          ),
        );
      }

      // =================================================
      // JIKA REGISTER BERHASIL
      // =================================================

      else {
        // Tampilkan pesan sukses.
        _showMessage(
          (
            data['pesan'] ??
                'Akun berhasil dibuat. Silakan masuk.'
          ).toString(),
          success: true,
        );

        // Reset validasi form.
        _formKey.currentState?.reset();

        // Username tetap disimpan agar tidak perlu
        // diketik ulang setelah registrasi.
        _username.text = username;

        // Kosongkan password.
        _password.clear();

        // Kosongkan konfirmasi password.
        _confirm.clear();

        // Kembali ke tab login.
        setState(() {
          _tab = 0;
          _hidePassword = true;
          _hideConfirm = true;
        });
      }
    }

    // =====================================================
    // SERVER TIMEOUT
    // =====================================================

    on TimeoutException {
      _showMessage(
        'Server tidak merespons. '
        'Pastikan Laravel dan MySQL sedang berjalan.',
      );
    }

    // =====================================================
    // RESPONSE BUKAN JSON
    // =====================================================

    on FormatException {
      _showMessage(
        'Respons Laravel bukan JSON yang sesuai.',
      );
    }

    // =====================================================
    // ERROR LAIN
    // =====================================================

    catch (e) {
      final message = e
          .toString()
          .replaceFirst(
            'Exception: ',
            '',
          );

      _showMessage(message);
    }

    // =====================================================
    // SELESAI
    // =====================================================

    finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  // =====================================================
  // LABEL
  // =====================================================

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 6,
      ),
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

  // =====================================================
  // TAB LOGIN / REGISTER
  // =====================================================

  Widget _tabButton(
    String text,
    int index,
  ) {
    // Mengecek tab aktif.
    final active = _tab == index;

    return Expanded(
      child: GestureDetector(
        // Tidak bisa pindah tab saat loading.
        onTap:
            _loading ? null : () => _changeTab(index),

        child: AnimatedContainer(
          duration:
              const Duration(milliseconds: 200),

          padding:
              const EdgeInsets.symmetric(
            vertical: 12,
          ),

          decoration: BoxDecoration(
            color:
                active ? Colors.white : Colors.transparent,

            borderRadius:
                BorderRadius.circular(10),

            boxShadow: active
                ? [
                    BoxShadow(
                      color:
                          Colors.black.withAlpha(20),
                      blurRadius: 6,
                    ),
                  ]
                : null,
          ),

          child: Center(
            child: Text(
              text,

              style: TextStyle(
                fontWeight:
                    FontWeight.w700,

                color: active
                    ? AppColors.navy
                    : AppColors.grey,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // =====================================================
  // SHOW / HIDE PASSWORD
  // =====================================================

  Widget _passwordEye(
    bool hidden,
    VoidCallback tap,
  ) {
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

  // =====================================================
  // TAMPILAN
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 24,
            ),

            child: Form(
              key: _formKey,

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.stretch,

                children: [
                  // =================================================
                  // LOGO
                  // =================================================

                  Center(
                    child: ClipRRect(
                      borderRadius:
                          BorderRadius.circular(20),

                      child: Image.asset(
                        'assets/logo/logo.png',

                        width: 90,
                        height: 90,

                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // =================================================
                  // TAGLINE
                  // =================================================

                  const Text(
                    'Cari lomba? Gas!',

                    textAlign:
                        TextAlign.center,

                    style: TextStyle(
                      color: AppColors.grey,
                      fontSize: 12,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // =================================================
                  // TAB LOGIN / REGISTER
                  // =================================================

                  Container(
                    padding:
                        const EdgeInsets.all(4),

                    decoration: BoxDecoration(
                      color: AppColors.tabBg,

                      borderRadius:
                          BorderRadius.circular(12),
                    ),

                    child: Row(
                      children: [
                        _tabButton(
                          'Masuk',
                          0,
                        ),

                        _tabButton(
                          'Daftar',
                          1,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // =================================================
                  // USERNAME
                  // =================================================

                  _label(
                    'Nama Pengguna',
                  ),

                  CustomTextField(
                    controller:
                        _username,

                    hintText:
                        'Masukkan nama pengguna',

                    icon:
                        Icons.person_outline,

                    validator: (value) {
                      // Username wajib diisi.
                      if (value == null ||
                          value.trim().isEmpty) {
                        return 'Nama pengguna wajib diisi';
                      }

                      // Maksimal 255 karakter saat register.
                      if (!_isLogin &&
                          value.trim().length > 255) {
                        return 'Nama pengguna maksimal 255 karakter';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // =================================================
                  // PASSWORD
                  // =================================================

                  _label(
                    'Password',
                  ),

                  CustomTextField(
                    controller:
                        _password,

                    hintText:
                        'Masukkan password',

                    icon:
                        Icons.lock_outline,

                    obscureText:
                        _hidePassword,

                    suffixIcon:
                        _passwordEye(
                      _hidePassword,
                      () {
                        setState(() {
                          _hidePassword =
                              !_hidePassword;
                        });
                      },
                    ),

                    validator: (value) {
                      // Password wajib diisi.
                      if (value == null ||
                          value.isEmpty) {
                        return 'Password wajib diisi';
                      }

                      // Saat register minimal 8 karakter.
                      if (!_isLogin &&
                          value.length < 8) {
                        return 'Password minimal 8 karakter';
                      }

                      return null;
                    },
                  ),

                  // =================================================
                  // KONFIRMASI PASSWORD
                  // HANYA REGISTER
                  // =================================================

                  if (!_isLogin) ...[
                    const SizedBox(height: 16),

                    _label(
                      'Konfirmasi Password',
                    ),

                    CustomTextField(
                      controller:
                          _confirm,

                      hintText:
                          'Ulangi password',

                      icon:
                          Icons.lock_outline,

                      obscureText:
                          _hideConfirm,

                      suffixIcon:
                          _passwordEye(
                        _hideConfirm,
                        () {
                          setState(() {
                            _hideConfirm =
                                !_hideConfirm;
                          });
                        },
                      ),

                      validator: (value) {
                        // Konfirmasi wajib diisi.
                        if (value == null ||
                            value.isEmpty) {
                          return 'Konfirmasi password wajib diisi';
                        }

                        // Harus sama dengan password.
                        if (value !=
                            _password.text) {
                          return 'Password tidak sama';
                        }

                        return null;
                      },
                    ),
                  ],

                  const SizedBox(height: 26),

                  // =================================================
                  // TOMBOL LOGIN / REGISTER
                  // =================================================

                  CustomButton(
                    text:
                        _isLogin ? 'Masuk' : 'Daftar',

                    loading:
                        _loading,

                    onPressed:
                        _submit,
                  ),

                  const SizedBox(height: 20),

                  // =================================================
                  // LINK PINDAH LOGIN / REGISTER
                  // =================================================

                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.center,

                    children: [
                      Text(
                        _isLogin
                            ? 'Belum punya akun? '
                            : 'Sudah punya akun? ',

                        style:
                            const TextStyle(
                          color:
                              AppColors.grey,

                          fontSize:
                              12,
                        ),
                      ),

                      GestureDetector(
                        onTap: _loading
                            ? null
                            : () => _changeTab(
                                  _isLogin
                                      ? 1
                                      : 0,
                                ),

                        child: Text(
                          _isLogin
                              ? 'Registrasi'
                              : 'Masuk',

                          style:
                              const TextStyle(
                            color:
                                AppColors.primary,

                            fontWeight:
                                FontWeight.bold,

                            fontSize:
                                12,
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