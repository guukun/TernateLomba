import '../../design_system/tl_playful.dart';
import '../../widgets/app_feedback.dart';

import 'package:flutter/material.dart';

import '../../widgets/competition_detail_poster.dart';

import 'package:intl/intl.dart';

import '../../config/appTheme.dart';
import '../../services/api_service.dart';

class DetailPengajuanPage extends StatefulWidget {
  final String token;
  final Map<String, dynamic> item;

  const DetailPengajuanPage({
    super.key,
    required this.token,
    required this.item,
  });

  @override
  State<DetailPengajuanPage> createState() => _DetailPengajuanPageState();
}

class _DetailPengajuanPageState extends State<DetailPengajuanPage> {
  String _statusPengajuan = 'Menunggu';
  bool _decisionChanged = false;

  bool get _isPending => _statusPengajuan.trim().toLowerCase() == 'menunggu';

  @override
  void initState() {
    super.initState();
    _statusPengajuan =
        widget.item['status_pengajuan']?.toString() ?? 'Menunggu';
  }

  // ==========================================
  // WARNA APP THEME
  // ==========================================

  Color get _primary => context.tl.primary;
  Color get _primaryDark => context.tl.primaryDark;
  Color get _cream => context.tl.cream;
  Color get _creamLight => context.tl.creamLight;
  Color get _creamDark => context.tl.creamDark;
  Color get _background => context.tl.background;
  Color get _text => context.tl.navy;
  Color get _muted => context.tl.grey;
  Color get _outline => context.tl.fieldBorder;

