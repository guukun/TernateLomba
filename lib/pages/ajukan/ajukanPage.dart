import 'package:flutter/material.dart';

import '../../config/appTheme.dart';
import 'formAjukanLombaPage.dart';

class AjukanPage extends StatelessWidget {
  final String? token;
  final VoidCallback? onLombaDiajukan;

  const AjukanPage({super.key, this.token, this.onLombaDiajukan});

  // Warna mengikuti AppTheme aplikasi.
  static const Color darkBlue = AppColors.primaryDark;
  static const Color primaryBlue = AppColors.primary;
  static const Color cream = AppColors.cream;
  static const Color creamLight = AppColors.creamLight;
  static const Color creamDark = AppColors.creamDark;
  static const Color background = AppColors.background;
  static const Color textColor = AppColors.navy;
  static const Color mutedColor = AppColors.grey;
  static const Color borderColor = AppColors.fieldBorder;

  Future<void> _bukaFormPengajuan(BuildContext context) async {
    final apiToken = token?.trim();

    if (apiToken == null || apiToken.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Silakan login terlebih dahulu untuk mengajukan lomba.',
          ),
        ),
      );
      return;
    }

    final berhasil = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => FormAjukanLombaPage(token: apiToken)),
    );

    if (!context.mounted) return;

    if (berhasil == true) {
      onLombaDiajukan?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.only(
            bottom: 125 + MediaQuery.of(context).padding.bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),

              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildIntroCard(),

                    const SizedBox(height: 28),

                    _buildSectionHeading(
                      'Syarat dan Ketentuan',
                      'Pastikan pengajuan memenuhi ketentuan berikut.',
                    ),

                    const SizedBox(height: 17),

                    _buildSyaratItem(
                      number: '01',
                      icon: Icons.info_outline_rounded,
                      text: 'Informasi lomba harus jelas dan valid.',
                    ),

                    _buildSyaratItem(
                      number: '02',
                      icon: Icons.verified_user_outlined,
                      text: 'Tidak mengandung unsur SARA atau penipuan.',
                    ),

                    _buildSyaratItem(
                      number: '03',
                      icon: Icons.gavel_rounded,
                      text: 'Sesuai dengan ketentuan hukum yang berlaku di Indonesia.',
                    ),

                    _buildSyaratItem(
                      number: '04',
                      icon: Icons.fact_check_outlined,
                      text: 'Akan melalui proses verifikasi tim admin TernateLomba (1x24 jam).',
                    ),

                    const SizedBox(height: 18),

                    _buildCallToAction(context),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 30, 24, 35),
      decoration: const BoxDecoration(
        color: darkBlue,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(34),
          bottomRight: Radius.circular(34),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -28,
            top: -45,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.045),
                shape: BoxShape.circle,
              ),
            ),
          ),

          Positioned(
            right: 28,
            bottom: -65,
            child: Container(
              width: 105,
              height: 105,
              decoration: BoxDecoration(
                color: cream.withValues(alpha: 0.07),
                shape: BoxShape.circle,
              ),
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: cream.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lightbulb_outline_rounded,
                      size: 15,
                      color: cream,
                    ),
                    SizedBox(width: 7),
                    Text(
                      'Kembangkan Peluang',
                      style: TextStyle(
                        color: cream,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 17),

              const Text(
                'Ajukan Lomba',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 29,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                'Punya ide kompetisi? Bagikan kesempatan '
                'dan jangkau lebih banyak peserta melalui TernateLomba.',
                style: TextStyle(
                  color: creamLight.withValues(alpha: 0.88),
                  fontSize: 13,
                  height: 1.7,
                  fontWeight: FontWeight.w400,
                ),
              ),

              const SizedBox(height: 23),

              Container(
                width: 62,
                height: 4,
                decoration: BoxDecoration(
                  color: cream,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // INTRO CARD
  // ============================================================

  Widget _buildIntroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(21),
      decoration: BoxDecoration(
        color: creamLight,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: creamDark, width: 1.1),
        boxShadow: [
          BoxShadow(
            color: darkBlue.withValues(alpha: 0.045),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 57,
                height: 57,
                decoration: BoxDecoration(
                  color: darkBlue,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  color: cream,
                  size: 29,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TERNATELOMBA',
                      style: TextStyle(
                        color: darkBlue,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      'Platform Informasi Lomba',
                      style: TextStyle(
                        color: mutedColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          const Text(
            'Publikasikan kompetisimu!',
            style: TextStyle(
              color: textColor,
              fontSize: 19,
              fontWeight: FontWeight.w800,
              height: 1.35,
            ),
          ),

          const SizedBox(height: 9),

          Text(
            'Ajukan informasi lomba yang kamu selenggarakan. '
            'Tim admin akan melakukan pemeriksaan sebelum '
            'lomba ditampilkan kepada pengguna.',
            style: TextStyle(color: mutedColor, fontSize: 13, height: 1.8),
          ),

          const SizedBox(height: 18),

          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: cream,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                const Icon(Icons.shield_outlined, color: darkBlue, size: 21),

                const SizedBox(width: 11),

                Expanded(
                  child: Text(
                    'Setiap pengajuan akan melalui proses verifikasi admin.',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 11,
                      height: 1.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION HEADING
  // ============================================================

  Widget _buildSectionHeading(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: textColor,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),

        const SizedBox(height: 7),

        Text(
          subtitle,
          style: TextStyle(color: mutedColor, fontSize: 12, height: 1.6),
        ),
      ],
    );
  }

  // ============================================================
  // REQUIREMENT ITEM
  // ============================================================

  Widget _buildSyaratItem({
    required String number,
    required IconData icon,
    required String text,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: creamLight,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: darkBlue.withValues(alpha: 0.025),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: cream,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: darkBlue, size: 21),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'KETENTUAN $number',
                  style: const TextStyle(
                    color: darkBlue,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.7,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  text,
                  style: const TextStyle(
                    color: textColor,
                    fontSize: 12,
                    height: 1.65,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 5),

          const Icon(Icons.check_circle_rounded, color: darkBlue, size: 18),
        ],
      ),
    );
  }

  // ============================================================
  // CALL TO ACTION
  // ============================================================

  Widget _buildCallToAction(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: darkBlue,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: darkBlue.withValues(alpha: 0.15),
            blurRadius: 17,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.rocket_launch_rounded, color: cream, size: 29),

          const SizedBox(height: 14),

          const Text(
            'Siap mengajukan lomba?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 7),

          Text(
            'Lengkapi informasi lomba dan kirimkan '
            'pengajuan untuk diperiksa oleh admin.',
            style: TextStyle(
              color: creamLight.withValues(alpha: 0.85),
              fontSize: 12,
              height: 1.7,
            ),
          ),

          const SizedBox(height: 19),

          SizedBox(
            width: double.infinity,
            height: 51,
            child: ElevatedButton.icon(
              onPressed: () => _bukaFormPengajuan(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: cream,
                foregroundColor: darkBlue,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
              label: const Text(
                'Mulai Pengajuan',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
