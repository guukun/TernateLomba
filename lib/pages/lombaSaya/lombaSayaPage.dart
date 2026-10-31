import 'package:flutter/material.dart';

import '../../services/api_service.dart';

class LombaSayaPage extends StatefulWidget {
  final VoidCallback? onJelajahiLomba;
  final VoidCallback? onAjukanLomba;
  final String token;
  final int refreshVersion;

  const LombaSayaPage({
    super.key,
    this.onJelajahiLomba,
    this.onAjukanLomba,
    required this.token,
    this.refreshVersion = 0,
  });

  @override
  State<LombaSayaPage> createState() => _LombaSayaPageState();
}

class _LombaSayaPageState extends State<LombaSayaPage> {
  int selectedTab = 0;

  List<Map<String, dynamic>> _riwayatPendaftaran = [];
  bool _isLoadingRiwayat = false;
  String? _errorRiwayat;
  bool _riwayatSudahDimuat = false;

  List<Map<String, dynamic>> _lombaDibuat = [];
  bool _isLoadingLombaDibuat = false;
  String? _errorLombaDibuat;
  bool _lombaDibuatSudahDimuat = false;

  static const Color primaryBlue = Color(0xFF3478E5);
  static const Color lightBlue = Color(0xFFEAF2FF);
  static const Color backgroundColor = Color(0xFFF5F7FB);
  static const Color textColor = Color(0xFF202938);
  static const Color mutedColor = Color(0xFF8995A7);
  static const Color borderColor = Color(0xFFE8EDF4);

