import 'package:flutter/material.dart';

import 'editProfilePage.dart';
import 'historyRegistrationPage.dart';
import '../../screens/auth/authScreen.dart';

class ProfilePage extends StatefulWidget {
  final String username;
  final String role;
  final String token;

  // Mengirim perubahan username ke halaman induk.
  final ValueChanged<String> onUsernameChanged;

  const ProfilePage({
    super.key,
    required this.username,
    required this.role,
    required this.token,
    required this.onUsernameChanged,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Salinan username agar tampilan langsung berubah setelah edit.
  late String _username;

  @override
  void initState() {
    super.initState();
    _username = widget.username;
  }

  // Menyesuaikan username jika diperbarui oleh halaman induk.
  @override
  void didUpdateWidget(covariant ProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.username != widget.username) {
      _username = widget.username;
    }
  }

  // Kembali ke autentikasi dan menghapus riwayat navigasi.
  // Ini belum mencabut token Sanctum atau menghapus token tersimpan.
  void logout() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => const AuthScreen(),
      ),
      (route) => false,
    );
  }

  // Membuat inisial dari satu atau dua kata pertama username.
  String getInitials(String name) {
    final cleanName = name.trim();

    if (cleanName.isEmpty) return 'U';

    final parts = cleanName.split(RegExp(r'\s+'));

    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  void _updateUsername(String usernameBaru) {
    if (!mounted) return;

    setState(() {
      _username = usernameBaru;
    });

    widget.onUsernameChanged(usernameBaru);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 40),

              // Avatar dengan inisial username.
              CircleAvatar(
                radius: 65,
                backgroundColor: Colors.blue,
                child: Stack(
                  children: [
                    Center(
                      child: Text(
                        getInitials(_username),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Positioned(
                      right: 5,
                      bottom: 5,
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.camera_alt,
                          size: 18,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Username pengguna.
              Text(
                _username,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              // Role dari data login.
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.blue),
                ),
                child: Text(
                  'Role : ${widget.role}',
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(height: 50),

              profileMenu(
                icon: Icons.person,
                title: 'Edit Profil',
                color: Colors.blue,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => EditProfilePage(
                        username: _username,
                        token: widget.token,
                        onSave: _updateUsername,
                      ),
                    ),
                  );
                },
              ),

              profileMenu(
                icon: Icons.description,
                title: 'Riwayat Pendaftaran',
                color: Colors.green,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) =>
                          const HistoryRegistrationPage(),
                    ),
                  );
                },
              ),

              profileMenu(
                icon: Icons.logout,
                title: 'Keluar / Logout',
                color: Colors.red,
                onTap: logout,
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // Komponen menu profil yang digunakan kembali.
  Widget profileMenu({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 25,
        vertical: 10,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: color.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.1),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 18,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}