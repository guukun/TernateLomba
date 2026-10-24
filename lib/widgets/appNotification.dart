import 'dart:async';

import 'package:flutter/material.dart';

enum NotificationType { success, error, warning, info }

class AppNotification {
  static OverlayEntry? _entry;
  static Timer? _timer;

  static void show({
    required BuildContext context,
    required String title,
    required String message,
    NotificationType type = NotificationType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    _timer?.cancel();

    // Tutup notifikasi sebelumnya jika masih tampil.
    final previousEntry = _entry;
    _entry = null;

    if (previousEntry != null) {
      previousEntry.remove();
      previousEntry.dispose();
    }

    final Color color;
    final IconData icon;

    switch (type) {
      case NotificationType.success:
        color = const Color(0xFF21866D);
        icon = Icons.check_circle_rounded;
        break;

      case NotificationType.error:
        color = const Color(0xFFD92D20);
        icon = Icons.error_rounded;
        break;

      case NotificationType.warning:
        color = const Color(0xFFE5A000);
        icon = Icons.warning_rounded;
        break;

      case NotificationType.info:
        color = const Color(0xFF3478E5);
        icon = Icons.info_rounded;
        break;
    }

    final overlay = Overlay.of(context, rootOverlay: true);

    late final OverlayEntry entry;

    entry = OverlayEntry(
      builder: (overlayContext) {
        final topPadding = MediaQuery.paddingOf(overlayContext).top;

        return Positioned(
          top: topPadding + 12,
          left: 16,
          right: 16,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: color.withValues(alpha: 0.20)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 18,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(icon, color: color, size: 27),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF202938),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              message,
                              style: const TextStyle(
                                fontSize: 12,
                                height: 1.5,
                                color: Color(0xFF667085),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () {
                          _dismiss(entry);
                        },
                        tooltip: 'Tutup notifikasi',
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 19,
                          color: Color(0xFF667085),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    _entry = entry;
    overlay.insert(entry);

    _timer = Timer(duration, () {
      _dismiss(entry);
    });
  }

  static void _dismiss(OverlayEntry entry) {
    if (!identical(_entry, entry)) return;

    _timer?.cancel();
    _timer = null;
    _entry = null;

    entry.remove();
    entry.dispose();
  }
}
