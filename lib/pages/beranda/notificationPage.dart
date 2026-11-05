import 'package:flutter/material.dart';

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
  static const Color primary = Color(0xFF3478E5);
  static const Color textColor = Color(0xFF202938);
  static const Color muted = Color(0xFF667085);

  // DATA DUMMY LOKAL
  // Hanya menampilkan keputusan pengajuan lomba.

  final List<_NotificationItem> notifications = [
    _NotificationItem(
      id: 1,
      title: 'Pengajuan Lomba Disetujui',
      message: 'Pengajuan lomba "Kompetisi Karya Tulis Ilmiah" berhasil disetujui dan telah diterbitkan.',
      timeLabel: 'Baru saja',
      isRead: false,
    ),
    _NotificationItem(
      id: 2,
      title: 'Pengajuan Lomba Ditolak',
      message: 'Pengajuan lomba "Festival Teknologi 2026" ditolak. Catatan admin: Persyaratan belum lengkap.',
      timeLabel: 'Kemarin',
      isRead: false,
    ),
  ];

  // REFRESH LOKAL
  Future<void> _refreshDummy() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;

    setState(() {});
  }

  // TANDAI SATU NOTIFIKASI DIBACA
  void markAsRead(_NotificationItem item) {
    if (item.isRead) return;

    setState(() {
      item.isRead = true;
    });
  }

  // TANDAI SEMUA DIBACA
  void markAllAsRead() {
    if (!notifications.any((item) => !item.isRead)) return;

    setState(() {
      for (final item in notifications) {
        item.isRead = true;
      }
    });

    showMessage('Semua notifikasi sudah dibaca.');
  }

  // HAPUS NOTIFIKASI LOKAL
  void deleteNotification(_NotificationItem item) {
    setState(() {
      notifications.removeWhere((n) => n.id == item.id);
    });

    showMessage('Notifikasi berhasil dihapus.');
  }

  // SNACKBAR
  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  // ICON BERDASARKAN STATUS
  IconData getIcon(String title) {
    final value = title.toLowerCase();

    if (value.contains('disetujui')) {
      return Icons.check_circle_outline_rounded;
    }

    if (value.contains('ditolak')) {
      return Icons.cancel_outlined;
    }

    return Icons.notifications_none_rounded;
  }

  // WARNA ICON BERDASARKAN STATUS
  Color getIconColor(String title) {
    final value = title.toLowerCase();

    if (value.contains('disetujui')) {
      return const Color(0xFF16A36A);
    }

    if (value.contains('ditolak')) {
      return const Color(0xFFD92D20);
    }

    return primary;
  }

  // HALAMAN KOSONG
  Widget _emptyBody() {
    return RefreshIndicator(
      onRefresh: _refreshDummy,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 150),
          Icon(Icons.notifications_off_outlined, size: 58, color: muted),
          SizedBox(height: 14),
          Center(
            child: Text(
              'Belum ada notifikasi',
              style: TextStyle(color: muted, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // KARTU NOTIFIKASI
  Widget _notificationCard(_NotificationItem item) {
    final iconColor = getIconColor(item.title);

    return Dismissible(
      key: ValueKey('notification-${item.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async => true,
      onDismissed: (_) {
        deleteNotification(item);
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 22),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => markAsRead(item),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(getIcon(item.title), color: iconColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: textColor,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          if (!item.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.message,
                        style: const TextStyle(
                          color: muted,
                          height: 1.4,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.timeLabel,
                        style: const TextStyle(color: muted, fontSize: 11),
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

  // DAFTAR NOTIFIKASI
  Widget _listBody() {
    return RefreshIndicator(
      onRefresh: _refreshDummy,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        itemCount: notifications.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          return _notificationCard(notifications[index]);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = notifications.where((item) => !item.isRead).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text(
          'Notifikasi',
          style: TextStyle(fontWeight: FontWeight.w800, color: textColor),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        actions: [
          TextButton(
            onPressed: unreadCount == 0 ? null : markAllAsRead,
            child: const Text('Baca semua'),
          ),
        ],
      ),
      body: notifications.isEmpty ? _emptyBody() : _listBody(),
    );
  }
}
