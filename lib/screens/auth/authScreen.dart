import 'dart:async';

import 'package:flutter/material.dart';

import '../../widgets/app_feedback.dart';
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
        ).timeout(Duration(seconds: 20));
      } else {
        // Role akun baru ditetapkan oleh Laravel.
        data = await ApiService.register(
          username,
          password,
          confirmation,
        ).timeout(Duration(seconds: 20));
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

  Color get _navy => context.tl.primary;

  Widget _logo(double size) => Image.asset(
    'assets/Logo.png',
    width: size,
    height: size,
    fit: BoxFit.contain,
    errorBuilder: (_, _, _) => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: context.tl.fieldBg,
        borderRadius: BorderRadius.circular(size * .28),
      ),
      child: Icon(Icons.emoji_events_rounded, color: _navy, size: size * .47),
    ),
  );

  Widget _header() => Container(
    width: double.infinity,
    margin: const EdgeInsets.fromLTRB(18, 18, 18, 12),
    padding: const EdgeInsets.fromLTRB(23, 24, 20, 24),
    decoration: BoxDecoration(
      color: context.tl.surface,
      borderRadius: BorderRadius.circular(32),
      border: Border.all(color: context.tl.fieldBorder),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: .04),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _logo(48),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TernateLomba',
                    style: TextStyle(
                      color: context.tl.navy,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    'Mono Edition',
                    style: TextStyle(color: context.tl.grey, fontSize: 11),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: context.tl.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'LOCK IN',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        Text(
          _isLogin
              ? 'Focus on\nyour next win.'
              : 'Start here.\nStay locked in.',
          style: TextStyle(
            color: context.tl.navy,
            fontSize: 36,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.4,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _isLogin
              ? 'Masuk dan lanjutkan perjalananmu menuju kompetisi berikutnya.'
              : 'Buat akun, pilih panggungmu, lalu kerjakan yang penting.',
          style: TextStyle(color: context.tl.grey, fontSize: 12.8, height: 1.5),
        ),
      ],
    ),
  );

  Widget _tabButton(int index, String label) {
    final chosen = _tab == index;
    return Expanded(
      child: InkWell(
        onTap: _loading ? null : () => _changeTab(index),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 190),
          padding: const EdgeInsets.symmetric(vertical: 13),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: chosen ? _navy : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: chosen ? Colors.white : context.tl.grey,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _passwordEye(bool hidden, VoidCallback callback) => IconButton(
    tooltip: hidden ? 'Tampilkan password' : 'Sembunyikan password',
    onPressed: _loading ? null : callback,
    icon: Icon(
      hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined,
      size: 19,
      color: context.tl.grey,
    ),
  );

  Widget _fieldLabel(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      label,
      style: TextStyle(
        color: context.tl.navy,
        fontSize: 12.5,
        fontWeight: FontWeight.w800,
      ),
    ),
  );

  Widget _formPanel(double minHeight) => Container(
    width: double.infinity,
    constraints: BoxConstraints(minHeight: minHeight),
    margin: const EdgeInsets.fromLTRB(18, 0, 18, 24),
    padding: const EdgeInsets.fromLTRB(22, 24, 22, 30),
    decoration: BoxDecoration(
      color: context.tl.surface,
      borderRadius: BorderRadius.circular(30),
      border: Border.all(color: context.tl.fieldBorder),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: .03),
          blurRadius: 20,
          offset: const Offset(0, 7),
        ),
      ],
    ),
    child: Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: context.tl.tabBg,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [_tabButton(0, 'Masuk'), _tabButton(1, 'Daftar')],
                ),
              ),
              const SizedBox(height: 28),
              Text(
                _isLogin ? 'Masuk ke Akun' : 'Buat Akun Baru',
                style: TextStyle(
                  color: context.tl.navy,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.55,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _isLogin
                    ? 'Gunakan akun TernateLomba milikmu.'
                    : 'Daftar untuk mulai menjelajahi berbagai lomba.',
                style: TextStyle(
                  color: context.tl.grey,
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 27),
              _fieldLabel('Nama Pengguna'),
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
              _fieldLabel('Password'),
              CustomTextField(
                controller: _password,
                hintText: 'Masukkan password',
                icon: Icons.lock_outline_rounded,
                obscureText: _hidePassword,
                suffixIcon: _passwordEye(
                  _hidePassword,
                  () => setState(() => _hidePassword = !_hidePassword),
                ),
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
              if (!_isLogin) ...[
                const SizedBox(height: 19),
                _fieldLabel('Konfirmasi Password'),
                CustomTextField(
                  controller: _confirm,
                  hintText: 'Ulangi password',
                  icon: Icons.lock_reset_rounded,
                  obscureText: _hideConfirm,
                  suffixIcon: _passwordEye(
                    _hideConfirm,
                    () => setState(() => _hideConfirm = !_hideConfirm),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Konfirmasi password wajib diisi';
                    }
                    if (value != _password.text) return 'Password tidak sama';
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 29),
              CustomButton(
                text: _isLogin ? 'Masuk' : 'Daftar Sekarang',
                loading: _loading,
                onPressed: _submit,
              ),
              const SizedBox(height: 25),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _isLogin ? 'Belum punya akun? ' : 'Sudah punya akun? ',
                    style: TextStyle(color: context.tl.grey, fontSize: 12.5),
                  ),
                  InkWell(
                    onTap: _loading ? null : () => _changeTab(_isLogin ? 1 : 0),
                    child: Text(
                      _isLogin ? 'Daftar' : 'Masuk',
                      style: TextStyle(
                        color: context.tl.primary,
                        fontSize: 12.5,
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
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: context.tl.background,
    resizeToAvoidBottomInset: true,
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            physics: const BouncingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [_header(), _formPanel(0)],
              ),
            ),
          );
        },
      ),
    ),
  );
}
