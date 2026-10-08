import 'package:flutter/material.dart';
import '../appTheme.dart';
import '../widgets/customTextfield.dart';
import '../widgets/customButton.dart';

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
    setState(() {
      _tab = value;
    });

    _formKey.currentState?.reset();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
    });

    await Future.delayed(
      const Duration(seconds: 1),
    );

    setState(() {
      _loading = false;
    });

    if (!_isLogin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.green,
          content: Text(
            "Registrasi berhasil",
          ),
        ),
      );

      _changeTab(0);
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
        onTap: () {
          _changeTab(index);
        },
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
                    )
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
        hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined,
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
                  // LOGO PNG
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
                    "Cari lomba? Gas!",
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
                        _tabButton(
                          "Masuk",
                          0,
                        ),
                        _tabButton(
                          "Daftar",
                          1,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  _label(
                    "Nama Pengguna",
                  ),

                  CustomTextField(
                    controller: _username,
                    hintText: "Masukkan nama pengguna",
                    icon: Icons.person_outline,
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return "Nama pengguna wajib diisi";
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  _label(
                    "Password",
                  ),

                  CustomTextField(
                    controller: _password,
                    hintText: "Masukkan password",
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
                  ),

                  if (!_isLogin) ...[
                    const SizedBox(height: 16),
                    _label(
                      "Konfirmasi Password",
                    ),
                    CustomTextField(
                      controller: _confirm,
                      hintText: "Ulangi password",
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
                        if (v != _password.text) {
                          return "Password tidak sama";
                        }

                        return null;
                      },
                    ),
                  ],

                  const SizedBox(height: 26),

                  CustomButton(
                    text: _isLogin ? "Masuk" : "Daftar",
                    loading: _loading,
                    onPressed: _submit,
                  ),

                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isLogin ? "Belum punya akun? " : "Sudah punya akun? ",
                        style: const TextStyle(
                          color: AppColors.grey,
                          fontSize: 12,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          _changeTab(_isLogin ? 1 : 0);
                        },
                        child: Text(
                          _isLogin ? "Registrasi" : "Masuk",
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
