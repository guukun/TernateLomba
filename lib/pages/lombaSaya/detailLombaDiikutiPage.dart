import '../../design_system/tl_playful.dart';

import 'dart:async';

import 'package:flutter/material.dart';

import '../../widgets/competition_detail_poster.dart';

import '../../config/appTheme.dart';
import '../../services/api_service.dart';

class DetailLombaDiikutiPage extends StatefulWidget {
  final String token;
  final int idPendaftaran;

  const DetailLombaDiikutiPage({
    super.key,
    required this.token,
    required this.idPendaftaran,
  });

  @override
  State<DetailLombaDiikutiPage> createState() => _DetailLombaDiikutiPageState();
}

class _DetailLombaDiikutiPageState extends State<DetailLombaDiikutiPage> {
  Color get _primary => context.tl.primary;
  Color get _cream => context.tl.cream;
  Color get _text => context.tl.navy;
  Color get _muted => context.tl.grey;
  Color get _border => context.tl.fieldBorder;

  Timer? _timer;
  Map<String, dynamic> _data = {};
  bool _loading = true;
  bool _refreshing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(Duration(seconds: 8), (_) => _load(silent: true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (_refreshing) return;
    _refreshing = true;
    if (!silent && mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final result = await ApiService.getDetailPendaftaran(
        token: widget.token,
        idPendaftaran: widget.idPendaftaran,
      );
      if (!mounted) return;
      setState(() {
        _data = result;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      if (!silent || _data.isEmpty) {
        setState(() {
          _loading = false;
          _error = e.toString().replaceFirst(RegExp(r'^Exception: ?'), '');
        });
      }
    } finally {
      _refreshing = false;
    }
  }

  Color _statusColor(String value) {
    switch (value.toLowerCase()) {
      case 'diterima':
      case 'aktif':
        return context.tl.green;
      case 'ditolak':
      case 'selesai':
        return context.tl.error;
      default:
        return context.tl.orange;
    }
  }

  Widget _badge(String value) {
    final color = _statusColor(value);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        value,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  String _value(String key, [String fallback = 'Belum tersedia']) {
    final value = _data[key]?.toString().trim() ?? '';
    return value.isEmpty ? fallback : value;
  }

  String _dateText(String key) {
    final raw = _value(key, '-');
    if (raw == '-') return raw;
    try {
      final date = DateTime.parse(raw).toLocal();
      final dd = date.day.toString().padLeft(2, '0');
      final mm = date.month.toString().padLeft(2, '0');
      return '$dd/$mm/${date.year}';
    } catch (_) {
      return raw.length >= 10 ? raw.substring(0, 10) : raw;
    }
  }

  Widget _statusSummary() {
    final p = context.tl;
    final status = _value('status_pendaftaran', 'Menunggu');
    final accepted = status.toLowerCase() == 'diterima';
    final rejected = status.toLowerCase() == 'ditolak';
    final accent = accepted
        ? p.mint
        : rejected
        ? p.error
        : p.orange;
    final title = accepted
        ? 'Kamu diterima!'
        : rejected
        ? 'Belum berhasil kali ini'
        : 'Sedang ditinjau ⏳';
    final description = accepted
        ? 'Kamu resmi tercatat sebagai peserta lomba ini.'
        : rejected
        ? 'Pendaftaranmu belum dapat diterima penyelenggara.'
        : 'Pendaftaranmu sedang ditinjau oleh penyelenggara.';
    return Container(
      margin: const EdgeInsets.only(bottom: 17),
      padding: const EdgeInsets.all(20),
      decoration: TLPlayful.card(context, tint: accent, radius: 27),
      child: Row(
        children: [
          Container(
            width: 63,
            height: 63,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: .20),
              borderRadius: BorderRadius.circular(23),
            ),
            child: Icon(
              accepted
                  ? Icons.verified_rounded
                  : rejected
                  ? Icons.sentiment_dissatisfied_rounded
                  : Icons.hourglass_top_rounded,
              color: accent,
              size: 31,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: p.navy,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: TextStyle(color: p.grey, height: 1.45, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _biayaLabel() {
    final amount = double.tryParse(_data['biaya']?.toString() ?? '0') ?? 0;
    if (amount <= 0) return 'Gratis';
    final digits = amount.toStringAsFixed(0);
    final formatted = digits.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '.',
    );
    return 'Rp $formatted';
  }

  Widget _section(String title, IconData icon, List<Widget> children) {
    final p = context.tl;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(19),
      decoration: TLPlayful.card(context, tint: p.mint, radius: 27),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: p.mint.withValues(alpha: .18),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, size: 22, color: p.mint),
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
          ),
          const SizedBox(height: 15),
          Divider(color: p.fieldBorder, height: 1),
          const SizedBox(height: 7),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 300) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: _muted, fontSize: 11)),
                SizedBox(height: 4),
                Text(
                  value.isEmpty ? 'Belum tersedia' : value,
                  style: TextStyle(
                    color: _text,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    height: 1.45,
                  ),
                ),
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: constraints.maxWidth * .42,
                child: Text(
                  label,
                  style: TextStyle(color: _muted, fontSize: 12),
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  value.isEmpty ? 'Belum tersedia' : value,
                  style: TextStyle(
                    color: _text,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _answersSection(List<Map<String, dynamic>> answers) {
    return _section('Data Pendaftaran Saya', Icons.assignment_outlined, [
      Padding(
        padding: EdgeInsets.only(top: 8, bottom: 12),
        child: Text(
          'Jawaban yang kamu kirim saat mendaftar.',
          style: TextStyle(color: _muted, fontSize: 11),
        ),
      ),
      ...answers.map((answer) {
        final name = answer['nama_field']?.toString() ?? 'Pertanyaan';
        final type = answer['tipe_field']?.toString().toLowerCase() ?? '';
        final value = answer['jawaban']?.toString() ?? '';
        return Container(
          margin: EdgeInsets.only(bottom: 8),
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: context.tl.background,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: TextStyle(color: _muted, fontSize: 11)),
              SizedBox(height: 5),
              Text(
                type == 'file'
                    ? 'Berkas telah dikirim'
                    : (value.isEmpty ? 'Tidak diisi' : value),
                style: TextStyle(
                  color: _text,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  height: 1.5,
                ),
              ),
            ],
          ),
        );
      }),
    ]);
  }

  Widget _keyFact(IconData icon, String label, String value) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _cream,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: _primary, size: 18),
            SizedBox(height: 8),
            Text(label, style: TextStyle(color: _muted, fontSize: 10)),
            SizedBox(height: 4),
            Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _text,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final poster = _data['poster_url']?.toString() ?? '';
    final additional = _data['informasi_tambahan'] is List
        ? (_data['informasi_tambahan'] as List)
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
        : <Map<String, dynamic>>[];
    final answers = _data['jawaban'] is List
        ? (_data['jawaban'] as List)
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
        : <Map<String, dynamic>>[];
    return Scaffold(
      backgroundColor: context.tl.background,
      appBar: AppBar(
        backgroundColor: context.tl.background,
        foregroundColor: _text,
        surfaceTintColor: context.tl.background,
        elevation: 0,
        title: Text(
          'My Competition',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: _loading
            ? Center(child: CircularProgressIndicator(color: _primary))
            : _error != null && _data.isEmpty
            ? Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.cloud_off_outlined, size: 42, color: _muted),
                      SizedBox(height: 12),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: _text),
                      ),
                      SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: _load,
                        child: Text('Coba lagi'),
                      ),
                    ],
                  ),
                ),
              )
            : RefreshIndicator(
                color: _primary,
                onRefresh: _load,
                child: ListView(
                  padding: EdgeInsets.fromLTRB(18, 8, 18, 110),
                  children: [
                    Container(
                      margin: const EdgeInsets.only(bottom: 19),
                      child: TLPlayful.decoratedHeading(
                        context,
                        title: 'You made\nyour move.',
                        subtitle: 'Status pendaftaran dan jadwal penting, tanpa distraksi.',
                        accent: context.tl.mint,
                        icon: Icons.verified_rounded,
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: context.tl.surface,
                        borderRadius: BorderRadius.circular(21),
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
                                Text(
                                  _value('nama_lomba', 'Lomba tanpa nama'),
                                  style: TextStyle(
                                    color: _text,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    height: 1.25,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.emoji_events_outlined,
                                      size: 16,
                                      color: _primary,
                                    ),
                                    SizedBox(width: 5),
                                    Expanded(
                                      child: Text(
                                        _value('kategori', 'Lomba'),
                                        style: TextStyle(
                                          color: _muted,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 7,
                                  children: [
                                    _badge(_value('status_pendaftaran')),
                                    _badge(_value('status_lomba')),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 14),
                    _statusSummary(),
                    Row(
                      children: [
                        _keyFact(
                          Icons.event_rounded,
                          'Pelaksanaan',
                          _dateText('tanggal_pelaksanaan'),
                        ),
                        SizedBox(width: 10),
                        _keyFact(
                          Icons.public_outlined,
                          'Metode',
                          _value('metode_pelaksanaan'),
                        ),
                      ],
                    ),
                    SizedBox(height: 15),
                    _section('My Participation', Icons.verified_user_outlined, [
                      _infoRow(
                        'Tanggal daftar',
                        _dateText('tanggal_pendaftaran'),
                      ),
                      _infoRow('Status peserta', _value('status_pendaftaran')),
                      _infoRow('Penyelenggara', _value('penyelenggara')),
                      _infoRow(
                        'Kuota diterima',
                        _data['kuota_peserta'] == null
                            ? '${_value('jumlah_peserta_diterima', '0')} peserta'
                            : '${_value('jumlah_peserta_diterima', '0')} / ${_value('kuota_peserta')} peserta',
                      ),
                    ]),
                    _section(
                      'Jadwal & Pelaksanaan',
                      Icons.event_note_outlined,
                      [
                        _infoRow(
                          'Mulai daftar',
                          _dateText('tanggal_mulai_pendaftaran'),
                        ),
                        _infoRow(
                          'Batas daftar',
                          _dateText('batas_pendaftaran'),
                        ),
                        _infoRow(
                          'Tanggal lomba',
                          _dateText('tanggal_pelaksanaan'),
                        ),
                        _infoRow(
                          'Tempat / platform',
                          _value(
                            'detail_pelaksanaan',
                            _value('lokasi_pendaftaran'),
                          ),
                        ),
                        _infoRow('Biaya', _biayaLabel()),
                        if (_value('hadiah', '').isNotEmpty)
                          _infoRow('Hadiah', _value('hadiah')),
                      ],
                    ),
                    _section('Tentang Lomba', Icons.info_outline_rounded, [
                      Padding(
                        padding: EdgeInsets.only(top: 9, bottom: 4),
                        child: Text(
                          _value('deskripsi'),
                          style: TextStyle(
                            color: _text,
                            fontSize: 12,
                            height: 1.65,
                          ),
                        ),
                      ),
                    ]),
                    if (_value('persyaratan', '').isNotEmpty)
                      _section('Persyaratan', Icons.fact_check_outlined, [
                        Padding(
                          padding: EdgeInsets.only(top: 9, bottom: 4),
                          child: Text(
                            _value('persyaratan'),
                            style: TextStyle(
                              color: _text,
                              fontSize: 12,
                              height: 1.6,
                            ),
                          ),
                        ),
                      ]),
                    if (additional.isNotEmpty)
                      _section(
                        'Informasi Tambahan',
                        Icons.list_alt_outlined,
                        additional
                            .map(
                              (item) => _infoRow(
                                item['label_informasi']?.toString() ??
                                    'Informasi',
                                item['nilai_informasi']?.toString() ?? '',
                              ),
                            )
                            .toList(),
                      ),
                    if (answers.isNotEmpty) _answersSection(answers),
                  ],
                ),
              ),
      ),
    );
  }
}