  Future<void> _loadRiwayatPendaftaran() async {
    if (_isLoadingRiwayat) return;

    setState(() {
      _isLoadingRiwayat = true;
      _errorRiwayat = null;
    });

    try {
      final response = await ApiService.getRiwayatPendaftaran(
        token: widget.token,
      );

      if (!mounted) return;

      final data = response['data'];

      if (data is! List) {
        throw const FormatException(
          'Format data riwayat pendaftaran tidak sesuai.',
        );
      }

      setState(() {
        _riwayatPendaftaran = data
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
        _riwayatSudahDimuat = true;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorRiwayat = 'Riwayat pendaftaran gagal dimuat.';
      });

      debugPrint('Gagal memuat riwayat pendaftaran: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingRiwayat = false;
        });
      }
    }
  }

  Future<void> _loadLombaDibuat() async {
    if (_isLoadingLombaDibuat) return;

    setState(() {
      _isLoadingLombaDibuat = true;
      _errorLombaDibuat = null;
    });

    try {
      final response = await ApiService.getPengajuanLombaSaya(
        token: widget.token,
      );
      if (!mounted) return;

      final data = response['data'];
      if (data is! List) {
        throw const FormatException(
          'Format data lomba yang dibuat tidak sesuai.',
        );
      }

      setState(() {
        _lombaDibuat = data
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
        _lombaDibuatSudahDimuat = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorLombaDibuat = e.toString().replaceFirst('Exception: ', '');
      });
      debugPrint('Gagal memuat lomba yang dibuat: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingLombaDibuat = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadRiwayatPendaftaran();
  }

  @override
  void didUpdateWidget(covariant LombaSayaPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.refreshVersion != oldWidget.refreshVersion) {
      selectedTab = 1;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadLombaDibuat();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 26),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFDCE9FF),
                    Color(0xFFEDF3FF),
                    Color(0xFFF5F7FB),
                  ],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Aktivitas Kamu',
                    style: TextStyle(
                      color: primaryBlue,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Lomba Saya',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 27,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    selectedTab == 0
                        ? 'Lihat lomba yang kamu ikuti.'
                        : 'Lihat lomba yang kamu buat.',
                    style: const TextStyle(
                      color: mutedColor,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 22),

                  // TAB NAVIGATION
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(19),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Row(
                      children: [
                        _buildTab(
                          title: 'Lomba Diikuti',
                          icon: Icons.emoji_events_outlined,
                          index: 0,
                        ),
                        _buildTab(
                          title: 'Lomba Dibuat',
                          icon: Icons.add_circle_outline_rounded,
                          index: 1,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // CONTENT
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.025),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: KeyedSubtree(
                  key: ValueKey<int>(selectedTab),
                  child: selectedTab == 0
                      ? _buildRiwayatContent()
                      : _buildLombaDibuatContent(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab({
    required String title,
    required IconData icon,
    required int index,
  }) {
    final bool isSelected = selectedTab == index;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (selectedTab == index) return;

          setState(() {
            selectedTab = index;
          });
          if (index == 1) {
            _loadLombaDibuat();
          }
        },

        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 13),
          decoration: BoxDecoration(
            color: isSelected ? primaryBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(15),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: primaryBlue.withValues(alpha: 0.16),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : mutedColor,
              ),
              const SizedBox(width: 7),
              Flexible(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    color: isSelected ? Colors.white : textColor,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLombaDibuatContent() {
    if (_isLoadingLombaDibuat) {
      return const Center(
        child: CircularProgressIndicator(color: primaryBlue),
      );
    }

    if (_errorLombaDibuat != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 46, color: mutedColor),
              const SizedBox(height: 12),
              Text(
                _errorLombaDibuat!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: textColor, fontSize: 13),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: _loadLombaDibuat,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    if (_lombaDibuatSudahDimuat && _lombaDibuat.isEmpty) {
      return _buildEmptyState(
        icon: Icons.add_circle_outline_rounded,
        title: 'Belum ada lomba yang dibuat',
        description:
            'Pengajuan lomba yang kamu kirim akan muncul di sini, '
            'beserta status verifikasi dari admin.',
        tabIndex: 1,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadLombaDibuat,
      color: primaryBlue,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 30),
        itemCount: _lombaDibuat.length,
        itemBuilder: (context, index) {
          final item = _lombaDibuat[index];
          final nama = item['nama_lomba']?.toString() ?? 'Lomba tanpa nama';
          final status = item['status_pengajuan']?.toString() ?? 'Menunggu';
          final kategori = item['kategori'] is Map
              ? (item['kategori'] as Map)['nama_kategori']?.toString() ?? 'Kategori tidak tersedia'
              : 'Kategori tidak tersedia';
          final tanggalPelaksanaan = item['tanggal_pelaksanaan']?.toString() ?? '';
          final tanggalPengajuan = item['tanggal_pengajuan']?.toString() ?? '';
          final catatan = item['catatan_admin']?.toString().trim() ?? '';

          final Color statusColor;
          switch (status.toLowerCase()) {
            case 'disetujui':
              statusColor = const Color(0xFF21866D);
              break;
            case 'ditolak':
              statusColor = const Color(0xFFD92D20);
              break;
            default:
              statusColor = const Color(0xFFE5A000);
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF344054).withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: lightBlue,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(
                        Icons.add_business_outlined,
                        color: primaryBlue,
                        size: 25,
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nama,
                            style: const TextStyle(
                              color: textColor,
                              fontSize: 14,
                              height: 1.4,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            kategori,
                            style: const TextStyle(
                              color: mutedColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _infoChip(
                      Icons.calendar_today_rounded,
                      'Pelaksanaan: ${tanggalPelaksanaan.isEmpty ? '-' : tanggalPelaksanaan}',
                    ),
                    _infoChip(
                      Icons.send_rounded,
                      'Diajukan: ${tanggalPengajuan.isEmpty ? '-' : tanggalPengajuan.split('T').first}',
                    ),
                  ],
                ),
                const SizedBox(height: 13),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Status: $status',
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (catatan.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Catatan admin: $catatan',
                    style: const TextStyle(
                      color: mutedColor,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: mutedColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(color: mutedColor, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildRiwayatContent() {
    if (_isLoadingRiwayat) {
      return const Center(child: CircularProgressIndicator(color: primaryBlue));
    }

    if (_errorRiwayat != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 48, color: mutedColor),
              const SizedBox(height: 12),
              Text(
                _errorRiwayat!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: textColor, fontSize: 14),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _loadRiwayatPendaftaran,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    if (_riwayatSudahDimuat && _riwayatPendaftaran.isEmpty) {
      return _buildEmptyState(
        icon: Icons.emoji_events_outlined,
        title: 'Belum mengikuti lomba',
        description:
            'Lomba yang kamu ikuti akan muncul di sini. '
            'Temukan lomba yang sesuai dengan minatmu '
            'melalui halaman Beranda.',
        tabIndex: 0,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 28),
      itemCount: _riwayatPendaftaran.length,
      itemBuilder: (context, index) {
        final item = _riwayatPendaftaran[index];

        final namaLomba = item['nama_lomba']?.toString() ?? 'Lomba tanpa nama';
        final status =
            item['status_pendaftaran']?.toString() ?? 'Tidak diketahui';
        final tanggal = item['tanggal_pendaftaran']?.toString() ?? '';

        Color warnaStatus;
        switch (status.toLowerCase()) {
          case 'diterima':
            warnaStatus = const Color(0xFF21866D);
            break;
          case 'ditolak':
            warnaStatus = const Color(0xFFD92D20);
            break;
          default:
            warnaStatus = const Color(0xFFE5A000);
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF344054).withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: lightBlue,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      Icons.emoji_events_rounded,
                      color: primaryBlue,
                      size: 25,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Text(
                      namaLomba,
                      style: const TextStyle(
                        color: textColor,
                        fontSize: 14,
                        height: 1.4,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_rounded,
                    size: 14,
                    color: mutedColor,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      tanggal.isEmpty ? 'Tanggal tidak tersedia' : tanggal,
                      style: const TextStyle(color: mutedColor, fontSize: 11),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: warnaStatus.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: warnaStatus,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // EMPTY STATE
  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String description,
    required int tabIndex,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 28),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight - 52 > 0
                  ? constraints.maxHeight - 52
                  : 0,
            ),
            child: Center(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 34, 24, 30),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(27),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF344054).withValues(alpha: 0.035),
                      blurRadius: 22,
                      offset: const Offset(0, 7),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ICON
                    Container(
                      width: 86,
                      height: 86,
                      decoration: BoxDecoration(
                        color: lightBlue,
                        borderRadius: BorderRadius.circular(27),
                      ),
                      child: Center(
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: primaryBlue.withValues(alpha: 0.08),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(icon, size: 30, color: primaryBlue),
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    // TITLE
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: textColor,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // DESCRIPTION
                    Text(
                      description,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: mutedColor,
                        fontSize: 13,
                        height: 1.8,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // NAVIGATION TO HOME
                    if (tabIndex == 0)
                      OutlinedButton.icon(
                        onPressed: () {
                          if (widget.onJelajahiLomba != null) {
                            widget.onJelajahiLomba!();
                          } else {
                            Navigator.of(context)
                                .popUntil((route) => route.isFirst);
                          }
                        },
                        icon: const Icon(Icons.explore_outlined, size: 18),
                        label: const Text('Jelajahi Lomba'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primaryBlue,
                          side: const BorderSide(color: Color(0xFFD5E4FF)),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 13,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    else if (tabIndex == 1)
                      ElevatedButton.icon(
                        onPressed: widget.onAjukanLomba,
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Ajukan Lomba'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 13,
                          ),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
