import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../config/appTheme.dart';
import 'detailPengajuanPage.dart';

class PengajuanPage extends StatefulWidget {
  final String token;

  const PengajuanPage({super.key, required this.token});

  @override
  State<PengajuanPage> createState() => _PengajuanPageState();
}

class _PengajuanPageState extends State<PengajuanPage> {
  // ==========================================
  // WARNA DARI APP THEME
  // ==========================================

  static const Color _primary = AppColors.primary;
  static const Color _primaryDark = AppColors.primaryDark;
  static const Color _cream = AppColors.cream;
  static const Color _creamLight = AppColors.creamLight;
  static const Color _creamDark = AppColors.creamDark;
  static const Color _background = AppColors.background;
  static const Color _surface = AppColors.surface;
  static const Color _text = AppColors.navy;
  static const Color _muted = AppColors.grey;
  static const Color _outline = AppColors.fieldBorder;

  static const List<String> _filters = [
    'Menunggu',
    'Ditolak',
    'Diterima',
    'Sedang Aktif',
  ];

  // ==========================================
  // STATE
  // ==========================================

  List<Map<String, dynamic>> _items = [];

  bool _loading = true;

  String? _error;

  String? _activeFilter;

  @override
  void initState() {
    super.initState();
    _load();
  }

  // ==========================================
  // MEMUAT DATA
  // ==========================================

  Future<void> _load() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await ApiService.getPengajuanLombaAdmin(
        token: widget.token,
      );

      final raw = response['data'];

      if (raw is! List) {
        throw const FormatException('Format daftar pengajuan tidak valid.');
      }

      final items = raw
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      if (!mounted) return;

      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  // ==========================================
  // STATUS PENGAJUAN DAN PUBLIKASI
  // ==========================================

  String _status(Map<String, dynamic> item) {
    return (item['status_pengajuan'] ?? '').toString().trim().toLowerCase();
  }

  String _lombaStatus(Map<String, dynamic> item) {
    final lomba = item['lomba'];

    if (lomba is Map) {
      return (lomba['status_lomba'] ?? '').toString().trim().toLowerCase();
    }

    return (item['status_lomba'] ?? '').toString().trim().toLowerCase();
  }

  bool _isActive(Map<String, dynamic> item) {
    return _status(item) == 'disetujui' && _lombaStatus(item) == 'aktif';
  }

  String _itemCategory(Map<String, dynamic> item) {
    final status = _status(item);

    if (status == 'menunggu') return 'Menunggu';

    if (status == 'ditolak') return 'Ditolak';

    if (status == 'disetujui' && _isActive(item)) {
      return 'Sedang Aktif';
    }

    if (status == 'disetujui') return 'Diterima';

    return 'Lainnya';
  }

  bool _matchesFilter(Map<String, dynamic> item, String? filter) {
    final status = _status(item);

    if (filter == null) return true;

    switch (filter) {
      case 'Menunggu':
        return status == 'menunggu';

      case 'Ditolak':
        return status == 'ditolak';

      case 'Diterima':
        return status == 'disetujui';

      case 'Sedang Aktif':
        return status == 'disetujui' && _lombaStatus(item) == 'aktif';

      default:
        return true;
    }
  }

  // ==========================================
  // FILTER DAN JUMLAH DATA
  // ==========================================

  int _count(String category) {
    return _items.where((item) => _matchesFilter(item, category)).length;
  }

  List<Map<String, dynamic>> get _filteredItems {
    if (_activeFilter == null) return _items;

    return _items
        .where((item) => _matchesFilter(item, _activeFilter))
        .toList(growable: false);
  }

  // ==========================================
  // INFORMASI PENYELENGGARA
  // ==========================================

  String _organizer(Map<String, dynamic> item) {
    final organizer = item['penyelenggara'];

    if (organizer is Map) {
      return (organizer['username'] ??
              organizer['nama'] ??
              'Penyelenggara tidak tersedia')
          .toString();
    }

    return organizer?.toString() ?? 'Penyelenggara tidak tersedia';
  }

  // ==========================================
  // INFORMASI KATEGORI
  // ==========================================

  String _category(Map<String, dynamic> item) {
    final category = item['kategori'];

    if (category is Map) {
      final label = (category['nama_kategori'] ?? '').toString().trim();

      if (label.isNotEmpty) return label;
    }

    return 'Tanpa kategori';
  }

