import 'package:flutter/material.dart';

import '../../config/appTheme.dart';
import 'notificationPage.dart';
import '../../widgets/appConfirmDialog.dart';
import '../../screens/auth/authScreen.dart';
import 'detailLombaPage.dart';
import '../../services/api_service.dart';

class HomePage extends StatefulWidget {
  final String username;
  final String role;
  final String token;
  final int profileRefreshVersion;

  const HomePage({
    super.key,
    required this.username,
    required this.role,
    required this.token,
    this.profileRefreshVersion = 0,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // =====================================================
  // WARNA DIAMBIL DARI APP THEME
  // =====================================================

  static const Color _primary = AppColors.primary;
  static const Color _primaryDark = AppColors.primaryDark;
  static const Color _primaryLight = AppColors.cream;
  static const Color _background = AppColors.background;
  static const Color _surface = AppColors.surface;
  static const Color _text = AppColors.navy;
  static const Color _muted = AppColors.grey;
  static const Color _border = AppColors.fieldBorder;

  // =====================================================
  // STATE DAN DATA
  // =====================================================

  final TextEditingController searchController = TextEditingController();

  String keyword = '';
  String? kategoriAktif;

  List<Map<String, dynamic>> daftarKategoriApi = [];
  List<Map<String, String>> daftarLomba = [];

  bool isLoadingLomba = true;
  String? errorLomba;

  // Popup notifikasi
  final LayerLink _notificationLink = LayerLink();
  OverlayEntry? _notificationOverlay;

  // Popup profil
  final LayerLink _profileLink = LayerLink();
  OverlayEntry? _profileOverlay;

  // Foto profil
  String? _fotoProfilUrl;
  bool _isLoadingProfile = false;
  bool _isLoggingOut = false;

  // Data dummy notifikasi
  final List<Map<String, String>> _notifikasiRingkas = [
    {
      'judul': 'Pengajuan Lomba Disetujui',
      'isi': 'Pengajuan lomba "Kompetisi Karya Tulis Ilmiah" berhasil disetujui dan telah diterbitkan.',
      'waktu': 'Baru saja',
    },
    {
      'judul': 'Pengajuan Lomba Ditolak',
      'isi': 'Pengajuan lomba "Festival Teknologi 2026" ditolak. Catatan admin: Persyaratan belum lengkap.',
      'waktu': 'Kemarin',
    },
  ];

  // =====================================================
  // MAPPING DATA LOMBA DARI API
  // =====================================================

  Map<String, String> _mapLomba(Map<String, dynamic> item) {
    final kategori = item['kategori'];
    final penyelenggara = item['penyelenggara'];

    final kategoriMap = kategori is Map ? kategori : {};
    final penyelenggaraMap = penyelenggara is Map ? penyelenggara : {};

    final tanggalRaw = item['tanggal_pelaksanaan']?.toString() ?? '';

    final tanggal = DateTime.tryParse(tanggalRaw);

    final tanggalTampil = tanggal == null
        ? tanggalRaw
        : '${tanggal.day}/${tanggal.month}/${tanggal.year}';

    final biaya = double.tryParse(item['biaya']?.toString() ?? '0') ?? 0;

    final kuota = item['kuota_peserta']?.toString();

    return {
      'id_lomba': item['id_lomba']?.toString() ?? '',
      'id_pengajuan': item['id_pengajuan']?.toString() ?? '',
      'kategori': kategoriMap['nama_kategori']?.toString() ?? '',
      'judul': item['nama_lomba']?.toString() ?? '',
      'penyelenggara': penyelenggaraMap['username']?.toString() ?? '',
      'kuota': kuota == null ? '-' : '$kuota peserta',
      'poster': 'LOMBA',
      'poster_lomba': item['poster_lomba']?.toString() ?? '',
      'tanggal': tanggalTampil,
      'tanggal_pelaksanaan': tanggalRaw,
      'batas_pendaftaran': item['batas_pendaftaran']?.toString() ?? '',
      'lokasi_pendaftaran': item['lokasi_pendaftaran']?.toString() ?? '',
      'deskripsi': item['deskripsi']?.toString() ?? '',
      'persyaratan': item['persyaratan']?.toString() ?? '',
      'biaya': biaya == 0 ? 'Gratis' : 'Rp${biaya.toStringAsFixed(0)}',
      'hadiah': item['hadiah']?.toString() ?? '',
      'kontak_penyelenggara': item['kontak_penyelenggara']?.toString() ?? '',
      'status_lomba': item['status_lomba']?.toString() ?? '',
    };
  }

  // =====================================================
  // MEMUAT KATEGORI DAN LOMBA
  // =====================================================

  Future<void> _loadDataLomba() async {
    if (!mounted) return;

    setState(() {
      isLoadingLomba = true;
      errorLomba = null;
    });

    try {
      final results = await Future.wait([
        ApiService.getKategori(),
        ApiService.getLomba(),
      ]);

      if (!mounted) return;

      final kategori = results[0];
      final lomba = results[1];

      setState(() {
        daftarKategoriApi = kategori;
        daftarLomba = lomba.map(_mapLomba).toList();
        isLoadingLomba = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorLomba = e.toString();
        isLoadingLomba = false;
      });

      debugPrint('Gagal mengambil data lomba: $e');
    }
  }

  // =====================================================
  // FILTER KATEGORI DAN PENCARIAN
  // =====================================================

  List<Map<String, String>> get lombaTampil {
    return daftarLomba.where((lomba) {
      // Jika kategoriAktif null, semua kategori ditampilkan.
      final cocokKategori =
          kategoriAktif == null || lomba['kategori'] == kategoriAktif;

      final query = keyword.trim().toLowerCase();

      final cocokSearch =
          query.isEmpty ||
          (lomba['judul'] ?? '').toLowerCase().contains(query) ||
          (lomba['kategori'] ?? '').toLowerCase().contains(query) ||
          (lomba['penyelenggara'] ?? '').toLowerCase().contains(query);

      return cocokKategori && cocokSearch;
    }).toList();
  }

  // =====================================================
  // INITIALIZATION
  // =====================================================

  @override
  void initState() {
    super.initState();
    _loadProfilePhoto();
    _loadDataLomba();
  }

  // =====================================================
  // MEMUAT FOTO PROFIL
  // =====================================================

  Future<void> _loadProfilePhoto() async {
    if (_isLoadingProfile) return;

    _isLoadingProfile = true;

    try {
      final user = await ApiService.getCurrentUser(token: widget.token);

      if (!mounted) return;

      final foto = user['foto_profil_url'];

      setState(() {
        _fotoProfilUrl = foto == null || foto.toString().isEmpty
            ? null
            : foto.toString();
      });
    } catch (e) {
      debugPrint('Gagal memuat foto profil Beranda: $e');
    } finally {
      _isLoadingProfile = false;
    }
  }

  @override
  void dispose() {
    _closeNotificationPopup();
    _closeProfilePopup();
    searchController.dispose();
    super.dispose();
  }

  // =====================================================
  // POPUP NOTIFIKASI
  // =====================================================

  void _toggleNotificationPopup() {
    if (_notificationOverlay != null) {
      _closeNotificationPopup();
      return;
    }

    _closeProfilePopup();

    _notificationOverlay = OverlayEntry(
      builder: (overlayContext) {
        final screenWidth = MediaQuery.of(overlayContext).size.width;

        final popupWidth = (screenWidth - 32).clamp(0.0, 360.0).toDouble();

        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _closeNotificationPopup,
                child: const SizedBox.expand(),
              ),
            ),

            CompositedTransformFollower(
              link: _notificationLink,
              showWhenUnlinked: false,
              targetAnchor: Alignment.bottomRight,
              followerAnchor: Alignment.topRight,
              offset: const Offset(0, 10),

              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: popupWidth,
                  constraints: const BoxConstraints(maxHeight: 430),
                  decoration: BoxDecoration(
                    color: AppColors.creamLight,
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(color: _border),
                    boxShadow: [
                      BoxShadow(
                        color: _primaryDark.withValues(alpha: 0.12),
                        blurRadius: 26,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,

                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 16, 12, 14),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Notifikasi',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: _text,
                                ),
                              ),
                            ),

                            TextButton(
                              onPressed: _showAllNotifications,
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('Lihat Semua'),
                                  SizedBox(width: 7),
                                  Icon(Icons.arrow_forward_rounded, size: 16),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      Divider(height: 1, color: _border),

                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 320),
                        child: _notifikasiRingkas.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 32,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.notifications_off_outlined,
                                      size: 42,
                                      color: _muted,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Belum ada notifikasi',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: _muted,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                physics: const ClampingScrollPhysics(),
                                padding: EdgeInsets.zero,
                                itemCount: _notifikasiRingkas.length,
                                separatorBuilder: (_, _) => Divider(
                                  height: 1,
                                  indent: 18,
                                  endIndent: 18,
                                  color: _border,
                                ),
                                itemBuilder: (context, index) {
                                  final item = _notifikasiRingkas[index];

                                  final judul = item['judul'] ?? 'Notifikasi';
                                  final isi = item['isi'] ?? '';
                                  final waktu = item['waktu'] ?? '';

                                  final judulLower = judul.toLowerCase();

                                  final IconData notificationIcon =
                                      judulLower.contains('disetujui')
                                      ? Icons.check_circle_outline_rounded
                                      : judulLower.contains('ditolak')
                                      ? Icons.cancel_outlined
                                      : Icons.notifications_none_rounded;

                                  return InkWell(
                                    onTap: _closeNotificationPopup,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 18,
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: 46,
                                            height: 46,
                                            decoration: BoxDecoration(
                                              color: _primaryLight,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              notificationIcon,
                                              color: _primary,
                                              size: 22,
                                            ),
                                          ),

                                          const SizedBox(width: 12),

                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  judul,
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    height: 1.4,
                                                    fontWeight: FontWeight.w700,
                                                    color: _text,
                                                  ),
                                                ),
                                                const SizedBox(height: 5),
                                                Text(
                                                  isi,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    height: 1.5,
                                                    color: _muted,
                                                  ),
                                                ),
                                                const SizedBox(height: 7),
                                                Text(
                                                  waktu,
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: _muted,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    Overlay.of(context).insert(_notificationOverlay!);
  }

  void _closeNotificationPopup() {
    _notificationOverlay?.remove();
    _notificationOverlay = null;
  }

  void _showAllNotifications() {
    _closeNotificationPopup();

    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const NotifikasiPage()));
  }

  // =====================================================
  // POPUP PROFIL
  // =====================================================

  void _toggleProfilePopup() {
    if (_profileOverlay != null) {
      _closeProfilePopup();
      return;
    }

    _closeNotificationPopup();

    _profileOverlay = OverlayEntry(
      builder: (overlayContext) {
        final screenWidth = MediaQuery.of(overlayContext).size.width;

        final popupWidth = (screenWidth - 32).clamp(0.0, 300.0).toDouble();

        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _closeProfilePopup,
                child: const SizedBox.expand(),
              ),
            ),

            CompositedTransformFollower(
              link: _profileLink,
              showWhenUnlinked: false,
              targetAnchor: Alignment.bottomRight,
              followerAnchor: Alignment.topRight,
              offset: const Offset(0, 10),

              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: popupWidth,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: AppColors.creamLight,
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(color: _border),
                    boxShadow: [
                      BoxShadow(
                        color: _primaryDark.withValues(alpha: 0.14),
                        blurRadius: 26,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),

                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildHomeProfileAvatar(size: 78),

                      const SizedBox(height: 14),

                      Text(
                        widget.username,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: _text,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 13,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _primaryLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.role,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _primary,
                          ),
                        ),
                      ),

                      const SizedBox(height: 22),

                      Divider(height: 1, color: _border),

                      const SizedBox(height: 14),

                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _logoutFromHome,
                          icon: const Icon(Icons.logout_rounded, size: 19),
                          label: const Text('Keluar'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            backgroundColor: Colors.white,
                            side: const BorderSide(color: Color(0xFFF3C5C2)),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    Overlay.of(context).insert(_profileOverlay!);
  }

  void _closeProfilePopup() {
    _profileOverlay?.remove();
    _profileOverlay = null;
  }

  // =====================================================
  // LOGOUT
  // =====================================================

  Future<void> _logoutFromHome() async {
    if (_isLoggingOut) return;

    _closeProfilePopup();

    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'Keluar dari akun?',
      message: 'Kamu perlu masuk kembali untuk mengakses akunmu.',
      confirmText: 'Keluar',
      cancelText: 'Batal',
      confirmColor: _primary,
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _isLoggingOut = true;
    });

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopScope(
        canPop: false,
        child: Center(
          child: Material(
            color: AppColors.surface,
            borderRadius: BorderRadius.all(Radius.circular(20)),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 3,
                  ),
                  SizedBox(height: 18),
                  Text(
                    'Sedang keluar...',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navy,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    try {
      await ApiService.logout(token: widget.token);

      if (!mounted) return;

      Navigator.of(context, rootNavigator: true).pop();

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthScreen()),
        (route) => false,
      );
    } catch (_) {
      if (!mounted) return;

      Navigator.of(context, rootNavigator: true).pop();

      setState(() {
        _isLoggingOut = false;
      });

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Logout gagal. Silakan coba lagi.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  @override
  void didUpdateWidget(covariant HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.profileRefreshVersion != widget.profileRefreshVersion) {
      _loadProfilePhoto();
    }
  }

  // =====================================================
  // AVATAR PROFIL
  // =====================================================

  Widget _buildHomeProfileAvatar({double size = 44}) {
    final fotoUrl = _fotoProfilUrl;

    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: _primaryLight,
        shape: BoxShape.circle,
      ),
      clipBehavior: Clip.antiAlias,
      child: fotoUrl != null
          ? Image.network(
              fotoUrl,
              key: ValueKey(fotoUrl),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.person_rounded,
                  color: _primary,
                  size: size * 0.58,
                );
              },
            )
          : Icon(Icons.person_rounded, color: _primary, size: size * 0.58),
    );
  }

  // =====================================================
  // IKON KATEGORI
  // =====================================================

  IconData _iconKategori(String nama) {
    switch (nama.toLowerCase()) {
      case 'akademik':
        return Icons.menu_book_rounded;
      case 'olahraga':
        return Icons.emoji_events_rounded;
      case 'seni':
        return Icons.palette_rounded;
      case 'teknologi':
        return Icons.memory_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  // =====================================================
  // MENU PINTASAN KATEGORI
  // =====================================================

  Widget _kategoriShortcut(String nama) {
    final aktif = kategoriAktif == nama;

    return SizedBox(
      width: 112,
      height: 116,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () {
            setState(() {
              // Klik kategori aktif kembali untuk menampilkan semua lomba.
              kategoriAktif = aktif ? null : nama;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
            decoration: BoxDecoration(
              color: aktif ? _primary : _surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: aktif ? _primary : _border),
              boxShadow: [
                BoxShadow(
                  color: _primaryDark.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _iconKategori(nama),
                  color: aktif ? Colors.white : _primary,
                  size: 29,
                ),
                const SizedBox(height: 10),
                Text(
                  nama,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: aktif ? Colors.white : _text,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =====================================================
  // TAMPILAN BERANDA
  // =====================================================

  @override
  Widget build(BuildContext context) {
final kategoriPintasan = daftarKategoriApi
    .map((item) => item['nama_kategori']?.toString().trim() ?? '')
    .where((nama) => nama.isNotEmpty)
    .toSet()
    .toList();

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: _primary,
          onRefresh: _loadDataLomba,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // =========================================
                // HEADER UTAMA - DEEP NAVY BLUE
                // =========================================

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(22, 20, 22, 26),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary,
                        AppColors.primaryDark,
                        AppColors.primaryDeep,
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
                      // LOGO, NAMA, NOTIFIKASI, AVATAR

                      Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: AppColors.creamLight,
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.12),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.emoji_events_rounded,
                              color: AppColors.primary,
                              size: 26,
                            ),
                          ),

                          const SizedBox(width: 10),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'TERNATELOMBA',
                                  maxLines: 1,
                                  style: TextStyle(
                                    fontSize: 13,
                                    letterSpacing: 1.1,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: 3),
                                Text(
                                  'Platform Informasi Lomba',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.creamDark,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // NOTIFIKASI
                          CompositedTransformTarget(
                            link: _notificationLink,
                            child: Material(
                              color: AppColors.creamLight,
                              shape: const CircleBorder(),
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: _toggleNotificationPopup,
                                child: SizedBox(
                                  width: 44,
                                  height: 44,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      const Icon(
                                        Icons.notifications_none_rounded,
                                        color: AppColors.primaryDark,
                                        size: 24,
                                      ),

                                      if (_notifikasiRingkas.isNotEmpty)
                                        Positioned(
                                          top: 9,
                                          right: 10,
                                          child: Container(
                                            width: 9,
                                            height: 9,
                                            decoration: const BoxDecoration(
                                              color: AppColors.primary,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 9),

                          // AVATAR
                          CompositedTransformTarget(
                            link: _profileLink,
                            child: Material(
                              color: AppColors.creamLight,
                              shape: const CircleBorder(),
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: _toggleProfilePopup,
                                child: SizedBox(
                                  width: 44,
                                  height: 44,
                                  child: Padding(
                                    padding: const EdgeInsets.all(3),
                                    child: ClipOval(
                                      child: _buildHomeProfileAvatar(),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 29),

                      // SAPAAN
                      Text(
                        'Halo, ${widget.username}! 👋',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 23,
                          height: 1.2,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        'Temukan lomba dan raih kesempatan terbaikmu.',
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: AppColors.creamDark,
                        ),
                      ),

                      const SizedBox(height: 23),

                      // KOLOM PENCARIAN
                      Container(
                        height: 58,
                        decoration: BoxDecoration(
                          color: AppColors.creamLight,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: AppColors.creamDark),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.10),
                              blurRadius: 14,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: TextField(
                          controller: searchController,
                          onChanged: (value) {
                            setState(() {
                              keyword = value;
                            });
                          },
                          decoration: const InputDecoration(
                            hintText:
                                'Cari lomba, kategori, atau penyelenggara...',
                            hintStyle: TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              color: AppColors.primaryDark,
                              size: 25,
                            ),
                            filled: true,
                            fillColor: Colors.transparent,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 19),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // =========================================
                // MENU PINTASAN KATEGORI
                // =========================================
                Padding(
                  padding: const EdgeInsets.only(top: 24, bottom: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 22),
                        child: Text(
                          'Jelajahi Lomba',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: _text,
                          ),
                        ),
                      ),

                      const SizedBox(height: 15),

                      SizedBox(
                        height: 116,
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 22),
                          scrollDirection: Axis.horizontal,
                          itemCount: kategoriPintasan.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            return _kategoriShortcut(kategoriPintasan[index]);
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // =========================================
                // DAFTAR LOMBA TERBARU
                // =========================================
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 16, 22, 13),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Lomba Terbaru',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: _text,
                          ),
                        ),
                      ),

                      Text(
                        '${lombaTampil.length} lomba',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _muted,
                        ),
                      ),
                    ],
                  ),
                ),

                if (isLoadingLomba)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 42),
                    child: Center(
                      child: CircularProgressIndicator(color: _primary),
                    ),
                  )
                else if (errorLomba != null)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.wifi_off_rounded,
                          color: _muted,
                          size: 40,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Gagal memuat daftar lomba.',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: _text,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _loadDataLomba,
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  )
                else if (lombaTampil.isEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 18, 22, 42),
                    child: Center(
                      child: Column(
                        children: [
                          Container(
                            width: 66,
                            height: 66,
                            decoration: const BoxDecoration(
                              color: AppColors.cream,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.search_off_rounded,
                              size: 30,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Lomba tidak ditemukan',
                            style: TextStyle(
                              color: _text,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            'Coba ubah kata kunci atau pilih kategori lain.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: _muted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 0, 22, 125),
                    child: Column(
                      children: lombaTampil
                          .map((lomba) => cardLomba(context, lomba))
                          .toList(),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =====================================================
  // FORMAT BIAYA LOMBA
  // =====================================================

  String _formatBiayaLomba(String biaya) {
    if (biaya.trim().isEmpty) return '';

    if (biaya.toLowerCase().contains('gratis')) {
      return 'GRATIS';
    }

    final angka = biaya.replaceAll(RegExp(r'[^0-9]'), '');

    if (angka.isEmpty) return biaya;

    final nilai = int.tryParse(angka);

    if (nilai == null) return biaya;

    final digits = nilai.toString();
    final groups = <String>[];

    for (int i = digits.length; i > 0; i -= 3) {
      final start = (i - 3).clamp(0, digits.length);
      groups.add(digits.substring(start, i));
    }

    return 'Rp${groups.reversed.join('.')}';
  }

  // =====================================================
  // KARTU LOMBA
  // =====================================================

  Widget cardLomba(BuildContext context, Map<String, String> lomba) {
    final kategori = (lomba['kategori'] ?? 'Lomba').trim();
    final judul = (lomba['judul'] ?? 'Tanpa judul').trim();
    final penyelenggara = (lomba['penyelenggara'] ?? '').trim();
    final tanggal = (lomba['tanggal'] ?? '').trim();
    final kuota = (lomba['kuota'] ?? '-').trim();

    final biaya = _formatBiayaLomba((lomba['biaya'] ?? '').trim());

    final posterUrl = ApiService.publicStorageUrl(lomba['poster_lomba']);

    final isGratis = biaya == 'GRATIS';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: AppColors.fieldBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.045),
            blurRadius: 20,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(23),
        child: InkWell(
          borderRadius: BorderRadius.circular(23),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    DetailLombaPage(lomba: lomba, token: widget.token),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // POSTER LOMBA

                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    width: 112,
                    height: 150,
                    child: posterUrl == null
                        ? Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppColors.creamLight,
                                  AppColors.creamDark,
                                ],
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _iconKategori(kategori),
                                  color: _primary,
                                  size: 38,
                                ),
                                const SizedBox(height: 10),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  child: Text(
                                    kategori.toUpperCase(),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: _primary,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.7,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Image.network(
                            posterUrl,
                            width: 112,
                            height: 150,
                            fit: BoxFit.cover,
                            cacheWidth: 336,
                            cacheHeight: 450,
                            filterQuality: FilterQuality.low,
                            errorBuilder: (_, _, _) {
                              return Container(
                                color: AppColors.cream,
                                child: const Icon(
                                  Icons.image_not_supported_outlined,
                                  color: AppColors.primary,
                                  size: 35,
                                ),
                              );
                            },
                          ),
                  ),
                ),

                const SizedBox(width: 14),

                // INFORMASI LOMBA
                Expanded(
                  child: SizedBox(
                    height: 150,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // BADGE KATEGORI DAN BIAYA

                        Wrap(
                          spacing: 6,
                          runSpacing: 5,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.cream,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Text(
                                kategori.isEmpty ? 'Lomba' : kategori,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),

                            if (biaya.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isGratis
                                      ? const Color(0xFFE8F8EF)
                                      : AppColors.creamLight,
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Text(
                                  biaya,
                                  maxLines: 1,
                                  style: TextStyle(
                                    color: isGratis
                                        ? AppColors.green
                                        : AppColors.primaryDark,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 11),

                        // JUDUL LOMBA
                        Text(
                          judul,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.navy,
                            fontSize: 15,
                            height: 1.3,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.25,
                          ),
                        ),

                        const SizedBox(height: 9),

                        // PENYELENGGARA
                        Row(
                          children: [
                            const Icon(
                              Icons.apartment_rounded,
                              size: 15,
                              color: AppColors.grey,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                penyelenggara.isEmpty
                                    ? 'Penyelenggara'
                                    : penyelenggara,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.grey,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const Spacer(),

                        // TANGGAL
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_month_rounded,
                              color: AppColors.grey,
                              size: 15,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                tanggal.isEmpty
                                    ? 'Jadwal belum tersedia'
                                    : tanggal,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.grey,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // KUOTA
                        Row(
                          children: [
                            const Icon(
                              Icons.groups_rounded,
                              color: AppColors.primary,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                kuota,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 5),

                // INDIKATOR DETAIL
                SizedBox(
                  height: 150,
                  child: Center(
                    child: Container(
                      width: 27,
                      height: 27,
                      decoration: BoxDecoration(
                        color: AppColors.cream,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
