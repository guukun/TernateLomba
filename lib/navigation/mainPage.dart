import 'package:flutter/material.dart';

import '../pages/beranda/homePage.dart';
import '../pages/profile/profilePage.dart';
import '../pages/lombaSaya/lombaSayaPage.dart';
import '../pages/ajukan/ajukanPage.dart';

class MainPage extends StatefulWidget {
  // Data yang diterima setelah login
  final String username;
  final String role;
  final String token;

  const MainPage({
    super.key,
    required this.username,
    required this.role,
    required this.token,
  });

  @override
  State<MainPage> createState() =>
      _MainPageState();
}

class _MainPageState
    extends State<MainPage> {
  // Index bottom navigation
  int selectedIndex = 0;

  // Username aktif
  late String currentUsername;

  @override
  void initState() {
    super.initState();

    // Simpan username awal
    currentUsername =
        widget.username;
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      // BERANDA
      HomePage(
        username: currentUsername,
      ),

      // LOMBA SAYA
      const LombaSayaPage(),

      // AJUKAN
      const AjukanPage(),

      // PROFILE
      ProfilePage(
        username: currentUsername,
        role: widget.role,
        token: widget.token,

        // Jika username diubah,
        // MainPage ikut diperbarui.
        onUsernameChanged: (usernameBaru) {
          setState(() {
            currentUsername =
                usernameBaru;
          });
        },
      ),
    ];

    return Scaffold(
      body: pages[selectedIndex],

      bottomNavigationBar:
          BottomNavigationBar(
        currentIndex:
            selectedIndex,

        type:
            BottomNavigationBarType.fixed,

        selectedItemColor:
            Colors.blue,

        unselectedItemColor:
            Colors.grey,

        onTap: (index) {
          setState(() {
            selectedIndex =
                index;
          });
        },

        items: const [
          BottomNavigationBarItem(
            icon:
                Icon(Icons.home),
            label:
                'Beranda',
          ),

          BottomNavigationBarItem(
            icon: Icon(
              Icons.card_giftcard,
            ),
            label:
                'Lomba Saya',
          ),

          BottomNavigationBarItem(
            icon:
                Icon(Icons.explore),
            label:
                'Ajukan',
          ),

          BottomNavigationBarItem(
            icon:
                Icon(Icons.person),
            label:
                'Profile',
          ),
        ],
      ),
    );
  }
}