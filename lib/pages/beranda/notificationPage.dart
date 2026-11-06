import 'package:flutter/material.dart';

import '../../config/appTheme.dart';

class _NotificationItem {
  final int id;
  final String title;
  final String message;
  final String timeLabel;
  bool isRead;

  _NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.timeLabel,
    this.isRead = false,
  });
}

class NotifikasiPage extends StatefulWidget {
  const NotifikasiPage({super.key, String? token, String? baseApiUrl});

  @override
  State<NotifikasiPage> createState() => _NotifikasiPageState();
}

class _NotifikasiPageState extends State<NotifikasiPage> {
  // ==========================================
  // APP THEME
  // ==========================================

  static const Color primary = AppColors.primary;
  static const Color primaryDark = AppColors.primaryDark;
  static const Color cream = AppColors.cream;
  static const Color creamDark = AppColors.creamDark;
  static const Color creamLight = AppColors.creamLight;
  static const Color background = AppColors.background;
  static const Color textColor = AppColors.navy;
  static const Color muted = AppColors.grey;
  static const Color borderColor = AppColors.fieldBorder;

  // ==========================================
  // DATA NOTIFIKASI LOKAL
  // ==========================================

  final List<_NotificationItem> notifications = [
    _NotificationItem(
      id: 1,
      title: 'Pengajuan Lomba Disetujui',
      message:
          'Pengajuan lomba "Kompetisi Karya Tulis Ilmiah" '
          'berhasil disetujui dan telah diterbitkan.',
      timeLabel: 'Baru saja',
      isRead: false,
    ),
    _NotificationItem(
      id: 2,
      title: 'Pengajuan Lomba Ditolak',
      message:
          'Pengajuan lomba "Festival Teknologi 2026" ditolak. '
          'Catatan admin: Persyaratan belum lengkap.',
      timeLabel: 'Kemarin',
      isRead: false,
    ),
  ];

  // ==========================================
  // HELPER
  // ==========================================

  int get unreadCount => notifications.where((item) => !item.isRead).length;

