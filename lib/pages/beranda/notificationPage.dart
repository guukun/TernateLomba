import '../../design_system/tl_playful.dart';
import '../../widgets/app_feedback.dart';

import 'dart:async';

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

class _NotifikasiPageState extends State<NotifikasiPage>
    with WidgetsBindingObserver {
  bool isLoading = true;
  String? loadError;
  bool _isFetching = false;
  bool _appIsResumed = true;
  Timer? _syncTimer;

  static const Duration _syncInterval = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadNotifications();
    _startRealtimePolling();
  }

  void _startRealtimePolling() {
    _syncTimer?.cancel();
    if (!_appIsResumed) return;
    _syncTimer = Timer.periodic(_syncInterval, (_) {
      if (mounted && _appIsResumed) {
        _loadNotifications(showLoading: false);
      }
    });
  }

  void _stopRealtimePolling() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appIsResumed = state == AppLifecycleState.resumed;
    if (_appIsResumed) {
      _loadNotifications(showLoading: false);
      _startRealtimePolling();
    } else {
      _stopRealtimePolling();
    }
  }

  @override
  void dispose() {
    _stopRealtimePolling();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
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

  Future<void> _loadNotifications({bool showLoading = true}) async {
    if (!mounted || _isFetching) return;
    _isFetching = true;

    if (showLoading) {
      setState(() {
        isLoading = true;
        loadError = null;
      });
    }

    try {
      final rows = await ApiService.getNotifikasi(token: widget.token);
      if (!mounted) return;

      final nextItems = rows
          .map(
            (row) => _NotificationItem(
              id: int.tryParse('${row['id_notifikasi']}') ?? 0,
              title: (row['judul'] ?? 'Notifikasi').toString(),
              message: (row['pesan'] ?? '').toString(),
              timeLabel: _formatTime(row['created_at']),
              isRead: row['dibaca'] == true,
            ),
          )
          .toList(growable: false);

      setState(() {
        notifications
          ..clear()
          ..addAll(nextItems);
        isLoading = false;
        loadError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        // Jangan hilangkan notifikasi yang sudah tampil ketika polling gagal.
        if (showLoading || notifications.isEmpty) {
          loadError = e.toString();
        }
        isLoading = false;
      });
    } finally {
      _isFetching = false;
    }
  }

  // ==========================================
  // APP THEME
  // ==========================================

  Color get primary => context.tl.primary;
  Color get primaryDark => context.tl.primaryDark;
  Color get cream => context.tl.cream;
  Color get creamDark => context.tl.creamDark;
  Color get creamLight => context.tl.creamLight;
  Color get background => context.tl.background;
  Color get textColor => context.tl.navy;
  Color get muted => context.tl.grey;
  Color get borderColor => context.tl.fieldBorder;

  // ==========================================
  // DATA NOTIFIKASI LOKAL
  // ==========================================

  final List<_NotificationItem> notifications = [];

  // ==========================================
  // HELPER
  // ==========================================

  int get unreadCount => notifications.where((item) => !item.isRead).length;

  Future<void> _refreshNotifications() async {
    await _loadNotifications(showLoading: true);
  }

  void markAsRead(_NotificationItem item) {
    if (item.isRead) return;

    setState(() {
      item.isRead = true;
    });
    ApiService.bacaNotifikasi(
      token: widget.token,
      idNotifikasi: item.id,
    ).catchError((error) {
      if (!mounted) return;
      setState(() => item.isRead = false);
      _showMessage('Gagal memperbarui status notifikasi.');
    });
  }

  void markAllAsRead() {
    if (unreadCount == 0) return;

    final previous = notifications.map((item) => item.isRead).toList();
    setState(() {
      for (final item in notifications) {
        item.isRead = true;
      }
    });
    ApiService.bacaSemuaNotifikasi(token: widget.token)
        .then((_) {
          if (mounted) _showMessage('Semua notifikasi sudah dibaca.');
        })
        .catchError((error) {
          if (!mounted) return;
          setState(() {
            for (
              var i = 0;
              i < notifications.length && i < previous.length;
              i++
            ) {
              notifications[i].isRead = previous[i];
            }
          });
          _showMessage('Gagal memperbarui notifikasi.');
        });
  }

  void deleteNotification(_NotificationItem item) {
    setState(() {
      notifications.removeWhere((n) => n.id == item.id);
    });
    ApiService.hapusNotifikasi(
      token: widget.token,
      idNotifikasi: item.id,
    ).catchError((error) {
      if (mounted) {
        _showMessage('Gagal menghapus notifikasi dari server.');
        _loadNotifications();
      }
    });
  }

  void _showMessage(String message) {
    if (!mounted) return;

    AppNotification.message(context, message, type: NotificationType.info);
  }

  // ==========================================
  // ICON STATUS
  // ==========================================

  IconData getIcon(String title) {
    final value = title.toLowerCase();

    if (value.contains('disetujui') || value.contains('diterima')) {
      return Icons.check_circle_rounded;
    }

    if (value.contains('ditolak')) {
      return Icons.cancel_rounded;
    }

    return Icons.notifications_rounded;
  }

  Color getIconColor(String title) {
    final value = title.toLowerCase();

    if (value.contains('disetujui') || value.contains('diterima')) {
      return context.tl.green;
    }

    if (value.contains('ditolak')) {
      return context.tl.error;
    }

    return primary;
  }

  // ==========================================
  // HEADER
  // ==========================================

  Widget _buildHeader() => Column(
    children: [
      TLPlayful.pageHeader(
        context,
        title: 'Kabar terbaru\nuntukmu! 🔔',
        description: 'Update pendaftaran, pengajuan, dan aktivitas lombamu.',
        icon: Icons.notifications_active_rounded,
        accent: context.tl.orange,
        onBack: () => Navigator.of(context).pop(),
      ),
      if (unreadCount > 0)
        Padding(
          padding: const EdgeInsets.fromLTRB(19, 10, 19, 0),
          child: Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: markAllAsRead,
              icon: const Icon(Icons.done_all_rounded),
              label: Text('Tandai $unreadCount telah dibaca'),
            ),
          ),
        ),
    ],
  );

  // ==========================================
  // SECTION TITLE
  // ==========================================

  Widget _buildSectionTitle() {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 25, 20, 15),
      child: Row(
        children: [
          Expanded(
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
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: cream,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$unreadCount belum dibaca',
                style: TextStyle(
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

  Widget _buildEmptyState() => TLPlayful.empty(
    context,
    title: 'Belum ada kabar baru',
    message: 'Status pendaftaran dan aktivitas lombamu akan muncul di sini.',
    icon: Icons.notifications_active_outlined,
    accent: context.tl.lavender,
  );

  // ==========================================
  // NOTIFICATION CARD
  // ==========================================

  Widget _notificationCard(_NotificationItem item) {
    final p = context.tl;
    final accent = getIconColor(item.title);
    return Dismissible(
      key: ValueKey('notification-${item.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => deleteNotification(item),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 23),
        decoration: BoxDecoration(
          color: p.error,
          borderRadius: BorderRadius.circular(25),
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
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
      child: Container(
        decoration: TLPlayful.card(
          context,
          tint: item.isRead ? null : accent,
          radius: 25,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(25),
            onTap: () => markAsRead(item),
            child: Padding(
              padding: const EdgeInsets.all(17),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: .17),
                      borderRadius: BorderRadius.circular(19),
                    ),
                    child: Icon(getIcon(item.title), color: accent, size: 26),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: p.navy,
                                  fontSize: 14,
                                  height: 1.25,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            if (!item.isRead)
                              Container(
                                width: 9,
                                height: 9,
                                decoration: BoxDecoration(
                                  color: p.coral,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 9),
                        Text(
                          item.message,
                          style: TextStyle(
                            color: p.grey,
                            height: 1.45,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              color: p.muted,
                              size: 14,
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                item.timeLabel,
                                style: TextStyle(color: p.grey, fontSize: 10.5),
                              ),
                            ),
                            TLPlayful.statusPill(
                              context,
                              item.isRead ? 'Dibaca' : 'Baru',
                              item.isRead ? p.mint : p.coral,
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
            physics: AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),

            slivers: [
              // HEADER

              SliverToBoxAdapter(child: _buildHeader()),

              // JUDUL SECTION
              SliverToBoxAdapter(child: _buildSectionTitle()),

              // STATUS PEMUATAN DAN ERROR DARI API
              if (isLoading)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (loadError != null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.wifi_off_rounded, size: 42, color: muted),
                          SizedBox(height: 12),
                          Text(
                            'Notifikasi gagal dimuat',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          SizedBox(height: 8),
                          Text(
                            loadError!,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: muted, fontSize: 11),
                          ),
                          SizedBox(height: 12),
                          TextButton(
                            onPressed: _loadNotifications,
                            child: Text('Coba lagi'),
                          ),
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
                  padding: EdgeInsets.fromLTRB(18, 0, 18, 30),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final itemIndex = index ~/ 2;

                      if (index.isOdd) {
                        return SizedBox(height: 11);
                      }

                      return _notificationCard(notifications[itemIndex]);
                    }, childCount: notifications.length * 2 - 1),
                  ),
                ),

              // FOOTER
              SliverToBoxAdapter(
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