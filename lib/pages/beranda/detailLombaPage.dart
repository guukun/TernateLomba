import 'package:flutter/material.dart';

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

  static const Color primary = AppColors.primary;
  static const Color primaryDark = AppColors.primaryDark;
  static const Color cream = AppColors.cream;
  static const Color creamLight = AppColors.creamLight;
  static const Color creamDark = AppColors.creamDark;
  static const Color background = AppColors.background;
  static const Color textColor = AppColors.navy;
  static const Color muted = AppColors.grey;
  static const Color borderColor = AppColors.fieldBorder;

  // ==========================================
  // STATE
  // ==========================================

  late Map<String, String> lomba;

  bool isLoadingDetail = true;
  String? errorDetail;

  @override
  void initState() {
    super.initState();

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

      setState(() {
        lomba = {
          'id_lomba': data['id_lomba']?.toString() ?? '',
          'id_pengajuan': data['id_pengajuan']?.toString() ?? '',
          'judul': data['nama_lomba']?.toString() ?? '',
          'kategori': kategoriMap['nama_kategori']?.toString() ?? '',
          'penyelenggara': penyelenggaraMap['username']?.toString() ?? '',
          'deskripsi': data['deskripsi']?.toString() ?? '',
          'persyaratan': data['persyaratan']?.toString() ?? '',
          'kuota': data['kuota_peserta']?.toString() ?? '',
          'biaya': biaya == 0 ? 'Gratis' : 'Rp${biaya.toStringAsFixed(0)}',
          'hadiah': data['hadiah']?.toString() ?? '',
          'batas_pendaftaran': data['batas_pendaftaran']?.toString() ?? '',
          'tanggal_pelaksanaan': data['tanggal_pelaksanaan']?.toString() ?? '',
          'lokasi_pendaftaran': data['lokasi_pendaftaran']?.toString() ?? '',
          'kontak_penyelenggara':
              data['kontak_penyelenggara']?.toString() ?? '',
          'poster_lomba': data['poster_lomba']?.toString() ?? '',
          'status_lomba': data['status_lomba']?.toString() ?? '',
        };

        isLoadingDetail = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorDetail = e.toString();
        isLoadingDetail = false;
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

  int get totalKuota {
    return int.tryParse(lomba['kuota']?.trim() ?? '') ?? 0;
  }

  String get informasiKuota {
    if (totalKuota <= 0) {
      return 'Kuota tidak dibatasi atau belum tersedia';
    }

    return 'Kapasitas maksimal $totalKuota peserta';
  }

  String get _posterUrl {
    return lomba['poster_lomba'] ?? '';
  }

  // ==========================================
  // CARD DECORATION
  // ==========================================

  BoxDecoration _cardDecoration({Color color = AppColors.surface}) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: borderColor),
      boxShadow: [
        BoxShadow(
          color: primaryDark.withValues(alpha: 0.035),
          blurRadius: 16,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }

  // ==========================================
  // HEADER
  // ==========================================

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 15, 20, 25),
      decoration: const BoxDecoration(
        color: primaryDark,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
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
                    width: 43,
                    height: 43,
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
                  'Detail Lomba',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: cream,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.emoji_events_outlined, color: primary, size: 15),
                    SizedBox(width: 5),
                    Text(
                      'LOMBA',
                      style: TextStyle(
                        color: primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.7,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          const Text(
            'TEMUKAN PELUANG BERPRESTASI',
            style: TextStyle(
              color: cream,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Kenali Lomba Lebih Dekat',
            style: TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Pelajari informasi, ketentuan, dan kesempatan '
            'yang tersedia sebelum mendaftar.',
            style: TextStyle(
              color: Color(0xFFDCE6F0),
              fontSize: 12,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // POSTER
  // ==========================================

  Widget _buildPoster() {
    final posterUrl = ApiService.publicStorageUrl(_posterUrl);

    return ClipRRect(
      borderRadius: BorderRadius.circular(19),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: posterUrl != null
            ? Image.network(
                posterUrl,
                width: double.infinity,
                fit: BoxFit.cover,
                cacheWidth: 1000,
                gaplessPlayback: true,
                errorBuilder: (_, _, _) => _posterFallback(),
              )
            : _posterFallback(),
      ),
    );
  }

  Widget _posterFallback() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [creamLight, cream, creamDark],
        ),
      ),
      child: const Column(
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
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPoster(),

          const SizedBox(height: 17),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: cream,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              getValue('kategori'),
              style: const TextStyle(
                color: primary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),

          const SizedBox(height: 13),

          Text(
            getValue('judul', fallback: 'Detail Lomba'),
            style: const TextStyle(
              color: textColor,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.3,
              letterSpacing: -0.3,
            ),
          ),

          const SizedBox(height: 13),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.account_balance_outlined,
                color: primary,
                size: 19,
              ),

              const SizedBox(width: 9),

              Expanded(
                child: Text(
                  getValue('penyelenggara'),
                  style: const TextStyle(
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: cream,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: primary, size: 20),
          ),
          const SizedBox(width: 11),
        ],

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),

              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: muted,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================
  // STATUS / KUOTA
  // ==========================================

  Widget _buildQuotaCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
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
                    const Text(
                      'Kuota Peserta',
                      style: TextStyle(color: muted, fontSize: 12),
                    ),

                    const SizedBox(height: 7),

                    Text(
                      informasiKuota,
                      style: const TextStyle(
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
                child: const Icon(
                  Icons.groups_rounded,
                  color: primary,
                  size: 24,
                ),
              ),
            ],
          ),

          const SizedBox(height: 17),

          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: const LinearProgressIndicator(
              value: 0,
              minHeight: 8,
              backgroundColor: creamDark,
              color: primary,
            ),
          ),

          const SizedBox(height: 10),

          const Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 15, color: muted),
              SizedBox(width: 7),
              Expanded(
                child: Text(
                  'Jumlah peserta terdaftar belum tersedia.',
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
  // INFORMATION BOX
  // ==========================================

  Widget _infoBox({
    required IconData icon,
    required String title,
    required String value,
    bool highlight = false,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 145),
      padding: const EdgeInsets.all(13),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: cream,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: primary, size: 20),
          ),

          const SizedBox(height: 13),

          Text(
            title,
            style: const TextStyle(color: muted, fontSize: 11, height: 1.4),
          ),

          const SizedBox(height: 7),

          Text(
            value,
            style: TextStyle(
              color: highlight ? AppColors.green : textColor,
              fontSize: 13,
              height: 1.45,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // INFORMASI LOMBA
  // ==========================================

  Widget _buildInformationGrid() {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _infoBox(
                icon: Icons.payments_outlined,
                title: 'Biaya Pendaftaran',
                value: getValue('biaya'),
                highlight: getValue('biaya') == 'Gratis',
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: _infoBox(
                icon: Icons.emoji_events_outlined,
                title: 'Hadiah',
                value: getValue('hadiah'),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _infoBox(
                icon: Icons.event_available_outlined,
                title: 'Batas Pendaftaran',
                value: getValue('batas_pendaftaran'),
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: _infoBox(
                icon: Icons.calendar_month_outlined,
                title: 'Tanggal Pelaksanaan',
                value: getValue('tanggal_pelaksanaan'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ==========================================
  // DETAIL TAMBAHAN
  // ==========================================

  Widget _buildAdditionalInformation() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          _detailRow(
            Icons.location_on_outlined,
            'Lokasi',
            getValue('lokasi_pendaftaran'),
          ),

          _detailDivider(),

          _detailRow(
            Icons.phone_outlined,
            'Kontak Penyelenggara',
            getValue('kontak_penyelenggara'),
          ),

          _detailDivider(),

          _detailRow(Icons.groups_outlined, 'Kuota', informasiKuota),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 37,
            height: 37,
            decoration: BoxDecoration(
              color: cream,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: primary, size: 19),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: muted, fontSize: 11)),

                const SizedBox(height: 5),

                Text(
                  value,
                  style: const TextStyle(
                    color: textColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailDivider() {
    return const Divider(height: 1, thickness: 0.8, color: borderColor);
  }

  // ==========================================
  // DESKRIPSI
  // ==========================================

  Widget _buildDescription() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: _cardDecoration(),
      child: Text(
        getValue('deskripsi', fallback: 'Belum ada deskripsi lomba.'),
        style: const TextStyle(color: muted, fontSize: 13, height: 1.8),
      ),
    );
  }

  // ==========================================
  // PERSYARATAN
  // ==========================================

  Widget _buildRequirements() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
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
                child: const Icon(
                  Icons.fact_check_outlined,
                  color: primary,
                  size: 20,
                ),
              ),

              const SizedBox(width: 11),

              const Expanded(
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

          const SizedBox(height: 15),

          Text(
            getValue(
              'persyaratan',
              fallback: 'Informasi persyaratan belum tersedia.',
            ),
            style: const TextStyle(color: muted, fontSize: 13, height: 1.8),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TOMBOL PENDAFTARAN
  // ==========================================

  Widget _buildRegisterButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: () {
          final idLomba = int.tryParse(lomba['id_lomba'] ?? '');

          if (idLomba == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('ID lomba tidak valid.')),
            );
            return;
          }

          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  FormulirPesertaPage(idLomba: idLomba, token: widget.token),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Daftar Sekarang',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),

            SizedBox(width: 9),

            Icon(Icons.arrow_forward_rounded, size: 19),
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
          const SizedBox(height: 100),

          const CircularProgressIndicator(color: primary, strokeWidth: 3),

          const SizedBox(height: 20),

          const Text(
            'Memuat informasi lomba...',
            style: TextStyle(
              color: muted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 100),
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
      padding: const EdgeInsets.all(23),
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
            child: const Icon(
              Icons.cloud_off_outlined,
              color: primary,
              size: 32,
            ),
          ),

          const SizedBox(height: 16),

          const Text(
            'Gagal Memuat Detail',
            style: TextStyle(
              color: textColor,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            errorDetail ?? 'Terjadi kesalahan.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: muted, fontSize: 12, height: 1.6),
          ),

          const SizedBox(height: 18),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _loadDetailLomba,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba Lagi'),
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
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // HEADER IKUT TERSCROLL

              _buildHeader(),

              Padding(
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 35),
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

                      const SizedBox(height: 25),

                      // STATUS DAN KUOTA
                      _sectionTitle(
                        'Status Pendaftaran',
                        subtitle: 'Informasi kapasitas peserta lomba.',
                        icon: Icons.groups_outlined,
                      ),

                      const SizedBox(height: 13),

                      _buildQuotaCard(),

                      const SizedBox(height: 25),

                      // INFORMASI LOMBA
                      _sectionTitle(
                        'Informasi Lomba',
                        subtitle: 'Biaya, hadiah, dan jadwal kegiatan.',
                        icon: Icons.event_note_outlined,
                      ),

                      const SizedBox(height: 13),

                      _buildInformationGrid(),

                      const SizedBox(height: 25),

                      // INFORMASI TAMBAHAN
                      _sectionTitle(
                        'Informasi Tambahan',
                        subtitle: 'Lokasi dan kontak penyelenggara.',
                        icon: Icons.info_outline_rounded,
                      ),

                      const SizedBox(height: 13),

                      _buildAdditionalInformation(),

                      const SizedBox(height: 25),

                      // DESKRIPSI
                      _sectionTitle(
                        'Deskripsi Lomba',
                        subtitle: 'Kenali kegiatan yang akan diikuti.',
                        icon: Icons.description_outlined,
                      ),

                      const SizedBox(height: 13),

                      _buildDescription(),

                      const SizedBox(height: 25),

                      // PERSYARATAN
                      _sectionTitle(
                        'Persyaratan Lomba',
                        subtitle: 'Ketentuan yang harus dipenuhi peserta.',
                        icon: Icons.fact_check_outlined,
                      ),

                      const SizedBox(height: 13),

                      _buildRequirements(),

                      const SizedBox(height: 25),

                      // TOMBOL DAFTAR
                      _buildRegisterButton(),

                      const SizedBox(height: 18),

                      const Center(
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