  Future<void> _refreshDummy() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));

    if (!mounted) return;

    setState(() {});
  }

  void markAsRead(_NotificationItem item) {
    if (item.isRead) return;

    setState(() {
      item.isRead = true;
    });
  }

  void markAllAsRead() {
    if (unreadCount == 0) return;

    setState(() {
      for (final item in notifications) {
        item.isRead = true;
      }
    });

    _showMessage('Semua notifikasi sudah dibaca.');
  }

  void deleteNotification(_NotificationItem item) {
    setState(() {
      notifications.removeWhere((n) => n.id == item.id);
    });

    _showMessage('Notifikasi berhasil dihapus.');
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: primaryDark,
        ),
      );
  }

  // ==========================================
  // ICON STATUS
  // ==========================================

  IconData getIcon(String title) {
    final value = title.toLowerCase();

    if (value.contains('disetujui')) {
      return Icons.check_circle_rounded;
    }

    if (value.contains('ditolak')) {
      return Icons.cancel_rounded;
    }

    return Icons.notifications_rounded;
  }

  Color getIconColor(String title) {
    final value = title.toLowerCase();

    if (value.contains('disetujui')) {
      return AppColors.green;
    }

    if (value.contains('ditolak')) {
      return AppColors.error;
    }

    return primary;
  }

  // ==========================================
  // HEADER
  // ==========================================

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(21, 18, 21, 27),
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
                  'Notifikasi',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),

              if (unreadCount > 0)
                Material(
                  color: cream,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: markAllAsRead,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 9,
                      ),
                      child: Text(
                        'Baca Semua',
                        style: TextStyle(
                          color: primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 27),

          const Text(
            'INFORMASI TERBARU',
            style: TextStyle(
              color: cream,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Tetap Terhubung',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Dapatkan informasi mengenai perkembangan '
            'pengajuan lomba Anda.',
            style: TextStyle(
              color: Color(0xFFDCE6F0),
              fontSize: 12,
              height: 1.6,
            ),
          ),

          const SizedBox(height: 20),

          // SUMMARY NOTIFIKASI
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(19),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Row(
              children: [
                Container(
                  width: 43,
                  height: 43,
                  decoration: BoxDecoration(
                    color: cream,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.notifications_active_outlined,
                    color: primary,
                    size: 22,
                  ),
                ),

                const SizedBox(width: 13),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Notifikasi Anda',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        '${notifications.length} informasi tersedia',
                        style: const TextStyle(
                          color: Color(0xFFDCE6F0),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: cream,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$unreadCount Baru',
                    style: const TextStyle(
                      color: primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
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

  // ==========================================
  // SECTION TITLE
  // ==========================================

  Widget _buildSectionTitle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 25, 20, 15),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Aktivitas Terbaru',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                SizedBox(height: 4),

                Text(
                  'Informasi keputusan pengajuan lomba.',
                  style: TextStyle(color: muted, fontSize: 11),
                ),
              ],
            ),
          ),

          if (unreadCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: cream,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$unreadCount belum dibaca',
                style: const TextStyle(
                  color: primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ==========================================
  // EMPTY STATE
  // ==========================================

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(vertical: 35, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Container(
            width: 75,
            height: 75,
            decoration: BoxDecoration(
              color: cream,
              borderRadius: BorderRadius.circular(23),
            ),
            child: const Icon(
              Icons.notifications_off_outlined,
              color: primary,
              size: 35,
            ),
          ),

          const SizedBox(height: 17),

          const Text(
            'Belum Ada Notifikasi',
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Informasi mengenai pengajuan lomba '
            'akan muncul di sini.',
            textAlign: TextAlign.center,
            style: TextStyle(color: muted, fontSize: 12, height: 1.6),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // NOTIFICATION CARD
  // ==========================================

  Widget _notificationCard(_NotificationItem item) {
    final iconColor = getIconColor(item.title);

    return Dismissible(
      key: ValueKey('notification-${item.id}'),
      direction: DismissDirection.endToStart,

      onDismissed: (_) {
        deleteNotification(item);
      },

      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 22),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_outline_rounded, color: Colors.white, size: 25),
            SizedBox(height: 4),
            Text(
              'Hapus',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),

      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => markAsRead(item),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: item.isRead ? borderColor : creamDark),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 47,
                  height: 47,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(getIcon(item.title), color: iconColor, size: 23),
                ),

                const SizedBox(width: 13),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              style: TextStyle(
                                color: textColor,
                                fontSize: 13,
                                height: 1.4,
                                fontWeight: item.isRead
                                    ? FontWeight.w600
                                    : FontWeight.w800,
                              ),
                            ),
                          ),

                          if (!item.isRead) ...[
                            const SizedBox(width: 7),
                            Container(
                              width: 9,
                              height: 9,
                              margin: const EdgeInsets.only(top: 5),
                              decoration: const BoxDecoration(
                                color: primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 7),

                      Text(
                        item.message,
                        style: const TextStyle(
                          color: muted,
                          fontSize: 12,
                          height: 1.6,
                        ),
                      ),

                      const SizedBox(height: 11),

                      Row(
                        children: [
                          const Icon(
                            Icons.access_time_rounded,
                            size: 13,
                            color: muted,
                          ),

                          const SizedBox(width: 5),

                          Text(
                            item.timeLabel,
                            style: const TextStyle(
                              color: muted,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          const Spacer(),

                          if (!item.isRead)
                            const Text(
                              'Ketuk untuk membaca',
                              style: TextStyle(
                                color: primary,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            )
                          else
                            const Text(
                              'Sudah dibaca',
                              style: TextStyle(
                                color: AppColors.green,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
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
        child: RefreshIndicator(
          color: primary,
          backgroundColor: creamLight,
          onRefresh: _refreshDummy,

          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),

            slivers: [
              // HEADER

              SliverToBoxAdapter(child: _buildHeader()),

              // JUDUL SECTION
              SliverToBoxAdapter(child: _buildSectionTitle()),

              // EMPTY STATE
              if (notifications.isEmpty)
                SliverToBoxAdapter(child: _buildEmptyState())
              // NOTIFICATION LIST
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 30),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final itemIndex = index ~/ 2;

                      if (index.isOdd) {
                        return const SizedBox(height: 11);
                      }

                      return _notificationCard(notifications[itemIndex]);
                    }, childCount: notifications.length * 2 - 1),
                  ),
                ),

              // FOOTER
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(top: 5, bottom: 35),
                  child: Center(
                    child: Text(
                      'TERNATE LOMBA • INFORMASI PENGAJUAN',
                      style: TextStyle(
                        color: muted,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
