import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import 'detailPengajuanPage.dart';

/// Halaman verifikasi admin. Hanya mengubah presentasi; kontrak API tetap.
class PengajuanPage extends StatefulWidget {
  final String token;

  const PengajuanPage({super.key, required this.token});

  @override
  State<PengajuanPage> createState() => _PengajuanPageState();
}

class _PengajuanPageState extends State<PengajuanPage> {
  static const _blue = Color(0xFF3478E5);
  static const _ink = Color(0xFF1A2338);
  static const _muted = Color(0xFF768296);
  static const _background = Color(0xFFF4F7FC);
  static const _outline = Color(0xFFE3E9F1);

  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;
  int _activeTab = 0; // 0: pengajuan, 1: disetujui
  String _activeFilter = 'Semua';

  @override
  void initState() {
    super.initState();
    _load();
  }

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
      if (raw is! List)
        throw const FormatException('Format daftar pengajuan tidak valid.');
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

  String _status(Map<String, dynamic> item) =>
      (item['status_pengajuan']?.toString() ?? '').trim().toLowerCase();

  int _count(String status) =>
      _items.where((item) => _status(item) == status).length;

  List<Map<String, dynamic>> get _filteredItems {
    final list = _items.where((item) {
      final status = _status(item);
      if (_activeTab == 1) return status == 'disetujui';
      if (status != 'menunggu' && status != 'ditolak') return false;
      if (_activeFilter == 'Menunggu') return status == 'menunggu';
      if (_activeFilter == 'Ditolak') return status == 'ditolak';
      return true;
    }).toList();
    list.sort((a, b) {
      final aTime = DateTime.tryParse(
        (a['tanggal_pengajuan'] ?? a['created_at'] ?? '').toString(),
      );
      final bTime = DateTime.tryParse(
        (b['tanggal_pengajuan'] ?? b['created_at'] ?? '').toString(),
      );
      return (bTime ?? DateTime(1900)).compareTo(aTime ?? DateTime(1900));
    });
    return list;
  }

  void _selectTab(int index) {
    setState(() {
      _activeTab = index;
      _activeFilter = 'Semua';
    });
  }

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

