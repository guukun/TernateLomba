import '../../design_system/tl_playful.dart';

import 'dart:async';

import 'package:flutter/material.dart';

import '../../widgets/competition_poster_card.dart';

import '../../services/api_service.dart';
import '../../config/appTheme.dart';
import 'detailPengajuanPage.dart';

class PengajuanPage extends StatefulWidget {
  final String token;

  const PengajuanPage({super.key, required this.token});

  @override
  State<PengajuanPage> createState() => _PengajuanPageState();
}

class _PengajuanPageState extends State<PengajuanPage>
    with WidgetsBindingObserver {
  // ==========================================
  // WARNA DARI APP THEME
  // ==========================================

  Color get _primary => context.tl.primary;
  Color get _primaryDark => context.tl.primaryDark;
  Color get _cream => context.tl.cream;
  Color get _creamLight => context.tl.creamLight;
  Color get _background => context.tl.background;
  Color get _text => context.tl.navy;
  Color get _muted => context.tl.grey;
  Color get _outline => context.tl.fieldBorder;

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
  bool _isFetching = false;
  bool _appIsResumed = true;
  int _requestVersion = 0;
  Timer? _syncTimer;

  static const Duration _realtimeInterval = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ApiService.dataRevision.addListener(_onRealtimeDataChanged);
    _load();
    _startRealtimePolling();
  }

  // ==========================================
  // MEMUAT DAN MENYINKRONKAN DATA
  // ==========================================

  Future<void> _load({bool showLoading = true}) async {
    if (!mounted || _isFetching) return;

    _isFetching = true;
    final requestVersion = ++_requestVersion;

    if (showLoading) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final response = await ApiService.getPengajuanLombaAdmin(
        token: widget.token,
      );

      final raw = response['data'];
      if (raw is! List) {
        throw FormatException('Format daftar pengajuan tidak valid.');
      }

      final items = raw
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      if (!mounted || requestVersion != _requestVersion) return;

      setState(() {
        _items = items;
        _loading = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted || requestVersion != _requestVersion) return;

      setState(() {
        // Ketika sinkronisasi latar gagal, daftar yang sudah tampil tetap dipakai.
        if (showLoading || _items.isEmpty) {
          _error = ApiService.readableError(error);
        }
        _loading = false;
      });
      debugPrint('Sinkronisasi pengajuan admin gagal: $error');
    } finally {
      _isFetching = false;
    }
  }

  void _onRealtimeDataChanged() {
    if (!mounted) return;
    _load(showLoading: false);
  }

  void _startRealtimePolling() {
    _syncTimer?.cancel();
    if (!_appIsResumed) return;

    _syncTimer = Timer.periodic(_realtimeInterval, (_) {
      if (mounted && _appIsResumed) {
        _load(showLoading: false);
      }
    });
  }

  void _stopRealtimePolling() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appIsResumed = state == AppLifecycleState.resumed;
    if (_appIsResumed) {
      _load(showLoading: false);
      _startRealtimePolling();
    } else {
      _stopRealtimePolling();
    }
  }

  @override
  void dispose() {
    _stopRealtimePolling();
    WidgetsBinding.instance.removeObserver(this);
    ApiService.dataRevision.removeListener(_onRealtimeDataChanged);
    super.dispose();
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
        return status == 'disetujui' && _lombaStatus(item) != 'aktif';

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
      await _load(showLoading: false);
    }
  }

  // ==========================================
  // KARTU LOMBA
  // ==========================================

  // All competition lists share the same poster-led card.
  Widget _card(Map<String, dynamic> item) {
    return CompetitionPosterCard(
      compact: true,
      height: 278,
      title: '${item['nama_lomba'] ?? 'Lomba tanpa nama'}',
      posterUrl: ApiService.publicStorageUrl(item['poster_lomba']?.toString()),
      category: _category(item),
      organizer: _organizer(item),
      date: _shortDate(item['tanggal_pelaksanaan']),
      status: _itemCategory(item),
      meta: 'Status: ${_itemCategory(item)}',
      secondaryMeta: 'Buka detail untuk verifikasi',
      onTap: () => _openDetails(item),
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
    final foreground = active ? Colors.white : _primaryDark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => setState(() {
          _activeFilter = active ? null : title;
        }),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 180),
          height: 88,
          padding: EdgeInsets.symmetric(horizontal: 3, vertical: 9),
          decoration: BoxDecoration(
            color: active ? _primaryDark : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: active ? _primaryDark : _outline),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_filterIcon(title), color: foreground, size: 21),
              SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  title,
                  maxLines: 1,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              SizedBox(height: 3),
              Text(
                '${_count(title)}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: active ? Colors.white70 : _muted,
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

  Widget _emptyState() => TLPlayful.empty(
    context,
    title: 'Belum ada pengajuan',
    message: _activeFilter == null
        ? 'Belum ada pengajuan lomba yang perlu diperiksa.'
        : 'Tidak ada lomba dengan status $_activeFilter.',
    icon: Icons.fact_check_outlined,
    accent: context.tl.mint,
  );

  // ==========================================
  // HEADER HALAMAN
  // ==========================================

  Widget _header() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      TLPlayful.decoratedHeading(
        context,
        title: 'Review\napplications.',
        subtitle: 'Pantau, tinjau, dan putuskan pengajuan lomba dengan mudah.',
        icon: Icons.fact_check_rounded,
        accent: context.tl.mint,
      ),
      Container(
        margin: const EdgeInsets.fromLTRB(20, 10, 20, 2),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: context.tl.primary,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Row(
          children: [
            Icon(Icons.verified_outlined, color: Colors.white, size: 19),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'REVIEW WITH PURPOSE.',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );

  // ==========================================
  // HEADER DAFTAR PENGAJUAN
  // ==========================================

  Widget _listHeader(int total) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 25, 20, 13),
      child: Row(
        children: [
          Expanded(
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
            padding: EdgeInsets.symmetric(horizontal: 13, vertical: 8),
            decoration: BoxDecoration(
              color: _cream,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$total lomba',
              style: TextStyle(
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
        padding: EdgeInsets.all(24),
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
              child: Icon(Icons.wifi_off_rounded, size: 34, color: _primary),
            ),

            SizedBox(height: 15),

            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: _text, fontSize: 13, height: 1.5),
            ),

            SizedBox(height: 15),

            OutlinedButton.icon(
              onPressed: _load,
              icon: Icon(Icons.refresh_rounded),
              label: Text('Coba lagi'),
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
            physics: AlwaysScrollableScrollPhysics(),
            slivers: [
              // HEADER DAN FILTER

              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _header(),

                    SizedBox(height: 24),

                    Padding(
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
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          for (var i = 0; i < _filters.length; i++) ...[
                            if (i > 0) SizedBox(width: 7),
                            Expanded(child: _filter(_filters[i])),
                          ],
                        ],
                      ),
                    ),

                    _listHeader(items.length),
                  ],
                ),
              ),

              // LOADING
              if (_loading)
                SliverFillRemaining(
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
                    padding: EdgeInsets.only(bottom: 40),
                    child: Center(child: _emptyState()),
                  ),
                )
              // DAFTAR KARTU
              else
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverLayoutBuilder(
                    builder: (context, constraints) {
                      final twoColumns = constraints.crossAxisExtent >= 300;
                      return SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: twoColumns ? 2 : 1,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          mainAxisExtent: twoColumns ? 278 : 288,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _card(items[index]),
                          childCount: items.length,
                        ),
                      );
                    },
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