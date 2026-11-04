
import 'package:flutter/material.dart';

import '../../models/notification_model.dart';
import '../../services/notification_service.dart';

class NotifikasiPage extends StatefulWidget {
  final String token;
  final String baseApiUrl;

  const NotifikasiPage({
    super.key,
    required this.token,
    required this.baseApiUrl,
  });

  @override
  State<NotifikasiPage> createState() =>
      _NotifikasiPageState();
}

class _NotifikasiPageState extends State<NotifikasiPage> {
  static const Color primary = Color(0xFF3478E5);
  static const Color textColor = Color(0xFF202938);
  static const Color muted = Color(0xFF667085);

  late final NotificationService service;

  List<NotificationModel> notifications = [];

  bool loading = true;
  bool markingAll = false;
  String? error;

  @override
  void initState() {
    super.initState();

    service = NotificationService(
      baseApiUrl: widget.baseApiUrl,
    );

    loadNotifications();
  }

  // Mengambil data notifikasi
  Future<void> loadNotifications() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final data = await service.getNotifications(
        token: widget.token,
      );

      if (!mounted) return;

      setState(() {
        notifications = data;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  // Menandai satu notifikasi dibaca
  Future<void> markAsRead(
    NotificationModel item,
  ) async {
    if (item.isRead || item.id == 0) return;

    try {
      await service.markAsRead(
        token: widget.token,
        id: item.id,
      );

      await loadNotifications();
    } catch (e) {
      showMessage('Gagal menandai notifikasi: $e');
    }
  }

  // Menandai semua notifikasi dibaca
  Future<void> markAllAsRead() async {
    if (notifications.isEmpty || markingAll) return;

    setState(() => markingAll = true);

    try {
      await service.markAllAsRead(
        token: widget.token,
      );

      await loadNotifications();

      showMessage('Semua notifikasi sudah dibaca.');
    } catch (e) {
      showMessage('Gagal memperbarui notifikasi: $e');
    } finally {
      if (mounted) {
        setState(() => markingAll = false);
      }
    }
  }

  // Menghapus notifikasi
  Future<void> deleteNotification(
    NotificationModel item,
  ) async {
    if (item.id == 0) {
      showMessage('ID notifikasi tidak ditemukan.');
      return;
    }

    try {
      await service.deleteNotification(
        token: widget.token,
        id: item.id,
      );

      if (!mounted) return;

      setState(() {
        notifications.removeWhere(
          (n) => n.id == item.id,
        );
      });

      showMessage('Notifikasi berhasil dihapus.');
    } catch (e) {
      showMessage('Gagal menghapus notifikasi: $e');
      loadNotifications();
    }
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message)),
      );
  }

  IconData getIcon(String title) {
    final value = title.toLowerCase();

    if (value.contains('pendaftaran')) {
      return Icons.assignment_turned_in_outlined;
    }

    if (value.contains('lomba')) {
      return Icons.emoji_events_outlined;
    }

    if (value.contains('status')) {
      return Icons.query_stats_rounded;
    }

    return Icons.notifications_none_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = notifications
        .where((item) => !item.isRead)
        .length;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),

      appBar: AppBar(
        title: const Text(
          'Notifikasi',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: textColor,
          ),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,

        actions: [
          TextButton(
            onPressed: unreadCount == 0 || markingAll
                ? null
                : markAllAsRead,
            child: markingAll
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Text('Baca semua'),
          ),
        ],
      ),

      body: loading
          ? const Center(
              child: CircularProgressIndicator(
                color: primary,
              ),
            )

          : error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.cloud_off_outlined,
                        size: 45,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Gagal mengambil notifikasi',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                        ),
                        child: Text(
                          error!,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 15),
                      ElevatedButton(
                        onPressed: loadNotifications,
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                )

              : notifications.isEmpty
                  ? RefreshIndicator(
                      onRefresh: loadNotifications,
                      child: ListView(
                        children: const [
                          SizedBox(height: 150),
                          Icon(
                            Icons.notifications_off_outlined,
                            size: 58,
                            color: muted,
                          ),
                          SizedBox(height: 14),
                          Center(
                            child: Text(
                              'Belum ada notifikasi',
                              style: TextStyle(
                                color: muted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )

                  : RefreshIndicator(
                      onRefresh: loadNotifications,

                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: notifications.length,

                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),

                        itemBuilder: (context, index) {
                          final item = notifications[index];

                          return Dismissible(
                            key: ValueKey(
                              'notification-${item.id}-$index',
                            ),

                            direction:
                                DismissDirection.endToStart,

                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(
                                right: 22,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius:
                                    BorderRadius.circular(18),
                              ),
                              child: const Icon(
                                Icons.delete_outline,
                                color: Colors.white,
                              ),
                            ),

                            onDismissed: (_) {
                              deleteNotification(item);
                            },

                            child: Material(
                              color: Colors.white,
                              borderRadius:
                                  BorderRadius.circular(18),

                              child: InkWell(
                                borderRadius:
                                    BorderRadius.circular(18),

                                onTap: () => markAsRead(item),

                                child: Padding(
                                  padding: const EdgeInsets.all(16),

                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,

                                    children: [
                                      Container(
                                        width: 46,
                                        height: 46,

                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFFEAF2FF,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(15),
                                        ),

                                        child: Icon(
                                          getIcon(item.title),
                                          color: primary,
                                        ),
                                      ),

                                      const SizedBox(width: 12),

                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,

                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    item.title,
                                                    style:
                                                        const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      color: textColor,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ),

                                                if (!item.isRead)
                                                  Container(
                                                    width: 8,
                                                    height: 8,
                                                    decoration:
                                                        const BoxDecoration(
                                                      color: primary,
                                                      shape:
                                                          BoxShape.circle,
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
                                              style: const TextStyle(
                                                color: muted,
                                                fontSize: 11,
                                              ),
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
                        },
                      ),
                    ),
    );
  }
}