  String _shortDate(dynamic value) {
    if (value == null) return 'Belum diatur';

    final date = DateTime.tryParse(value.toString());

    if (date == null) return 'Belum diatur';

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  IconData _categoryIcon(String category) {
    final lower = category.toLowerCase();

    if (lower.contains('olahraga')) {
      return Icons.sports_soccer_rounded;
    }

    if (lower.contains('teknologi')) {
      return Icons.computer_rounded;
    }

    if (lower.contains('seni')) {
      return Icons.palette_outlined;
    }

    if (lower.contains('musik')) {
      return Icons.music_note_rounded;
    }

    return Icons.menu_book_rounded;
  }

  // ==========================================
  // WARNA STATUS
  // ==========================================

  Color _statusColor(String category) {
    switch (category) {
      case 'Menunggu':
        return const Color(0xFFB7791F);

      case 'Ditolak':
        return AppColors.error;

      case 'Diterima':
        return AppColors.green;

      case 'Sedang Aktif':
        return _primary;

      default:
        return _muted;
    }
  }

  Color _statusBackground(String category) {
    switch (category) {
      case 'Menunggu':
        return const Color(0xFFFFF4DF);

      case 'Ditolak':
        return const Color(0xFFFFEBEB);

      case 'Diterima':
        return const Color(0xFFE7F4EC);

      case 'Sedang Aktif':
        return _cream;

      default:
        return _creamLight;
    }
  }

  // ==========================================
  // BADGE STATUS
  // ==========================================

  Widget _statusBadge(Map<String, dynamic> item) {
    final category = _itemCategory(item);

    final color = _statusColor(category);
    final background = _statusBackground(category);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 7),
          Text(
            category,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // DETAIL PENGAJUAN
  // ==========================================

  Future<void> _openDetails(Map<String, dynamic> item) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DetailPengajuanPage(token: widget.token, item: item),
      ),
    );

    if (!mounted) return;

