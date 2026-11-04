import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../services/api_service.dart';

class DetailPengajuanPage extends StatelessWidget {
  final String token;
  final Map<String, dynamic> item;

  const DetailPengajuanPage({
    super.key,
    required this.token,
    required this.item,
  });

  static const _blue = Color(0xFF3478E5);

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd MMM yyyy', 'id_ID').format(date);
    } catch (e) {
      return dateString;
    }
  }

  String _value(String key, {String fallback = 'Belum diisi'}) {
    final value = item[key];
    if (value == null || value.toString().trim().isEmpty) return fallback;
    return value.toString();
  }

  String _tanggal(String key) {
    final raw = item[key]?.toString();
    if (raw == null || raw.trim().isEmpty) return 'Belum diisi';
    return _formatDate(raw);
  }

  String _kategori() {
    final raw = item['kategori'];
    if (raw is Map) {
      final nama = raw['nama_kategori']?.toString();
      if (nama != null && nama.trim().isNotEmpty) return nama;
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
    if (value == null || value.toString().trim().isEmpty)
      return 'Tidak dibatasi';
    return '${value.toString()} peserta';
  }

  String _getPenyelenggara() {
    if (item['penyelenggara'] is Map) {
      return (item['penyelenggara'] as Map)['username']?.toString() ??
          (item['penyelenggara'] as Map)['nama']?.toString() ??
          'Tidak diketahui';
    }
    return item['penyelenggara']?.toString() ?? 'Tidak diketahui';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A2E)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Ringkasan Pengajuan',
          style: TextStyle(
            color: Color(0xFF1A1A2E),
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLombaCard(context),
                  const SizedBox(height: 16),
                  _buildFormulirCard(context),
                ],
              ),
            ),
          ),
          _buildBottomActions(context),
        ],
      ),
    );
  }

  Widget _buildLombaCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (ApiService.publicStorageUrl(item['poster_lomba']?.toString()) != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    ApiService.publicStorageUrl(item['poster_lomba']?.toString())!,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFFEAF2FF),
                      child: const Icon(Icons.image_not_supported_outlined, color: _blue, size: 42),
                    ),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 88,
                    height: 88,
                    child: ApiService.publicStorageUrl(item['poster_lomba']?.toString()) == null
                        ? Container(
                            color: const Color(0xFFEAF2FF),
                            child: const Icon(
                              Icons.emoji_events_outlined,
                              color: _blue,
                              size: 34,
                            ),
                          )
                        : Image.network(
                            ApiService.publicStorageUrl(item['poster_lomba']?.toString())!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: const Color(0xFFEAF2FF),
                              child: const Icon(
                                Icons.image_not_supported_outlined,
                                color: _blue,
                                size: 34,
                              ),
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE3F2FD),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _kategori(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _blue,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '• ${_getPenyelenggara()}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF757575),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _value(
                          'nama_lomba',
                          fallback: 'Nama lomba tidak tersedia',
                        ),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _value('deskripsi'),
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF757575),
                  height: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _infoRow(
                  'Biaya Pendaftaran',
                  _biaya(),
                  isFree: _biaya() == 'Gratis',
                ),
                const SizedBox(height: 12),
                _infoRow('Batas Pendaftaran', _tanggal('batas_pendaftaran')),
                const SizedBox(height: 12),
                _infoRow('Pelaksanaan', _tanggal('tanggal_pelaksanaan')),
                const SizedBox(height: 12),
                _infoRow('Total Kuota', _kuota()),
                const SizedBox(height: 12),
                _infoRowWithIcon(
                  'Kontak Panitia',
                  _value('kontak_penyelenggara'),
                  Icons.phone,
                ),
                const SizedBox(height: 12),
                _infoRow('Lokasi', _value('lokasi_pendaftaran')),
                const SizedBox(height: 12),
                _infoRow('Hadiah', _value('hadiah')),
                const SizedBox(height: 12),
                _infoRow('Persyaratan', _value('persyaratan')),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool isFree = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Color(0xFF757575)),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isFree ? const Color(0xFF4CAF50) : const Color(0xFF1A1A2E),
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoRowWithIcon(String label, String value, IconData icon) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Color(0xFF757575)),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(icon, size: 16, color: _blue),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _blue,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFormulirCard(BuildContext context) {
    final raw = item['form_fields'];
    final fields = raw is List ? raw.whereType<Map>().toList() : <Map>[];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Formulir Pendaftaran Peserta',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          if (raw is! List)
            const Text(
              'Daftar field belum tersedia dari API. Muat ulang setelah backend diperbarui.',
            ),
          if (raw is List && fields.isEmpty)
            const Text(
              'Pengajuan ini belum memiliki field pendaftaran. Periksa sebelum menyetujui.',
            ),
          for (var i = 0; i < fields.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.list_alt_outlined, size: 18, color: _blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fields[i]['nama_field']?.toString() ?? 'Tanpa nama',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '${fields[i]['tipe_field'] ?? 'Tidak diketahui'} • '
                          '${fields[i]['wajib'] == true || fields[i]['wajib'] == 1 ? 'Wajib' : 'Opsional'}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF757575),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                _showRejectDialog(context);
              },
              icon: const Icon(Icons.close, size: 18),
              label: const Text('Tolak Pengajuan'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: Color(0xFFE0E0E0), width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                _showApproveDialog(context);
              },
              icon: const Icon(Icons.check_circle_outline, size: 18),
              label: const Text('Setujui Lomba'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _blue,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

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
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(disetujui ? 'Setujui Pengajuan' : 'Tolak Pengajuan'),
          content: Text(
            disetujui
                ? 'Apakah Anda yakin ingin menyetujui pengajuan lomba ini?'
                : 'Apakah Anda yakin ingin menolak pengajuan lomba ini?',
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
                      setDialogState(() => sedangMengirim = true);
                      try {
                        await ApiService.putuskanPengajuanLomba(
                          token: token,
                          idPengajuan: idPengajuan,
                          keputusan: keputusan,
                        );
                        if (!dialogContext.mounted || !context.mounted) return;
                        final messenger = ScaffoldMessenger.of(context);
                        Navigator.pop(
                          dialogContext,
                        ); // Tutup dialog setelah API berhasil.
                        Navigator.pop(
                          context,
                          true,
                        ); // Segarkan daftar pengajuan.
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              disetujui
                                  ? 'Pengajuan berhasil disetujui.'
                                  : 'Pengajuan berhasil ditolak.',
                            ),
                            backgroundColor: disetujui
                                ? const Color(0xFF4CAF50)
                                : const Color(0xFFE53935),
                          ),
                        );
                      } catch (error) {
                        if (!dialogContext.mounted) return;
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          SnackBar(
                            content: Text('Gagal memproses pengajuan: $error'),
                          ),
                        );
                      } finally {
                        if (dialogContext.mounted) {
                          setDialogState(() => sedangMengirim = false);
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: disetujui ? _blue : const Color(0xFFE53935),
                foregroundColor: Colors.white,
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
        ),
      ),
    );
  }
}
