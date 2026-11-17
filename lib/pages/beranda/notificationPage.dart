import 'package:flutter/material.dart';

import '../../config/appTheme.dart';
import '../../services/api_service.dart';

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
  final String token;

  const NotifikasiPage({super.key, required this.token});

  @override
  State<NotifikasiPage> createState() => _NotifikasiPageState();
}

class _NotifikasiPageState extends State<NotifikasiPage> {
  bool isLoading = true;
  String? loadError;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  String _formatTime(dynamic raw) {
    if (raw == null) return '';
    final date = DateTime.tryParse(raw.toString())?.toLocal();
    if (date == null) return '';
    final difference = DateTime.now().difference(date);
    if (difference.inMinutes < 1) return 'Baru saja';
    if (difference.inHours < 1) return '${difference.inMinutes} menit lalu';
    if (difference.inDays < 1) return '${difference.inHours} jam lalu';
    if (difference.inDays == 1) return 'Kemarin';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _loadNotifications() async {
    if (mounted) setState(() { isLoading = true; loadError = null; });
    try {
      final rows = await ApiService.getNotifikasi(token: widget.token);
      if (!mounted) return;
      setState(() {
        notifications
          ..clear()
          ..addAll(rows.map((row) => _NotificationItem(
            id: int.tryParse('${row['id_notifikasi']}') ?? 0,
            title: (row['judul'] ?? 'Notifikasi').toString(),
            message: (row['pesan'] ?? '').toString(),
            timeLabel: _formatTime(row['created_at']),
            isRead: row['dibaca'] == true,
          )));
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { isLoading = false; loadError = e.toString(); });
    }
  }

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

  final List<_NotificationItem> notifications = [];

  // ==========================================
  // HELPER
  // ==========================================

  int get unreadCount => notifications.where((item) => !item.isRead).length;

  Future<void> _refreshNotifications() async {
    await _loadNotifications();
  }

  void markAsRead(_NotificationItem item) {
    if (item.isRead) return;

    setState(() { item.isRead = true; });
    ApiService.bacaNotifikasi(token: widget.token, idNotifikasi: item.id)
        .catchError((error) {
      if (!mounted) return;
      setState(() => item.isRead = false);
      _showMessage('Gagal memperbarui status notifikasi.');
    });
  }

  void markAllAsRead() {
    if (unreadCount == 0) return;

    final previous = notifications.map((item) => item.isRead).toList();
    setState(() {
      for (final item in notifications) { item.isRead = true; }
    });
    ApiService.bacaSemuaNotifikasi(token: widget.token).then((_) {
      if (mounted) _showMessage('Semua notifikasi sudah dibaca.');
    }).catchError((error) {
      if (!mounted) return;
      setState(() {
        for (var i = 0; i < notifications.length && i < previous.length; i++) {
          notifications[i].isRead = previous[i];
        }
      });
      _showMessage('Gagal memperbarui notifikasi.');
    });
  }

  void deleteNotification(_NotificationItem item) {
    setState(() { notifications.removeWhere((n) => n.id == item.id); });
    ApiService.hapusNotifikasi(token: widget.token, idNotifikasi: item.id)
        .catchError((error) {
      if (mounted) {
        _showMessage('Gagal menghapus notifikasi dari server.');
        _loadNotifications();
      }
    });
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
          onRefresh: _refreshNotifications,

          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),

            slivers: [
              // HEADER

              SliverToBoxAdapter(child: _buildHeader()),

              // JUDUL SECTION
              SliverToBoxAdapter(child: _buildSectionTitle()),

              // STATUS PEMUATAN DAN ERROR DARI API
              if (isLoading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (loadError != null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.wifi_off_rounded, size: 42, color: muted),
                          const SizedBox(height: 12),
                          const Text('Notifikasi gagal dimuat', style: TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          Text(loadError!, textAlign: TextAlign.center, style: const TextStyle(color: muted, fontSize: 11)),
                          const SizedBox(height: 12),
                          TextButton(onPressed: _loadNotifications, child: const Text('Coba lagi')),
                        ],
                      ),
                    ),
                  ),
                )
              // EMPTY STATE
              else if (notifications.isEmpty)
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
