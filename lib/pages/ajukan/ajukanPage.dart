import '../../widgets/app_feedback.dart';
import 'package:flutter/material.dart';
import '../../config/appTheme.dart';
import '../../design_system/tl_playful.dart';
import 'formAjukanLombaPage.dart';

// AjukanPage
class AjukanPage extends StatefulWidget {
  final String? token;
  final VoidCallback? onLombaDiajukan;

  const AjukanPage({super.key, this.token, this.onLombaDiajukan});

  @override
  State<AjukanPage> createState() => _AjukanPageState();
}

class _AjukanPageState extends State<AjukanPage> {
  // Warna mengikuti AppTheme aplikasi.
  Color get darkBlue => context.tl.primaryDark;
  Color get primaryBlue => context.tl.primary;
  Color get cream => context.tl.cream;
  Color get creamLight => context.tl.creamLight;
  Color get creamDark => context.tl.creamDark;
  Color get background => context.tl.background;
  Color get textColor => context.tl.navy;
  Color get mutedColor => context.tl.grey;
  Color get borderColor => context.tl.fieldBorder;

  Future<void> _bukaFormPengajuan(BuildContext context) async {
    final apiToken = widget.token?.trim();

    if (apiToken == null || apiToken.isEmpty) {
      AppNotification.message(
        context,
        'Silakan login terlebih dahulu untuk mengajukan lomba.',
        type: NotificationType.info,
      );
      return;
    }

    final berhasil = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => FormAjukanLombaPage(token: apiToken)),
    );

    if (!context.mounted) return;

    if (berhasil == true) {
      widget.onLombaDiajukan?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          padding: EdgeInsets.only(
            bottom: 125 + MediaQuery.of(context).padding.bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),

              Padding(
                padding: EdgeInsets.fromLTRB(20, 24, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildIntroCard(),

                    SizedBox(height: 28),

                    _buildSectionHeading(
                      'Syarat dan Ketentuan',
                      'Pastikan pengajuan memenuhi ketentuan berikut.',
                    ),

                    SizedBox(height: 17),

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

                    SizedBox(height: 18),

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

  Widget _buildHeader() => TLPlayful.decoratedHeading(
    context,
    title: 'Make your\nidea real.',
    subtitle:
        'Buka peluang untuk banyak talenta melalui kompetisi yang kamu buat.',
    accent: context.tl.mint,
    icon: Icons.rocket_launch_rounded,
  );

  // ============================================================
  // INTRO CARD
  // ============================================================

  Widget _buildIntroCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(21),
      decoration: BoxDecoration(
        color: creamLight,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: creamDark, width: 1.1),
        boxShadow: [
          BoxShadow(
            color: darkBlue.withValues(alpha: 0.045),
            blurRadius: 18,
            offset: Offset(0, 6),
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
                child: Icon(Icons.emoji_events_rounded, color: cream, size: 29),
              ),

              SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TERNATELOMBA',
                      style: TextStyle(
                        color: darkBlue,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),

                    SizedBox(height: 5),

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

          SizedBox(height: 22),

          Text(
            'Publikasikan kompetisimu!',
            style: TextStyle(
              color: textColor,
              fontSize: 19,
              fontWeight: FontWeight.w800,
              height: 1.35,
            ),
          ),

          SizedBox(height: 9),

          Text(
            'Ajukan informasi lomba yang kamu selenggarakan. '
            'Tim admin akan melakukan pemeriksaan sebelum '
            'lomba ditampilkan kepada pengguna.',
            style: TextStyle(color: mutedColor, fontSize: 13, height: 1.8),
          ),

          SizedBox(height: 18),

          Container(
            padding: EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: cream,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                Icon(Icons.shield_outlined, color: darkBlue, size: 21),

                SizedBox(width: 11),

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
          style: TextStyle(
            color: textColor,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),

        SizedBox(height: 7),

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
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: creamLight,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: darkBlue.withValues(alpha: 0.025),
            blurRadius: 10,
            offset: Offset(0, 3),
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

          SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'KETENTUAN $number',
                  style: TextStyle(
                    color: darkBlue,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.7,
                  ),
                ),

                SizedBox(height: 5),

                Text(
                  text,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 12,
                    height: 1.65,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(width: 5),

          Icon(Icons.check_circle_rounded, color: darkBlue, size: 18),
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
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: darkBlue,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: darkBlue.withValues(alpha: 0.15),
            blurRadius: 17,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.rocket_launch_rounded, color: cream, size: 29),

          SizedBox(height: 14),

          Text(
            'Siap mengajukan lomba?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),

          SizedBox(height: 7),

          Text(
            'Lengkapi informasi lomba dan kirimkan '
            'pengajuan untuk diperiksa oleh admin.',
            style: TextStyle(
              color: creamLight.withValues(alpha: 0.85),
              fontSize: 12,
              height: 1.7,
            ),
          ),

          SizedBox(height: 19),

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
              icon: Icon(Icons.add_circle_outline_rounded, size: 20),
              label: Text(
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