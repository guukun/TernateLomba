import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../config/appTheme.dart';
import '../../services/api_service.dart';

class DetailPengajuanPage extends StatelessWidget {
  final String token;
  final Map<String, dynamic> item;

  const DetailPengajuanPage({
    super.key,
    required this.token,
    required this.item,
  });

  // ==========================================
  // WARNA APP THEME
  // ==========================================

  static const Color _primary = AppColors.primary;
  static const Color _primaryDark = AppColors.primaryDark;
  static const Color _cream = AppColors.cream;
  static const Color _creamLight = AppColors.creamLight;
  static const Color _creamDark = AppColors.creamDark;
  static const Color _background = AppColors.background;
  static const Color _text = AppColors.navy;
  static const Color _muted = AppColors.grey;
  static const Color _outline = AppColors.fieldBorder;

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
    final value = item[key];

    if (value == null || value.toString().trim().isEmpty) {
      return fallback;
    }

    return value.toString();
  }

  String _tanggal(String key) {
    final raw = item[key]?.toString();

    if (raw == null || raw.trim().isEmpty) {
      return 'Belum diisi';
    }

    return _formatDate(raw);
  }

  String _kategori() {
    final raw = item['kategori'];

    if (raw is Map) {
      final nama = raw['nama_kategori']?.toString();

      if (nama != null && nama.trim().isNotEmpty) {
        return nama;
      }
    }

    return 'Kategori tidak tersedia';
  }

  String _biaya() {
    final value = num.tryParse(item['biaya']?.toString() ?? '');

    if (value == null) return 'Belum diisi';

    if (value == 0) return 'Gratis';

    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(value);
  }

  String _kuota() {
    final value = item['kuota_peserta'];

    if (value == null || value.toString().trim().isEmpty) {
      return 'Tidak dibatasi';
    }

    return '${value.toString()} peserta';
  }

  String _getPenyelenggara() {
    if (item['penyelenggara'] is Map) {
      final organizer = item['penyelenggara'] as Map;

      return (organizer['username'] ?? organizer['nama'] ?? 'Tidak diketahui')
          .toString();
    }

    return item['penyelenggara']?.toString() ?? 'Tidak diketahui';
  }

  // ==========================================
  // POSTER LOMBA
  // ==========================================

  Widget _poster(String? posterUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: posterUrl == null
            ? _posterFallback()
            : Image.network(
                posterUrl,
                width: double.infinity,
                fit: BoxFit.cover,
                cacheWidth: 1000,
                gaplessPlayback: true,
                errorBuilder: (_, _, _) => _posterFallback(),
              ),
      ),
    );
  }

  Widget _posterFallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.creamLight, AppColors.cream],
        ),
      ),
      child: const Center(
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
      item['poster_lomba']?.toString(),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Poster

          _poster(posterUrl),

          const SizedBox(height: 18),

          // Kategori
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: _cream,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              _kategori(),
              style: const TextStyle(
                color: _primary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Nama lomba
          Text(
            _value('nama_lomba', fallback: 'Nama lomba tidak tersedia'),
            style: const TextStyle(
              color: _text,
              fontSize: 21,
              fontWeight: FontWeight.w800,
              height: 1.3,
            ),
          ),

          const SizedBox(height: 10),

          // Penyelenggara
          Row(
            children: [
              const Icon(
                Icons.account_balance_outlined,
                size: 17,
                color: _primary,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  _getPenyelenggara(),
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Deskripsi
          _sectionHeading('Deskripsi Lomba', Icons.description_outlined),

          const SizedBox(height: 10),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _creamLight,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: _creamDark),
            ),
            child: Text(
              _value('deskripsi'),
              style: const TextStyle(color: _muted, fontSize: 13, height: 1.65),
            ),
          ),

          const SizedBox(height: 22),

          // Detail informasi
          _sectionHeading('Informasi Pelaksanaan', Icons.event_note_rounded),

          const SizedBox(height: 15),

          _infoRow(
            'Biaya Pendaftaran',
            _biaya(),
            icon: Icons.payments_outlined,
            isFree: _biaya() == 'Gratis',
          ),

          _infoDivider(),

          _infoRow(
            'Batas Pendaftaran',
            _tanggal('batas_pendaftaran'),
            icon: Icons.event_available_outlined,
          ),

          _infoDivider(),

          _infoRow(
            'Tanggal Pelaksanaan',
            _tanggal('tanggal_pelaksanaan'),
            icon: Icons.calendar_month_outlined,
          ),

          _infoDivider(),

          _infoRow('Total Kuota', _kuota(), icon: Icons.groups_outlined),

          _infoDivider(),

          _infoRow(
            'Kontak Panitia',
            _value('kontak_penyelenggara'),
            icon: Icons.phone_outlined,
          ),

          _infoDivider(),

          _infoRow(
            'Lokasi',
            _value('lokasi_pendaftaran'),
            icon: Icons.location_on_outlined,
          ),

          _infoDivider(),

          _infoRow(
            'Hadiah',
            _value('hadiah'),
            icon: Icons.emoji_events_outlined,
          ),

          _infoDivider(),

          _infoRow(
            'Persyaratan',
            _value('persyaratan'),
            icon: Icons.checklist_rounded,
          ),
        ],
      ),
    );
  }

  // ==========================================
  // DEKORASI KARTU
  // ==========================================

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(23),
      border: Border.all(color: _outline),
      boxShadow: [
        BoxShadow(
          color: _primaryDark.withValues(alpha: 0.035),
          blurRadius: 16,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }

  // ==========================================
  // JUDUL BAGIAN
  // ==========================================

  Widget _sectionHeading(String title, IconData icon) {
    return Row(
      children: [
        Container(
          width: 35,
          height: 35,
          decoration: BoxDecoration(
            color: _cream,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: _primary, size: 19),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: _text,
              fontSize: 15,
              fontWeight: FontWeight.w800,
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
      padding: const EdgeInsets.symmetric(vertical: 11),
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

          const SizedBox(width: 11),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  value,
                  style: TextStyle(
                    color: isFree ? AppColors.green : _text,
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
    return const Divider(color: _outline, height: 1, thickness: 0.8);
  }

  // ==========================================
  // FORMULIR PENDAFTARAN PESERTA
  // ==========================================

  Widget _buildFormulirCard(BuildContext context) {
    final raw = item['form_fields'];

    final fields = raw is List ? raw.whereType<Map>().toList() : <Map>[];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeading(
            'Formulir Pendaftaran Peserta',
            Icons.assignment_outlined,
          ),

          const SizedBox(height: 8),

          const Text(
            'Daftar informasi yang harus diisi peserta ketika mendaftar lomba.',
            style: TextStyle(color: _muted, fontSize: 12, height: 1.5),
          ),

          const SizedBox(height: 17),

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
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: _creamLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _creamDark),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: _muted, fontSize: 12, height: 1.5),
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

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
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
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),

          const SizedBox(width: 11),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nama,
                  style: const TextStyle(
                    color: _text,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  'Tipe: $tipe',
                  style: const TextStyle(color: _muted, fontSize: 11),
                ),
              ],
            ),
          ),

          const SizedBox(width: 7),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            decoration: BoxDecoration(
              color: wajib ? const Color(0xFFFFEEEE) : _cream,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              wajib ? 'Wajib' : 'Opsional',
              style: TextStyle(
                color: wajib ? AppColors.error : _primary,
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
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 25),
      decoration: const BoxDecoration(
        color: _primaryDark,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(27)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Material(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(13),
                child: InkWell(
                  borderRadius: BorderRadius.circular(13),
                  onTap: () => Navigator.pop(context),
                  child: const SizedBox(
                    width: 42,
                    height: 42,
                    child: Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                      size: 21,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 13),

              const Expanded(
                child: Text(
                  'Detail Pengajuan',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: _cream,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
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

          const SizedBox(height: 20),

          const Text(
            'TINJAUAN PENGAJUAN',
            style: TextStyle(
              color: _cream,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),

          const SizedBox(height: 7),

          const Text(
            'Periksa informasi lomba sebelum mengambil keputusan.',
            style: TextStyle(
              color: Color(0xFFE2EAF3),
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TOMBOL KEPUTUSAN
  // ==========================================

  Widget _buildBottomActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(top: BorderSide(color: _outline)),
        boxShadow: [
          BoxShadow(
            color: _primaryDark.withValues(alpha: 0.06),
            blurRadius: 15,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  _showRejectDialog(context);
                },
                icon: const Icon(Icons.close_rounded, size: 18),
                label: const Text('Tolak'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFFE8CACA), width: 1.2),
                  minimumSize: const Size(0, 50),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 11),

            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  _showApproveDialog(context);
                },
                icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                label: const Text('Setujui', maxLines: 1),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 50),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
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

  Future<void> _showDecisionDialog(
    BuildContext context,
    String keputusan,
  ) async {
    final idPengajuan = int.tryParse(item['id_pengajuan']?.toString() ?? '');

    if (idPengajuan == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ID pengajuan tidak valid.')),
      );
      return;
    }

    final disetujui = keputusan == 'Disetujui';

    bool sedangMengirim = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              titlePadding: const EdgeInsets.fromLTRB(22, 22, 22, 10),
              contentPadding: const EdgeInsets.fromLTRB(22, 5, 22, 10),
              actionsPadding: const EdgeInsets.fromLTRB(16, 5, 16, 16),

              // Ikon dialog
              title: Row(
                children: [
                  Container(
                    width: 43,
                    height: 43,
                    decoration: BoxDecoration(
                      color: disetujui
                          ? const Color(0xFFE7F4EC)
                          : const Color(0xFFFFEBEB),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(
                      disetujui
                          ? Icons.verified_rounded
                          : Icons.cancel_outlined,
                      color: disetujui ? AppColors.green : AppColors.error,
                      size: 23,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Text(
                      disetujui ? 'Setujui Pengajuan' : 'Tolak Pengajuan',
                      style: const TextStyle(
                        color: _text,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),

              content: Text(
                disetujui
                    ? 'Apakah Anda yakin ingin menyetujui pengajuan lomba ini?'
                    : 'Apakah Anda yakin ingin menolak pengajuan lomba ini?',
                style: const TextStyle(
                  color: _muted,
                  fontSize: 13,
                  height: 1.6,
                ),
              ),

              actions: [
                TextButton(
                  onPressed: sedangMengirim
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text('Batal'),
                ),

                ElevatedButton(
                  onPressed: sedangMengirim
                      ? null
                      : () async {
                          setDialogState(() {
                            sedangMengirim = true;
                          });

                          try {
                            await ApiService.putuskanPengajuanLomba(
                              token: token,
                              idPengajuan: idPengajuan,
                              keputusan: keputusan,
                            );

                            if (!dialogContext.mounted || !context.mounted) {
                              return;
                            }

                            final messenger = ScaffoldMessenger.of(context);

                            // Tutup dialog.

                            Navigator.pop(dialogContext);

                            // Kembali ke daftar pengajuan.
                            // Nilai true memicu refresh halaman sebelumnya.

                            Navigator.pop(context, true);

                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  disetujui
                                      ? 'Pengajuan berhasil disetujui.'
                                      : 'Pengajuan berhasil ditolak.',
                                ),
                                backgroundColor: disetujui
                                    ? AppColors.green
                                    : AppColors.error,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(13),
                                ),
                              ),
                            );
                          } catch (error) {
                            if (!dialogContext.mounted) return;

                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Gagal memproses pengajuan: $error',
                                ),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          } finally {
                            if (dialogContext.mounted) {
                              setDialogState(() {
                                sedangMengirim = false;
                              });
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: disetujui ? _primary : AppColors.error,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: sedangMengirim
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(disetujui ? 'Setujui' : 'Tolak'),
                ),
              ],
            );
          },
        );
      },
    );
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
          // Header

          _buildHeader(context),

          // Konten yang dapat di-scroll
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLombaCard(context),

                  const SizedBox(height: 16),

                  _buildFormulirCard(context),

                  const SizedBox(height: 15),
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
