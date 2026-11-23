import 'dart:async';

import 'package:flutter/material.dart';

import '../config/appTheme.dart';
import '../pages/beranda/homePage.dart';
import '../pages/favorit/favoritPage.dart';
import '../pages/lombaSaya/LombaSayaPage.dart';
import '../pages/ajukan/formAjukanLombaPage.dart';
import '../pages/profile/profilePage.dart';
import '../pages/admin/pengajuanPage.dart';
import '../pages/admin/adminHubPage.dart';
import '../pages/chat/chatPage.dart';
import '../widgets/floatingNavigationBar.dart';
import '../services/api_service.dart';

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

class _MainPageState extends State<MainPage>
    with SingleTickerProviderStateMixin {
  // TERNATELOMBA_SMOOTH_MOTION_V1
  late final AnimationController _tabMotionController;
  late final Animation<double> _tabOpacity;
  int _currentTab = 0;
  late String _username;
  late String _role;
  Timer? _roleTimer;
  bool _checkingRole = false;
  int _profileRevision = 0;
  int _mineRevision = 0;
  int _favoriteRevision = 0;

  bool get _isAdmin => _role.trim().toLowerCase() == 'administrator';

  @override
  void initState() {
    super.initState();
    _tabMotionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 230),
      value: 1,
    );
    _tabOpacity = Tween<double>(begin: 0.78, end: 1).animate(
      CurvedAnimation(parent: _tabMotionController, curve: Curves.easeOutCubic),
    );
    _username = widget.username;
    _role = widget.role;
    _syncRole();
    _roleTimer = Timer.periodic(const Duration(seconds: 5), (_) => _syncRole());
  }

  @override
  void didUpdateWidget(covariant MainPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.username != widget.username) _username = widget.username;
    if (oldWidget.role != widget.role) _role = widget.role;
  }

  @override
  void dispose() {
    _roleTimer?.cancel();
    _tabMotionController.dispose();
    super.dispose();
  }

  Future<void> _syncRole() async {
    if (_checkingRole || !mounted) return;
    _checkingRole = true;
    try {
      final data = await ApiService.getCurrentUser(token: widget.token);
      if (!mounted) return;
      final role = data['role']?.toString() ?? _role;
      final username = data['username']?.toString() ?? _username;
      if (role != _role || username != _username) {
        final oldAdmin = _isAdmin;
        final newAdmin = role.trim().toLowerCase() == 'administrator';
        setState(() {
          _role = role;
          _username = username;
          // Hindari membuka halaman dengan indeks sama tetapi hak akses berbeda.
          if (oldAdmin != newAdmin) _currentTab = 0;
        });
      }
    } catch (e) {
      debugPrint('Gagal sinkronisasi role: $e');
    } finally {
      _checkingRole = false;
    }
  }

  void _select(int index) {
    if (index < 0 || index > (_isAdmin ? 5 : 4) || index == _currentTab) return;
    _tabMotionController.forward(from: 0);
    setState(() {
      _currentTab = index;
      if (index == 1) _favoriteRevision++;
      if (index == 2) _mineRevision++;
    });
  }

  Future<void> _openAjukan() async {
    // Langsung masuk tahap pertama, tanpa halaman pengantar Ajukan.
    final berhasil = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => FormAjukanLombaPage(token: widget.token),
      ),
    );
    if (!mounted) return;
    if (berhasil == true) ApiService.notifyDataChanged();
    setState(() {
      _mineRevision++;
      _currentTab = 2;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Admin memakai 6 tab; user tetap 5 tab.
    final List<Widget> tabs = _isAdmin
        ? [
            AdminHubPage(
              key: const PageStorageKey('adminHub'),
              token: widget.token,
              username: _username,
              role: _role,
              profileRevision: _profileRevision,
              onOpenPengajuan: () => _select(3),
              onOpenProfile: () => _select(5),
            ),
            FavoritPage(
              key: ValueKey('admin-favorite-$_favoriteRevision'),
              token: widget.token,
            ),
            LombaSayaPage(
              key: const PageStorageKey('adminMyLomba'),
              token: widget.token,
              refreshVersion: _mineRevision,
              onJelajahiLomba: () => _select(0),
              onAjukanLomba: _openAjukan,
            ),
            PengajuanPage(
              key: const PageStorageKey('adminPengajuan'),
              token: widget.token,
            ),
            ChatPage(
              key: const PageStorageKey('adminChat'),
              token: widget.token,
            ),
            ProfilePage(
              key: const PageStorageKey('adminProfile'),
              username: _username,
              role: _role,
              token: widget.token,
              onUsernameChanged: (name) {
                if (mounted) setState(() => _username = name);
              },
              onProfileChanged: () {
                if (mounted) setState(() => _profileRevision++);
              },
            ),
          ]
        : [
            HomePage(
              key: const PageStorageKey('home'),
              username: _username,
              role: _role,
              token: widget.token,
              profileRefreshVersion: _profileRevision,
            ),
            FavoritPage(
              key: ValueKey('favorite-$_favoriteRevision'),
              token: widget.token,
            ),
            LombaSayaPage(
              key: const PageStorageKey('myLomba'),
              token: widget.token,
              refreshVersion: _mineRevision,
              onJelajahiLomba: () => _select(0),
              onAjukanLomba: _openAjukan,
            ),
            ChatPage(key: const PageStorageKey('chat'), token: widget.token),
            ProfilePage(
              key: const PageStorageKey('profile'),
              username: _username,
              role: _role,
              token: widget.token,
              onUsernameChanged: (name) {
                if (mounted) setState(() => _username = name);
              },
              onProfileChanged: () {
                if (mounted) setState(() => _profileRevision++);
              },
            ),
          ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Keep IndexedStack alive: no tab state reset on animation.
          FadeTransition(
            opacity: _tabOpacity,
            child: IndexedStack(index: _currentTab, children: tabs),
          ),
          if (_currentTab == 2)
            Positioned(
              right: 24,
              bottom: 116 + MediaQuery.of(context).padding.bottom,
              child: FloatingActionButton.extended(
                heroTag: 'ajukan-lomba-main',
                onPressed: _openAjukan,
                backgroundColor: context.tl.primary,
                foregroundColor: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                icon: const Icon(Icons.add_rounded),
                label: const Text(
                  'Ajukan Lomba',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: FloatingNavigationBar(
              currentIndex: _currentTab,
              isAdmin: _isAdmin,
              onTap: _select,
            ),
          ),
        ],
      ),
    );
  }
}
