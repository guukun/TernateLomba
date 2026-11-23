import '../../widgets/app_feedback.dart';
import '../../widgets/competition_poster_card.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../../config/appTheme.dart';
import '../../design_system/tl_playful.dart';
import 'notificationPage.dart';
import '../../screens/auth/authScreen.dart';
import 'detailLombaPage.dart';
import '../../services/api_service.dart';
import '../admin/adminDashboardPage.dart';

class HomePage extends StatefulWidget {
  final String username;
  final String role;
  final String token;
  final int profileRefreshVersion;
  final int lombaRefreshVersion;
  final bool adminDashboardEnabled;
  final bool showAdminPanel;
  final ValueChanged<bool>? onAdminPanelChanged;
  final VoidCallback? onOpenPengajuan;

  const HomePage({
    super.key,
    required this.username,
    required this.role,
    required this.token,
    this.profileRefreshVersion = 0,
    this.lombaRefreshVersion = 0,
    this.adminDashboardEnabled = false,
    this.showAdminPanel = true,
    this.onAdminPanelChanged,
    this.onOpenPengajuan,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  // =====================================================
  // WARNA DIAMBIL DARI APP THEME
  // =====================================================

  Color get _primary => context.tl.primary;
  Color get _primaryLight => context.tl.cream;
  Color get _background => context.tl.background;
  Color get _text => context.tl.navy;
  Color get _muted => context.tl.grey;
  Color get _border => context.tl.fieldBorder;

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

  // Penanda request agar respons lama tidak menimpa data terbaru.
  int _lombaRequestVersion = 0;
  bool _isFetchingLomba = false;
  Timer? _lombaSyncTimer;
  final PageController _featuredPageController = PageController();
  int _featuredPage = 0;
  final Set<int> _favoriteIds = <int>{};
  bool _favoriteBusy = false;

  Future<void> _loadFavorit() async {
    try {
      final items = await ApiService.getFavorit(token: widget.token);
      if (!mounted) return;
      setState(() {
        _favoriteIds
          ..clear()
          ..addAll(items.map((e) => int.tryParse('${e['id_lomba']}') ?? -1));
      });
    } catch (e) {
      debugPrint('Favorit tidak tersedia: $e');
    }
  }

  Future<void> _toggleFavorit(Map<String, String> lomba) async {
    final id = int.tryParse(lomba['id_lomba'] ?? '');
    if (id == null || _favoriteBusy) return;
    final wasFavorite = _favoriteIds.contains(id);
    setState(() {
      _favoriteBusy = true;
      if (wasFavorite) {
        _favoriteIds.remove(id);
      } else {
        _favoriteIds.add(id);
      }
    });
    try {
      await ApiService.setFavorit(
        token: widget.token,
        idLomba: id,
        favorite: !wasFavorite,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (wasFavorite) {
          _favoriteIds.add(id);
        } else {
          _favoriteIds.remove(id);
        }
      });
      AppNotification.message(
        context,
        'Favorit gagal disimpan: $e',
        type: NotificationType.error,
      );
    } finally {
      if (mounted) setState(() => _favoriteBusy = false);
    }
  }

  bool _appIsResumed = true;

  static const Duration _realtimeInterval = Duration(seconds: 5);

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
  final List<Map<String, String>> _notifikasiRingkas = [];

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
      'jumlah_peserta': item['jumlah_peserta']?.toString() ?? '0',
      'jumlah_pendaftar': item['jumlah_pendaftar']?.toString() ?? '0',
    };
  }

  // =====================================================
  // MEMUAT KATEGORI DAN LOMBA
  // =====================================================

  Future<void> _loadDataLomba() async {
    await _fetchDataLomba(showLoading: true);
  }

  // Memperbarui daftar lomba tanpa menampilkan loading penuh.
  // Dipanggil saat pengguna kembali membuka tab Beranda.
  Future<void> _refreshDataLomba() async {
    await _fetchDataLomba(showLoading: false);
  }

  Future<void> _fetchDataLomba({required bool showLoading}) async {
    if (!mounted || _isFetchingLomba) return;

    _isFetchingLomba = true;
    final requestVersion = ++_lombaRequestVersion;

    if (showLoading) {
      setState(() {
        isLoadingLomba = true;
        errorLomba = null;
      });
    }

    try {
      final results = await Future.wait([
        ApiService.getKategori(),
        ApiService.getLomba(),
      ]);

      // Abaikan respons lama jika widget sudah tidak aktif.
      if (!mounted || requestVersion != _lombaRequestVersion) return;

      final kategori = results[0];
      final lomba = results[1];

      setState(() {
        daftarKategoriApi = kategori;
        daftarLomba = lomba.map(_mapLomba).toList();
        isLoadingLomba = false;
        errorLomba = null;
      });

      debugPrint('Beranda disinkronkan: ${daftarLomba.length} lomba aktif.');
    } catch (e) {
      if (!mounted || requestVersion != _lombaRequestVersion) return;

      setState(() {
        // Refresh otomatis tidak menghilangkan data yang sedang tampil.
        if (showLoading || daftarLomba.isEmpty) {
          errorLomba = e.toString();
        }
        isLoadingLomba = false;
      });

      debugPrint('Sinkronisasi beranda gagal: $e');
    } finally {
      _isFetchingLomba = false;
    }
  }

  // =====================================================
  // SINKRONISASI OTOMATIS LOMBA
  // =====================================================

  void _onRealtimeDataChanged() {
    if (!mounted) return;
    _refreshDataLomba();
    _loadFavorit();
  }

  void _startRealtimePolling() {
    _lombaSyncTimer?.cancel();
    if (!_appIsResumed) return;

    _lombaSyncTimer = Timer.periodic(_realtimeInterval, (_) {
      if (mounted && _appIsResumed) {
        _refreshDataLomba();
      }
    });
  }

  void _stopRealtimePolling() {
    _lombaSyncTimer?.cancel();
    _lombaSyncTimer = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appIsResumed = state == AppLifecycleState.resumed;
    if (_appIsResumed) {
      _refreshDataLomba();
      _startRealtimePolling();
    } else {
      _stopRealtimePolling();
    }
  }

  // Peringkat menggunakan seluruh pengajuan pendaftaran yang sudah dikirim
  // (Menunggu, Diterima, atau Ditolak), BUKAN kuota diterima.
  // Hot global, tidak terpengaruh pilihan kategori/pencarian, maksimal 5.
  List<Map<String, String>> get _hotLomba {
    final entries = List<Map<String, String>>.from(daftarLomba);
    entries.sort((a, b) {
      final registrantsA = int.tryParse(a['jumlah_pendaftar'] ?? '') ?? 0;
      final registrantsB = int.tryParse(b['jumlah_pendaftar'] ?? '') ?? 0;
      if (registrantsA != registrantsB) {
        return registrantsB.compareTo(registrantsA);
      }
      // Tiebreaker stabil ketika pendaftar sama banyak.
      final idA = int.tryParse(a['id_lomba'] ?? '') ?? 0;
      final idB = int.tryParse(b['id_lomba'] ?? '') ?? 0;
      return idB.compareTo(idA);
    });
    return entries.take(5).toList();
  }

  // Filter horizontal untuk katalog. Pilihan aktif berwarna hitam,
  // sedangkan pilihan lain putih; jumlah lomba dihitung dari data aktual.
  Widget _kategoriChips(List<String> categories) {
    final allCategories = <String>['Semua', ...categories];
    return SizedBox(
      height: 55,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        itemCount: allCategories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 9),
        itemBuilder: (context, index) {
          final category = allCategories[index];
          final isAll = index == 0;
          final active = isAll
              ? kategoriAktif == null
              : kategoriAktif == category;
          final count = isAll
              ? daftarLomba.length
              : daftarLomba
                    .where((lomba) => lomba['kategori'] == category)
                    .length;

          return Semantics(
            button: true,
            selected: active,
            label: '$category, $count lomba',
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => setState(() {
                  kategoriAktif = isAll ? null : category;
                }),
                borderRadius: BorderRadius.circular(23),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: active ? const Color(0xFF171717) : Colors.white,
                    borderRadius: BorderRadius.circular(23),
                    border: Border.all(
                      color: active ? const Color(0xFF171717) : _border,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        category,
                        style: TextStyle(
                          color: active ? Colors.white : _text,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 9),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: active
                              ? Colors.white.withValues(alpha: .15)
                              : const Color(0xFFF2F0ED),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$count',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: active ? Colors.white : _text,
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
      ),
    );
  }

  /// LOCK IN: competition discovery is the only primary task on the page.
  Widget _exploreHero() {
    final p = context.tl;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(18, 16, 18, 0),
      padding: const EdgeInsets.fromLTRB(23, 26, 23, 24),
      decoration: TLPlayful.card(context, radius: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: p.primary,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: const Text(
                  'LOCK IN  /  LEVEL UP',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const Spacer(),
              Icon(Icons.north_east_rounded, color: p.navy, size: 22),
            ],
          ),
          const SizedBox(height: 25),
          Text(
            'Find your\nnext challenge.',
            style: TextStyle(
              color: p.navy,
              fontSize: 37,
              letterSpacing: -1.7,
              height: 1.02,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 13),
          Text(
            'Halo, ${widget.username}. Fokus pada kesempatan yang penting. Pilih lomba dan mulai bergerak.',
            style: TextStyle(color: p.grey, fontSize: 13, height: 1.55),
          ),
          const SizedBox(height: 23),
          Container(
            decoration: BoxDecoration(
              color: p.fieldBg,
              borderRadius: BorderRadius.circular(19),
              border: Border.all(color: p.fieldBorder),
            ),
            child: TextField(
              controller: searchController,
              onChanged: (value) => setState(() => keyword = value),
              style: TextStyle(color: p.navy),
              decoration: InputDecoration(
                hintText: 'Cari lomba, kategori, penyelenggara...',
                prefixIcon: Icon(Icons.search_rounded, color: p.primary),
                suffixIcon: Icon(
                  Icons.north_east_rounded,
                  color: p.grey,
                  size: 18,
                ),
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Isi banner diganti dengan fade/slide pendek tanpa menggeser
  // keseluruhan kartu. Bingkai banner selalu berada di tempat yang sama.
  /// Poster-led spotlight, editorial layout; original navigation and API preserved.
  /// Editorial spotlight intentionally differs from the standard list cards.
  Widget _featuredContent(Map<String, String> lomba) {
    final poster = ApiService.publicStorageUrl(lomba['poster_lomba']);
    final title = (lomba['judul'] ?? '').trim().isEmpty
        ? 'Kompetisi pilihan'
        : lomba['judul']!;
    final count = int.tryParse(lomba['jumlah_pendaftar'] ?? '') ?? 0;
    final category = (lomba['kategori'] ?? 'Kompetisi').toUpperCase();
    final quota = lomba['kuota']?.trim();

    return Material(
      key: ValueKey(lomba['id_lomba']),
      color: const Color(0xFF171717),
      child: InkWell(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  DetailLombaPage(lomba: lomba, token: widget.token),
            ),
          );
          if (mounted) _loadFavorit();
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (poster != null)
              Image.network(
                poster,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const ColoredBox(
                  color: Color(0xFF303030),
                  child: Center(
                    child: Icon(
                      Icons.emoji_events_outlined,
                      color: Colors.white54,
                      size: 64,
                    ),
                  ),
                ),
              )
            else
              const ColoredBox(
                color: Color(0xFF303030),
                child: Center(
                  child: Icon(
                    Icons.emoji_events_outlined,
                    color: Colors.white54,
                    size: 64,
                  ),
                ),
              ),
            // Poster fills the whole spotlight. The deep vignette makes
            // typography legible even on busy photographs.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0, .35, 1],
                  colors: [
                    Color(0x85000000),
                    Color(0x42000000),
                    Color(0xF5000000),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 20,
              top: 18,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.local_fire_department_rounded,
                      color: Color(0xFF171717),
                      size: 15,
                    ),
                    SizedBox(width: 6),
                    Text(
                      "EDITOR'S PICK",
                      style: TextStyle(
                        color: Color(0xFF171717),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              right: 18,
              top: 18,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.north_east_rounded,
                  color: Color(0xFF171717),
                  size: 22,
                ),
              ),
            ),
            Positioned(
              left: 20,
              right: 70,
              bottom: 29,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -.9,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    '$count pendaftar  ·  Kuota ${quota == null || quota.isEmpty ? 'Tidak dibatasi' : quota}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Ketika jumlahnya N, setiap tile memperoleh 1/N lebar banner.
  // Featured mempunyai satu card besar per halaman dan digeser MANUAL.
  // Peringkat tetap berdasarkan jumlah pendaftar, maksimal lima lomba.
  Widget _featuredCarousel() {
    final featured = _hotLomba;
    if (featured.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 16),
      child: Container(
        height: 220,
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: context.tl.primary,
          borderRadius: BorderRadius.circular(27),
          boxShadow: [
            BoxShadow(
              color: context.tl.orange.withValues(alpha: .13),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: PageView.builder(
                scrollBehavior: const MaterialScrollBehavior().copyWith(
                  dragDevices: {
                    PointerDeviceKind.touch,
                    PointerDeviceKind.mouse,
                    PointerDeviceKind.stylus,
                    PointerDeviceKind.trackpad,
                  },
                ),
                controller: _featuredPageController,
                physics: const PageScrollPhysics(),
                itemCount: featured.length,
                onPageChanged: (index) {
                  if (mounted) setState(() => _featuredPage = index);
                },
                itemBuilder: (context, index) =>
                    _featuredContent(featured[index]),
              ),
            ),
            if (featured.length > 1)
              Positioned(
                bottom: 13,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(featured.length, (index) {
                      final selected = _featuredPage == index;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: selected ? 17 : 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: selected
                              ? Colors.white
                              : Colors.white.withValues(alpha: .38),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      );
                    }),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
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
    WidgetsBinding.instance.addObserver(this);
    ApiService.dataRevision.addListener(_onRealtimeDataChanged);
    _loadProfilePhoto();
    _loadFavorit();
    _loadDataLomba();
    _loadNotificationPreview();
    _startRealtimePolling();
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
    _stopRealtimePolling();
    _featuredPageController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    ApiService.dataRevision.removeListener(_onRealtimeDataChanged);
    _closeNotificationPopup();
    _closeProfilePopup();
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadNotificationPreview() async {
    try {
      final rows = await ApiService.getNotifikasi(token: widget.token);
      if (!mounted) return;
      setState(() {
        _notifikasiRingkas
          ..clear()
          ..addAll(
            rows
                .take(5)
                .map(
                  (row) => {
                    'id': '${row['id_notifikasi'] ?? ''}',
                    'judul': (row['judul'] ?? 'Notifikasi').toString(),
                    'isi': (row['pesan'] ?? '').toString(),
                    'waktu': (row['created_at'] ?? '').toString(),
                    'dibaca': row['dibaca'] == true ? '1' : '0',
                  },
                ),
          );
      });
      _notificationOverlay?.markNeedsBuild();
    } catch (e) {
      debugPrint('Gagal memuat ringkasan notifikasi: $e');
    }
  }

  // =====================================================
  // POPUP NOTIFIKASI
  // =====================================================

  String _notificationTimeLabel(String raw) {
    final date = DateTime.tryParse(raw)?.toLocal();
    if (date == null) return raw;
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(date.day)}/${two(date.month)}/${date.year}  ·  ${two(date.hour)}:${two(date.minute)}';
  }

  void _toggleNotificationPopup() {
    if (_notificationOverlay != null) {
      _closeNotificationPopup();
      return;
    }
    _closeProfilePopup();
    _notificationOverlay = AppPopup.anchored(
      context: context,
      link: _notificationLink,
      maxWidth: 325,
      maxHeight: 385,
      onDismiss: _closeNotificationPopup,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(18, 13, 10, 10),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: context.tl.tabBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.notifications_active_outlined,
                    color: context.tl.primary,
                    size: 22,
                  ),
                ),
                SizedBox(width: 11),
                Expanded(
                  child: Text(
                    'Notifikasi',
                    style: TextStyle(
                      color: context.tl.navy,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _showAllNotifications,
                  child: Text('Lihat semua'),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: context.tl.fieldBorder),
          if (_notifikasiRingkas.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 18, vertical: 34),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.notifications_none_rounded,
                    color: context.tl.lavender,
                    size: 38,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Belum ada notifikasi',
                    style: TextStyle(color: context.tl.grey, fontSize: 13),
                  ),
                ],
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: _notifikasiRingkas.length,
                separatorBuilder: (_, _) => Divider(
                  height: 1,
                  color: context.tl.fieldBorder,
                  indent: 18,
                  endIndent: 18,
                ),
                itemBuilder: (_, index) {
                  final notice = _notifikasiRingkas[index];
                  final title = notice['judul'] ?? 'Notifikasi';
                  final isApproved = title.toLowerCase().contains('disetujui');
                  final isRejected = title.toLowerCase().contains('ditolak');
                  final accent = isApproved
                      ? context.tl.green
                      : isRejected
                      ? context.tl.error
                      : context.tl.primary;
                  return InkWell(
                    onTap: _closeNotificationPopup,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: .13),
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: Icon(
                              isApproved
                                  ? Icons.check_circle_outline_rounded
                                  : isRejected
                                  ? Icons.cancel_outlined
                                  : Icons.notifications_none_rounded,
                              color: accent,
                              size: 20,
                            ),
                          ),
                          SizedBox(width: 11),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: context.tl.navy,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  notice['isi'] ?? '',
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: context.tl.grey,
                                    fontSize: 12,
                                    height: 1.4,
                                  ),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  _notificationTimeLabel(notice['waktu'] ?? ''),
                                  style: TextStyle(
                                    color: context.tl.muted,
                                    fontSize: 10,
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
    );
  }

  void _closeNotificationPopup() {
    _notificationOverlay?.remove();
    _notificationOverlay?.dispose();
    _notificationOverlay = null;
  }

  void _showAllNotifications() {
    _closeNotificationPopup();

    // Transisi dibuat lebih singkat agar halaman notifikasi segera terbuka.
    Navigator.of(context)
        .push(
          PageRouteBuilder<void>(
            pageBuilder: (_, _, _) => NotifikasiPage(token: widget.token),
            transitionDuration: Duration(milliseconds: 120),
            reverseTransitionDuration: Duration(milliseconds: 100),
            transitionsBuilder: (_, animation, _, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        )
        .then((_) => _loadNotificationPreview());
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
    _profileOverlay = AppPopup.anchored(
      context: context,
      link: _profileLink,
      maxWidth: 290,
      onDismiss: _closeProfilePopup,
      child: Padding(
        padding: EdgeInsets.all(19),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHomeProfileAvatar(size: 70),
            SizedBox(height: 12),
            Text(
              widget.username,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: context.tl.navy,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: context.tl.cream,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                widget.role,
                style: TextStyle(
                  color: context.tl.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            SizedBox(height: 18),
            Divider(color: context.tl.fieldBorder),
            SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _logoutFromHome,
                icon: Icon(Icons.logout_rounded, size: 18),
                label: Text('Keluar dari akun'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: context.tl.error,
                  backgroundColor: context.tl.statusBadBg,
                  side: BorderSide(
                    color: context.tl.error.withValues(alpha: .18),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _closeProfilePopup() {
    _profileOverlay?.remove();
    _profileOverlay?.dispose();
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

    AppPopup.loading(context, message: 'Sedang keluar...');

    try {
      await ApiService.logout(token: widget.token);

      if (!mounted) return;

      Navigator.of(context, rootNavigator: true).pop();

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => AuthScreen()),
        (route) => false,
      );
    } catch (_) {
      if (!mounted) return;

      Navigator.of(context, rootNavigator: true).pop();

      setState(() {
        _isLoggingOut = false;
      });

      AppNotification.message(
        context,
        'Logout gagal. Silakan coba lagi.',
        type: NotificationType.error,
      );
    }
  }

  @override
  void didUpdateWidget(covariant HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.profileRefreshVersion != widget.profileRefreshVersion) {
      _loadProfilePhoto();
    }

    if (oldWidget.lombaRefreshVersion != widget.lombaRefreshVersion) {
      _refreshDataLomba();
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
      decoration: BoxDecoration(color: _primaryLight, shape: BoxShape.circle),
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

  Widget _adminSwitch(String label, IconData icon, bool isPanel) {
    final selected = widget.showAdminPanel == isPanel;
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: () => widget.onAdminPanelChanged?.call(isPanel),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 210),
              curve: Curves.easeOutCubic,
              height: 83,
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
              decoration: BoxDecoration(
                color: selected ? context.tl.primary : context.tl.surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: selected ? context.tl.primary : context.tl.fieldBorder,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: .10),
                          blurRadius: 18,
                          offset: const Offset(0, 5),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  Container(
                    width: 39,
                    height: 39,
                    decoration: BoxDecoration(
                      color: selected
                          ? Colors.white.withValues(alpha: .15)
                          : context.tl.fieldBg,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(
                      icon,
                      size: 21,
                      color: selected ? Colors.white : context.tl.navy,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.2,
                        fontWeight: FontWeight.w800,
                        color: selected ? Colors.white : context.tl.navy,
                      ),
                    ),
                  ),
                ],
              ),
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
            physics: AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // =========================================
                // Playful white-first header shared by admin and explorer
                // =========================================

                Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(
                    22,
                    20,
                    22,
                    widget.adminDashboardEnabled && widget.showAdminPanel
                        ? 20
                        : 26,
                  ),
                  decoration: BoxDecoration(
                    color: context.tl.background,
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
                              color: context.tl.surface,
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.12),
                                  blurRadius: 12,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(6),
                              child: Image.asset(
                                'assets/Logo.png',
                                fit: BoxFit.contain,
                                errorBuilder: (_, _, _) => Icon(
                                  Icons.emoji_events_rounded,
                                  color: context.tl.primary,
                                  size: 26,
                                ),
                              ),
                            ),
                          ),

                          SizedBox(width: 10),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'TERNATELOMBA',
                                  maxLines: 1,
                                  style: TextStyle(
                                    fontSize: 13,
                                    letterSpacing: 1.1,
                                    fontWeight: FontWeight.w900,
                                    color: context.tl.navy,
                                  ),
                                ),
                                SizedBox(height: 3),
                                Text(
                                  'LOCK IN. LEVEL UP.',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: context.tl.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // NOTIFIKASI
                          CompositedTransformTarget(
                            link: _notificationLink,
                            child: Material(
                              color: context.tl.surface,
                              shape: CircleBorder(),
                              child: InkWell(
                                customBorder: CircleBorder(),
                                onTap: _toggleNotificationPopup,
                                child: SizedBox(
                                  width: 44,
                                  height: 44,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Icon(
                                        Icons.notifications_none_rounded,
                                        color: context.tl.primaryDark,
                                        size: 24,
                                      ),

                                      if (_notifikasiRingkas.any(
                                        (item) => item['dibaca'] != '1',
                                      ))
                                        Positioned(
                                          top: 9,
                                          right: 10,
                                          child: Container(
                                            width: 9,
                                            height: 9,
                                            decoration: BoxDecoration(
                                              color: context.tl.primary,
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

                          SizedBox(width: 9),

                          // AVATAR
                          CompositedTransformTarget(
                            link: _profileLink,
                            child: Material(
                              color: context.tl.surface,
                              shape: CircleBorder(),
                              child: InkWell(
                                customBorder: CircleBorder(),
                                onTap: _toggleProfilePopup,
                                child: SizedBox(
                                  width: 44,
                                  height: 44,
                                  child: Padding(
                                    padding: EdgeInsets.all(3),
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
                    ],
                  ),
                ),

                if (widget.adminDashboardEnabled)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 15, 18, 10),
                    child: Row(
                      children: [
                        _adminSwitch(
                          'Panel Admin',
                          Icons.space_dashboard_outlined,
                          true,
                        ),
                        const SizedBox(width: 12),
                        _adminSwitch(
                          'Jelajahi Lomba',
                          Icons.explore_outlined,
                          false,
                        ),
                      ],
                    ),
                  ),
                if (!widget.adminDashboardEnabled || !widget.showAdminPanel)
                  _exploreHero(),
                if (widget.adminDashboardEnabled && widget.showAdminPanel)
                  AdminDashboardPage(
                    token: widget.token,
                    onOpenPengajuan: widget.onOpenPengajuan ?? () {},
                    showHeader: false,
                    embedded: true,
                  ),
                if (!widget.adminDashboardEnabled ||
                    !widget.showAdminPanel) ...[
                  // Featured tetap tampil tanpa header; katalog berada di bawahnya.
                  if (!isLoadingLomba && errorLomba == null)
                    _featuredCarousel(),

                  // Filter kategori di antara featured dan kartu seluruh lomba.
                  // Layout seperti pill navigasi: putih, aktif hitam.
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 18),
                    child: _kategoriChips(kategoriPintasan),
                  ),

                  if (isLoadingLomba)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 42),
                      child: Center(
                        child: CircularProgressIndicator(color: _primary),
                      ),
                    )
                  else if (errorLomba != null)
                    Padding(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.wifi_off_rounded, color: _muted, size: 40),
                          SizedBox(height: 12),
                          Text(
                            'Gagal memuat daftar lomba.',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: _text,
                            ),
                          ),
                          SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _loadDataLomba,
                            child: Text('Coba Lagi'),
                          ),
                        ],
                      ),
                    )
                  else if (lombaTampil.isEmpty)
                    Padding(
                      padding: EdgeInsets.fromLTRB(22, 18, 22, 42),
                      child: Center(
                        child: Column(
                          children: [
                            Container(
                              width: 66,
                              height: 66,
                              decoration: BoxDecoration(
                                color: context.tl.cream,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.search_off_rounded,
                                size: 30,
                                color: context.tl.primary,
                              ),
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Lomba tidak ditemukan',
                              style: TextStyle(
                                color: _text,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
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
                      padding: EdgeInsets.fromLTRB(22, 0, 22, 125),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final twoColumns = constraints.maxWidth >= 300;
                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: lombaTampil.length,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: twoColumns ? 2 : 1,
                                  mainAxisSpacing: 3,
                                  crossAxisSpacing: 12,
                                  mainAxisExtent: twoColumns ? 278 : 288,
                                ),
                            itemBuilder: (context, index) => cardLomba(
                              context,
                              lombaTampil[index],
                              compact: twoColumns,
                            ),
                          );
                        },
                      ),
                    ),
                ], // Konten jelajahi hanya muncul saat dipilih.
                if (widget.adminDashboardEnabled && widget.showAdminPanel)
                  const SizedBox(height: 170),
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

  Widget cardLomba(
    BuildContext context,
    Map<String, String> lomba, {
    bool compact = false,
  }) {
    final id = int.tryParse(lomba['id_lomba'] ?? '') ?? -1;
    final biaya = _formatBiayaLomba((lomba['biaya'] ?? '').trim());
    return CompetitionPosterCard(
      compact: compact,
      height: compact ? 278 : 288,
      title: (lomba['judul'] ?? 'Tanpa judul').trim(),
      posterUrl: ApiService.publicStorageUrl(lomba['poster_lomba']),
      category: lomba['kategori'] ?? 'Kompetisi',
      organizer: lomba['penyelenggara'] ?? '',
      date: lomba['tanggal'],
      meta: biaya.isEmpty ? 'Gratis' : biaya,
      liveQuota:
          '${lomba['jumlah_peserta'] ?? '—'}/${(lomba['kuota'] ?? '—').replaceAll(' peserta', '')}',
      isFavorite: _favoriteIds.contains(id),
      showFavorite: true,
      onFavorite: () => _toggleFavorit(lomba),
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetailLombaPage(lomba: lomba, token: widget.token),
          ),
        );
        if (mounted) _loadFavorit();
      },
    );
  }
}