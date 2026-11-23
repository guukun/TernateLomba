import '../../design_system/tl_playful.dart';
import '../../widgets/app_feedback.dart';

import 'dart:async';

import 'package:flutter/material.dart';

import '../../widgets/competition_detail_poster.dart';

import '../../config/appTheme.dart';
import '../../services/api_service.dart';
import 'formulirPesertaPage.dart';

class DetailLombaPage extends StatefulWidget {
  final Map<String, String> lomba;
  final String token;

  const DetailLombaPage({super.key, required this.lomba, required this.token});

  @override
  State<DetailLombaPage> createState() => _DetailLombaPageState();
}

class _DetailLombaPageState extends State<DetailLombaPage> {
  // ==========================================
  // APP THEME
  // ==========================================

  Color get primary => context.tl.primary;
  Color get primaryDark => context.tl.primaryDark;
  Color get cream => context.tl.cream;
  Color get creamLight => context.tl.creamLight;
  Color get creamDark => context.tl.creamDark;
  Color get background => context.tl.background;
  Color get textColor => context.tl.navy;
  Color get muted => context.tl.grey;
  Color get borderColor => context.tl.fieldBorder;

  // ==========================================
  // STATE
  // ==========================================

  late Map<String, String> lomba;

  bool isLoadingDetail = true;
  bool _isFavorite = false;
  bool _favoriteBusy = false;

  Future<void> _loadFavorite() async {
    try {
      final favorites = await ApiService.getFavorit(token: widget.token);
      final id = int.tryParse(lomba['id_lomba'] ?? '');
      if (mounted) {
        setState(() => _isFavorite = favorites.any((e) => e['id_lomba'] == id));
      }
    } catch (e) {
      debugPrint('Gagal membaca favorit: $e');
    }
  }

  Future<void> _toggleFavorite() async {
    final id = int.tryParse(lomba['id_lomba'] ?? '');
    if (id == null || _favoriteBusy) return;
    final previous = _isFavorite;
    setState(() {
      _isFavorite = !previous;
      _favoriteBusy = true;
    });
    try {
      await ApiService.setFavorit(
        token: widget.token,
        idLomba: id,
        favorite: !previous,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isFavorite = previous);
      AppNotification.message(
        context,
        'Tidak dapat menyimpan favorit: $e',
        type: NotificationType.error,
      );
    } finally {
      if (mounted) setState(() => _favoriteBusy = false);
    }
  }

  String? errorDetail;

  // STATUS PENDAFTARAN
  Map<String, dynamic>? statusPendaftaran;

  bool isLoadingStatusPendaftaran = true;
  String? errorStatusPendaftaran;

  List<Map<String, dynamic>> _informasiTambahan = [];

  Timer? _quotaRefreshTimer;
  bool _isRefreshingQuota = false;

  @override
  void initState() {
    super.initState();
    _loadFavorite();

    lomba = Map<String, String>.from(widget.lomba);

    _loadDetailLomba();
  }

  // ==========================================
  // LOAD DETAIL LOMBA
  // ==========================================

