import 'package:flutter/material.dart';

class NotifikasiPage extends StatelessWidget {
  final List<Map<String, String>> notifications;

  const NotifikasiPage({super.key, required this.notifications});

  static const Color _primary = Color(0xFF3478E5);
  static const Color _text = Color(0xFF202938);
  static const Color _muted = Color(0xFF667085);
  static const Color _background = Color(0xFFF4F7FC);

  IconData _iconFor(String title) {
    final value = title.toLowerCase();

    if (value.contains('pendaftaran')) {
      return Icons.task_alt_rounded;
    }

    if (value.contains('lomba')) {
      return Icons.emoji_events_rounded;
    }

    if (value.contains('status')) {
      return Icons.hourglass_top_rounded;
    }

    return Icons.notifications_active_rounded;
  }

  Color _colorFor(String title) {
    final value = title.toLowerCase();

    if (value.contains('pendaftaran')) {
      return const Color(0xFF3478E5);
    }

    if (value.contains('lomba')) {
      return const Color(0xFF8B65D8);
    }

    if (value.contains('status')) {
      return const Color(0xFFE59A24);
    }

    return const Color(0xFF238A78);
  }

  String _categoryFor(String title) {
    final value = title.toLowerCase();

    if (value.contains('pendaftaran')) {
      return 'PENDAFTARAN';
    }

    if (value.contains('lomba')) {
      return 'INFORMASI LOMBA';
    }

    if (value.contains('status')) {
      return 'PEMBARUAN STATUS';
    }

    return 'PEMBERITAHUAN';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // HEADER DENGAN GRADASI
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF235FC7),
                    Color(0xFF3478E5),
                    Color(0xFF6398F2),
                  ],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    right: -35,
                    top: 15,
                    child: Container(
                      width: 145,
                      height: 145,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.07),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 38,
                    bottom: -46,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.13),
                          width: 18,
                        ),
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Material(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () => Navigator.of(context).pop(),
                              child: const SizedBox(
                                width: 44,
                                height: 44,
                                child: Icon(
                                  Icons.arrow_back_rounded,
                                  color: Colors.white,
                                  size: 23,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 13),
                          const Expanded(
                            child: Text(
                              'PUSAT AKTIVITAS',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.8,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.18),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.notifications_active_rounded,
                                  color: Colors.white,
                                  size: 15,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${notifications.length}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      const Text(
                        'Notifikasi',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          height: 1.15,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.7,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Semua kabar penting tentang aktivitas\n'
                        'dan perjalanan lombamu ada di sini.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.84),
                          fontSize: 13,
                          height: 1.7,
                        ),
                      ),
                      const SizedBox(height: 22),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.13),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.history_rounded,
                              color: Colors.white,
                              size: 17,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${notifications.length} aktivitas tersedia',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // DAFTAR NOTIFIKASI
            Expanded(
              child: notifications.isEmpty
                  ? _buildEmptyState()
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 25, 20, 36),
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Aktivitas terbaru',
                                style: TextStyle(
                                  color: _text,
                                  fontSize: 19,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.4,
                                ),
                              ),
                            ),
                            Text(
                              '${notifications.length} notifikasi',
                              style: const TextStyle(
                                color: _muted,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Informasi yang tersedia untuk akunmu.',
                          style: TextStyle(color: _muted, fontSize: 12),
                        ),
                        const SizedBox(height: 19),
                        ...List.generate(notifications.length, (index) {
                          final item = notifications[index];

                          return Padding(
                            key: ValueKey(
                              '${item['judul']}_${item['waktu']}_$index',
                            ),
                            padding: const EdgeInsets.only(bottom: 13),
                            child: _buildNotificationCard(item),
                          );
                        }),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, String> item) {
    final title = item['judul'] ?? 'Notifikasi';
    final message = item['isi'] ?? '';
    final time = item['waktu'] ?? '';
    final accent = _colorFor(title);

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: const Color(0xFFE7ECF4)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF344054).withValues(alpha: 0.035),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(17),
            ),
            child: Icon(_iconFor(title), color: accent, size: 25),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: _text,
                          fontSize: 14,
                          height: 1.4,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 7,
                      height: 7,
                      margin: const EdgeInsets.only(top: 5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 12,
                    height: 1.65,
                  ),
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Icon(Icons.schedule_rounded, color: accent, size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        time,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _muted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _categoryFor(title),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                        style: TextStyle(
                          color: accent,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
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
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                color: Color(0xFFEAF2FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                size: 45,
                color: _primary,
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'Belum ada kabar baru',
              style: TextStyle(
                color: _text,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 9),
            const Text(
              'Notifikasi mengenai lomba dan aktivitasmu\n'
              'akan ditampilkan di halaman ini.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _muted, fontSize: 13, height: 1.7),
            ),
          ],
        ),
      ),
    );
  }
}