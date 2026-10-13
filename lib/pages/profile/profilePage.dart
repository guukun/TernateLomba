import 'package:flutter/material.dart';

import 'editProfilePage.dart';
import 'historyRegistrationPage.dart';
import '../../screens/auth/authScreen.dart';

class ProfilePage extends StatefulWidget {
  final String username;

  const ProfilePage({super.key, required this.username});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Dummy User
  String username = "Ahmad Fauzan";
  String role = "User";

  void logout() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const AuthScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),

            // FOTO PROFILE
            CircleAvatar(
              radius: 65,

              backgroundColor: Colors.blue,

              child: Stack(
                children: [
                  Center(
                    child: Text(
                      "AF",

                      style: TextStyle(
                        color: Colors.white,

                        fontSize: 40,

                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  Positioned(
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

            Text(
              username,

              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),

              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),

                border: Border.all(color: Colors.blue),
              ),

              child: Text(
                "Role : $role",

                style: const TextStyle(color: Colors.blue),
              ),
            ),

            const SizedBox(height: 50),

            profileMenu(
              icon: Icons.person,

              title: "Edit Profil",

              color: Colors.blue,

              onTap: () {
                Navigator.push(
                  context,

                  MaterialPageRoute(
                    builder: (context) => EditProfilePage(
                      username: username,

                      onSave: (value) {
                        setState(() {
                          username = value;
                        });
                      },
                    ),
                  ),
                );
              },
            ),

            profileMenu(
              icon: Icons.description,

              title: "Riwayat Pendaftaran",

              color: Colors.green,

              onTap: () {
                Navigator.push(
                  context,

                  MaterialPageRoute(
                    builder: (context) => const HistoryRegistrationPage(),
                  ),
                );
              },
            ),

            profileMenu(
              icon: Icons.logout,

              title: "Keluar / Logout",

              color: Colors.red,

              onTap: logout,
            ),
          ],
        ),
      ),
    );
  }

  Widget profileMenu({
    required IconData icon,

    required String title,

    required Color color,

    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),

      child: InkWell(
        onTap: onTap,

        child: Container(
          padding: const EdgeInsets.all(20),

          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),

            border: Border.all(color: color.withOpacity(.2)),
          ),

          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(.1),

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

              Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
