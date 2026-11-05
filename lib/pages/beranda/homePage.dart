import 'package:flutter/material.dart';

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
  // Warna khusus tampilan Beranda.
  static const Color _primary = Color(0xFF3478E5);
  static const Color _primaryLight = Color(0xFFEAF2FF);
  static const Color _background = Color(0xFFF5F7FB);
  static const Color _text = Color(0xFF202938);
  static const Color _muted = Color(0xFF667085);

  final TextEditingController searchController = TextEditingController();

  String keyword = '';
  String kategoriAktif = 'Semua';

  // DATA KATEGORI DAN LOMBA DARI API
  List<Map<String, dynamic>> daftarKategoriApi = [];

  List<Map<String, String>> daftarLomba = [];

  bool isLoadingLomba = true;
  String? errorLomba;

  // Mengubah JSON Laravel menjadi format yang
  // sudah digunakan oleh kartu dan halaman detail.
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

  List<Map<String, String>> get lombaTampil {
    return daftarLomba.where((lomba) {
      final cocokKategori =
          kategoriAktif == 'Semua' || lomba['kategori'] == kategoriAktif;

      final query = keyword.trim().toLowerCase();

      final cocokSearch =
          query.isEmpty ||
          (lomba['judul'] ?? '').toLowerCase().contains(query) ||
          (lomba['kategori'] ?? '').toLowerCase().contains(query) ||
          (lomba['penyelenggara'] ?? '').toLowerCase().contains(query);

      return cocokKategori && cocokSearch;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadProfilePhoto();
    _loadDataLomba();
  }

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

  // =========================================================
  // POPUP NOTIFIKASI
  // =========================================================

  void _toggleNotificationPopup() {
    if (_notificationOverlay != null) {
      _closeNotificationPopup();
      return;
    }

    _notificationOverlay = OverlayEntry(
      builder: (overlayContext) {
        final screenWidth = MediaQuery.of(overlayContext).size.width;
        final popupWidth = (screenWidth - 32).clamp(0.0, 360.0).toDouble();

        return Stack(
          children: [
            // Area luar untuk menutup popup.
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _closeNotificationPopup,
                child: const SizedBox.expand(),
              ),
            ),

            // Popup notifikasi.
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
                    color: const Color(0xFFFCFCFF),
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(color: const Color(0xFFE5EAF2)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.10),
                        blurRadius: 26,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // HEADER: JUDUL DAN LIHAT SEMUA.
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
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF2864D8),
                                backgroundColor: const Color(0xFFEFF5FF),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                minimumSize: const Size(0, 40),
                                tapTargetSize: MaterialTapTargetSize.padded,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(13),
                                  side: const BorderSide(
                                    color: Color(0xFFD6E5FF),
                                    width: 1,
                                  ),
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
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

                      const Divider(height: 1, color: Color(0xFFEAEFF5)),

                      // DAFTAR NOTIFIKASI.

                      // DAFTAR NOTIFIKASI.
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 320),
                        child: _notifikasiRingkas.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.symmetric(
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
                                    SizedBox(height: 12),
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
                                separatorBuilder: (_, _) => const Divider(
                                  height: 1,
                                  indent: 18,
                                  endIndent: 18,
                                  color: Color(0xFFEAEFF5),
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
                                          // IKON
                                          Container(
                                            width: 46,
                                            height: 46,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Color(0xFF3478E5),
                                              ),
                                            ),
                                            child: Icon(
                                              notificationIcon,
                                              color: _text,
                                              size: 22,
                                            ),
                                          ),

                                          const SizedBox(width: 12),

                                          // INFORMASI NOTIFIKASI
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Container(
                                                      margin:
                                                          const EdgeInsets.only(
                                                            top: 5,
                                                          ),
                                                      width: 6,
                                                      height: 6,
                                                      decoration:
                                                          const BoxDecoration(
                                                            color: Color(
                                                              0xFF3478E5,
                                                            ),
                                                            shape:
                                                                BoxShape.circle,
                                                          ),
                                                    ),
                                                    const SizedBox(width: 7),
                                                    Expanded(
                                                      child: Text(
                                                        judul,
                                                        style: const TextStyle(
                                                          fontSize: 13,
                                                          height: 1.4,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          color: _text,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),

                                                const SizedBox(height: 5),

                                                Text(
                                                  isi,
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    height: 1.5,
                                                    color: _muted,
                                                  ),
                                                ),

                                                const SizedBox(height: 7),

                                                Text(
                                                  waktu,
                                                  style: const TextStyle(
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
                    color: const Color(0xFFFCFCFF),
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(color: const Color(0xFFE5EAF2)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
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
                      const Divider(height: 1, color: Color(0xFFEAEFF5)),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _logoutFromHome,
                          icon: const Icon(Icons.logout_rounded, size: 19),
                          label: const Text('Keluar'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFD92D20),
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

  Future<void> _logoutFromHome() async {
    if (_isLoggingOut) return;

    _closeProfilePopup();

    // Tampilkan dialog konfirmasi seperti di halaman Profil.
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'Keluar dari akun?',
      message: 'Kamu perlu masuk kembali untuk mengakses akunmu.',
      confirmText: 'Keluar',
      cancelText: 'Batal',
      confirmColor: _primary,
    );

    // Batalkan logout jika pengguna memilih Batal.
    if (confirmed != true || !mounted) return;

    setState(() {
      _isLoggingOut = true;
    });

    // Tampilkan indikator selama permintaan logout berjalan.
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopScope(
        canPop: false,
        child: Center(
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.all(Radius.circular(20)),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    color: Color(0xFF3478E5),
                    strokeWidth: 3,
                  ),
                  SizedBox(height: 18),
                  Text(
                    'Sedang keluar...',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF202938),
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

      // Tutup indikator loading.
      Navigator.of(context, rootNavigator: true).pop();

      // Hapus halaman sebelumnya dan kembali ke halaman autentikasi.
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthScreen()),
        (route) => false,
      );
    } catch (_) {
      if (!mounted) return;

      // Tutup indikator loading jika logout gagal.
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

  // TAMPILAN BERANDA
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER GRADASI
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 15, 20, 18),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFEAF2FF),
                    Color(0xFFD9E8FF),
                    Color(0xFFF5F7FB),
                  ],
                  stops: [0, 0.65, 1],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: _primary.withValues(alpha: 0.10),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.emoji_events_rounded,
                          color: _primary,
                          size: 25,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TERNATELOMBA',
                              style: TextStyle(
                                fontSize: 12,
                                letterSpacing: 1.1,
                                fontWeight: FontWeight.w800,
                                color: _primary,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Temukan peluangmu',
                              style: TextStyle(fontSize: 12, color: _muted),
                            ),
                          ],
                        ),
                      ),
                      CompositedTransformTarget(
                        link: _notificationLink,
                        child: Material(
                          color: Colors.white,
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
                                    color: _text,
                                    size: 23,
                                  ),
                                  if (_notifikasiRingkas.isNotEmpty)
                                    Positioned(
                                      top: 10,
                                      right: 11,
                                      child: Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: _primary,
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
                      const SizedBox(width: 8),

                      CompositedTransformTarget(
                        link: _profileLink,
                        child: Material(
                          color: Colors.white,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: _toggleProfilePopup,
                            child: SizedBox(
                              width: 44,
                              height: 44,
                              child: Center(child: _buildHomeProfileAvatar()),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Halo, ${widget.username}!',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 24,
                      height: 1.2,
                      fontWeight: FontWeight.w800,
                      color: _text,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Temukan lomba yang sesuai dengan minatmu.',
                    style: TextStyle(fontSize: 14, height: 1.5, color: _muted),
                  ),
                  const SizedBox(height: 22),

                  // KOTAK PENCARIAN

                  // KOTAK PENCARIAN
                  Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(19),
                      border: Border.all(color: const Color(0xFFE5EAF2)),
                      boxShadow: [
                        BoxShadow(
                          color: _primary.withValues(alpha: 0.06),
                          blurRadius: 16,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        hoverColor: Colors.transparent,
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                      ),
                      child: TextField(
                        controller: searchController,
                        onChanged: (value) {
                          setState(() {
                            keyword = value;
                          });
                        },
                        decoration: const InputDecoration(
                          hintText: 'Cari lomba yang kamu inginkan...',
                          hintStyle: TextStyle(
                            color: Color(0xFF98A2B3),
                            fontSize: 13,
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: _primary,
                            size: 23,
                          ),
                          filled: true,
                          fillColor: Colors.transparent,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          focusedErrorBorder: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 17),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // KATEGORI LOMBA - GRID 2 KOLOM
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 17, 20, 9),
              child: Text(
                'Kategori Lomba',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: _text,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: daftarKategoriApi.isEmpty
                  ? const SizedBox(
                      height: 84,
                      child: Center(
                        child: Text(
                          'Kategori belum tersedia.',
                          style: TextStyle(color: _muted, fontSize: 13),
                        ),
                      ),
                    )
                  : GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: daftarKategoriApi.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 9,
                            childAspectRatio: 2.85,
                          ),
                      itemBuilder: (context, index) {
                        final nama =
                            daftarKategoriApi[index]['nama_kategori']
                                ?.toString()
                                .trim() ??
                            '';

                        if (nama.isEmpty) return const SizedBox.shrink();
                        return kategoriCard(nama);
                      },
                    ),
            ),

            // JUDUL DAFTAR LOMBA
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 19, 20, 11),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Lomba Terbaru',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: _text,
                      ),
                    ),
                  ),
                  Text(
                    '${lombaTampil.length} lomba',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _muted,
                    ),
                  ),
                ],
              ),
            ),

            // DAFTAR KARTU LOMBA
            Expanded(
              child: isLoadingLomba
                  ? const Center(
                      child: CircularProgressIndicator(color: _primary),
                    )
                  : errorLomba != null
                  ? Center(
                      child: Padding(
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
                      ),
                    )
                  : lombaTampil.isEmpty
                  ? const Center(
                      child: Text(
                        'Lomba tidak ditemukan.',
                        style: TextStyle(color: _muted, fontSize: 14),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadDataLomba,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 118),
                        itemCount: lombaTampil.length,
                        itemBuilder: (context, index) {
                          return cardLomba(context, lombaTampil[index]);
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // KARTU KATEGORI LOMBA
  // =========================================================

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

  Widget kategoriCard(String nama) {
    final aktif = kategoriAktif == nama;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          setState(() {
            // Ketuk kategori yang sama sekali lagi untuk menampilkan semua lomba.
            kategoriAktif = aktif ? 'Semua' : nama;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: aktif ? _primaryLight : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: aktif ? _primary : const Color(0xFFE5EAF2),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.035),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: aktif ? Colors.white : _primaryLight,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(_iconKategori(nama), color: _primary, size: 20),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  nama,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _text,
                    fontSize: 12,
                    fontWeight: aktif ? FontWeight.w800 : FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                color: aktif ? _primary : _muted,
                size: 21,
              ),
            ],
          ),
        ),
      ),
    );
  }

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

  // =========================================================
  // KARTU LOMBA
  // =========================================================

  Widget cardLomba(BuildContext context, Map<String, String> lomba) {
    final kategori = lomba['kategori'] ?? '';

    final Color warnaPoster;
    final Color warnaLatarPoster;

    switch (kategori) {
      case 'Seni':
        warnaPoster = const Color(0xFF8B65D8);
        warnaLatarPoster = const Color(0xFFF0EAFE);
        break;
      case 'Teknologi':
        warnaPoster = const Color(0xFF238A78);
        warnaLatarPoster = const Color(0xFFE1F5F0);
        break;
      default:
        warnaPoster = _primary;
        warnaLatarPoster = _primaryLight;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE9EDF4)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF344054).withValues(alpha: 0.035),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
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
              // Poster asli dari pengajuan. Gunakan ilustrasi kategori jika poster belum tersedia.
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: SizedBox(
                  width: 104,
                  height: 132,
                  child:
                      ApiService.publicStorageUrl(lomba['poster_lomba']) == null
                      ? Container(
                          color: warnaLatarPoster,
                          child: Stack(
                            children: [
                              Positioned(
                                top: -12,
                                right: -12,
                                child: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: warnaPoster.withValues(alpha: 0.10),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                              Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      kategori == 'Seni'
                                          ? Icons.palette_rounded
                                          : kategori == 'Teknologi'
                                          ? Icons.psychology_alt_rounded
                                          : Icons.menu_book_rounded,
                                      size: 28,
                                      color: warnaPoster,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      kategori.isEmpty
                                          ? 'LOMBA'
                                          : kategori.toUpperCase(),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: warnaPoster,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                      : Image.network(
                          ApiService.publicStorageUrl(lomba['poster_lomba'])!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            color: warnaLatarPoster,
                            child: Icon(
                              Icons.image_not_supported_outlined,
                              color: warnaPoster,
                              size: 30,
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 13),

              // INFORMASI LOMBA
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: warnaLatarPoster,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        kategori,
                        style: TextStyle(
                          color: warnaPoster,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      lomba['judul'] ?? '',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.3,
                        fontWeight: FontWeight.w800,
                        color: _text,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        const Icon(
                          Icons.account_balance_outlined,
                          size: 14,
                          color: _muted,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            lomba['penyelenggara'] ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11, color: _muted),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        const Icon(
                          Icons.people_outline_rounded,
                          size: 14,
                          color: _primary,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            'Kuota ${lomba['kuota'] ?? '-'}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: _primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: _primary,
                          size: 18,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}