  // ==========================================
  // FORMAT DATA
  // ==========================================

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd MMMM yyyy', 'id_ID').format(date);
    } catch (_) {
      return dateString;
    }
  }

  String _value(String key, {String fallback = 'Belum diisi'}) {
    final value = widget.item[key];

    if (value == null || value.toString().trim().isEmpty) {
      return fallback;
    }

    return value.toString();
  }

  String _tanggal(String key) {
    final raw = widget.item[key]?.toString();

    if (raw == null || raw.trim().isEmpty) {
      return 'Belum diisi';
    }

    return _formatDate(raw);
  }

  String _kategori() {
    final raw = widget.item['kategori'];

    if (raw is Map) {
      final nama = raw['nama_kategori']?.toString();

      if (nama != null && nama.trim().isNotEmpty) {
        return nama;
      }
    }

    return 'Kategori tidak tersedia';
  }

  String _biaya() {
    final value = num.tryParse(widget.item['biaya']?.toString() ?? '');

    if (value == null) return 'Belum diisi';

    if (value == 0) return 'Gratis';

    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(value);
  }

  String _kuota() {
    final value = widget.item['kuota_peserta'];

    if (value == null || value.toString().trim().isEmpty) {
      return 'Tidak dibatasi';
    }

    return '${value.toString()} peserta';
  }

  String _getPenyelenggara() {
    if (widget.item['penyelenggara'] is Map) {
      final organizer = widget.item['penyelenggara'] as Map;

      return (organizer['username'] ?? organizer['nama'] ?? 'Tidak diketahui')
          .toString();
    }

    return widget.item['penyelenggara']?.toString() ?? 'Tidak diketahui';
  }

  // ==========================================
  // POSTER LOMBA
  // ==========================================

  Widget _poster(String? posterUrl) {
    return CompetitionDetailPoster(url: posterUrl, fallback: _posterFallback());
  }

  Widget _posterFallback() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [context.tl.creamLight, context.tl.cream],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events_rounded, color: _primary, size: 48),
            SizedBox(height: 10),
            Text(
              'POSTER LOMBA',
              style: TextStyle(
                color: _primary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // KARTU INFORMASI LOMBA
  // ==========================================

  Widget _buildLombaCard(BuildContext context) {
    final posterUrl = ApiService.publicStorageUrl(
      widget.item['poster_lomba']?.toString(),
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Poster

          _poster(posterUrl),

          SizedBox(height: 18),

          // Kategori
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: _cream,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              _kategori(),
              style: TextStyle(
                color: _primary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),

          SizedBox(height: 12),

          // Nama lomba
          Text(
            _value('nama_lomba', fallback: 'Nama lomba tidak tersedia'),
            style: TextStyle(
              color: _text,
              fontSize: 21,
              fontWeight: FontWeight.w800,
              height: 1.3,
            ),
          ),

          SizedBox(height: 10),

          // Penyelenggara
          Row(
            children: [
              Icon(Icons.account_balance_outlined, size: 17, color: _primary),
              SizedBox(width: 7),
              Expanded(
                child: Text(
                  _getPenyelenggara(),
                  style: TextStyle(
                    color: _muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 20),

          // Deskripsi
          _sectionHeading('Deskripsi Lomba', Icons.description_outlined),

          SizedBox(height: 10),

          Container(
            width: double.infinity,
            padding: EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _creamLight,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: _creamDark),
            ),
            child: Text(
              _value('deskripsi'),
              style: TextStyle(color: _muted, fontSize: 13, height: 1.65),
            ),
          ),

          SizedBox(height: 22),

          // Detail informasi
          _sectionHeading('Informasi Pelaksanaan', Icons.event_note_rounded),

          SizedBox(height: 15),

          _infoRow(
            'Mulai Pendaftaran',
            _tanggal('tanggal_mulai_pendaftaran'),
            icon: Icons.event_available_outlined,
          ),

          _infoDivider(),

          _infoRow(
            'Batas Pendaftaran',
            _tanggal('batas_pendaftaran'),
            icon: Icons.event_busy_outlined,
          ),

          _infoDivider(),

          _infoRow(
            'Tanggal Pelaksanaan',
            _tanggal('tanggal_pelaksanaan'),
            icon: Icons.calendar_month_outlined,
          ),

          _infoDivider(),

          _infoRow(
            'Metode Pelaksanaan',
            _value('metode_pelaksanaan'),
            icon: Icons.public_outlined,
          ),

          _infoDivider(),

          _infoRow(
            _value('metode_pelaksanaan', fallback: '').toLowerCase() == 'online'
                ? 'Platform / Tautan'
                : 'Tempat Pelaksanaan',
            _value(
              'detail_pelaksanaan',
              fallback: _value('lokasi_pendaftaran'),
            ),
            icon: Icons.location_on_outlined,
          ),

          _infoDivider(),

          _infoRow(
            'Biaya Pendaftaran',
            _biaya(),
            icon: Icons.payments_outlined,
            isFree: _biaya() == 'Gratis',
          ),

          _infoDivider(),

          _infoRow('Total Kuota', _kuota(), icon: Icons.groups_outlined),
        ],
      ),
    );
  }

  // ==========================================
  // INFORMASI TAMBAHAN SEMI-DINAMIS
  // ==========================================

  Widget _buildAdditionalInfoCard() {
    final raw = widget.item['informasi_tambahan'];
    final rows = raw is List ? raw.whereType<Map>().toList() : <Map>[];
    if (rows.isEmpty) return SizedBox.shrink();

    final groups = <String, List<Map>>{};
    for (final row in rows) {
      final header = row['kelompok_informasi']?.toString().trim();
      final label = row['label_informasi']?.toString().trim();
      final value = row['nilai_informasi']?.toString().trim();
      if (header == null ||
          header.isEmpty ||
          label == null ||
          label.isEmpty ||
          value == null ||
          value.isEmpty) {
        continue;
      }
      groups.putIfAbsent(header, () => []).add(row);
    }
    if (groups.isEmpty) return SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeading(
            'Informasi Tambahan',
            Icons.playlist_add_check_circle_outlined,
          ),
          SizedBox(height: 14),
          for (final group in groups.entries) ...[
            Text(
              group.key,
              style: TextStyle(
                color: _primary,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 5),
            for (var index = 0; index < group.value.length; index++) ...[
              _infoRow(
                group.value[index]['label_informasi']?.toString() ?? '-',
                group.value[index]['nilai_informasi']?.toString() ?? '-',
                icon: Icons.info_outline_rounded,
              ),
              if (index != group.value.length - 1) _infoDivider(),
            ],
            SizedBox(height: 9),
          ],
        ],
      ),
    );
  }

  // ==========================================
  // DEKORASI KARTU
  // ==========================================

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: context.tl.surface,
      borderRadius: BorderRadius.circular(23),
      border: Border.all(color: _outline),
      boxShadow: [
        BoxShadow(
          color: _primaryDark.withValues(alpha: 0.035),
          blurRadius: 16,
          offset: Offset(0, 5),
        ),
      ],
    );
  }

  // ==========================================
  // JUDUL BAGIAN
  // ==========================================

  Widget _sectionHeading(String title, IconData icon) {
    final p = context.tl;
    return Row(
      children: [
        Container(
          width: 43,
          height: 43,
          decoration: BoxDecoration(
            color: p.lavender.withValues(alpha: .19),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: p.lavender, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: p.navy,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // BARIS INFORMASI
  // ==========================================

  Widget _infoRow(
    String label,
    String value, {
    required IconData icon,
    bool isFree = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: _creamLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: _primary, size: 17),
          ),

          SizedBox(width: 11),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: _muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                SizedBox(height: 5),

                Text(
                  value,
                  style: TextStyle(
                    color: isFree ? context.tl.green : _text,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoDivider() {
    return Divider(color: _outline, height: 1, thickness: 0.8);
  }

  // ==========================================
  // FORMULIR PENDAFTARAN PESERTA
  // ==========================================

  Widget _buildFormulirCard(BuildContext context) {
    final raw = widget.item['form_fields'];

    final fields = raw is List ? raw.whereType<Map>().toList() : <Map>[];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeading(
            'Formulir Pendaftaran Peserta',
            Icons.assignment_outlined,
          ),

          SizedBox(height: 8),

          Text(
            'Daftar informasi yang harus diisi peserta ketika mendaftar lomba.',
            style: TextStyle(color: _muted, fontSize: 12, height: 1.5),
          ),

          SizedBox(height: 17),

          if (raw is! List)
            _formEmpty(
              Icons.info_outline_rounded,
              'Daftar field belum tersedia dari API. Muat ulang setelah backend diperbarui.',
            ),

          if (raw is List && fields.isEmpty)
            _formEmpty(
              Icons.assignment_late_outlined,
              'Pengajuan ini belum memiliki field pendaftaran. Periksa sebelum menyetujui.',
            ),

          for (var i = 0; i < fields.length; i++) _formFieldItem(fields[i], i),
        ],
      ),
    );
  }

  Widget _formEmpty(IconData icon, String message) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: _creamLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _creamDark),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _primary, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: _muted, fontSize: 12, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _formFieldItem(Map field, int index) {
    final nama = field['nama_field']?.toString() ?? 'Tanpa nama';

    final tipe = field['tipe_field']?.toString() ?? 'Tidak diketahui';

    final wajib =
        field['wajib'] == true ||
        field['wajib'] == 1 ||
        field['wajib']?.toString() == '1';
    final isDefault =
        field['is_default'] == true ||
        field['is_default'] == 1 ||
        field['is_default']?.toString() == '1';
    final placeholder = field['placeholder']?.toString() ?? '';
    final rawOptions = field['opsi_field'];
    final options = rawOptions is List
        ? rawOptions.map((option) => option.toString()).toList()
        : <String>[];

    return Container(
      margin: EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: _creamLight,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _creamDark),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${index + 1}',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),

          SizedBox(width: 11),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nama,
                  style: TextStyle(
                    color: _text,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                SizedBox(height: 6),

                Text(
                  'Tipe: $tipe${isDefault ? ' • Field bawaan' : ''}',
                  style: TextStyle(color: _muted, fontSize: 11),
                ),
                if (placeholder.trim().isNotEmpty) ...[
                  SizedBox(height: 4),
                  Text(
                    'Petunjuk: $placeholder',
                    style: TextStyle(color: _muted, fontSize: 10),
                  ),
                ],
                if (tipe.toLowerCase() == 'dropdown' && options.isNotEmpty) ...[
                  SizedBox(height: 4),
                  Text(
                    'Pilihan: ${options.join(', ')}',
                    style: TextStyle(color: _muted, fontSize: 10, height: 1.4),
                  ),
                ],
              ],
            ),
          ),

          SizedBox(width: 7),

          Container(
            padding: EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            decoration: BoxDecoration(
              color: wajib ? context.tl.statusBadBg : _cream,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              wajib ? 'Wajib' : 'Opsional',
              style: TextStyle(
                color: wajib ? context.tl.error : _primary,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // HEADER HALAMAN
  // ==========================================

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, 12, 20, 25),
      decoration: BoxDecoration(
        color: context.tl.background,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(27)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Material(
                color: context.tl.tabBg,
                borderRadius: BorderRadius.circular(13),
                child: InkWell(
                  borderRadius: BorderRadius.circular(13),
                  onTap: () => Navigator.pop(context, _decisionChanged),
                  child: SizedBox(
                    width: 42,
                    height: 42,
                    child: Icon(
                      Icons.arrow_back_rounded,
                      color: context.tl.navy,
                      size: 21,
                    ),
                  ),
                ),
              ),

              SizedBox(width: 13),

              Expanded(
                child: Text(
                  'Detail Pengajuan',
                  style: TextStyle(
                    color: context.tl.navy,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),

              Container(
                padding: EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                decoration: BoxDecoration(
                  color: context.tl.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'ADMIN',
                  style: TextStyle(
                    color: _primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 20),

          Text(
            'TINJAUAN PENGAJUAN',
            style: TextStyle(
              color: context.tl.primary,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),

          SizedBox(height: 7),

          Text(
            'Periksa informasi lomba sebelum mengambil keputusan.',
            style: TextStyle(color: context.tl.grey, fontSize: 12, height: 1.5),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TOMBOL KEPUTUSAN
  // ==========================================

  Widget _buildBottomActions(BuildContext context) {
    final locked = !_isPending;
    final approved = _statusPengajuan.trim().toLowerCase() == 'disetujui';
    final rejected = _statusPengajuan.trim().toLowerCase() == 'ditolak';

    return Container(
      padding: EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: context.tl.surface,
        border: Border(top: BorderSide(color: _outline)),
        boxShadow: [
          BoxShadow(
            color: _primaryDark.withValues(alpha: 0.06),
            blurRadius: 15,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (locked) ...[
              Container(
                width: double.infinity,
                margin: EdgeInsets.only(bottom: 12),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: approved
                      ? context.tl.statusGoodBg
                      : rejected
                      ? context.tl.statusBadBg
                      : context.tl.statusNeutralBg,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: approved
                        ? context.tl.statusGoodBg
                        : rejected
                        ? context.tl.statusBadBg
                        : _outline,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      approved
                          ? Icons.check_circle_rounded
                          : rejected
                          ? Icons.cancel_rounded
                          : Icons.lock_rounded,
                      color: approved
                          ? context.tl.green
                          : rejected
                          ? context.tl.error
                          : _muted,
                      size: 19,
                    ),
                    SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        approved
                            ? 'Pengajuan telah disetujui. Keputusan terkunci.'
                            : rejected
                            ? 'Pengajuan telah ditolak. Keputusan terkunci.'
                            : 'Pengajuan sudah diproses dan tidak dapat diubah.',
                        style: TextStyle(
                          color: approved
                              ? context.tl.green
                              : rejected
                              ? context.tl.error
                              : _muted,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: locked ? null : () => _showRejectDialog(context),
                    icon: Icon(Icons.close_rounded, size: 18),
                    label: Text(locked ? 'Terkunci' : 'Tolak'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: locked ? _muted : context.tl.error,
                      disabledForegroundColor: _muted,
                      backgroundColor: locked
                          ? context.tl.statusNeutralBg
                          : Colors.white,
                      side: BorderSide(
                        color: locked
                            ? context.tl.fieldBorder
                            : context.tl.statusBadBg,
                        width: 1.2,
                      ),
                      minimumSize: Size(0, 50),
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 11),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: locked
                        ? null
                        : () => _showApproveDialog(context),
                    icon: Icon(
                      locked
                          ? Icons.lock_rounded
                          : Icons.check_circle_outline_rounded,
                      size: 18,
                    ),
                    label: Text(
                      locked
                          ? (approved
                                ? 'Disetujui'
                                : rejected
                                ? 'Ditolak'
                                : 'Terkunci')
                          : 'Setujui',
                      maxLines: 1,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: locked
                          ? context.tl.fieldBorder
                          : _primary,
                      foregroundColor: locked ? _muted : Colors.white,
                      disabledBackgroundColor: context.tl.fieldBorder,
                      disabledForegroundColor: _muted,
                      minimumSize: Size(0, 50),
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // DIALOG KEPUTUSAN
  // ==========================================

  void _showApproveDialog(BuildContext context) {
    _showDecisionDialog(context, 'Disetujui');
  }

  void _showRejectDialog(BuildContext context) {
    _showDecisionDialog(context, 'Ditolak');
  }

  bool _decisionBusy = false;

  Future<void> _showDecisionDialog(
    BuildContext context,
    String keputusan,
  ) async {
    if (_decisionBusy) return;
    if (!_isPending) {
      AppNotification.message(
        context,
        'Pengajuan ini sudah diproses dan terkunci.',
        type: NotificationType.warning,
      );
      return;
    }

    final idPengajuan = int.tryParse(
      widget.item['id_pengajuan']?.toString() ?? '',
    );
    if (idPengajuan == null) {
      AppNotification.message(
        context,
        'ID pengajuan tidak valid.',
        type: NotificationType.error,
      );
      return;
    }

    final approved = keputusan == 'Disetujui';
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: approved ? 'Setujui pengajuan?' : 'Tolak pengajuan?',
      message: approved
          ? 'Lomba akan disetujui dan dapat dilanjutkan sesuai proses yang berlaku.'
          : 'Lomba akan ditolak. Periksa kembali detail pengajuan sebelum melanjutkan.',
      confirmText: approved ? 'Setujui' : 'Tolak',
      confirmColor: approved ? context.tl.green : context.tl.error,
    );
    if (!mounted || !context.mounted || confirmed != true || _decisionBusy) {
      return;
    }

    setState(() => _decisionBusy = true);
    AppPopup.loading(context, message: 'Memproses pengajuan...');
    String? failure;
    try {
      await ApiService.putuskanPengajuanLomba(
        token: widget.token,
        idPengajuan: idPengajuan,
        keputusan: keputusan,
      );
      if (!mounted || !context.mounted) return;

      setState(() {
        _statusPengajuan = keputusan;
        _decisionChanged = true;
      });
    } catch (error) {
      failure = error.toString().replaceFirst('Exception: ', '');
    } finally {
      if (mounted && context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (mounted) {
        setState(() => _decisionBusy = false);
      }
    }
    if (!mounted || !context.mounted) return;

    if (failure != null) {
      AppNotification.message(context, failure, type: NotificationType.error);
    } else {
      AppNotification.message(
        context,
        approved
            ? 'Pengajuan berhasil disetujui.'
            : 'Pengajuan berhasil ditolak.',
        type: NotificationType.success,
      );
    }
  }

  // ==========================================
  // BUILD UTAMA
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,

      body: Column(
        children: [
          // Header menjadi bagian dari area scroll, bukan elemen fixed.
          Expanded(
            child: SingleChildScrollView(
              physics: BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 25),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TLPlayful.decoratedHeading(
                          context,
                          title: 'Review before\nyou decide.',
                          subtitle: 'Tinjau detail dan formulir sebelum memberikan keputusan.',
                          icon: Icons.fact_check_rounded,
                          accent: context.tl.mint,
                        ),
                        _buildLombaCard(context),

                        SizedBox(height: 16),

                        _buildAdditionalInfoCard(),

                        SizedBox(height: 16),

                        _buildFormulirCard(context),

                        SizedBox(height: 15),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Tombol keputusan
          _buildBottomActions(context),
        ],
      ),
    );
  }
}