  Future<void> _loadDetailLomba() async {
    final idLomba = int.tryParse(lomba['id_lomba'] ?? '');

    if (idLomba == null) {
      if (!mounted) return;

      setState(() {
        errorDetail = 'ID lomba tidak valid.';
        isLoadingDetail = false;
      });

      return;
    }

    setState(() {
      isLoadingDetail = true;
      errorDetail = null;
    });

    try {
      final data = await ApiService.getDetailLomba(idLomba);

      if (!mounted) return;

      final kategori = data['kategori'];
      final penyelenggara = data['penyelenggara'];

      final kategoriMap = kategori is Map ? kategori : {};
      final penyelenggaraMap = penyelenggara is Map ? penyelenggara : {};

      final biaya = double.tryParse(data['biaya']?.toString() ?? '0') ?? 0;
      final rawAdditionalInfo = data['informasi_tambahan'];
      final additionalInfo = rawAdditionalInfo is List
          ? rawAdditionalInfo
                .whereType<Map>()
                .map((item) => Map<String, dynamic>.from(item))
                .toList()
          : <Map<String, dynamic>>[];

      setState(() {
        _informasiTambahan = additionalInfo;
        lomba = {
          'id_lomba': data['id_lomba']?.toString() ?? '',
          'id_pengajuan': data['id_pengajuan']?.toString() ?? '',
          'judul': data['nama_lomba']?.toString() ?? '',
          'kategori': kategoriMap['nama_kategori']?.toString() ?? '',
          'penyelenggara': penyelenggaraMap['username']?.toString() ?? '',
          'deskripsi': data['deskripsi']?.toString() ?? '',
          'persyaratan': data['persyaratan']?.toString() ?? '',
          'kuota': data['kuota_peserta']?.toString() ?? '',
          'jumlah_peserta': data['jumlah_peserta']?.toString() ?? '0',
          'biaya': biaya == 0 ? 'Gratis' : _formatAmount(biaya),
          'hadiah': data['hadiah']?.toString() ?? '',
          'tanggal_mulai_pendaftaran':
              data['tanggal_mulai_pendaftaran']?.toString() ?? '',
          'batas_pendaftaran': data['batas_pendaftaran']?.toString() ?? '',
          'tanggal_pelaksanaan': data['tanggal_pelaksanaan']?.toString() ?? '',
          'metode_pelaksanaan': data['metode_pelaksanaan']?.toString() ?? '',
          'detail_pelaksanaan': data['detail_pelaksanaan']?.toString() ?? '',
          'lokasi_pendaftaran': data['lokasi_pendaftaran']?.toString() ?? '',
          'kontak_penyelenggara':
              data['kontak_penyelenggara']?.toString() ?? '',
          'poster_lomba': data['poster_lomba']?.toString() ?? '',
          'status_lomba': data['status_lomba']?.toString() ?? '',
          'alasan_penghentian': data['alasan_penghentian']?.toString() ?? '',
        };

        isLoadingDetail = false;
      });

      if (lomba['status_lomba'] == 'Aktif') {
        _startQuotaRefresh();
      } else {
        _quotaRefreshTimer?.cancel();
      }

      // Periksa hak pendaftaran setelah detail lomba berhasil dimuat.
      await _loadStatusPendaftaran(idLomba);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorDetail = e.toString();
        isLoadingDetail = false;
      });
    }
  }

  // ==========================================
  // LOAD STATUS PENDAFTARAN
  // ==========================================

  Future<void> _loadStatusPendaftaran(
    int idLomba, {
    bool showLoading = true,
  }) async {
    if (!mounted) return;

    if (showLoading) {
      setState(() {
        isLoadingStatusPendaftaran = true;
        errorStatusPendaftaran = null;
      });
    }

    try {
      final data = await ApiService.getStatusPendaftaranLomba(
        idLomba: idLomba,
        token: widget.token,
      );

      if (!mounted) return;

      setState(() {
        statusPendaftaran = data;
        isLoadingStatusPendaftaran = false;
        errorStatusPendaftaran = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorStatusPendaftaran = e.toString();
        isLoadingStatusPendaftaran = false;
      });
    }
  }

  // ==========================================
  // DATA HELPERS
  // ==========================================

  String getValue(String key, {String fallback = 'Belum tersedia'}) {
    final value = lomba[key]?.trim();

    if (value == null || value.isEmpty) {
      return fallback;
    }

    return value;
  }

  String _formatAmount(double amount) {
    final digits = amount.toStringAsFixed(0);
    final formatted = digits.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '.',
    );
    return 'Rp $formatted';
  }

  int get totalKuota {
    return int.tryParse(lomba['kuota']?.trim() ?? '') ?? 0;
  }

  int get jumlahPeserta {
    return int.tryParse(lomba['jumlah_peserta']?.trim() ?? '') ?? 0;
  }

  double get progressKuota {
    if (totalKuota <= 0) return 0;

    return (jumlahPeserta / totalKuota).clamp(0.0, 1.0).toDouble();
  }

  int get sisaKuota {
    if (totalKuota <= 0) return 0;

    return (totalKuota - jumlahPeserta).clamp(0, totalKuota).toInt();
  }

  String get informasiKuota {
    if (totalKuota <= 0) {
      return 'Kuota tidak dibatasi atau belum tersedia';
    }

    return 'Kapasitas maksimal $totalKuota peserta';
  }

  // STATUS PENGGUNA
  bool get _sudahMendaftar => statusPendaftaran?['sudah_mendaftar'] == true;

  bool get _isPenyelenggara => statusPendaftaran?['is_penyelenggara'] == true;

  bool get _kuotaPenuh => statusPendaftaran?['kuota_penuh'] == true;

  bool get _batasLewat => statusPendaftaran?['batas_pendaftaran_lewat'] == true;

  bool get _bolehMendaftar =>
      lomba['status_lomba'] == 'Aktif' &&
      statusPendaftaran?['boleh_mendaftar'] == true;

  bool get _lombaArsip =>
      lomba['status_lomba']?.isNotEmpty == true &&
      lomba['status_lomba'] != 'Aktif';

  // ==========================================
  // LIVE REFRESH KUOTA
  // ==========================================

  void _startQuotaRefresh() {
    _quotaRefreshTimer?.cancel();

    _quotaRefreshTimer = Timer.periodic(
      Duration(seconds: 15),
      (_) => _refreshQuota(),
    );
  }

  Future<void> _refreshQuota() async {
    if (!mounted || isLoadingDetail || _isRefreshingQuota) return;

    final idLomba = int.tryParse(lomba['id_lomba'] ?? '');

    if (idLomba == null) return;

    _isRefreshingQuota = true;

    try {
      final data = await ApiService.getDetailLomba(idLomba);

      if (!mounted) return;

      final jumlahTerbaru =
          int.tryParse(data['jumlah_peserta']?.toString() ?? '') ?? 0;

      final kuotaTerbaru = data['kuota_peserta']?.toString() ?? '';

      if (jumlahTerbaru != jumlahPeserta ||
          (kuotaTerbaru.isNotEmpty && kuotaTerbaru != lomba['kuota'])) {
        setState(() {
          lomba['jumlah_peserta'] = jumlahTerbaru.toString();

          if (kuotaTerbaru.isNotEmpty) {
            lomba['kuota'] = kuotaTerbaru;
          }
        });
      }

      // Perbarui juga status pengguna dan ketersediaan kuota.
      await _loadStatusPendaftaran(idLomba, showLoading: false);
    } catch (e) {
      debugPrint('Gagal memperbarui kuota lomba: $e');
    } finally {
      _isRefreshingQuota = false;
    }
  }

  @override
  void dispose() {
    _quotaRefreshTimer?.cancel();
    super.dispose();
  }

  String get _posterUrl {
    return lomba['poster_lomba'] ?? '';
  }

  // ==========================================
  // CARD DECORATION
  // ==========================================

  BoxDecoration _cardDecoration({Color? color}) {
    return BoxDecoration(
      color: color ?? context.tl.surface,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: borderColor),
      boxShadow: [
        BoxShadow(
          color: primaryDark.withValues(alpha: 0.035),
          blurRadius: 16,
          offset: Offset(0, 5),
        ),
      ],
    );
  }

  // ==========================================
  // HEADER
  // ==========================================

  Widget _buildHeader() => TLPlayful.pageHeader(
    context,
    title: 'Know your\nchallenge.',
    description:
        'Detail, persyaratan, dan jadwal. Fokus pada langkah berikutnya.',
    icon: Icons.emoji_events_rounded,
    accent: context.tl.orange,
    onBack: () => Navigator.of(context).pop(),
  );

  // ==========================================
  // POSTER
  // ==========================================

  Widget _buildPoster() {
    return CompetitionDetailPoster(
      url: ApiService.publicStorageUrl(_posterUrl),
      radius: 19,
      fallback: _posterFallback(),
    );
  }

  Widget _posterFallback() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [creamLight, cream, creamDark],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.emoji_events_rounded, color: primary, size: 47),
          SizedBox(height: 10),
          Text(
            'POSTER LOMBA',
            style: TextStyle(
              color: primary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // INFORMASI UTAMA LOMBA
  // ==========================================

  Widget _buildMainInformation() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPoster(),

          SizedBox(height: 17),

          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: cream,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              getValue('kategori'),
              style: TextStyle(
                color: primary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),

          SizedBox(height: 13),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  getValue('judul', fallback: 'Competition Details'),
                  style: TextStyle(
                    color: textColor,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    height: 1.3,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              SizedBox(width: 8),
              IconButton(
                tooltip: _isFavorite ? 'Hapus dari favorit' : 'Tambah favorit',
                onPressed: _favoriteBusy ? null : _toggleFavorite,
                icon: Icon(
                  _isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: primary,
                  size: 26,
                ),
              ),
            ],
          ),

          SizedBox(height: 13),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.account_balance_outlined, color: primary, size: 19),

              SizedBox(width: 9),

              Expanded(
                child: Text(
                  getValue('penyelenggara'),
                  style: TextStyle(
                    color: muted,
                    fontSize: 12,
                    height: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // SECTION TITLE
  // ==========================================

  Widget _sectionTitle(String title, {String? subtitle, IconData? icon}) {
    final p = context.tl;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: p.yellow.withValues(alpha: .20),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: p.orange, size: 22),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: p.navy,
                    fontSize: 17,
                    letterSpacing: -.3,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: p.grey,
                      fontSize: 11.5,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // STATUS / KUOTA
  // ==========================================

  Widget _buildQuotaCard() {
    final kuotaTerbatas = totalKuota > 0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(17),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kuota Peserta',
                      style: TextStyle(color: muted, fontSize: 12),
                    ),

                    SizedBox(height: 7),

                    Text(
                      informasiKuota,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: cream,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.groups_rounded, color: primary, size: 24),
              ),
            ],
          ),

          SizedBox(height: 17),

          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: progressKuota),
              duration: Duration(milliseconds: 500),
              curve: Curves.easeInOut,
              builder: (context, value, child) {
                return LinearProgressIndicator(
                  value: kuotaTerbatas ? value : 0,
                  minHeight: 8,
                  backgroundColor: creamDark,
                  color: primary,
                );
              },
            ),
          ),

          SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                kuotaTerbatas
                    ? '$jumlahPeserta dari $totalKuota peserta terdaftar'
                    : '$jumlahPeserta peserta terdaftar',
                style: TextStyle(
                  color: textColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),

              if (kuotaTerbatas)
                Text(
                  '$sisaKuota slot tersisa',
                  style: TextStyle(
                    color: muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),

          SizedBox(height: 10),

          Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 15, color: muted),

              SizedBox(width: 7),

              Expanded(
                child: Text(
                  jumlahPeserta == 0
                      ? 'Belum ada peserta yang mendaftar. Data diperbarui otomatis.'
                      : 'Jumlah peserta diperbarui otomatis setiap 15 detik.',
                  style: TextStyle(color: muted, fontSize: 11),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // INFORMASI LOMBA: SATU BARIS PER INFORMASI
  // ==========================================

  Widget _buildInformationSections() {
    final groups = <String, List<Map<String, String>>>{};

    void addRow(String group, String label, String value) {
      final clean = value.trim();
      if (clean.isEmpty || clean == 'Belum tersedia') return;
      groups.putIfAbsent(group, () => []).add({'label': label, 'value': clean});
    }

    addRow(
      'Pendaftaran',
      'Mulai pendaftaran',
      getValue('tanggal_mulai_pendaftaran', fallback: ''),
    );
    addRow(
      'Pendaftaran',
      'Batas pendaftaran',
      getValue('batas_pendaftaran', fallback: ''),
    );
    addRow(
      'Pendaftaran',
      'Kuota peserta',
      totalKuota > 0
          ? '$jumlahPeserta / $totalKuota peserta'
          : '$jumlahPeserta peserta terdaftar',
    );
    addRow(
      'Pendaftaran',
      'Biaya pendaftaran',
      getValue('biaya', fallback: 'Gratis'),
    );

    addRow(
      'Pelaksanaan',
      'Tanggal pelaksanaan',
      getValue('tanggal_pelaksanaan', fallback: ''),
    );
    addRow(
      'Pelaksanaan',
      'Metode pelaksanaan',
      getValue('metode_pelaksanaan', fallback: ''),
    );
    addRow(
      'Pelaksanaan',
      getValue('metode_pelaksanaan', fallback: '').toLowerCase() == 'online'
          ? 'Platform'
          : 'Tempat',
      getValue(
        'detail_pelaksanaan',
        fallback: getValue('lokasi_pendaftaran', fallback: ''),
      ),
    );

    // Semua field bebas yang ditambahkan penyelenggara selalu berada
    // di satu kelompok, yaitu Informasi Tambahan.
    for (final item in _informasiTambahan) {
      final label = item['label_informasi']?.toString().trim();
      final value = item['nilai_informasi']?.toString().trim();
      if (label == null || label.isEmpty || value == null || value.isEmpty) {
        continue;
      }
      addRow('Informasi Tambahan', label, value);
    }

    if (getValue('kontak_penyelenggara', fallback: '').isNotEmpty) {
      addRow(
        'Kontak Penyelenggara',
        'Kontak',
        getValue('kontak_penyelenggara', fallback: ''),
      );
    }

    if (groups.isEmpty) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(16),
        decoration: _cardDecoration(),
        child: Text(
          'Informasi lomba belum tersedia.',
          style: TextStyle(color: muted, fontSize: 12),
        ),
      );
    }

    return Column(
      children: groups.entries
          .map((entry) => _buildInformationGroup(entry.key, entry.value))
          .toList(),
    );
  }

  Widget _buildInformationGroup(String title, List<Map<String, String>> rows) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 13),
      padding: EdgeInsets.fromLTRB(16, 15, 16, 8),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: primary,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 7),
          ...List.generate(rows.length, (index) {
            final row = rows[index];
            return Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 11),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 5,
                        child: Text(
                          row['label'] ?? '',
                          style: TextStyle(
                            color: muted,
                            fontSize: 12,
                            height: 1.45,
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        flex: 6,
                        child: Text(
                          row['value'] ?? '',
                          textAlign: TextAlign.end,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 12,
                            height: 1.45,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (index != rows.length - 1)
                  Divider(height: 1, thickness: 0.7, color: borderColor),
              ],
            );
          }),
        ],
      ),
    );
  }

  // ==========================================
  // DESKRIPSI
  // ==========================================

  Widget _buildDescription() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(17),
      decoration: _cardDecoration(),
      child: Text(
        getValue('deskripsi', fallback: 'Belum ada deskripsi lomba.'),
        style: TextStyle(color: muted, fontSize: 13, height: 1.8),
      ),
    );
  }

  // ==========================================
  // PERSYARATAN
  // ==========================================

  Widget _buildRequirements() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(17),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 37,
                height: 37,
                decoration: BoxDecoration(
                  color: cream,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  Icons.fact_check_outlined,
                  color: primary,
                  size: 20,
                ),
              ),

              SizedBox(width: 11),

              Expanded(
                child: Text(
                  'Ketentuan Peserta',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 15),

          Text(
            getValue(
              'persyaratan',
              fallback: 'Informasi persyaratan belum tersedia.',
            ),
            style: TextStyle(color: muted, fontSize: 13, height: 1.8),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TOMBOL PENDAFTARAN
  // ==========================================

  Widget _buildRegisterButton() {
    final bool statusSiap =
        !isLoadingStatusPendaftaran &&
        errorStatusPendaftaran == null &&
        statusPendaftaran != null;

    final bool bisaMendaftar = statusSiap && _bolehMendaftar;

    final bool bisaCobaLagi =
        !_lombaArsip &&
        !isLoadingStatusPendaftaran &&
        errorStatusPendaftaran != null;

    String teksTombol;

    if (_lombaArsip) {
      teksTombol = 'Pendaftaran Ditutup';
    } else if (isLoadingStatusPendaftaran) {
      teksTombol = 'Memeriksa Status...';
    } else if (errorStatusPendaftaran != null) {
      teksTombol = 'Coba Periksa Status';
    } else if (_isPenyelenggara) {
      teksTombol = 'Lomba Anda Sendiri';
    } else if (_sudahMendaftar) {
      teksTombol = 'Sudah Terdaftar';
    } else if (_kuotaPenuh) {
      teksTombol = 'Kuota Penuh';
    } else if (_batasLewat) {
      teksTombol = 'Pendaftaran Ditutup';
    } else {
      teksTombol = 'Daftar Sekarang';
    }

    final int? idLomba = int.tryParse(lomba['id_lomba'] ?? '');

    final bool tombolAktif = bisaMendaftar || bisaCobaLagi;

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: !tombolAktif
            ? null
            : () async {
                if (idLomba == null) {
                  AppNotification.message(
                    context,
                    'ID lomba tidak valid.',
                    type: NotificationType.error,
                  );
                  return;
                }

                // Jika pemeriksaan status gagal, coba periksa ulang dahulu.
                if (bisaCobaLagi) {
                  await _loadStatusPendaftaran(idLomba);
                  return;
                }

                final berhasil = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => FormulirPesertaPage(
                      idLomba: idLomba,
                      token: widget.token,
                    ),
                  ),
                );

                if (!mounted) return;

                // Periksa ulang setelah kembali dari halaman formulir.
                if (berhasil == true) {
                  await _refreshQuota();
                } else {
                  await _loadStatusPendaftaran(idLomba);
                }
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: tombolAktif ? primary : context.tl.fieldBorder,
          foregroundColor: Colors.white,
          disabledBackgroundColor: context.tl.fieldBorder,
          disabledForegroundColor: context.tl.navy,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoadingStatusPendaftaran)
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            else
              Icon(
                bisaCobaLagi
                    ? Icons.refresh_rounded
                    : bisaMendaftar
                    ? Icons.arrow_forward_rounded
                    : Icons.lock_outline_rounded,
                size: 19,
              ),

            SizedBox(width: 9),

            Text(
              teksTombol,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // LOADING STATE
  // ==========================================

  Widget _buildLoadingState() {
    return SizedBox(
      width: double.infinity,
      child: Column(
        children: [
          SizedBox(height: 100),

          CircularProgressIndicator(color: primary, strokeWidth: 3),

          SizedBox(height: 20),

          Text(
            'Memuat informasi lomba...',
            style: TextStyle(
              color: muted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),

          SizedBox(height: 100),
        ],
      ),
    );
  }

  // ==========================================
  // ERROR STATE
  // ==========================================

  Widget _buildErrorState() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(23),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Container(
            width: 65,
            height: 65,
            decoration: BoxDecoration(
              color: cream,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(Icons.cloud_off_outlined, color: primary, size: 32),
          ),

          SizedBox(height: 16),

          Text(
            'Gagal Memuat Detail',
            style: TextStyle(
              color: textColor,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),

          SizedBox(height: 8),

          Text(
            errorDetail ?? 'Terjadi kesalahan.',
            textAlign: TextAlign.center,
            style: TextStyle(color: muted, fontSize: 12, height: 1.6),
          ),

          SizedBox(height: 18),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _loadDetailLomba,
              icon: Icon(Icons.refresh_rounded),
              label: Text('Coba Lagi'),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // BUILD
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // HEADER IKUT TERSCROLL
              _buildHeader(),

              Padding(
                padding: EdgeInsets.fromLTRB(18, 20, 18, 35),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isLoadingDetail)
                      _buildLoadingState()
                    else if (errorDetail != null)
                      _buildErrorState()
                    else ...[
                      // INFORMASI UTAMA
                      _buildMainInformation(),

                      if (_lombaArsip) ...[
                        SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: creamLight,
                            border: Border.all(color: borderColor),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Lomba ${lomba['status_lomba']}',
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Lomba ini dapat dilihat sebagai arsip, tetapi pendaftaran sudah ditutup.',
                                style: TextStyle(color: muted, fontSize: 12),
                              ),
                              if (getValue(
                                'alasan_penghentian',
                                fallback: '',
                              ).isNotEmpty) ...[
                                SizedBox(height: 10),
                                Text(
                                  'Alasan: ${getValue('alasan_penghentian')}',
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],

                      SizedBox(height: 25),

                      // STATUS DAN KUOTA
                      _sectionTitle(
                        'Status Pendaftaran',
                        subtitle: 'Informasi kapasitas peserta lomba.',
                        icon: Icons.groups_outlined,
                      ),

                      SizedBox(height: 13),

                      _buildQuotaCard(),

                      SizedBox(height: 25),

                      // INFORMASI LOMBA DALAM BARIS PER KELOMPOK
                      _sectionTitle(
                        'Informasi Lomba',
                        subtitle: 'Setiap informasi ditampilkan satu baris dan dikelompokkan berdasarkan header.',
                        icon: Icons.event_note_outlined,
                      ),

                      SizedBox(height: 13),

                      _buildInformationSections(),

                      SizedBox(height: 25),

                      // DESKRIPSI
                      _sectionTitle(
                        'Deskripsi Lomba',
                        subtitle: 'Kenali kegiatan yang akan diikuti.',
                        icon: Icons.description_outlined,
                      ),

                      SizedBox(height: 13),

                      _buildDescription(),

                      SizedBox(height: 25),

                      // PERSYARATAN LOMBA
                      // Bagian ini berasal dari kolom lama `persyaratan`.
                      // Tampilkan hanya untuk lomba lama yang memang memiliki isi.
                      if (getValue(
                        'persyaratan',
                        fallback: '',
                      ).trim().isNotEmpty) ...[
                        SizedBox(height: 25),
                        _sectionTitle(
                          'Persyaratan Lomba',
                          subtitle: 'Ketentuan yang harus dipenuhi peserta.',
                          icon: Icons.fact_check_outlined,
                        ),
                        SizedBox(height: 13),
                        _buildRequirements(),
                      ],

                      SizedBox(height: 25),

                      // TOMBOL DAFTAR
                      _buildRegisterButton(),

                      SizedBox(height: 18),

                      Center(
                        child: Text(
                          'TERNATE LOMBA • TEMUKAN PRESTASIMU',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: muted,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}