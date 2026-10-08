import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'logo.dart';
import 'splash_screen.dart' show BrandName;

/// Satu halaman dengan tab Masuk / Daftar (sesuai desain Figma).
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
  int _tab = 0; // 0 = Masuk, 1 = Daftar
  bool _hide = true;
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

  void _setTab(int i) {
    setState(() => _tab = i);
    _formKey.currentState?.reset();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    // TODO: panggil POST /api/login atau POST /api/register.
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() => _loading = false);
    if (!_isLogin) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          backgroundColor: AppColors.green,
          content: Text('Akun berhasil dibuat, silakan masuk.')));
      _setTab(0);
    }
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(t,
            style: const TextStyle(
                color: AppColors.navy,
                fontSize: 13,
                fontWeight: FontWeight.w700)),
      );

  Widget _tabButton(String label, int i) {
    final selected = _tab == i;
    return Expanded(
      child: GestureDetector(
        onTap: () => _setTab(i),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: selected
                ? [
                    BoxShadow(
                        color: Colors.black.withAlpha(20),
                        blurRadius: 6,
                        offset: const Offset(0, 1))
                  ]
                : null,
          ),
          child: Center(
            child: Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: selected ? AppColors.navy : AppColors.grey)),
          ),
        ),
      ),
    );
  }

  Widget _eye(bool hidden, VoidCallback onTap) => IconButton(
        icon: Icon(
            hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            size: 20,
            color: AppColors.grey),
        onPressed: onTap,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: TLLogo(size: 68)),
                  const SizedBox(height: 14),
                  const Center(child: BrandName(fontSize: 22)),
                  const SizedBox(height: 4),
                  const Center(
                    child: Text('Cari lomba? Gas!',
                        style: TextStyle(color: AppColors.grey, fontSize: 11)),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                        color: AppColors.tabBg,
                        borderRadius: BorderRadius.circular(12)),
                    child: Row(children: [
                      _tabButton('Masuk', 0),
                      _tabButton('Daftar', 1),
                    ]),
                  ),
                  const SizedBox(height: 24),
                  _label('Nama Pengguna'),
                  TextFormField(
                    controller: _username,
                    textInputAction: TextInputAction.next,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Nama pengguna wajib diisi';
                      }
                      if (v.trim().length < 3) return 'Minimal 3 karakter';
                      return null;
                    },
                    decoration: const InputDecoration(
                      hintText: 'Masukkan nama pengguna',
                      prefixIcon: Icon(Icons.person_outline_rounded,
                          size: 20, color: AppColors.grey),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _label('Password'),
                  TextFormField(
                    controller: _password,
                    obscureText: _hide,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Password wajib diisi';
                      if (v.length < 6) return 'Minimal 6 karakter';
                      return null;
                    },
                    decoration: InputDecoration(
                      hintText: 'Masukkan password',
                      prefixIcon: const Icon(Icons.lock_outline_rounded,
                          size: 20, color: AppColors.grey),
                      suffixIcon: _eye(_hide, () => setState(() => _hide = !_hide)),
                    ),
                  ),
                  if (!_isLogin) ...[
                    const SizedBox(height: 16),
                    _label('Konfirmasi Password'),
                    TextFormField(
                      controller: _confirm,
                      obscureText: _hideConfirm,
                      validator: (v) =>
                          v != _password.text ? 'Password tidak sama' : null,
                      decoration: InputDecoration(
                        hintText: 'Ulangi password',
                        prefixIcon: const Icon(Icons.lock_outline_rounded,
                            size: 20, color: AppColors.grey),
                        suffixIcon: _eye(_hideConfirm,
                            () => setState(() => _hideConfirm = !_hideConfirm)),
                      ),
                    ),
                  ],
                  const SizedBox(height: 26),
                  ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5, color: Colors.white))
                        : Text(_isLogin ? 'Masuk' : 'Daftar'),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                          _isLogin ? 'Belum punya akun? ' : 'Sudah punya akun? ',
                          style: const TextStyle(
                              color: AppColors.grey, fontSize: 12)),
                      GestureDetector(
                        onTap: () => _setTab(_isLogin ? 1 : 0),
                        child: Text(_isLogin ? 'Registrasi' : 'Masuk',
                            style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w800)),
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
