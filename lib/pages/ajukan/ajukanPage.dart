import 'package:flutter/material.dart';

import 'formAjukanLombaPage.dart';

class AjukanPage extends StatelessWidget {
  final String? token;
  final VoidCallback? onLombaDiajukan;

  const AjukanPage({
    super.key,
    this.token,
    this.onLombaDiajukan,
  });

  static const Color primaryBlue = Color(0xFF3478E5);
  static const Color lightBlue = Color(0xFFEAF2FF);
  static const Color backgroundColor = Color(0xFFF5F7FB);
  static const Color textColor = Color(0xFF202938);
  static const Color mutedColor = Color(0xFF667085);
  static const Color borderColor = Color(0xFFE8EDF4);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // HEADER
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 27),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFDCE9FF),
                    Color(0xFFEDF3FF),
                    Color(0xFFF5F7FB),
                  ],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Kembangkan Peluang',
                    style: TextStyle(
                      color: primaryBlue,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Ajukan Lomba',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 27,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 9),
                  const Text(
                    'Punya ide kompetisi? Ajukan agar lebih banyak orang dapat berpartisipasi.',
                    style: TextStyle(
                      color: mutedColor,
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),

            // KONTEN
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 160),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // KARTU PENGANTAR
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: borderColor),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF344054)
                                .withValues(alpha: 0.035),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: lightBlue,
                              borderRadius: BorderRadius.circular(19),
                            ),
                            child: const Icon(
                              Icons.description_outlined,
                              color: primaryBlue,
                              size: 30,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Ajukan Lomba di TernateLomba',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Ingin mengadakan lomba? Ajukan sekarang untuk ditampilkan kepada pelajar dan masyarakat melalui TernateLomba.',
                            style: TextStyle(
                              color: mutedColor,
                              fontSize: 14,
                              height: 1.8,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // SYARAT DAN KETENTUAN
                    const Text(
                      'Syarat dan Ketentuan',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 7),
                    const Text(
                      'Pastikan pengajuan memenuhi ketentuan berikut.',
                      style: TextStyle(
                        color: mutedColor,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 17),

                    _buildSyaratItem(
                      number: '01',
                      text: 'Informasi lomba harus jelas dan valid.',
                    ),
                    _buildSyaratItem(
                      number: '02',
                      text: 'Tidak mengandung unsur SARA atau penipuan.',
                    ),
                    _buildSyaratItem(
                      number: '03',
                      text: 'Sesuai dengan ketentuan hukum yang berlaku di Indonesia.',
                    ),
                    _buildSyaratItem(
                      number: '04',
                      text: 'Akan melalui proses verifikasi tim admin TernateLomba (1x24 jam).',
                    ),
                  ],
                ),
              ),
            ),

            // TOMBOL PENGAJUAN
            Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                14,
                20,
                MediaQuery.of(context).padding.bottom + 92,
              ),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () async {
                    final apiToken = token?.trim();
                    if (apiToken == null || apiToken.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Silakan login terlebih dahulu untuk mengajukan lomba.'),
                        ),
                      );
                      return;
                    }

                    final berhasil = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => FormAjukanLombaPage(token: apiToken),
                      ),
                    );

                    if (!context.mounted) return;
                    if (berhasil == true) {
                      onLombaDiajukan?.call();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(17),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Mulai Pengajuan Lomba',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(width: 9),
                      Icon(Icons.arrow_forward_rounded, size: 19),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyaratItem({required String number, required String text}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: lightBlue,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Text(
              number,
              style: const TextStyle(
                color: primaryBlue,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                text,
                style: const TextStyle(
                  color: textColor,
                  fontSize: 13,
                  height: 1.65,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          const Padding(
            padding: EdgeInsets.only(top: 3),
            child: Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF3478E5),
              size: 18,
            ),
          ),
        ],
      ),
    );
  }
}
