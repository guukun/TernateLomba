import '../../design_system/tl_playful.dart';
import '../../widgets/app_feedback.dart';

import 'dart:async';

import 'package:flutter/material.dart';

import '../../widgets/competition_detail_poster.dart';

import 'package:url_launcher/url_launcher.dart';

import '../../config/appTheme.dart';
import '../../services/api_service.dart';
import '../chat/chatPage.dart';

/// Foto profil peserta jika tersedia; fallback ke inisial jika belum ada
/// atau URL foto tidak bisa dimuat.
Widget _avatarPeserta({
  required BuildContext context,
  required String nama,
  String? fotoUrl,
  double radius = 23,
}) {
  final initial = nama.trim().isEmpty ? '?' : nama.trim()[0].toUpperCase();
  final placeholder = Center(
    child: Text(
      initial,
      style: TextStyle(
        color: context.tl.primary,
        fontSize: radius * .75,
        fontWeight: FontWeight.w800,
      ),
    ),
  );

  final url = fotoUrl?.trim() ?? '';
  return CircleAvatar(
    radius: radius,
    backgroundColor: context.tl.cream,
    child: url.isEmpty
        ? placeholder
        : ClipOval(
            child: Image.network(
              url,
              width: radius * 2,
              height: radius * 2,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => placeholder,
            ),
          ),
  );
}

class KelolaLombaPage extends StatefulWidget {
  final String token;
  final Map<String, dynamic> pengajuan;

  const KelolaLombaPage({
    super.key,
    required this.token,
    required this.pengajuan,
  });

  @override
  State<KelolaLombaPage> createState() => _KelolaLombaPageState();
}

