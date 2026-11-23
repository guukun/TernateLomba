import '../../widgets/app_feedback.dart';
import '../../widgets/competition_poster_card.dart';
import '../../widgets/competition_card_grid.dart';

import 'package:flutter/material.dart';

import '../../config/appTheme.dart';
import '../../design_system/tl_playful.dart';
import '../../services/api_service.dart';
import '../beranda/detailLombaPage.dart';

class FavoritPage extends StatefulWidget {
  final String token;

  const FavoritPage({super.key, required this.token});

  @override
  State<FavoritPage> createState() => _FavoritPageState();
}

class _FavoritPageState extends State<FavoritPage> {
  Color get _text => context.tl.navy;
  Color get _muted => context.tl.grey;

  List<Map<String, dynamic>> _items = [];
  final Set<int> _busyIds = <int>{};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
    ApiService.dataRevision.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    ApiService.dataRevision.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted && !_loading) _load(silent: true);
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent && mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final result = await ApiService.getFavorit(token: widget.token);
      if (!mounted) return;
      setState(() {
        _items = result;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (!silent) _error = e.toString();
      });
    }
  }

  Future<void> _remove(Map<String, dynamic> item) async {
    final id = int.tryParse('${item['id_lomba']}');
    if (id == null || _busyIds.contains(id)) return;
    setState(() => _busyIds.add(id));
    try {
      await ApiService.setFavorit(
        token: widget.token,
        idLomba: id,
        favorite: false,
      );
      if (!mounted) return;
      setState(() {
        _items.removeWhere((e) => '${e['id_lomba']}' == '$id');
      });
    } catch (e) {
      if (!mounted) return;
      AppNotification.message(
        context,
        'Tidak dapat menghapus favorit: $e',
        type: NotificationType.error,
      );
    } finally {
      if (mounted) setState(() => _busyIds.remove(id));
    }
  }

  Map<String, String> _toDetail(Map<String, dynamic> item) {
    final raw = item['tanggal_pelaksanaan']?.toString() ?? '';
    final dt = DateTime.tryParse(raw);
    final date = dt == null
        ? raw
        : '${dt.day.toString().padLeft(2, '0')}/'
              '${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    final price = double.tryParse('${item['biaya'] ?? 0}') ?? 0;
    final category = item['kategori'];
    final creator = item['penyelenggara'];
    return {
      'id_lomba': '${item['id_lomba']}',
      'id_pengajuan': '${item['id_pengajuan'] ?? ''}',
      'judul': '${item['nama_lomba'] ?? ''}',
      'kategori': category is Map ? '${category['nama_kategori'] ?? ''}' : '',
      'penyelenggara': creator is Map ? '${creator['username'] ?? ''}' : '',
      'poster_lomba': '${item['poster_lomba'] ?? ''}',
      'tanggal': date,
      'tanggal_pelaksanaan': raw,
      'batas_pendaftaran': '${item['batas_pendaftaran'] ?? ''}',
      'biaya': price <= 0 ? 'Gratis' : 'Rp${price.toStringAsFixed(0)}',
      'status_lomba': '${item['status_lomba'] ?? ''}',
      'kuota': '${item['kuota_peserta'] ?? '-'} peserta',
      'jumlah_peserta': '${item['jumlah_peserta'] ?? '0'}',
    };
  }

  String _formatPrice(Object? value) {
    final number = double.tryParse('${value ?? 0}') ?? 0;
    if (number <= 0) return 'Gratis';
    final digits = number.round().toString();
    final output = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) output.write('.');
      output.write(digits[i]);
    }
    return 'Rp$output';
  }

  Widget _summary() {
    return Padding(
      padding: EdgeInsets.fromLTRB(22, 23, 22, 15),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Your shortlist',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _text,
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 13, vertical: 7),
            decoration: BoxDecoration(
              color: context.tl.cream,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              '${_items.length} lomba',
              style: TextStyle(
                color: context.tl.primary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() => TLPlayful.empty(
    context,
    title: 'Belum ada lomba tersimpan',
    message: 'Temukan lomba yang menarik, lalu ketuk hati untuk menyimpannya.',
    icon: Icons.favorite_outline_rounded,
    accent: context.tl.coral,
  );

  Widget _errorState() {
    return Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        children: [
          SizedBox(height: 45),
          Icon(Icons.wifi_off_rounded, color: _muted, size: 42),
          SizedBox(height: 12),
          Text(
            'Favorit gagal dimuat',
            style: TextStyle(
              color: _text,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 10),
          Text(
            _error ?? '',
            textAlign: TextAlign.center,
            style: TextStyle(color: _muted, fontSize: 11),
          ),
          SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _load,
            icon: Icon(Icons.refresh_rounded),
            label: Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  Widget _card(Map<String, dynamic> item) {
    final id = int.tryParse('${item['id_lomba']}') ?? -1;
    final date = DateTime.tryParse('${item['tanggal_pelaksanaan'] ?? ''}');
    final dateText = date == null
        ? 'Jadwal menyusul'
        : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    final category = item['kategori'] is Map
        ? '${(item['kategori'] as Map)['nama_kategori'] ?? 'Kompetisi'}'
        : 'Kompetisi';
    final organizer = item['penyelenggara'] is Map
        ? '${(item['penyelenggara'] as Map)['username'] ?? ''}'
        : '';
    return CompetitionPosterCard(
      compact: true,
      height: 278,
      title: '${item['nama_lomba'] ?? 'Tanpa nama'}',
      posterUrl: ApiService.publicStorageUrl('${item['poster_lomba'] ?? ''}'),
      category: category,
      organizer: organizer,
      date: dateText,
      status: '${item['status_lomba'] ?? ''}'.toLowerCase() == 'aktif'
          ? null
          : '${item['status_lomba'] ?? ''}',
      meta: _formatPrice(item['biaya']),
      liveQuota:
          '${item['jumlah_peserta'] ?? '—'}/${item['kuota_peserta'] ?? '—'}',
      showFavorite: true,
      isFavorite: true,
      onFavorite: _busyIds.contains(id) ? null : () => _remove(item),
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                DetailLombaPage(lomba: _toDetail(item), token: widget.token),
          ),
        );
        if (mounted) _load(silent: true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.tl.background,
      body: RefreshIndicator(
        color: context.tl.primary,
        onRefresh: _load,
        child: ListView(
          padding: EdgeInsets.zero,
          physics: AlwaysScrollableScrollPhysics(),
          children: [
            TLPlayful.decoratedHeading(
              context,
              title: 'Koleksi Pilihanmu',
              subtitle: 'Semua lomba yang kamu suka ada di sini.',
              accent: context.tl.coral,
              icon: Icons.favorite_rounded,
            ),
            _summary(),
            if (_loading)
              Padding(
                padding: EdgeInsets.only(top: 65),
                child: Center(
                  child: CircularProgressIndicator(color: context.tl.primary),
                ),
              )
            else if (_error != null)
              _errorState()
            else if (_items.isEmpty)
              _emptyState()
            else
              Padding(
                padding: EdgeInsets.fromLTRB(22, 0, 22, 126),
                child: CompetitionCardGrid(
                  itemCount: _items.length,
                  itemBuilder: (_, index) => _card(_items[index]),
                ),
              ),
            if (_items.isEmpty) SizedBox(height: 130),
          ],
        ),
      ),
    );
  }
}
