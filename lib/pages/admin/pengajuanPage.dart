import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import 'detailPengajuanPage.dart';

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

  static const List<String> _filters = [
    'Semua',
    'Menunggu',
    'Ditolak',
    'Diterima',
    'Sedang Aktif',
  ];

  List<Map<String, dynamic>> _items = [];

  bool _loading = true;
  String? _error;

  String _activeFilter = 'Semua';

  @override
  void initState() {
    super.initState();
    _load();
  }

  // =========================================================
  // MEMUAT DATA
  // =========================================================

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

  // =========================================================
  // STATUS PENGAJUAN DAN PUBLIKASI
  // =========================================================

  String _status(Map<String, dynamic> item) {
    return (item['status_pengajuan'] ?? '').toString().trim().toLowerCase();
  }

  String _lombaStatus(Map<String, dynamic> item) {
    final lomba = item['lomba'];

    // Relasi lomba berbentuk object.
    if (lomba is Map) {
      return (lomba['status_lomba'] ?? '').toString().trim().toLowerCase();
    }

    // Antisipasi apabila API mengirim status di level utama.
    return (item['status_lomba'] ?? '').toString().trim().toLowerCase();
  }

  bool _isActive(Map<String, dynamic> item) {
    return _status(item) == 'disetujui' && _lombaStatus(item) == 'aktif';
  }

  // Menentukan label status untuk badge pada kartu pengajuan.
  // Label ini tidak dipakai sebagai satu-satunya dasar filter karena
  // kategori Diterima dan Sedang Aktif memang dapat saling beririsan.
  String _itemCategory(Map<String, dynamic> item) {
    final status = _status(item);

    if (status == 'menunggu') return 'Menunggu';
    if (status == 'ditolak') return 'Ditolak';
    if (status == 'disetujui' && _isActive(item)) return 'Sedang Aktif';
    if (status == 'disetujui') return 'Diterima';

    return 'Lainnya';
  }

  // Menentukan apakah satu pengajuan masuk ke filter yang dipilih.
  // Diterima mencakup semua pengajuan yang disetujui, termasuk yang aktif.
  bool _matchesFilter(Map<String, dynamic> item, String filter) {
    final status = _status(item);

    switch (filter) {
      case 'Semua':
        return true;
      case 'Menunggu':
        return status == 'menunggu';
      case 'Ditolak':
        return status == 'ditolak';
      case 'Diterima':
        return status == 'disetujui';
      case 'Sedang Aktif':
        return status == 'disetujui' && _lombaStatus(item) == 'aktif';
      default:
        return false;
    }
  }

  // =========================================================
  // FILTER DAN JUMLAH DATA
  // =========================================================

  int _count(String category) {
    return _items.where((item) => _matchesFilter(item, category)).length;
  }

  List<Map<String, dynamic>> get _filteredItems {
    final list = _items
        .where((item) => _matchesFilter(item, _activeFilter))
        .toList();

    // Urutkan berdasarkan pengajuan terbaru.
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

  // =========================================================
  // INFORMASI PENYELENGGARA
  // =========================================================

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

  // =========================================================
  // INFORMASI KATEGORI LOMBA
  // =========================================================

  String _category(Map<String, dynamic> item) {
    final category = item['kategori'];

    if (category is Map) {
      final label = (category['nama_kategori'] ?? '').toString().trim();

      if (label.isNotEmpty) {
        return label;
      }
    }

    return 'Tanpa kategori';
  }

  String _shortDate(dynamic value) {
    if (value == null) {
      return 'Belum diatur';
    }

    final date = DateTime.tryParse(value.toString());

    if (date == null) {
      return 'Belum diatur';
    }

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

  // =========================================================
  // BADGE STATUS
  // =========================================================

  Widget _statusBadge(Map<String, dynamic> item) {
    final category = _itemCategory(item);

    late Color color;
    late Color background;
    late String label;

    switch (category) {
      case 'Menunggu':
        color = const Color(0xFFB66B06);
        background = const Color(0xFFFFF3DA);
        label = 'Menunggu';
        break;

      case 'Ditolak':
        color = const Color(0xFFC53B47);
        background = const Color(0xFFFFE9ED);
        label = 'Ditolak';
        break;

      case 'Diterima':
        color = const Color(0xFF18794E);
        background = const Color(0xFFE5F6ED);
        label = 'Diterima';
        break;

      case 'Sedang Aktif':
        color = const Color(0xFF3478E5);
        background = const Color(0xFFE8F1FF);
        label = 'Sedang Aktif';
        break;

      default:
        color = _muted;
        background = const Color(0xFFE3E9F1);
        label = category;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
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

  // =========================================================
  // DETAIL PENGAJUAN
  // =========================================================

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

  // =========================================================
  // POSTER CADANGAN
  // =========================================================

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
              Icon(_categoryIcon(category), color: _blue, size: 30),
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

  // =========================================================
  // KARTU LOMBA
  // =========================================================

  Widget _card(Map<String, dynamic> item) {
    final name = (item['nama_lomba'] ?? 'Lomba tanpa nama').toString();

    final category = _category(item);
    final eventDate = _shortDate(item['tanggal_pelaksanaan']);

    final posterUrl = ApiService.publicStorageUrl(
      item['poster_lomba']?.toString(),
    );

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
                // Poster lomba.
                Container(
                  width: 94,
                  height: 122,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F1FF),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: posterUrl == null
                      ? _posterFallback(category, eventDate)
                      : Image.network(
                          posterUrl,
                          width: 94,
                          height: 122,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              _posterFallback(category, eventDate),
                        ),
                ),

                const SizedBox(width: 14),

                // Informasi lomba.
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
                            Flexible(child: _statusBadge(item)),
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

  // =========================================================
  // KATEGORI FILTER BERBENTUK KAPSUL
  // =========================================================

  Widget _filter(String title) {
    final active = _activeFilter == title;
    final count = _count(title);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text('$title ($count)'),
        selected: active,
        onSelected: (_) {
          setState(() {
            _activeFilter = title;
          });
        },
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

  // =========================================================
  // RUANG NAVIGASI BAWAH
  // =========================================================

  double _navigationClearance(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return 120.0 + bottomInset;
  }

  // =========================================================
  // TAMPILAN KOSONG
  // =========================================================

  Widget _emptyState() {
    return ListView(
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
          _activeFilter == 'Semua'
              ? 'Belum ada pengajuan lomba.'
              : 'Tidak ada lomba dalam kategori $_activeFilter.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: _muted, fontSize: 12),
        ),
      ],
    );
  }

  // =========================================================
  // HEADER
  // =========================================================

  Widget _header() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE5EFFD), Color(0xFFF0F5FE)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(26)),
      ),
      child: Row(
        children: [
          Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.fact_check_rounded, color: _blue, size: 25),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pengajuan Lomba',
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
        ],
      ),
    );
  }

  // =========================================================
  // TAMPILAN ERROR
  // =========================================================

  Widget _errorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 36, color: _muted),
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
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final items = _filteredItems;

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header tanpa tombol refresh.
            _header(),

            const SizedBox(height: 16),

            // Lima kategori filter.
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: _filters.map(_filter).toList(),
              ),
            ),

            // Jumlah data sesuai filter.
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
              child: Text(
                '${items.length} lomba',
                style: const TextStyle(
                  color: _muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            // Daftar data.
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: _blue))
                  : _error != null
                  ? _errorState()
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
                              itemBuilder: (_, index) {
                                return _card(items[index]);
                              },
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}