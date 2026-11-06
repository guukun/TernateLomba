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

  // ============================================================
  // AUTHENTICATION
  // ============================================================

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
      title: success
          ? 'Berhasil!'
          : (_isLogin ? 'Login Gagal' : 'Pendaftaran Gagal'),
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

        final roleLogin = user['role']?.toString().trim().toLowerCase() ?? '';

        const allowedRoles = {'user', 'penyelenggara', 'administrator'};

        if (!allowedRoles.contains(roleLogin)) {
          _showMessage('Role akun tidak valid. Hubungi administrator.');
          return;
        }

        if (usernameLogin.isEmpty) {
          _showMessage('Username dari database tidak valid.');
          return;
        }

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

  // ============================================================
  // LOGO
  // ============================================================

  Widget _buildLogo() {
    return Container(
      width: 66,
      height: 66,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AppColors.creamLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.creamDark),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Image.asset('assets/logo/logo.png', fit: BoxFit.contain),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 25, 22, 26),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(27),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.15),
            blurRadius: 22,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildLogo(),

              const SizedBox(width: 13),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TERNATELOMBA',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      'Platform Informasi Lomba',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  color: AppColors.cream,
                  size: 21,
                ),
              ),
            ],
          ),

          const SizedBox(height: 30),

          Text(
            _isLogin ? 'Selamat Datang!' : 'Bergabung Bersama Kami!',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
            ),
          ),

          const SizedBox(height: 9),

          Text(
            _isLogin
                ? 'Temukan berbagai peluang lomba dan raih prestasi terbaikmu.'
                : 'Buat akun dan mulai temukan kesempatan untuk mengembangkan potensimu.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.78),
              fontSize: 12,
              height: 1.65,
            ),
          ),

          const SizedBox(height: 21),

          Container(
            width: 55,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TAB MASUK / DAFTAR
  // ============================================================

  Widget _tabButton(String text, int index) {
    final active = _tab == index;

    return Expanded(
      child: Semantics(
        button: true,
        selected: active,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _loading ? null : () => _changeTab(index),
            borderRadius: BorderRadius.circular(14),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: active ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  text,
                  style: TextStyle(
                    color: active ? Colors.white : AppColors.grey,
                    fontSize: 13,
                    fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // LABEL INPUT
  // ============================================================

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
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

  // ============================================================
  // PASSWORD VISIBILITY
  // ============================================================

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

  // ============================================================
  // FORM CARD
  // ============================================================

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: AppColors.fieldBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDeep.withValues(alpha: 0.045),
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
            // JUDUL FORM
            Text(
              _isLogin ? 'Masuk ke Akun' : 'Buat Akun Baru',
              style: const TextStyle(
                color: AppColors.navy,
                fontSize: 21,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),

            const SizedBox(height: 7),

            Text(
              _isLogin
                  ? 'Silakan masukkan informasi akunmu untuk melanjutkan.'
                  : 'Lengkapi informasi berikut untuk membuat akun TernateLomba.',
              style: const TextStyle(
                color: AppColors.grey,
                fontSize: 12,
                height: 1.6,
              ),
            ),

            const SizedBox(height: 22),

            // TAB
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.cream,
                borderRadius: BorderRadius.circular(17),
                border: Border.all(color: AppColors.creamDark),
              ),
              child: Row(
                children: [_tabButton('Masuk', 0), _tabButton('Daftar', 1)],
              ),
            ),

            const SizedBox(height: 25),

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

            const SizedBox(height: 19),

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
              const SizedBox(height: 19),

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

            const SizedBox(height: 26),

            // TOMBOL SUBMIT
            CustomButton(
              text: _isLogin ? 'Masuk' : 'Daftar Sekarang',
              loading: _loading,
              onPressed: _submit,
            ),

            const SizedBox(height: 21),

            // PEMISAH
            Row(
              children: [
                Expanded(
                  child: Container(height: 1, color: AppColors.fieldBorder),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'ATAU',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                Expanded(
                  child: Container(height: 1, color: AppColors.fieldBorder),
                ),
              ],
            ),

            const SizedBox(height: 17),

            // PINDAH TAB
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  _isLogin ? 'Belum punya akun? ' : 'Sudah punya akun? ',
                  style: const TextStyle(color: AppColors.grey, fontSize: 12),
                ),

                GestureDetector(
                  onTap: _loading ? null : () => _changeTab(_isLogin ? 1 : 0),
                  child: Text(
                    _isLogin ? 'Daftar sekarang' : 'Masuk di sini',
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
    );
  }

  // ============================================================
  // FOOTER
  // ============================================================

  Widget _buildFooter() {
    return Column(
      children: [
        Container(
          width: 38,
          height: 3,
          decoration: BoxDecoration(
            color: AppColors.creamDark,
            borderRadius: BorderRadius.circular(10),
          ),
        ),

        const SizedBox(height: 13),

        const Text(
          'TERNATELOMBA',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),

        const SizedBox(height: 5),

        const Text(
          'PUSAT INFORMASI LOMBA & PRESTASI MALUKU UTARA',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.muted,
            fontSize: 9,
            letterSpacing: 0.7,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 5),

        const Text(
          'Temukan peluang. Kembangkan potensi. Raih prestasi.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.grey, fontSize: 10),
        ),
      ],
    );
  }

  // ============================================================
  // MAIN BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 30),

              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // HEADER NAVY
                      _buildHeader(),

                      const SizedBox(height: 23),

                      // FORM
                      _buildFormCard(),

                      const SizedBox(height: 27),

                      // FOOTER
                      _buildFooter(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}