  Widget _statusBadge(String status) {
    final pending = status == 'menunggu';
    final approved = status == 'disetujui';
    final color = pending
        ? const Color(0xFFB66B06)
        : approved
        ? const Color(0xFF18794E)
        : const Color(0xFFC53B47);
    final bg = pending
        ? const Color(0xFFFFF3DA)
        : approved
        ? const Color(0xFFE5F6ED)
        : const Color(0xFFFFE9ED);
    final label = pending
        ? 'Menunggu'
        : approved
        ? 'Disetujui'
        : 'Ditolak';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
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

  Future<void> _openDetails(Map<String, dynamic> item) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DetailPengajuanPage(token: widget.token, item: item),
      ),
    );
    if (!mounted) return;
    if (result != null) await _load();
  }

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
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  IconData _categoryIcon(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('olahraga')) return Icons.sports_soccer_rounded;
    if (lower.contains('teknologi')) return Icons.computer_rounded;
    if (lower.contains('seni')) return Icons.palette_outlined;
    if (lower.contains('musik')) return Icons.music_note_rounded;
    return Icons.menu_book_rounded;
  }


  Widget _posterFallback(String category, String eventDate) {
    return Stack(
                    children: [
                      Positioned(
                        top: -18,
                        right: -18,
                        child: Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            color: _blue.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -18,
                        left: -18,
                        child: Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: _blue.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _categoryIcon(category),
                              color: _blue,
                              size: 30,
                            ),
                            const SizedBox(height: 9),
                            const Text(
                              'LOMBA',
                              style: TextStyle(
                                color: _blue,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 5),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                eventDate,
                                style: const TextStyle(
                                  color: _blue,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
  }

  Widget _card(Map<String, dynamic> item) {
    final name = (item['nama_lomba'] ?? 'Lomba tanpa nama').toString();
    final status = _status(item);
    final category = _category(item);
    final eventDate = _shortDate(item['tanggal_pelaksanaan']);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: () => _openDetails(item),
          borderRadius: BorderRadius.circular(22),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              border: Border.all(color: _outline),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF253759).withValues(alpha: 0.025),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Poster yang diunggah penyelenggara ditampilkan apa adanya.
                Container(
                  width: 94,
                  height: 122,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F1FF),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: ApiService.publicStorageUrl(
                            item['poster_lomba']?.toString(),
                          ) ==
                          null
                      ? _posterFallback(category, eventDate)
                      : Image.network(
                          ApiService.publicStorageUrl(
                            item['poster_lomba']?.toString(),
                          )!,
                          width: 94,
                          height: 122,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _posterFallback(category, eventDate),
                        ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 122),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          constraints: const BoxConstraints(maxWidth: 170),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F1FF),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            category,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _blue,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _ink,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 5),
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
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 9),
                        Row(
                          children: [
                            Flexible(child: _statusBadge(status)),
                            const Spacer(),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              color: _blue,
                              size: 21,
                            ),
                          ],
                        ),
                      ],
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

  Widget _tab(String title, int index, int count) {
    final active = _activeTab == index;
    return Expanded(
      child: InkWell(
        onTap: () => _selectTab(index),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 13),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                    color: active ? _ink : _muted,
                  ),
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: active
                        ? const Color(0xFFEAF1FF)
                        : const Color(0xFFE3E9F1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 10,
                      color: active ? _blue : _muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _filter(String title, int count) {
    final active = _activeFilter == title;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text('$title ($count)'),
        selected: active,
        onSelected: (_) => setState(() => _activeFilter = title),
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: active ? Colors.white : _ink,
        ),
        backgroundColor: Colors.white,
        selectedColor: _blue,
        side: BorderSide(color: active ? _blue : const Color(0xFFD8E0EC)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      ),
    );
  }

  /// MainPage menampilkan FloatingNavigationBar sebagai overlay di dalam Stack.
  /// Sisakan ruang untuk bar sehingga kartu terakhir dapat digulir sepenuhnya.
  double _navigationClearance(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return 120.0 + bottomInset;
  }

  Widget _emptyState() => ListView(
    padding: EdgeInsets.only(bottom: _navigationClearance(context)),
    physics: const AlwaysScrollableScrollPhysics(),
    children: [
      const SizedBox(height: 110),
      Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Color(0xFFEAF1FF),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.inbox_outlined, size: 34, color: _blue),
        ),
      ),
      const SizedBox(height: 16),
      const Text(
        'Belum ada data',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: _ink,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 6),
      Text(
        _activeTab == 1
            ? 'Belum ada pengajuan yang disetujui.'
            : 'Tidak ada pengajuan pada filter ini.',
        textAlign: TextAlign.center,
        style: const TextStyle(color: _muted, fontSize: 12),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final items = _filteredItems;
    final pending = _count('menunggu');
    final rejected = _count('ditolak');
    final approved = _count('disetujui');

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFE5EFFD), Color(0xFFF0F5FE)],
                ),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(26),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    height: 46,
                    width: 46,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.fact_check_rounded,
                      color: _blue,
                      size: 25,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Verifikasi Lomba',
                          style: TextStyle(
                            color: _ink,
                            fontSize: 23,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Kelola pengajuan dan publikasi lomba',
                          style: TextStyle(color: _muted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    child: IconButton(
                      tooltip: 'Muat ulang',
                      onPressed: _loading ? null : _load,
                      icon: const Icon(Icons.refresh_rounded, color: _blue),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF0F7),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    _tab('Pengajuan Lomba', 0, pending + rejected),
                    _tab('Terpublikasi', 1, approved),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_activeTab == 0)
              SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _filter('Semua', pending + rejected),
                    _filter('Menunggu', pending),
                    _filter('Ditolak', rejected),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
              child: Text(
                _activeTab == 0
                    ? '${items.length} pengajuan'
                    : '${items.length} lomba terpublikasi',
                style: const TextStyle(
                  color: _muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: _blue))
                  : _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.wifi_off_rounded,
                              size: 36,
                              color: _muted,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _error!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: _ink, fontSize: 13),
                            ),
                            const SizedBox(height: 14),
                            OutlinedButton.icon(
                              onPressed: _load,
                              icon: const Icon(Icons.refresh, size: 16),
                              label: const Text('Coba lagi'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      color: _blue,
                      onRefresh: _load,
                      child: items.isEmpty
                          ? _emptyState()
                          : ListView.builder(
                              padding: EdgeInsets.fromLTRB(
                                20,
                                0,
                                20,
                                _navigationClearance(context),
                              ),
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: items.length,
                              itemBuilder: (_, index) => _card(items[index]),
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}