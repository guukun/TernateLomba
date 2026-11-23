import 'package:flutter/material.dart';

import '../beranda/homePage.dart';

/// Mono Edition hub. Shares the same notification, avatar and tab shell as
/// competition discovery while preserving independent Admin functionality.
class AdminHubPage extends StatefulWidget {
  final String token;
  final String username;
  final String role;
  final int profileRevision;
  final VoidCallback onOpenPengajuan;
  final VoidCallback onOpenProfile;

  const AdminHubPage({
    super.key,
    required this.token,
    required this.username,
    required this.role,
    required this.profileRevision,
    required this.onOpenPengajuan,
    required this.onOpenProfile,
  });

  @override
  State<AdminHubPage> createState() => _AdminHubPageState();
}

class _AdminHubPageState extends State<AdminHubPage> {
  bool _showAdminPanel = true;

  @override
  Widget build(BuildContext context) => HomePage(
    username: widget.username,
    role: widget.role,
    token: widget.token,
    profileRefreshVersion: widget.profileRevision,
    adminDashboardEnabled: true,
    showAdminPanel: _showAdminPanel,
    onAdminPanelChanged: (selected) {
      if (selected != _showAdminPanel) {
        setState(() => _showAdminPanel = selected);
      }
    },
    onOpenPengajuan: widget.onOpenPengajuan,
  );
}