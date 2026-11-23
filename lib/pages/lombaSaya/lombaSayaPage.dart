import 'dart:async';

import 'package:flutter/material.dart';

import '../../widgets/competition_poster_card.dart';
import '../../widgets/competition_card_grid.dart';

import '../../services/api_service.dart';
import '../../config/appTheme.dart';
import '../../design_system/tl_playful.dart';
import 'KelolaLombaPage.dart';
import 'detailLombaDiikutiPage.dart';

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

class _LombaSayaPageState extends State<LombaSayaPage>
    with WidgetsBindingObserver {
  int selectedTab = 0;
  String _selectedPengajuanFilter = 'Semua';
  Timer? _syncTimer;
  bool _appResumed = true;

  List<Map<String, dynamic>> _riwayatPendaftaran = [];
  bool _isLoadingRiwayat = false;
  String? _errorRiwayat;
  bool _riwayatSudahDimuat = false;

  List<Map<String, dynamic>> _lombaDibuat = [];
  bool _isLoadingLombaDibuat = false;
  String? _errorLombaDibuat;
  bool _lombaDibuatSudahDimuat = false;

  // Warna mengikuti AppTheme.
  Color get primaryBlue => context.tl.primary;
  Color get darkBlue => context.tl.primaryDark;
  Color get cream => context.tl.cream;
  Color get creamLight => context.tl.creamLight;
  Color get backgroundColor => context.tl.background;
  Color get textColor => context.tl.navy;
  Color get mutedColor => context.tl.grey;
  Color get borderColor => context.tl.fieldBorder;

  // ==========================================
  // MEMUAT RIWAYAT PENDAFTARAN
  // ==========================================

  Future<void> _loadRiwayatPendaftaran({bool silent = false}) async {
    if (_isLoadingRiwayat) return;

    setState(() {
      _isLoadingRiwayat = true;
      if (!silent) _errorRiwayat = null;
    });

    try {
      final response = await ApiService.getRiwayatPendaftaran(
        token: widget.token,
      );

      if (!mounted) return;

      final data = response['data'];

      if (data is! List) {
        throw FormatException('Format data riwayat pendaftaran tidak sesuai.');
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
        _errorRiwayat = ApiService.readableError(e);
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

  Future<void> _loadLombaDibuat({bool silent = false}) async {
    if (_isLoadingLombaDibuat) return;

    setState(() {
      _isLoadingLombaDibuat = true;
      if (!silent) _errorLombaDibuat = null;
    });

    try {
      final response = await ApiService.getPengajuanLombaSaya(
        token: widget.token,
      );

      if (!mounted) return;

      final data = response['data'];

      if (data is! List) {
        throw FormatException('Format data lomba yang dibuat tidak sesuai.');
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
        _errorLombaDibuat = ApiService.readableError(e);
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
    WidgetsBinding.instance.addObserver(this);
    ApiService.dataRevision.addListener(_onDataRevision);
    _loadRiwayatPendaftaran();
    _syncTimer = Timer.periodic(Duration(seconds: 5), (_) {
      if (!_appResumed) return;
      if (selectedTab == 0) {
        _loadRiwayatPendaftaran(silent: true);
      } else {
        _loadLombaDibuat(silent: true);
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appResumed = state == AppLifecycleState.resumed;
    if (_appResumed) {
      if (selectedTab == 0) {
        _loadRiwayatPendaftaran(silent: true);
      } else {
        _loadLombaDibuat(silent: true);
      }
    }
  }
  
  void _onDataRevision() {
    if (!mounted) return;
    if (selectedTab == 0) {
      _loadRiwayatPendaftaran(silent: true);
    } else {
      _loadLombaDibuat(silent: true);
    }
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    ApiService.dataRevision.removeListener(_onDataRevision);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
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
            physics: AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // HEADER
                TLPlayful.decoratedHeading(
                  context,
                  title: selectedTab == 0
                      ? 'Your next\nmove.'
                      : 'Make it\nhappen.',
                  subtitle: selectedTab == 0
                      ? 'Pantau status dan detail keikutsertaanmu.'
                      : 'Kelola kompetisi dan peserta dengan mudah.',
                  accent: context.tl.orange,
                  icon: Icons.emoji_events_rounded,
                ),

                // KATEGORI LOMBA
                _buildCategorySection(),

                // KONTEN LOMBA
                AnimatedSwitcher(
                  duration: Duration(milliseconds: 250),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: Offset(0, 0.02),
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
  // KATEGORI LOMBA
  // ==========================================

  Widget _buildCategorySection() {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: _buildTabCard(
              title: 'Lomba Diikuti',
              icon: Icons.emoji_events_rounded,
              index: 0,
            ),
          ),

          SizedBox(width: 13),

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
    final selected = selectedTab == index;
    final accent = context.tl.primary;
    final p = context.tl;
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(27),
        onTap: () {
          if (selectedTab == index) return;
          setState(() => selectedTab = index);
          if (index == 1) _loadLombaDibuat();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(15),
          height: 128,
          decoration: TLPlayful.card(context, radius: 25).copyWith(
            border: Border.all(
              color: selected ? accent : p.fieldBorder,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: selected ? p.primary : p.fieldBg,
                      borderRadius: BorderRadius.circular(17),
                    ),
                    child: Icon(
                      icon,
                      color: selected ? Colors.white : p.navy,
                      size: 25,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.arrow_outward_rounded,
                    color: selected ? p.primary : p.muted,
                    size: 20,
                  ),
                ],
              ),
              const Spacer(),
              Text(
                title,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: p.navy,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  letterSpacing: -.2,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: selected ? 50 : 21,
                height: 4,
                decoration: BoxDecoration(
                  color: p.primary,
                  borderRadius: BorderRadius.circular(9),
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

  int _jumlahStatusPengajuan(String status) {
    if (status == 'Semua') return _lombaDibuat.length;
    return _lombaDibuat
        .where(
          (item) =>
              (item['status_pengajuan']?.toString() ?? 'Menunggu')
                  .toLowerCase() ==
              status.toLowerCase(),
        )
        .length;
  }

  List<Map<String, dynamic>> get _pengajuanTerfilter {
    if (_selectedPengajuanFilter == 'Semua') return _lombaDibuat;
    return _lombaDibuat
        .where(
          (item) =>
              (item['status_pengajuan']?.toString() ?? 'Menunggu')
                  .toLowerCase() ==
              _selectedPengajuanFilter.toLowerCase(),
        )
        .toList();
  }

  Widget _buildPengajuanFilters() {
    final filters = [
      ('Semua', Icons.grid_view_rounded),
      ('Menunggu', Icons.hourglass_top_rounded),
      ('Disetujui', Icons.check_circle_outline_rounded),
      ('Ditolak', Icons.cancel_outlined),
    ];

    // Empat filter selalu rata dan selebar ruang yang tersedia.
    // Tidak menggunakan horizontal ListView / scrolling.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < filters.length; index++) ...[
          if (index > 0) SizedBox(width: 7),
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(15),
                onTap: () => setState(() {
                  _selectedPengajuanFilter = filters[index].$1;
                }),
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 180),
                  height: 85,
                  padding: EdgeInsets.symmetric(horizontal: 2, vertical: 7),
                  decoration: BoxDecoration(
                    color: _selectedPengajuanFilter == filters[index].$1
                        ? darkBlue
                        : Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: _selectedPengajuanFilter == filters[index].$1
                          ? darkBlue
                          : borderColor,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: darkBlue.withValues(alpha: 0.035),
                        blurRadius: 7,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        filters[index].$2,
                        color: _selectedPengajuanFilter == filters[index].$1
                            ? Colors.white
                            : darkBlue,
                        size: 20,
                      ),
                      SizedBox(height: 5),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          filters[index].$1,
                          maxLines: 1,
                          style: TextStyle(
                            color: _selectedPengajuanFilter == filters[index].$1
                                ? Colors.white
                                : textColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        '${_jumlahStatusPengajuan(filters[index].$1)}',
                        style: TextStyle(
                          color: _selectedPengajuanFilter == filters[index].$1
                              ? Colors.white70
                              : mutedColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _openLombaDibuat(Map<String, dynamic> item) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => KelolaLombaPage(token: widget.token, pengajuan: item),
      ),
    );
    if (mounted) _loadLombaDibuat(silent: true);
  }

  Future<void> _openLombaDiikuti(Map<String, dynamic> item) async {
    final id = int.tryParse(item['id_pendaftaran']?.toString() ?? '');
    if (id == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            DetailLombaDiikutiPage(token: widget.token, idPendaftaran: id),
      ),
    );
    if (mounted) _loadRiwayatPendaftaran(silent: true);
  }

  Widget _buildLombaDibuatContent() {
    if (_isLoadingLombaDibuat && !_lombaDibuatSudahDimuat) {
      return Padding(
        padding: EdgeInsets.all(45),
        child: Center(child: CircularProgressIndicator(color: darkBlue)),
      );
    }

    if (_errorLombaDibuat != null && !_lombaDibuatSudahDimuat) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_rounded, size: 46, color: mutedColor),
              SizedBox(height: 12),
              Text(
                _errorLombaDibuat!,
                textAlign: TextAlign.center,
                style: TextStyle(color: textColor, fontSize: 13),
              ),
              SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: _loadLombaDibuat,
                icon: Icon(Icons.refresh_rounded),
                label: Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    if (!_lombaDibuatSudahDimuat) return SizedBox(height: 20);

    final filtered = _pengajuanTerfilter;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 9, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPengajuanFilters(),
          SizedBox(height: 14),
          if (_lombaDibuat.isEmpty)
            _buildEmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'Belum ada lomba dibuat',
              description:
                  'Pengajuan dan lomba yang kamu buat akan muncul di sini.',
              tabIndex: 1,
            )
          else if (filtered.isEmpty)
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 15, vertical: 13),
              decoration: BoxDecoration(
                color: creamLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  Icon(Icons.tune_rounded, color: darkBlue, size: 19),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Belum ada status $_selectedPengajuanFilter. Pilih Semua untuk melihat ${_lombaDibuat.length} pengajuan yang tersedia.',
                      style: TextStyle(
                        color: mutedColor,
                        fontSize: 11,
                        height: 1.45,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        setState(() => _selectedPengajuanFilter = 'Semua'),
                    child: Text('Semua'),
                  ),
                ],
              ),
            )
          else
            CompetitionCardGrid(
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final item = filtered[index];
                final nama =
                    item['nama_lomba']?.toString() ?? 'Lomba tanpa nama';
                final status =
                    item['status_pengajuan']?.toString() ?? 'Menunggu';
                final kategori = item['kategori'] is Map
                    ? (item['kategori'] as Map)['nama_kategori']?.toString() ??
                          'Kategori tidak tersedia'
                    : 'Kategori tidak tersedia';
                final tanggal = item['tanggal_pelaksanaan']?.toString() ?? '';
                final note = item['catatan_admin']?.toString().trim() ?? '';
                final lomba = item['lomba'] is Map
                    ? Map<String, dynamic>.from(item['lomba'])
                    : <String, dynamic>{};
                final statusLomba =
                    lomba['status_lomba']?.toString() ?? 'Belum diterbitkan';
                final accepted =
                    int.tryParse(
                      lomba['jumlah_peserta_diterima']?.toString() ?? '',
                    ) ??
                    0;
                final pending =
                    int.tryParse(
                      lomba['jumlah_peserta_menunggu']?.toString() ?? '',
                    ) ??
                    0;
                final quota =
                    int.tryParse(item['kuota_peserta']?.toString() ?? '') ?? 0;
                final poster = ApiService.publicStorageUrl(
                  item['poster_lomba']?.toString(),
                );
                return CompetitionPosterCard(
                  compact: true,
                  height: 278,
                  title: nama,
                  liveQuota: '$accepted/${quota > 0 ? quota : '—'}',
                  liveQuotaBesideTitle: true,
                  posterUrl: poster,
                  category: kategori,
                  organizer: 'Pengajuan ${status.toLowerCase()}',
                  date: tanggal,
                  status: status.toLowerCase() == 'disetujui'
                      ? statusLomba
                      : status,
                  meta: '$accepted peserta diterima',
                  secondaryMeta: pending > 0
                      ? '$pending peserta menunggu review'
                      : note.isNotEmpty
                      ? 'Ada catatan administrator'
                      : 'Lihat detail pengajuan',
                  onTap: () => _openLombaDibuat(item),
                );
              },
            ),
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
          style: TextStyle(
            color: darkBlue,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),

        Container(
          padding: EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            color: cream,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            count,
            style: TextStyle(
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
  // KONTEN LOMBA YANG DIIKUTI
  // ==========================================

  Widget _buildRiwayatContent() {
    if (_isLoadingRiwayat && !_riwayatSudahDimuat) {
      return Padding(
        padding: EdgeInsets.all(45),
        child: Center(child: CircularProgressIndicator(color: darkBlue)),
      );
    }

    if (_errorRiwayat != null && !_riwayatSudahDimuat) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_rounded, size: 48, color: mutedColor),
              SizedBox(height: 12),
              Text(
                _errorRiwayat!,
                textAlign: TextAlign.center,
                style: TextStyle(color: textColor, fontSize: 13),
              ),
              SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: _loadRiwayatPendaftaran,
                icon: Icon(Icons.refresh_rounded),
                label: Text('Coba Lagi'),
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
        description: 'Lomba yang kamu ikuti akan muncul di sini. Temukan lomba yang sesuai dengan minatmu melalui halaman Beranda.',
        tabIndex: 0,
      );
    }
    if (!_riwayatSudahDimuat) return SizedBox(height: 20);

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 23, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildListHeading(
            'Lomba Diikuti',
            '${_riwayatPendaftaran.length} lomba',
          ),
          SizedBox(height: 15),
          CompetitionCardGrid(
            itemCount: _riwayatPendaftaran.length,
            itemBuilder: (context, index) {
              final item = _riwayatPendaftaran[index];
              final name = item['nama_lomba']?.toString() ?? 'Lomba tanpa nama';
              final statusRegistration =
                  item['status_pendaftaran']?.toString() ?? 'Menunggu';
              final statusCompetition =
                  item['status_lomba']?.toString() ?? 'Tidak diketahui';
              final date = item['tanggal_pendaftaran']?.toString() ?? '';
              final eventDate = item['tanggal_pelaksanaan']?.toString() ?? '';
              final category = item['kategori']?.toString() ?? 'Lomba';
              final poster = ApiService.publicStorageUrl(
                item['poster_lomba']?.toString(),
              );
              return CompetitionPosterCard(
                compact: true,
                height: 278,
                title: name,
                liveQuota:
                    '${item['jumlah_peserta_diterima'] ?? '—'}/${item['kuota_peserta'] ?? '—'}',
                liveQuotaBesideTitle: true,
                posterUrl: poster,
                category: category,
                organizer: 'Pendaftaran: $statusRegistration',
                date: eventDate,
                status: statusCompetition,
                meta: date.isEmpty
                    ? 'Tanggal daftar belum tersedia'
                    : 'Daftar: ${date.replaceFirst('T', ' ').split('.').first}',
                onTap: () => _openLombaDiikuti(item),
              );
            },
          ),
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
  }) => TLPlayful.empty(
    context,
    title: title,
    message: description,
    icon: icon,
    accent: tabIndex == 0 ? context.tl.orange : context.tl.mint,
    actionText: tabIndex == 0 ? 'Jelajahi Lomba' : 'Ajukan Lomba',
    onAction: tabIndex == 0
        ? () {
            if (widget.onJelajahiLomba != null) {
              widget.onJelajahiLomba!();
            } else {
              Navigator.of(context).popUntil((route) => route.isFirst);
            }
          }
        : widget.onAjukanLomba,
  );
}