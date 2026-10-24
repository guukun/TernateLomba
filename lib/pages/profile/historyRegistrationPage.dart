import 'package:flutter/material.dart';

class HistoryRegistrationPage extends StatelessWidget {
  const HistoryRegistrationPage({super.key});

  static const Color primary = Color(0xFF3478E5);
  static const Color lightBlue = Color(0xFFEAF2FF);
  static const Color background = Color(0xFFF5F7FB);
  static const Color textColor = Color(0xFF202938);
  static const Color muted = Color(0xFF667085);
  static const Color borderColor = Color(0xFFE8EDF4);

  final List<Map<String, String>> history = const [
    {'nama': 'Lomba UI/UX Nasional', 'tanggal': '12 Oktober 2026'},
    {'nama': 'Mobile Competition', 'tanggal': '20 September 2026'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded, color: textColor),
        ),
        title: const Text(
          'Riwayat Pendaftaran',
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: borderColor),
        ),
      ),
      body: SafeArea(
        child: history.isEmpty
            ? _buildEmptyState()
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 30),
                children: [
                  // HEADER
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFDCE9FF), Color(0xFFF0F5FF)],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 57,
                          height: 57,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(
                            Icons.history_rounded,
                            color: primary,
                            size: 29,
                          ),
                        ),
                        const SizedBox(width: 15),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Aktivitas Kamu',
                                style: TextStyle(
                                  color: primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                'Riwayat Lomba',
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                'Daftar lomba yang pernah didaftarkan.',
                                style: TextStyle(
                                  color: muted,
                                  fontSize: 12,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 27),

                  // JUDUL DAFTAR
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Riwayat Kamu',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: lightBlue,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${history.length} lomba',
                          style: const TextStyle(
                            color: primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 15),

                  // DAFTAR RIWAYAT
                  ...history.map((item) => _buildHistoryCard(item)),
                ],
              ),
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, String> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 13),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF344054).withValues(alpha: 0.025),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 49,
            height: 49,
            decoration: BoxDecoration(
              color: lightBlue,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.emoji_events_outlined,
              color: primary,
              size: 25,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['nama'] ?? 'Nama lomba tidak tersedia',
                  style: const TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 9),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      color: muted,
                      size: 15,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        item['tanggal'] ?? '-',
                        style: const TextStyle(color: muted, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: lightBlue,
                borderRadius: BorderRadius.circular(27),
              ),
              child: const Icon(
                Icons.history_rounded,
                size: 38,
                color: primary,
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'Belum ada riwayat',
              style: TextStyle(
                color: textColor,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 9),
            const Text(
              'Riwayat pendaftaran lomba akan muncul di sini.',
              textAlign: TextAlign.center,
              style: TextStyle(color: muted, fontSize: 13, height: 1.7),
            ),
          ],
        ),
      ),
    );
  }
}