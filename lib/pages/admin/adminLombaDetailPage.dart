import 'package:flutter/material.dart';

import '../../widgets/competition_detail_poster.dart';

import '../../config/appTheme.dart';
import '../../services/api_service.dart';
import '../../widgets/app_feedback.dart';

/// Detail administratif, including stop action, independent of public catalog.
class AdminLombaDetailPage extends StatefulWidget {
  final String token;
  final int lombaId;
  const AdminLombaDetailPage({
    super.key,
    required this.token,
    required this.lombaId,
  });

  @override
  State<AdminLombaDetailPage> createState() => _AdminLombaDetailPageState();
}

class _AdminLombaDetailPageState extends State<AdminLombaDetailPage> {
  Map<String, dynamic>? _lomba;
  String? _error;
  bool _loading = true;
  bool _stopping = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await ApiService.getAdminLombaDetail(
        token: widget.token,
        id: widget.lombaId,
      );
      if (!mounted) return;
      setState(() {
        _lomba = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  String _value(String key) {
    final value = _lomba?[key]?.toString().trim();
    return value == null || value.isEmpty ? '—' : value;
  }

  bool get _canStop => _lomba?['boleh_dihentikan'] == true;
  bool get _canCancel => _lomba?['boleh_dibatalkan'] == true;

  Future<void> _takeAction({required bool cancel}) async {
    if (_stopping || (cancel ? !_canCancel : !_canStop)) return;
    final action = cancel ? 'Batalkan' : 'Hentikan';
    final actionLower = cancel ? 'membatalkan' : 'menghentikan';
    final reason = await AppReasonDialog.show(
      context: context,
      title: '$action Lomba',
      description:
          'Tindakan ini akan $actionLower lomba dan memberi tahu peserta serta penyelenggara. Alasan wajib diisi (minimal 10 karakter).',
      actionLabel: 'Lanjut ke konfirmasi',
    );
    if (!mounted || reason == null) return;
    final approved = await AppConfirmDialog.show(
      context: context,
      title: 'Konfirmasi $action',
      message:
          'Yakin ingin $actionLower ${_value('nama_lomba')}? Tindakan ini tidak dapat dibatalkan.\n\nAlasan: $reason',
      confirmText: action,
      confirmColor: context.tl.error,
      barrierDismissible: false,
    );
    if (!mounted || approved != true) return;
    setState(() => _stopping = true);
    try {
      if (cancel) {
        await ApiService.cancelAdminLomba(
          token: widget.token,
          id: widget.lombaId,
          alasan: reason,
        );
      } else {
        await ApiService.stopAdminLomba(
          token: widget.token,
          id: widget.lombaId,
          alasan: reason,
        );
      }
      if (!mounted) return;
      AppNotification.message(
        context,
        cancel ? 'Lomba berhasil dibatalkan.' : 'Lomba berhasil dihentikan.',
        type: NotificationType.success,
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      AppNotification.message(context, '$e', type: NotificationType.error);
      await _load();
    } finally {
      if (mounted) setState(() => _stopping = false);
    }
  }

  Widget _field(
    String label,
    String value, {
    IconData icon = Icons.info_outline_rounded,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 11),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: context.tl.primary, size: 20),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: context.tl.grey, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  color: context.tl.navy,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _panel(String title, List<Widget> children) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    margin: const EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(
      color: context.tl.surface,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: context.tl.fieldBorder),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w900,
            color: context.tl.navy,
          ),
        ),
        const SizedBox(height: 10),
        ...children,
      ],
    ),
  );

  Widget _administratorActionCard() {
    final cancel = _canCancel;
    final action = cancel ? 'Batalkan Lomba' : 'Hentikan Lomba';
    final description = cancel
        ? 'Batalkan lomba sebelum pelaksanaan. Peserta dan penyelenggara akan menerima pemberitahuan.'
        : 'Hentikan lomba yang sedang berlangsung. Peserta dan penyelenggara akan menerima pemberitahuan.';
    final p = context.tl;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(21),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: p.fieldBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: p.fieldBg,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  Icons.admin_panel_settings_outlined,
                  color: p.navy,
                  size: 25,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kontrol Administrator',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        color: p.navy,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Tindakan khusus pengelolaan lomba',
                      style: TextStyle(fontSize: 11, color: p.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: p.fieldBg,
              borderRadius: BorderRadius.circular(17),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, color: p.navy, size: 19),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    description,
                    style: TextStyle(
                      color: p.grey,
                      height: 1.45,
                      fontSize: 12.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _stopping ? null : () => _takeAction(cancel: cancel),
              icon: Icon(
                cancel ? Icons.cancel_outlined : Icons.stop_circle_outlined,
                size: 19,
              ),
              label: Text(_stopping ? 'Memproses...' : action),
              style: OutlinedButton.styleFrom(
                foregroundColor: p.error,
                backgroundColor: p.surface,
                side: BorderSide(color: p.error.withValues(alpha: .43)),
                minimumSize: const Size.fromHeight(51),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(17),
                ),
                textStyle: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Text(
              'Alasan wajib diisi dan tindakan memerlukan konfirmasi.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: p.grey),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: context.tl.background,
    appBar: AppBar(
      title: const Text('Kelola Kompetisi'),
      backgroundColor: context.tl.background,
      foregroundColor: context.tl.navy,
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
        ? Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_error!, textAlign: TextAlign.center),
                TextButton(onPressed: _load, child: const Text('Coba lagi')),
              ],
            ),
          )
        : RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: context.tl.surface,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_lomba?['poster_url'] != null) ...[
                        CompetitionDetailPoster(
                          url: _lomba!['poster_url']?.toString(),
                          radius: 18,
                        ),
                        const SizedBox(height: 16),
                      ] else
                        const Icon(Icons.emoji_events_rounded, size: 32),
                      const SizedBox(height: 12),
                      Text(
                        _value('nama_lomba'),
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w900,
                          color: context.tl.navy,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Chip(label: Text(_value('status_lomba'))),
                    ],
                  ),
                ),
                _panel('Informasi Lomba', [
                  _field(
                    'Penyelenggara',
                    _value('penyelenggara'),
                    icon: Icons.person_outline,
                  ),
                  _field(
                    'Kategori',
                    _value('kategori'),
                    icon: Icons.category_outlined,
                  ),
                  _field(
                    'Deskripsi',
                    _value('deskripsi'),
                    icon: Icons.subject_outlined,
                  ),
                  _field(
                    'Persyaratan',
                    _value('persyaratan'),
                    icon: Icons.fact_check_outlined,
                  ),
                  _field(
                    'Metode Pelaksanaan',
                    _value('metode_pelaksanaan'),
                    icon: Icons.place_outlined,
                  ),
                  _field(
                    'Detail Pelaksanaan',
                    _value('detail_pelaksanaan'),
                    icon: Icons.notes_outlined,
                  ),
                  _field(
                    'Kontak Penyelenggara',
                    _value('kontak_penyelenggara'),
                    icon: Icons.contact_mail_outlined,
                  ),
                  _field(
                    'Kuota peserta',
                    _value('kuota_peserta'),
                    icon: Icons.groups_outlined,
                  ),
                  _field(
                    'Biaya',
                    _value('biaya'),
                    icon: Icons.payments_outlined,
                  ),
                  _field(
                    'Hadiah',
                    _value('hadiah'),
                    icon: Icons.card_giftcard_outlined,
                  ),
                ]),
                _panel('Jadwal dan Peserta', [
                  _field(
                    'Mulai pendaftaran',
                    _value('tanggal_mulai_pendaftaran'),
                    icon: Icons.event_available_outlined,
                  ),
                  _field(
                    'Batas pendaftaran',
                    _value('batas_pendaftaran'),
                    icon: Icons.event_busy_outlined,
                  ),
                  _field(
                    'Mulai pelaksanaan',
                    _value('tanggal_pelaksanaan'),
                    icon: Icons.flag_outlined,
                  ),
                  _field(
                    'Akhir pelaksanaan',
                    _value('tanggal_selesai_pelaksanaan'),
                    icon: Icons.flag_circle_outlined,
                  ),
                  _field(
                    'Jumlah pendaftar',
                    _value('jumlah_pendaftar'),
                    icon: Icons.groups_outlined,
                  ),
                  _field(
                    'Peserta diterima',
                    _value('jumlah_diterima'),
                    icon: Icons.check_circle_outline,
                  ),
                ]),
                if (_value('status_lomba') == 'Dihentikan' ||
                    _value('status_lomba') == 'Dibatalkan')
                  _panel('Riwayat Tindakan Administrator', [
                    _field(
                      'Tindakan',
                      _value('jenis_tindakan'),
                      icon: Icons.admin_panel_settings_outlined,
                    ),
                    _field(
                      'Alasan',
                      _value('alasan_penghentian'),
                      icon: Icons.report_outlined,
                    ),
                    _field(
                      'Waktu',
                      _value('dihentikan_at'),
                      icon: Icons.access_time,
                    ),
                  ]),
                if (_canStop || _canCancel)
                  _administratorActionCard()
                else if (_value('status_lomba') == 'Selesai')
                  _panel('Tindakan Administrator', [
                    const Text(
                      'Lomba sudah selesai sesuai jadwal dan tidak dapat dibatalkan atau dihentikan lagi.',
                    ),
                  ]),
                const SizedBox(height: 90),
              ],
            ),
          ),
  );
}