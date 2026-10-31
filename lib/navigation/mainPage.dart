import 'package:flutter/material.dart';

import '../config/appTheme.dart';
import '../pages/beranda/homePage.dart';
import '../pages/lombaSaya/lombaSayaPage.dart';
import '../pages/ajukan/ajukanPage.dart';
import '../pages/profile/profilePage.dart';
import '../pages/admin/verifikasiPengajuanPage.dart';
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
  int lombaSayaRefreshVersion = 0;

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

  bool get _isAdmin => widget.role.trim().toLowerCase() == 'administrator';

  void _onNavigationTap(int index) {
    final maxIndex = _isAdmin ? 4 : 3;
    if (index < 0 || index > maxIndex || index == selectedIndex) {
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

  void _onLombaDiajukan() {
    if (!mounted) return;
    setState(() {
      selectedIndex = 1;
      lombaSayaRefreshVersion++;
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
                token: widget.token,
                refreshVersion: lombaSayaRefreshVersion,
                onJelajahiLomba: () {
                  _onNavigationTap(0);
                },
                onAjukanLomba: () {
                  _onNavigationTap(2);
                },
              ),

              // 2. Ajukan
              AjukanPage(
                key: const PageStorageKey('ajukanPage'),
                token: widget.token,
                onLombaDiajukan: _onLombaDiajukan,
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
              if (_isAdmin)
                VerifikasiPengajuanPage(
                  key: const PageStorageKey('verifikasiPengajuanPage'),
                  token: widget.token,
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
              isAdmin: _isAdmin,
            ),
          ),
        ],
      ),
    );
  }
}
