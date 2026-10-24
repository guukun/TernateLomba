
import 'package:flutter/material.dart';

import '../config/appTheme.dart';
import '../pages/beranda/homePage.dart';
import '../pages/lombaSaya/lombaSayaPage.dart';
import '../pages/ajukan/ajukanPage.dart';
import '../pages/profile/profilePage.dart';
import '../widgets/floatingNavigationBar.dart';

class MainPage extends StatefulWidget {
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
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int selectedIndex = 0;
  late String currentUsername;

  int profileRefreshVersion = 0;

  @override
  void initState() {
    super.initState();
    currentUsername = widget.username;
  }

  void _onProfileChanged() {
    if (!mounted) return;

    setState(() {
      profileRefreshVersion++;
    });
  }

  void _onNavigationTap(int index) {
    if (index < 0 || index > 3 || index == selectedIndex) {
      return;
    }

    setState(() {
      selectedIndex = index;
    });
  }

  void _onUsernameChanged(String usernameBaru) {
    if (!mounted) return;

    setState(() {
      currentUsername = usernameBaru;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          IndexedStack(
            index: selectedIndex,
            children: [
              // 0. Beranda
              HomePage(
                key: const PageStorageKey('homePage'),
                username: currentUsername,
                role: widget.role,
                token: widget.token,
                profileRefreshVersion: profileRefreshVersion,
              ),

              // 1. Lomba Saya
              LombaSayaPage(
                key: const PageStorageKey('lombaSayaPage'),
                onJelajahiLomba: () {
                  _onNavigationTap(0);
                },
              ),

              // 2. Ajukan
              const AjukanPage(
                key: PageStorageKey('ajukanPage'),
              ),

              // 3. Profil
              ProfilePage(
                key: const PageStorageKey('profilePage'),
                username: currentUsername,
                role: widget.role,
                token: widget.token,
                onUsernameChanged: _onUsernameChanged,
                onProfileChanged: _onProfileChanged,
              ),
            ],
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: FloatingNavigationBar(
              currentIndex: selectedIndex,
              onTap: _onNavigationTap,
            ),
          ),
        ],
      ),
    );
  }
}
