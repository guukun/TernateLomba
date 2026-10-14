import 'package:flutter/material.dart';

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

    // Mengisi input dengan username pengguna yang login.
    nameController = TextEditingController(
      text: widget.username,
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  // Menampilkan pesan hasil penyimpanan.
  void _showMessage(String message, {bool success = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  // Menyimpan perubahan profil melalui Laravel.
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
      // Mengirim perubahan menggunakan token pengguna.
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

      // Memperbarui username pada halaman induk.
      widget.onSave(usernameHasil);

      if (!mounted) return;

      _showMessage(
        (hasil['pesan'] ?? 'Profil berhasil diperbarui').toString(),
        success: true,
      );

      Navigator.of(context).pop();
    } catch (e) {
      _showMessage(
        e.toString().replaceFirst('Exception: ', ''),
      );
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
      appBar: AppBar(
        title: const Text('Edit Profil'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Username pengguna.
              TextFormField(
                controller: nameController,
                enabled: !loading,
                decoration: const InputDecoration(
                  labelText: 'Nama Pengguna',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
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

              const SizedBox(height: 20),

              // Password boleh kosong jika tidak ingin diganti.
              TextFormField(
                controller: passwordController,
                enabled: !loading,
                obscureText: hidePassword,
                decoration: InputDecoration(
                  labelText: 'Password Baru',
                  hintText: 'Kosongkan jika tidak ingin mengganti',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
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
                    ),
                  ),
                  border: const OutlineInputBorder(),
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

              const SizedBox(height: 20),

              // Konfirmasi password baru.
              TextFormField(
                controller: confirmPasswordController,
                enabled: !loading,
                obscureText: hideConfirmPassword,
                decoration: InputDecoration(
                  labelText: 'Konfirmasi Password Baru',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    onPressed: loading
                        ? null
                        : () {
                            setState(() {
                              hideConfirmPassword = !hideConfirmPassword;
                            });
                          },
                    icon: Icon(
                      hideConfirmPassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                  border: const OutlineInputBorder(),
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

              const SizedBox(height: 40),

              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: loading ? null : save,
                  child: loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Simpan Perubahan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}