    if (result != null) {
      await _load();
    }
  }

  // ==========================================
  // POSTER CADANGAN
  // ==========================================

  Widget _posterFallback(String category, String eventDate) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.creamLight, AppColors.cream],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -18,
            right: -18,
            child: Container(
              width: 65,
              height: 65,
              decoration: BoxDecoration(
                color: _primary.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -18,
            left: -18,
            child: Container(
              width: 65,
              height: 65,
              decoration: BoxDecoration(
                color: _primary.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_categoryIcon(category), color: _primary, size: 30),
                  const SizedBox(height: 9),
                  const Text(
                    'LOMBA',
                    style: TextStyle(
                      color: _primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 5),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      eventDate,
                      style: const TextStyle(
                        color: _muted,
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // KARTU LOMBA
  // ==========================================

  Widget _card(Map<String, dynamic> item) {
    final name = (item['nama_lomba'] ?? 'Lomba tanpa nama').toString();

    final category = _category(item);

    final eventDate = _shortDate(item['tanggal_pelaksanaan']);

    final posterUrl = ApiService.publicStorageUrl(
      item['poster_lomba']?.toString(),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Material(
        color: _surface,
        borderRadius: BorderRadius.circular(23),
        child: InkWell(
          onTap: () => _openDetails(item),
          borderRadius: BorderRadius.circular(23),
          splashColor: _creamDark.withValues(alpha: 0.22),
          highlightColor: _cream.withValues(alpha: 0.35),
          child: Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              border: Border.all(color: _outline, width: 1),
              borderRadius: BorderRadius.circular(23),
              boxShadow: [
                BoxShadow(
                  color: _primaryDark.withValues(alpha: 0.035),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // POSTER

                Container(
                  width: 108,
                  height: 145,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: _cream,
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: posterUrl == null
                      ? _posterFallback(category, eventDate)
                      : Image.network(
                          posterUrl,
                          width: 108,
                          height: 145,
                          fit: BoxFit.cover,
                          cacheWidth: 324,
                          cacheHeight: 435,
                          gaplessPlayback: true,
                          errorBuilder: (_, _, _) {
                            return _posterFallback(category, eventDate);
                          },
                        ),
                ),

                const SizedBox(width: 13),

                // INFORMASI LOMBA
                Expanded(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 145),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          constraints: const BoxConstraints(maxWidth: 160),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _cream,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            category,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _primary,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),

                        const SizedBox(height: 9),

                        Text(
                          name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _text,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            height: 1.3,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Row(
                          children: [
                            const Icon(
                              Icons.account_balance_outlined,
                              color: _muted,
                              size: 15,
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                _organizer(item),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: _muted,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 11),

                        Row(children: [Flexible(child: _statusBadge(item))]),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 5),

                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: _primary,
                  size: 17,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // ICON FILTER
  // ==========================================

  IconData _filterIcon(String title) {
    switch (title) {
      case 'Menunggu':
        return Icons.schedule_rounded;

      case 'Ditolak':
        return Icons.cancel_outlined;

      case 'Diterima':
        return Icons.verified_outlined;

      case 'Sedang Aktif':
        return Icons.play_circle_outline_rounded;

      default:
        return Icons.category_outlined;
    }
  }

  // ==========================================
  // KARTU FILTER
  // ==========================================

  Widget _filter(String title) {
    final active = _activeFilter == title;

    final color = active ? Colors.white : _primary;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(21),
      child: InkWell(
        borderRadius: BorderRadius.circular(21),

        // Hover dan splash dibuat lembut.
        hoverColor: active
            ? _primaryDark.withValues(alpha: 0.15)
            : _cream.withValues(alpha: 0.55),

        splashColor: active
            ? Colors.white.withValues(alpha: 0.10)
            : _creamDark.withValues(alpha: 0.25),

        highlightColor: active
            ? Colors.white.withValues(alpha: 0.05)
            : _cream.withValues(alpha: 0.35),

        onTap: () {
          setState(() {
            _activeFilter = _activeFilter == title ? null : title;
          });
        },

        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
          decoration: BoxDecoration(
            color: active ? _primary : _surface,
            borderRadius: BorderRadius.circular(21),
            border: Border.all(
              color: active ? _primary : _outline,
              width: active ? 1.3 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: _primaryDark.withValues(alpha: active ? 0.10 : 0.035),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: active ? Colors.white.withValues(alpha: 0.13) : _cream,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  _filterIcon(title),
                  color: active ? Colors.white : _primary,
                  size: 24,
                ),
              ),

              const SizedBox(width: 9),

              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      '${_count(title)} lomba',
                      style: TextStyle(
                        color: active
                            ? Colors.white.withValues(alpha: 0.75)
                            : _muted,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
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

  // ==========================================
  // TAMPILAN KOSONG
  // ==========================================

  Widget _emptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(color: _cream, shape: BoxShape.circle),
            child: const Icon(Icons.inbox_outlined, size: 38, color: _primary),
          ),

          const SizedBox(height: 18),

          const Text(
            'Belum ada data',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _text,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            _activeFilter == null
                ? 'Belum ada pengajuan lomba.'
                : 'Tidak ada lomba dalam kategori $_activeFilter.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: _muted, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // HEADER HALAMAN
  // ==========================================

  Widget _header() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 27, 20, 30),
      decoration: const BoxDecoration(
        color: _primaryDark,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 49,
                height: 49,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.fact_check_rounded,
                  color: _cream,
                  size: 26,
                ),
              ),

              const SizedBox(width: 13),

              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TERNATELOMBA',
                      style: TextStyle(
                        color: _cream,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.6,
                      ),
                    ),

                    SizedBox(height: 5),

                    Text(
                      'Pengajuan Lomba',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          const Text(
            'Kelola pengajuan dan publikasi lomba',
            style: TextStyle(
              color: Color(0xFFE0E8F2),
              fontSize: 13,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 20),

          Container(
            width: 58,
            height: 4,
            decoration: BoxDecoration(
              color: _cream,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // HEADER DAFTAR PENGAJUAN
  // ==========================================

  Widget _listHeader(int total) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 25, 20, 13),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Daftar Pengajuan',
              style: TextStyle(
                color: _text,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
            decoration: BoxDecoration(
              color: _cream,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$total lomba',
              style: const TextStyle(
                color: _primary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAMPILAN ERROR
  // ==========================================

  Widget _errorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 75,
              height: 75,
              decoration: BoxDecoration(
                color: _cream,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                size: 34,
                color: _primary,
              ),
            ),

            const SizedBox(height: 15),

            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _text, fontSize: 13, height: 1.5),
            ),

            const SizedBox(height: 15),

            OutlinedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba lagi'),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // BUILD UTAMA
  // ==========================================

  @override
  Widget build(BuildContext context) {
    final items = _filteredItems;

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: RefreshIndicator(
          color: _primary,
          backgroundColor: _creamLight,
          onRefresh: _load,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // HEADER DAN FILTER

              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _header(),

                    const SizedBox(height: 24),

                    const Padding(
                      padding: EdgeInsets.fromLTRB(20, 0, 20, 13),
                      child: Text(
                        'Kategori Pengajuan',
                        style: TextStyle(
                          color: _text,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 2.05,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: _filters.map(_filter).toList(),
                      ),
                    ),

                    _listHeader(items.length),
                  ],
                ),
              ),

              // LOADING
              if (_loading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: CircularProgressIndicator(color: _primary),
                  ),
                )
              // ERROR
              else if (_error != null)
                SliverFillRemaining(hasScrollBody: false, child: _errorState())
              // DATA KOSONG
              else if (items.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 40),
                    child: Center(child: _emptyState()),
                  ),
                )
              // DAFTAR KARTU
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      return _card(items[index]);
                    }, childCount: items.length),
                  ),
                ),

              // RUANG SCROLL UNTUK NAVIGASI BAWAH
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 120 + MediaQuery.paddingOf(context).bottom,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}