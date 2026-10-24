import 'package:flutter/material.dart';
import 'formulirPesertaPage.dart';

class DetailLombaPage extends StatelessWidget {
  final Map<String, String> lomba;

  const DetailLombaPage({super.key, required this.lomba});

  static const Color primary = Color(0xFF3478E5);
  static const Color primaryLight = Color(0xFFEAF2FF);
  static const Color background = Color(0xFFF5F7FB);
  static const Color textColor = Color(0xFF202938);
  static const Color muted = Color(0xFF667085);
  static const Color borderColor = Color(0xFFE8EDF4);

  String getValue(String key, {String fallback = 'Belum tersedia'}) {
    final value = lomba[key]?.trim();
    if (value == null || value.isEmpty) return fallback;
    return value;
  }

  int get kuotaTerisi {
    final kuota = getValue('kuota', fallback: '');
    final parts = kuota.split('/');
    if (parts.isEmpty) return 0;
    return int.tryParse(parts.first.trim()) ?? 0;
  }

  int get totalKuota {
    final kuota = getValue('kuota', fallback: '');
    final parts = kuota.split('/');
    if (parts.length < 2) return 0;
    return int.tryParse(parts[1].trim()) ?? 0;
  }

  double get progressKuota {
    if (totalKuota <= 0) return 0;

    return (kuotaTerisi / totalKuota).clamp(0.0, 1.0);
  }

  String get sisaKuota {
    if (totalKuota <= 0) return 'Informasi kuota belum tersedia';
    final sisa = totalKuota - kuotaTerisi;
    return sisa > 0 ? '$sisa kuota masih tersedia' : 'Kuota telah terpenuhi';
  }

  @override
  Widget build(BuildContext context) {
    final judul = getValue('judul', fallback: 'Detail Lomba');
    final kategori = getValue('kategori');
    final penyelenggara = getValue('penyelenggara');
    final deskripsi = getValue(
      'deskripsi',
      fallback: 'Belum ada deskripsi lomba.',
    );
    final persyaratan = getValue(
      'persyaratan',
      fallback: 'Informasi persyaratan belum tersedia.',
    );

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            // HEADER
            SliverToBoxAdapter(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(22, 14, 22, 28),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFDCE9FF),
                      Color(0xFFEAF2FF),
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
                    Row(
                      children: [
                        _circleButton(
                          icon: Icons.arrow_back_rounded,
                          onTap: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Text(
                            'Detail Lomba',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: textColor,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.verified_outlined,
                                color: primary,
                                size: 16,
                              ),
                              SizedBox(width: 5),
                              Text(
                                'Lomba',
                                style: TextStyle(
                                  color: primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.82),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: primary.withValues(alpha: 0.06),
                            blurRadius: 22,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: primaryLight,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              kategori,
                              style: const TextStyle(
                                color: primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            judul,
                            style: const TextStyle(
                              fontSize: 24,
                              height: 1.3,
                              fontWeight: FontWeight.w800,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.account_balance_outlined,
                                size: 18,
                                color: primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  penyelenggara,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    height: 1.5,
                                    color: muted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ISI HALAMAN
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 30),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _sectionTitle('Status Pendaftaran'),
                  const SizedBox(height: 12),

                  _surfaceCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Kuota terisi',
                                    style: TextStyle(
                                      color: muted,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    totalKuota > 0
                                        ? '$kuotaTerisi dari $totalKuota peserta'
                                        : getValue('kuota'),
                                    style: const TextStyle(
                                      color: textColor,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(11),
                              decoration: BoxDecoration(
                                color: primaryLight,
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: const Icon(
                                Icons.people_alt_outlined,
                                color: primary,
                                size: 23,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: LinearProgressIndicator(
                            value: totalKuota > 0 ? progressKuota : null,
                            minHeight: 8,
                            backgroundColor: const Color(0xFFE9EEF6),
                            color: primary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          sisaKuota,
                          style: const TextStyle(color: muted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  _sectionTitle('Informasi Lomba'),
                  const SizedBox(height: 12),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _infoBox(
                          icon: Icons.payments_outlined,
                          title: 'Biaya Pendaftaran',
                          value: getValue('biaya'),
                          accent: const Color(0xFF21866D),
                          iconBackground: const Color(0xFFE2F5EE),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _infoBox(
                          icon: Icons.emoji_events_outlined,
                          title: 'Hadiah',
                          value: getValue('hadiah'),
                          accent: primary,
                          iconBackground: primaryLight,
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
                          icon: Icons.event_outlined,
                          title: 'Batas Pendaftaran',
                          value: getValue(
                            'batasPendaftaran',
                            fallback: 'Belum tersedia',
                          ),
                          accent: const Color(0xFFB7791F),
                          iconBackground: const Color(0xFFFFF3D9),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _infoBox(
                          icon: Icons.calendar_month_outlined,
                          title: 'Pelaksanaan',
                          value: getValue(
                            'pelaksanaan',
                            fallback: 'Belum tersedia',
                          ),
                          accent: const Color(0xFF8063C9),
                          iconBackground: const Color(0xFFF0EAFF),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 26),
                  _sectionTitle('Deskripsi Lomba'),
                  const SizedBox(height: 12),

                  _surfaceCard(
                    child: Text(
                      deskripsi,
                      style: const TextStyle(
                        color: muted,
                        fontSize: 14,
                        height: 1.8,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  _sectionTitle('Persyaratan Lomba'),
                  const SizedBox(height: 12),

                  _surfaceCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.fact_check_outlined,
                              color: primary,
                              size: 21,
                            ),
                            SizedBox(width: 9),
                            Text(
                              'Ketentuan peserta',
                              style: TextStyle(
                                color: textColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          persyaratan,
                          style: const TextStyle(
                            color: muted,
                            fontSize: 14,
                            height: 1.8,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),
                ]),
              ),
            ),
          ],
        ),
      ),

      // TOMBOL PENDAFTARAN
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
          20,
          14,
          20,
          MediaQuery.of(context).padding.bottom + 14,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(top: BorderSide(color: borderColor)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.035),
              blurRadius: 16,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SizedBox(
          height: 54,
          child: ElevatedButton(
            // Mempertahankan perilaku tombol dari kode awal.
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const FormulirPesertaPage()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
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
                  'Daftar Sekarang',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
                SizedBox(width: 9),
                Icon(Icons.arrow_forward_rounded, size: 19),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _circleButton({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: textColor, size: 21),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: textColor,
        fontSize: 18,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _surfaceCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF344054).withValues(alpha: 0.025),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _infoBox({
    required IconData icon,
    required String title,
    required String value,
    required Color accent,
    required Color iconBackground,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 142),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 37,
            height: 37,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accent, size: 20),
          ),
          const SizedBox(height: 13),
          Text(
            title,
            style: const TextStyle(color: muted, fontSize: 11, height: 1.4),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: value == 'Belum tersedia' ? muted : accent,
              fontSize: 13,
              height: 1.4,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}