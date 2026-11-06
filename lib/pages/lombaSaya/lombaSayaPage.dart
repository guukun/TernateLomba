import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../config/appTheme.dart';

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
  int _hoveredTab = -1;

  List<Map<String, dynamic>> _riwayatPendaftaran = [];
  bool _isLoadingRiwayat = false;
  String? _errorRiwayat;
  bool _riwayatSudahDimuat = false;

  List<Map<String, dynamic>> _lombaDibuat = [];
  bool _isLoadingLombaDibuat = false;
  String? _errorLombaDibuat;
  bool _lombaDibuatSudahDimuat = false;

  // Warna mengikuti AppTheme.
  static const Color primaryBlue = AppColors.primary;
  static const Color darkBlue = AppColors.primaryDark;
  static const Color cream = AppColors.cream;
  static const Color creamLight = AppColors.creamLight;
  static const Color backgroundColor = AppColors.background;
  static const Color textColor = AppColors.navy;
  static const Color mutedColor = AppColors.grey;
  static const Color borderColor = AppColors.fieldBorder;

  // ==========================================
  // MEMUAT RIWAYAT PENDAFTARAN
  // ==========================================

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

  // ==========================================
  // MEMUAT LOMBA YANG DIBUAT
  // ==========================================

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
        setState(() {
          _isLoadingLombaDibuat = false;
        });
      }
    }
  }

  // ==========================================
  // INITIALIZATION
  // ==========================================

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
        if (mounted) {
          _loadLombaDibuat();
        }
      });
    }
  }

  // ==========================================
  // BUILD UTAMA
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            if (selectedTab == 0) {
              await _loadRiwayatPendaftaran();
            } else {
              await _loadLombaDibuat();
            }
          },
          color: darkBlue,
          backgroundColor: creamLight,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // HEADER
                _buildHeader(),

                // KATEGORI LOMBA
                _buildCategorySection(),

                // KONTEN LOMBA
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.02),
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

                // Ruang tambahan agar card terakhir
                // tidak tertutup bottom navigation.
                SizedBox(height: 140 + MediaQuery.of(context).padding.bottom),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // HEADER BIRU GELAP + AKSEN CREAM
  // ==========================================

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(23, 27, 23, 30),
      decoration: BoxDecoration(
        color: darkBlue,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(34),
          bottomRight: Radius.circular(34),
        ),
        boxShadow: [
          BoxShadow(
            color: darkBlue.withValues(alpha: 0.16),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label cream
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: cream.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: cream.withValues(alpha: 0.25)),
            ),
            child: Text(
              'AKTIVITAS KAMU',
              style: TextStyle(
                color: creamLight,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
          ),

          const SizedBox(height: 15),

          const Text(
            'Lomba Saya',
            style: TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),

          const SizedBox(height: 9),

          Text(
            selectedTab == 0
                ? 'Lihat dan pantau lomba yang kamu ikuti.'
                : 'Kelola dan pantau pengajuan lomba yang kamu buat.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.78),
              fontSize: 13,
              height: 1.6,
            ),
          ),

          const SizedBox(height: 20),

          // Garis aksen cream
          Container(
            width: 55,
            height: 4,
            decoration: BoxDecoration(
              color: cream,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // KATEGORI LOMBA
  // ==========================================

  Widget _buildCategorySection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 23, 20, 5),
      child: Row(
        children: [
          Expanded(
            child: _buildTabCard(
              title: 'Lomba Diikuti',
              icon: Icons.emoji_events_rounded,
              index: 0,
            ),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: _buildTabCard(
              title: 'Lomba Dibuat',
              icon: Icons.add_circle_outline_rounded,
              index: 1,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // CARD KATEGORI DENGAN HOVER
  // ==========================================

  Widget _buildTabCard({
    required String title,
    required IconData icon,
    required int index,
  }) {
    final bool isSelected = selectedTab == index;
    final bool isHovered = _hoveredTab == index && !isSelected;

    // Warna berbeda antara selected dan hover.
    final Color cardColor = isSelected
        ? darkBlue
        : isHovered
        ? cream
        : creamLight;

    final Color foregroundColor = isSelected ? Colors.white : darkBlue;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        setState(() {
          _hoveredTab = index;
        });
      },
      onExit: (_) {
        setState(() {
          _hoveredTab = -1;
        });
      },
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
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          height: 112,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(23),
            border: Border.all(
              color: isSelected
                  ? darkBlue
                  : isHovered
                  ? cream
                  : borderColor,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: darkBlue.withValues(
                  alpha: isSelected
                      ? 0.15
                      : isHovered
                      ? 0.07
                      : 0.035,
                ),
                blurRadius: isSelected ? 15 : 9,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: isSelected
                      ? cream.withValues(alpha: 0.16)
                      : creamLight,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, size: 24, color: foregroundColor),
              ),

              const SizedBox(height: 9),

              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 220),
                style: TextStyle(
                  color: foregroundColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // KONTEN LOMBA YANG DIBUAT
  // ==========================================

  Widget _buildLombaDibuatContent() {
    if (_isLoadingLombaDibuat) {
      return const Padding(
        padding: EdgeInsets.all(45),
        child: Center(child: CircularProgressIndicator(color: darkBlue)),
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

    if (!_lombaDibuatSudahDimuat) {
      return const SizedBox(height: 20);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 23, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildListHeading('Pengajuan Lomba', '${_lombaDibuat.length} lomba'),

          const SizedBox(height: 15),

          ...List.generate(_lombaDibuat.length, (index) {
            final item = _lombaDibuat[index];

            final nama = item['nama_lomba']?.toString() ?? 'Lomba tanpa nama';

            final status = item['status_pengajuan']?.toString() ?? 'Menunggu';

            final kategori = item['kategori'] is Map
                ? (item['kategori'] as Map)['nama_kategori']?.toString() ??
                      'Kategori tidak tersedia'
                : 'Kategori tidak tersedia';

            final tanggalPelaksanaan =
                item['tanggal_pelaksanaan']?.toString() ?? '';

            final tanggalPengajuan =
                item['tanggal_pengajuan']?.toString() ?? '';

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

            final posterUrl = ApiService.publicStorageUrl(
              item['poster_lomba']?.toString(),
            );

            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 15),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(23),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: darkBlue.withValues(alpha: 0.045),
                    blurRadius: 16,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (posterUrl != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: SizedBox(
                        width: double.infinity,
                        height: 155,
                        child: Image.network(
                          posterUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) {
                            return Container(
                              color: cream,
                              child: const Icon(
                                Icons.image_not_supported_outlined,
                                color: darkBlue,
                                size: 40,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                  ],

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 49,
                        height: 49,
                        decoration: BoxDecoration(
                          color: cream,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.add_business_outlined,
                          color: darkBlue,
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
                                fontSize: 15,
                                height: 1.4,
                                fontWeight: FontWeight.w800,
                              ),
                            ),

                            const SizedBox(height: 6),

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

                  const SizedBox(height: 16),

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

                  const SizedBox(height: 14),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          'Status: $status',
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (catatan.isNotEmpty) ...[
                    const SizedBox(height: 13),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: creamLight,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Text(
                        'Catatan admin: $catatan',
                        style: const TextStyle(
                          color: mutedColor,
                          fontSize: 12,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ==========================================
  // JUDUL DAFTAR
  // ==========================================

  Widget _buildListHeading(String title, String count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: darkBlue,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            color: cream,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            count,
            style: const TextStyle(
              color: darkBlue,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // CHIP INFORMASI
  // ==========================================

  Widget _infoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: creamLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cream.withValues(alpha: 0.8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: darkBlue),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: mutedColor, fontSize: 10)),
        ],
      ),
    );
  }

  // ==========================================
  // KONTEN LOMBA YANG DIIKUTI
  // ==========================================

  Widget _buildRiwayatContent() {
    if (_isLoadingRiwayat) {
      return const Padding(
        padding: EdgeInsets.all(45),
        child: Center(child: CircularProgressIndicator(color: darkBlue)),
      );
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

    if (!_riwayatSudahDimuat) {
      return const SizedBox(height: 20);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 23, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildListHeading(
            'Riwayat Lomba',
            '${_riwayatPendaftaran.length} lomba',
          ),

          const SizedBox(height: 15),

          ...List.generate(_riwayatPendaftaran.length, (index) {
            final item = _riwayatPendaftaran[index];

            final namaLomba =
                item['nama_lomba']?.toString() ?? 'Lomba tanpa nama';

            final status =
                item['status_pendaftaran']?.toString() ?? 'Tidak diketahui';

            final tanggal = item['tanggal_pendaftaran']?.toString() ?? '';

            final posterUrl = ApiService.publicStorageUrl(
              item['poster_lomba']?.toString(),
            );

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
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 15),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(23),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: darkBlue.withValues(alpha: 0.045),
                    blurRadius: 16,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (posterUrl != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: SizedBox(
                        width: double.infinity,
                        height: 145,
                        child: Image.network(
                          posterUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) {
                            return Container(
                              color: cream,
                              child: const Icon(
                                Icons.image_not_supported_outlined,
                                color: darkBlue,
                                size: 38,
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),
                  ],

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 49,
                        height: 49,
                        decoration: BoxDecoration(
                          color: cream,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.emoji_events_rounded,
                          color: darkBlue,
                          size: 25,
                        ),
                      ),

                      const SizedBox(width: 13),

                      Expanded(
                        child: Text(
                          namaLomba,
                          style: const TextStyle(
                            color: textColor,
                            fontSize: 15,
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
                          style: const TextStyle(
                            color: mutedColor,
                            fontSize: 11,
                          ),
                        ),
                      ),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: warnaStatus.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: warnaStatus,
                                shape: BoxShape.circle,
                              ),
                            ),

                            const SizedBox(width: 6),

                            Text(
                              status,
                              style: TextStyle(
                                color: warnaStatus,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ==========================================
  // EMPTY STATE
  // ==========================================

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String description,
    required int tabIndex,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(23, 34, 23, 30),
        decoration: BoxDecoration(
          color: creamLight,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: cream.withValues(alpha: 0.9)),
          boxShadow: [
            BoxShadow(
              color: darkBlue.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, 6),
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
                color: cream,
                borderRadius: BorderRadius.circular(26),
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
                        color: darkBlue.withValues(alpha: 0.07),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(icon, size: 30, color: darkBlue),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // TITLE
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: darkBlue,
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

            // NAVIGASI
            if (tabIndex == 0)
              OutlinedButton.icon(
                onPressed: () {
                  if (widget.onJelajahiLomba != null) {
                    widget.onJelajahiLomba!();
                  } else {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  }
                },
                icon: const Icon(Icons.explore_outlined, size: 18),
                label: const Text('Jelajahi Lomba'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: darkBlue,
                  backgroundColor: cream,
                  side: BorderSide(color: cream.withValues(alpha: 0.9)),
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
            else
              ElevatedButton.icon(
                onPressed: widget.onAjukanLomba,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Ajukan Lomba'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: darkBlue,
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
    );
  }
}