class _KelolaLombaPageState extends State<KelolaLombaPage>
    with WidgetsBindingObserver {
  Color get _primary => context.tl.primary;
  Color get _dark => context.tl.primaryDark;
  Color get _cream => context.tl.cream;
  Color get _background => context.tl.background;
  Color get _text => context.tl.navy;
  Color get _muted => context.tl.grey;
  Color get _border => context.tl.fieldBorder;

  Timer? _timer;
  bool _loading = true;
  bool _refreshing = false;
  String? _error;
  Map<String, dynamic> _lomba = {};
  List<Map<String, dynamic>> _peserta = [];
  final Set<int> _processing = {};

  int? get _idLomba {
    final raw = widget.pengajuan['lomba'];
    if (raw is Map) return int.tryParse(raw['id_lomba']?.toString() ?? '');
    return null;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
    if (_idLomba != null) {
      _timer = Timer.periodic(Duration(seconds: 5), (_) {
        if (_appResumed) _load(silent: true);
      });
    }
  }

  bool _appResumed = true;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appResumed = state == AppLifecycleState.resumed;
    if (_appResumed) _load(silent: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    final id = _idLomba;
    if (_refreshing || id == null) {
      if (id == null && mounted) {
        setState(() {
          _loading = false;
          _lomba = {...widget.pengajuan, 'status_lomba': 'Belum diterbitkan'};
        });
      }
      return;
    }

    _refreshing = true;
    if (!silent && mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final response = await ApiService.getPesertaPenyelenggara(
        token: widget.token,
        idLomba: id,
      );
      if (!mounted) return;

      final lomba = response['lomba'];
      final peserta = response['peserta'];
      setState(() {
        _lomba = lomba is Map
            ? Map<String, dynamic>.from(lomba)
            : <String, dynamic>{};
        _peserta = peserta is List
            ? peserta
                  .whereType<Map>()
                  .map((e) => Map<String, dynamic>.from(e))
                  .toList()
            : <Map<String, dynamic>>[];
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      if (!silent || _lomba.isEmpty) {
        setState(() {
          _loading = false;
          _error = e.toString().replaceFirst(RegExp(r'^Exception: ?'), '');
        });
      }
    } finally {
      _refreshing = false;
    }
  }

  int _intValue(String key) => int.tryParse(_lomba[key]?.toString() ?? '') ?? 0;

  String _statusPengajuan() =>
      widget.pengajuan['status_pengajuan']?.toString() ?? 'Menunggu';

  String _statusLomba() =>
      _lomba['status_lomba']?.toString() ??
      (widget.pengajuan['lomba'] is Map
          ? (widget.pengajuan['lomba'] as Map)['status_lomba']?.toString() ??
                'Belum diterbitkan'
          : 'Belum diterbitkan');

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'aktif':
      case 'diterima':
      case 'disetujui':
        return context.tl.green;
      case 'ditolak':
      case 'selesai':
        return context.tl.error;
      default:
        return context.tl.orange;
    }
  }

  Future<void> _reviewPeserta(Map<String, dynamic> peserta) async {
    final id = int.tryParse(peserta['id_pendaftaran']?.toString() ?? '');
    if (id == null) return;

    try {
      final detail = await ApiService.getDetailPesertaPenyelenggara(
        token: widget.token,
        idPendaftaran: id,
      );
      if (!mounted) return;

      // Tutup bottom sheet lebih dulu. Menampilkan notifikasi sebelum sheet
      // ditutup membuat Navigator.pop() menutup dialog notifikasi yang baru
      // muncul, bukan sheet review peserta.
      final decision = await AppPopup.customSheet<String>(
        context: context,
        builder: (sheetContext) => _ReviewPesertaSheet(
          detail: detail,
          canDecide:
              _statusLomba().toLowerCase() == 'aktif' &&
              (peserta['status_pendaftaran']?.toString().toLowerCase() ==
                  'menunggu'),
          onDecision: (value, note) => _decide(id, value, note),
        ),
      );

      if (!mounted || decision == null) return;
      // Pesan keberhasilan tampil setelah sheet tertutup, tanpa menunggu
      // refresh jaringan. Refresh berjalan terpisah dari indikator tombol.
      _message(
        decision == 'Diterima'
            ? 'Peserta berhasil diterima.'
            : 'Peserta berhasil ditolak.',
      );
      unawaited(_load(silent: true));
    } catch (e) {
      if (!mounted) return;
      _message(
        e.toString().replaceFirst(RegExp(r'^Exception: ?'), ''),
        error: true,
      );
    }
  }

  Future<void> _decide(int idPendaftaran, String decision, String? note) async {
    if (_processing.contains(idPendaftaran)) return;
    setState(() => _processing.add(idPendaftaran));
    try {
      // Pada beberapa koneksi respons PATCH tertahan walaupun Laravel sudah
      // menyimpan keputusan. Jangan biarkan spinner menunggu sampai 25 detik:
      // setelah 6 detik, verifikasi status langsung dari detail pendaftaran.
      try {
        await ApiService.putuskanPendaftaranPeserta(
          token: widget.token,
          idPendaftaran: idPendaftaran,
          keputusan: decision,
          catatan: note,
        ).timeout(const Duration(seconds: 6));
      } on TimeoutException {
        final expected = decision.trim().toLowerCase();
        var confirmed = false;
        // GET hanya memeriksa hasil; tidak mengirim keputusan kedua kalinya.
        for (var attempt = 0; attempt < 2 && !confirmed; attempt++) {
          try {
            final latest = await ApiService.getDetailPesertaPenyelenggara(
              token: widget.token,
              idPendaftaran: idPendaftaran,
            ).timeout(const Duration(seconds: 5));
            confirmed =
                (latest['status_pendaftaran']
                        ?.toString()
                        .trim()
                        .toLowerCase() ??
                    '') ==
                expected;
          } catch (_) {
            // Permintaan verifikasi juga bisa gagal sementara.
          }
          if (!confirmed && attempt == 0) {
            await Future<void>.delayed(const Duration(milliseconds: 500));
          }
        }
        if (!confirmed) {
          throw Exception(
            'Respons server terlambat dan keputusan belum bisa dikonfirmasi. '
            'Tutup panel lalu periksa status peserta sebelum mencoba lagi.',
          );
        }
        ApiService.notifyDataChanged();
      }
      // Tutup sheet dulu sebelum menampilkan popup sukses di parent.
    } finally {
      if (mounted) setState(() => _processing.remove(idPendaftaran));
    }
  }

  void _message(String message, {bool error = false}) {
    if (!mounted) return;
    AppNotification.message(
      context,
      message,
      type: error ? NotificationType.error : NotificationType.success,
    );
  }

  Widget _statusBadge(String status) {
    final color = _statusColor(status);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _statCard(String title, int value, IconData icon, Color color) {
    final p = context.tl;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
        decoration: TLPlayful.card(context, tint: color, radius: 21),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 12),
            Text(
              '$value',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w900,
                color: p.navy,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: p.grey,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title =
        _lomba['nama_lomba']?.toString() ??
        widget.pengajuan['nama_lomba']?.toString() ??
        'Lomba';
    final accepted = _intValue('jumlah_peserta_diterima');
    final pending = _intValue('jumlah_peserta_menunggu');
    final rejected = _intValue('jumlah_peserta_ditolak');
    final quota = _intValue('kuota_peserta');
    final progress = quota > 0 ? (accepted / quota).clamp(0.0, 1.0) : 0.0;
    final active = _statusLomba().toLowerCase() == 'aktif';

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        foregroundColor: _text,
        surfaceTintColor: _background,
        elevation: 0,
        title: Text(
          'Competition Management',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: _loading
            ? Center(child: CircularProgressIndicator(color: _primary))
            : RefreshIndicator(
                color: _primary,
                onRefresh: () => _load(),
                child: ListView(
                  padding: EdgeInsets.fromLTRB(18, 5, 18, 90),
                  children: [
                    TLPlayful.decoratedHeading(
                      context,
                      title: 'Lead your\ncompetition.',
                      subtitle: 'Kelola peserta dan detail lomba dalam satu ruang fokus.',
                      icon: Icons.insights_rounded,
                      accent: context.tl.orange,
                    ),
                    _buildLombaHeader(title),
                    if (_idLomba != null &&
                        _statusPengajuan().toLowerCase() == 'disetujui') ...[
                      SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatRoomPage(
                              token: widget.token,
                              room: {
                                'id_lomba': _idLomba,
                                'nama_lomba': title,
                                'status_lomba': _statusLomba(),
                                'is_penyelenggara': true,
                              },
                            ),
                          ),
                        ),
                        icon: Icon(Icons.forum_outlined),
                        label: Text('Buka Ruang Chat Peserta'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _primary,
                          minimumSize: Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ],
                    SizedBox(height: 16),
                    if (_error != null && _lomba.isEmpty)
                      _errorCard()
                    else ...[
                      if (_statusPengajuan().toLowerCase() != 'disetujui')
                        _noticeCard(
                          'Pengajuan ${_statusPengajuan().toLowerCase()}',
                          'Kelola peserta tersedia setelah lomba disetujui dan diterbitkan.',
                          Icons.info_outline_rounded,
                        )
                      else if (!active)
                        _noticeCard(
                          'Lomba ${_statusLomba().toLowerCase()}',
                          'Data peserta masih dapat dibaca. Review baru sudah ditutup.',
                          Icons.lock_outline_rounded,
                        ),
                      _buildQuotaCard(accepted, quota, progress),
                      SizedBox(height: 12),
                      Row(
                        children: [
                          _statCard(
                            'Menunggu',
                            pending,
                            Icons.schedule_rounded,
                            context.tl.orange,
                          ),
                          SizedBox(width: 8),
                          _statCard(
                            'Diterima',
                            accepted,
                            Icons.check_circle_outline_rounded,
                            context.tl.green,
                          ),
                          SizedBox(width: 8),
                          _statCard(
                            'Ditolak',
                            rejected,
                            Icons.cancel_outlined,
                            context.tl.error,
                          ),
                        ],
                      ),
                      SizedBox(height: 22),
                      if (pending > 0 && active)
                        Container(
                          margin: EdgeInsets.only(bottom: 14),
                          padding: EdgeInsets.symmetric(
                            horizontal: 13,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: _cream,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.fact_check_outlined,
                                color: _primary,
                                size: 19,
                              ),
                              SizedBox(width: 9),
                              Expanded(
                                child: Text(
                                  '$pending pendaftar perlu ditinjau',
                                  style: TextStyle(
                                    color: _text,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Peserta Terdaftar',
                              style: TextStyle(
                                color: _text,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 11,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: _cream,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${_peserta.length} pendaftar',
                              style: TextStyle(
                                color: _dark,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 13),
                      if (_peserta.isEmpty)
                        _noticeCard(
                          'Belum ada pendaftar',
                          'Pendaftaran yang masuk akan muncul di sini.',
                          Icons.people_outline_rounded,
                        )
                      else
                        ..._peserta.map(_participantCard),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildLombaHeader(String title) {
    final poster =
        _lomba['poster_url']?.toString() ??
        widget.pengajuan['poster_url']?.toString() ??
        '';
    final rawCategory = _lomba['kategori'] ?? widget.pengajuan['kategori'];
    final category = rawCategory is Map
        ? rawCategory['nama_kategori']?.toString() ?? 'Lomba'
        : (rawCategory?.toString() ?? 'Lomba');
    final date =
        _lomba['tanggal_pelaksanaan']?.toString() ??
        widget.pengajuan['tanggal_pelaksanaan']?.toString() ??
        '';
    final method =
        _lomba['metode_pelaksanaan']?.toString() ??
        widget.pengajuan['metode_pelaksanaan']?.toString() ??
        '';

    return Container(
      decoration: BoxDecoration(
        color: context.tl.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CompetitionDetailPoster(
            url: poster,
            radius: 0,
            fallback: Container(
              color: _cream,
              alignment: Alignment.center,
              child: Icon(
                Icons.emoji_events_rounded,
                color: _primary,
                size: 40,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: _text,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              height: 1.25,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            category,
                            style: TextStyle(color: _muted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 8),
                    _statusBadge(_statusLomba()),
                  ],
                ),
                if (date.isNotEmpty || method.isNotEmpty) ...[
                  SizedBox(height: 14),
                  Divider(height: 1, color: _border),
                  SizedBox(height: 12),
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      if (date.isNotEmpty)
                        _smallMeta(Icons.event_outlined, _dateLabel(date)),
                      if (method.isNotEmpty)
                        _smallMeta(Icons.place_outlined, method),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _dateLabel(String raw) {
    try {
      final date = DateTime.parse(raw);
      return '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (_) {
      return raw;
    }
  }

  Widget _smallMeta(IconData icon, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, color: _primary, size: 16),
      SizedBox(width: 6),
      Text(
        label,
        style: TextStyle(
          color: _muted,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );

  Widget _buildQuotaCard(int accepted, int quota, double progress) {
    final remaining = quota > 0 ? (quota - accepted).clamp(0, quota) : null;
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.tl.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.groups_2_outlined, color: _primary, size: 20),
              SizedBox(width: 9),
              Expanded(
                child: Text(
                  'Kapasitas Lomba',
                  style: TextStyle(
                    color: _text,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                quota > 0 ? '$accepted / $quota' : '$accepted diterima',
                style: TextStyle(
                  color: _primary,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          SizedBox(height: 13),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: quota > 0 ? progress : null,
              minHeight: 8,
              backgroundColor: _cream,
              color: _primary,
            ),
          ),
          SizedBox(height: 9),
          Text(
            remaining == null
                ? 'Progres hanya menghitung peserta yang diterima.'
                : remaining == 0
                ? 'Kuota sudah penuh.'
                : '$remaining tempat tersisa • dihitung dari peserta diterima',
            style: TextStyle(color: _muted, fontSize: 11, height: 1.45),
          ),
        ],
      ),
    );
  }

  Widget _participantCard(Map<String, dynamic> item) {
    final p = context.tl;
    final status = item['status_pendaftaran']?.toString() ?? 'Menunggu';
    final name = item['username']?.toString() ?? 'Peserta';
    final id = int.tryParse(item['id_pendaftaran']?.toString() ?? '');
    final date = item['tanggal_pendaftaran']?.toString() ?? '';
    final canReview =
        status.toLowerCase() == 'menunggu' &&
        _statusLomba().toLowerCase() == 'aktif';
    final accent = canReview ? p.orange : p.mint;
    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      decoration: TLPlayful.card(context, tint: accent, radius: 25),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(25),
          onTap: id == null ? null : () => _reviewPeserta(item),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                _avatarPeserta(
                  context: context,
                  nama: name,
                  fotoUrl: item['foto_profil_url']?.toString(),
                  radius: 24,
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: p.navy,
                          fontWeight: FontWeight.w900,
                          fontSize: 14.5,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Row(
                        children: [
                          Icon(Icons.schedule_rounded, color: p.grey, size: 14),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              date.isEmpty
                                  ? 'Tanggal tidak tersedia'
                                  : _dateLabel(date),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: p.grey, fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 9),
                      _statusBadge(status),
                    ],
                  ),
                ),
                const SizedBox(width: 7),
                Container(
                  width: 37,
                  height: 37,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: .17),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    canReview
                        ? Icons.rate_review_rounded
                        : Icons.arrow_forward_ios_rounded,
                    size: 17,
                    color: accent,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _noticeCard(String title, String body, IconData icon) {
    return Container(
      margin: EdgeInsets.only(bottom: 14),
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: _cream,
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _primary, size: 22),
          SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: _text,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  body,
                  style: TextStyle(color: _muted, fontSize: 11, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorCard() => _noticeCard(
    'Gagal memuat data',
    _error ?? 'Terjadi kesalahan.',
    Icons.cloud_off_outlined,
  );
}

class _ReviewPesertaSheet extends StatefulWidget {
  final Map<String, dynamic> detail;
  final bool canDecide;
  final Future<void> Function(String decision, String? note) onDecision;

  const _ReviewPesertaSheet({
    required this.detail,
    required this.canDecide,
    required this.onDecision,
  });

  @override
  State<_ReviewPesertaSheet> createState() => _ReviewPesertaSheetState();
}

class _ReviewPesertaSheetState extends State<_ReviewPesertaSheet> {
  Color get _primary => context.tl.primary;
  Color get _text => context.tl.navy;
  Color get _muted => context.tl.grey;
  Color get _cream => context.tl.cream;
  Color get _border => context.tl.fieldBorder;
  final TextEditingController _noteController = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _decide(String decision) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await widget.onDecision(decision, _noteController.text.trim());
      if (mounted) Navigator.of(context).pop(decision);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      AppNotification.message(
        context,
        e.toString().replaceFirst(RegExp(r'^Exception: ?'), ''),
        type: NotificationType.error,
      );
    }
  }

  Color _statusColor(String value) {
    switch (value.toLowerCase()) {
      case 'diterima':
        return context.tl.green;
      case 'ditolak':
        return context.tl.error;
      default:
        return context.tl.orange;
    }
  }

  Widget _pill(String status) {
    final color = _statusColor(status);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final answers = widget.detail['jawaban'] is List
        ? (widget.detail['jawaban'] as List)
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
        : <Map<String, dynamic>>[];
    final status =
        widget.detail['status_pendaftaran']?.toString() ?? 'Menunggu';
    final username = widget.detail['username']?.toString() ?? 'Peserta';
    final date = widget.detail['tanggal_pendaftaran']?.toString() ?? '';
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * .92,
        ),
        padding: EdgeInsets.fromLTRB(18, 10, 18, bottomInset + 12),
        decoration: BoxDecoration(
          color: context.tl.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: _border,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            SizedBox(height: 15),
            Row(
              children: [
                _avatarPeserta(
                  context: context,
                  nama: username,
                  fotoUrl: widget.detail['foto_profil_url']?.toString(),
                  radius: 24,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        username,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _text,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        widget.detail['nama_lomba']?.toString() ??
                            'Pendaftaran peserta',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: _muted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Tutup',
                  onPressed: _busy ? null : () => Navigator.pop(context),
                  icon: Icon(Icons.close_rounded, color: _text),
                ),
              ],
            ),
            SizedBox(height: 13),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                children: [
                  Container(
                    padding: EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: context.tl.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Status pendaftaran',
                                style: TextStyle(
                                  color: _text,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            _pill(status),
                          ],
                        ),
                        if (date.isNotEmpty) ...[
                          SizedBox(height: 9),
                          Row(
                            children: [
                              Icon(
                                Icons.event_outlined,
                                color: _muted,
                                size: 16,
                              ),
                              SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  date.replaceFirst('T', ' ').split('.').first,
                                  style: TextStyle(color: _muted, fontSize: 11),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(height: 17),
                  Row(
                    children: [
                      Icon(
                        Icons.description_outlined,
                        color: _primary,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Jawaban formulir',
                          style: TextStyle(
                            color: _text,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Text(
                        '${answers.length} isian',
                        style: TextStyle(color: _muted, fontSize: 11),
                      ),
                    ],
                  ),
                  SizedBox(height: 11),
                  if (answers.isEmpty)
                    Container(
                      padding: EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: context.tl.surface,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: _border),
                      ),
                      child: Text(
                        'Belum ada jawaban yang tersimpan.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: _muted, fontSize: 12),
                      ),
                    )
                  else
                    ...answers.asMap().entries.map(
                      (entry) => _answerCard(entry.value, entry.key + 1),
                    ),
                  if (widget.canDecide) ...[
                    SizedBox(height: 14),
                    Text(
                      'Keputusan penyelenggara',
                      style: TextStyle(
                        color: _text,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Periksa isian dan lampiran sebelum menentukan keputusan.',
                      style: TextStyle(
                        color: _muted,
                        fontSize: 11,
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: 14),
                    Text(
                      'Catatan untuk peserta (opsional)',
                      style: TextStyle(
                        color: _text,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 7),
                    TextField(
                      controller: _noteController,
                      minLines: 2,
                      maxLines: 4,
                      maxLength: 2000,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Tulis arahan, informasi pembayaran, atau alasan keputusan…',
                        hintStyle: TextStyle(color: _muted, fontSize: 12),
                        helperText:
                            'Catatan ikut dikirim melalui notifikasi peserta.',
                        helperStyle: TextStyle(color: _muted, fontSize: 11),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: EdgeInsets.all(14),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: _border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: _primary),
                        ),
                      ),
                    ),
                  ] else ...[
                    SizedBox(height: 10),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _cream,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.lock_outline_rounded,
                            size: 18,
                            color: _primary,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Keputusan sudah diproses atau masa review ditutup.',
                              style: TextStyle(color: _muted, fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (widget.canDecide) ...[
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _busy ? null : () => _decide('Ditolak'),
                      icon: Icon(Icons.close_rounded, size: 17),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: context.tl.error,
                        side: BorderSide(color: context.tl.statusBadBg),
                        minimumSize: Size.fromHeight(49),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                      ),
                      label: Text(
                        'Tolak',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _busy ? null : () => _decide('Diterima'),
                      icon: _busy
                          ? SizedBox(
                              width: 15,
                              height: 15,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(Icons.check_rounded, size: 17),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: Colors.white,
                        minimumSize: Size.fromHeight(49),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                      ),
                      label: Text(
                        'Terima',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _answerCard(Map<String, dynamic> answer, int number) {
    final name = answer['nama_field']?.toString() ?? 'Informasi';
    final type = answer['tipe_field']?.toString() ?? 'Text';
    final value = answer['jawaban']?.toString() ?? '';
    final fileUrl = answer['file_url']?.toString() ?? '';
    final fileName = answer['nama_file']?.toString() ?? 'Lihat berkas';
    final isFile = type.toLowerCase() == 'file';
    return Container(
      margin: EdgeInsets.only(bottom: 9),
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.tl.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _cream,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Text(
              '$number',
              style: TextStyle(
                color: _primary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: _muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 6),
                if (isFile && fileUrl.isNotEmpty)
                  InkWell(
                    onTap: () async {
                      final uri = Uri.tryParse(fileUrl);
                      if (uri != null) {
                        final launched = await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        );
                        if (!mounted) return;

                        if (!launched) {
                          AppNotification.message(
                            context,
                            'Berkas tidak dapat dibuka.',
                            type: NotificationType.error,
                          );
                        }
                      }
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 11,
                      ),
                      decoration: BoxDecoration(
                        color: _cream,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.attach_file_rounded,
                            color: _primary,
                            size: 18,
                          ),
                          SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              fileName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: _primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.open_in_new_rounded,
                            color: _primary,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  )
                else if (isFile)
                  Text(
                    'Lampiran tidak tersedia',
                    style: TextStyle(color: _muted, fontSize: 12),
                  )
                else
                  SelectableText(
                    value.trim().isEmpty ? 'Tidak diisi' : value,
                    style: TextStyle(
                      color: _text,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.45,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}