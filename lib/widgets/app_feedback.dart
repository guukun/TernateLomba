import 'package:flutter/material.dart';

import '../config/appTheme.dart';

enum NotificationType { success, error, warning, info }

/// Presentation templates for all feedback, confirmations and modal sheets.
/// Feature pages provide text, forms and callbacks; UI styling stays here.
class AppNotification {
  // Root messenger keeps messages visible across navigation (including logout).
  static final GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  /// Non-blocking feedback. Successful actions are already complete before
  /// this is called; callers may navigate immediately without waiting for X.
  /// Confirmations and destructive actions still use AppConfirmDialog.
  static Future<void> show({
    required BuildContext context,
    required String title,
    required String message,
    NotificationType type = NotificationType.info,
    Duration duration = const Duration(seconds: 3),
  }) async {
    final messenger = messengerKey.currentState;
    if (messenger == null || !messenger.mounted) return;

    final icon = switch (type) {
      NotificationType.success => Icons.check_circle_outline_rounded,
      NotificationType.error => Icons.error_outline_rounded,
      NotificationType.warning => Icons.warning_amber_rounded,
      NotificationType.info => Icons.info_outline_rounded,
    };
    final isImportant =
        type == NotificationType.error || type == NotificationType.warning;
    final visibleFor = isImportant
        ? const Duration(seconds: 5)
        : (type == NotificationType.info
              ? const Duration(seconds: 2)
              : duration);

    // Prevent a long queue of low-priority messages.
    messenger.removeCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: visibleFor,
        showCloseIcon: isImportant,
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 21),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message.trim().isEmpty ? title : message,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> message(
    BuildContext context,
    String message, {
    NotificationType type = NotificationType.info,
    String? title,
  }) => show(
    context: context,
    title:
        title ??
        switch (type) {
          NotificationType.error => 'Terjadi Kesalahan',
          NotificationType.success => 'Berhasil!',
          NotificationType.warning => 'Perhatian',
          NotificationType.info => 'Informasi',
        },
    message: message,
    type: type,
  );
}

class AppConfirmDialog {
  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Ya',
    String cancelText = 'Batal',
    Color? confirmColor,
    bool barrierDismissible = true,
  }) {
    final destructive =
        RegExp(
          r'hapus|tolak|delete|keluar|hentikan|batalkan',
          caseSensitive: false,
        ).hasMatch(confirmText) ||
        confirmColor == AppColors.error;
    return showDialog<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (ctx) => AlertDialog(
        titlePadding: const EdgeInsets.fromLTRB(22, 22, 22, 0),
        contentPadding: const EdgeInsets.fromLTRB(22, 11, 22, 10),
        actionsPadding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: ctx.tl.fieldBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                destructive
                    ? Icons.warning_amber_rounded
                    : Icons.help_outline_rounded,
                color: ctx.tl.navy,
              ),
            ),
            const SizedBox(height: 15),
            Text(
              title,
              style: TextStyle(
                color: ctx.tl.navy,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Text(
            message,
            style: TextStyle(color: ctx.tl.grey, height: 1.5),
          ),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 50),
                  ),
                  child: Text(cancelText),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF171717),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 50),
                  ),
                  child: Text(confirmText),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class AppPopup {
  /// Reusable anchored overlay shell for notification and account menus.
  /// Pages supply content only; position, clipping, colors and shadows live here.
  static OverlayEntry anchored({
    required BuildContext context,
    required LayerLink link,
    required Widget child,
    required VoidCallback onDismiss,
    double maxWidth = 350,
    double? maxHeight,
  }) {
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (overlayContext) {
        final p = overlayContext.tl;
        final available = MediaQuery.sizeOf(overlayContext);
        final width = (available.width - 30).clamp(0.0, maxWidth).toDouble();
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: onDismiss,
                child: const SizedBox.expand(),
              ),
            ),
            CompositedTransformFollower(
              link: link,
              showWhenUnlinked: false,
              targetAnchor: Alignment.bottomRight,
              followerAnchor: Alignment.topRight,
              offset: const Offset(0, 10),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: width,
                  constraints: BoxConstraints(
                    maxHeight: maxHeight == null
                        ? available.height * .66
                        : (available.height * .65 < maxHeight
                              ? available.height * .65
                              : maxHeight),
                  ),
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: p.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: p.fieldBorder),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: .11),
                        blurRadius: 22,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: child,
                ),
              ),
            ),
          ],
        );
      },
    );
    Overlay.of(context).insert(entry);
    return entry;
  }

  /// Generic popup menu: only item definitions and callbacks vary per page.
  static Widget menu<T>({
    required BuildContext context,
    required Widget child,
    required PopupMenuItemBuilder<T> itemBuilder,
    required PopupMenuItemSelected<T> onSelected,
    String? tooltip,
    T? initialValue,
    VoidCallback? onOpened,
    Offset offset = Offset.zero,
    PopupMenuPosition position = PopupMenuPosition.under,
    BoxConstraints? constraints,
  }) => PopupMenuButton<T>(
    tooltip: tooltip,
    initialValue: initialValue,
    onOpened: onOpened,
    onSelected: onSelected,
    offset: offset,
    position: position,
    constraints: constraints,
    color: context.tl.surface,
    elevation: 6,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(19),
      side: BorderSide(color: context.tl.fieldBorder),
    ),
    itemBuilder: itemBuilder,
    child: child,
  );

  /// Consistent information sheet for account information, help and about.
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required Widget child,
    IconData icon = Icons.info_outline_rounded,
  }) => showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          2,
          20,
          MediaQuery.viewInsetsOf(ctx).bottom + 24,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(ctx).height * .78,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: ctx.tl.tabBg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: ctx.tl.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: ctx.tl.navy,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    tooltip: 'Tutup',
                    icon: Icon(Icons.close_rounded, color: ctx.tl.grey),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(color: ctx.tl.fieldBorder),
              Flexible(child: SingleChildScrollView(child: child)),
            ],
          ),
        ),
      ),
    ),
  );

  /// Unified editable form (category, confirmation with fields, etc.).
  static Future<bool?> form({
    required BuildContext context,
    required String title,
    required Widget child,
    required bool Function() validate,
    String confirmText = 'Simpan',
  }) => showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      scrollable: true,
      title: Text(title),
      content: child,
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Batal'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  if (validate()) Navigator.pop(ctx, true);
                },
                child: Text(confirmText),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  /// Complex sheets retain feature-specific content but use one modal host.
  static Future<T?> customSheet<T>({
    required BuildContext context,
    required WidgetBuilder builder,
  }) => showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: context.tl.surface,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: builder,
  );

  /// Complex approval forms retain their state; the modal host is centralized.
  static Future<T?> customDialog<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool barrierDismissible = true,
  }) => showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: builder,
  );

  static void loading(BuildContext context, {String message = 'Memproses...'}) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: Center(
          child: Material(
            color: ctx.tl.surface,
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 29, vertical: 25),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    color: ctx.tl.primary,
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 17),
                  Text(
                    message,
                    style: TextStyle(
                      color: ctx.tl.navy,
                      fontWeight: FontWeight.w900,
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
}

/// Shared reason form for destructive moderation actions.
/// Returns null when canceled and a trimmed reason when submitted.
class AppReasonDialog {
  static Future<String?> show({
    required BuildContext context,
    required String title,
    required String description,
    String actionLabel = 'Lanjutkan',
    int minLength = 10,
  }) => showDialog<String>(
    context: context,
    builder: (_) => _ReasonInputDialog(
      title: title,
      description: description,
      actionLabel: actionLabel,
      minLength: minLength,
    ),
  );
}

class _ReasonInputDialog extends StatefulWidget {
  final String title;
  final String description;
  final String actionLabel;
  final int minLength;

  const _ReasonInputDialog({
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.minLength,
  });

  @override
  State<_ReasonInputDialog> createState() => _ReasonInputDialogState();
}

class _ReasonInputDialogState extends State<_ReasonInputDialog> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    insetPadding: const EdgeInsets.symmetric(horizontal: 24),
    title: Text(
      widget.title,
      style: const TextStyle(fontWeight: FontWeight.w800),
    ),
    content: SizedBox(
      width: 420,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.description),
            const SizedBox(height: 16),
            TextFormField(
              controller: _controller,
              autofocus: true,
              maxLines: 4,
              minLines: 3,
              maxLength: 1000,
              decoration: const InputDecoration(
                labelText: 'Alasan tindakan *',
                hintText: 'Jelaskan alasan tindakan administratif...',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if ((value ?? '').trim().length < widget.minLength) {
                  return 'Alasan minimal ${widget.minLength} karakter.';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    ),
    actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
    actions: [
      Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 50)),
              child: const Text('Batal'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                if (_formKey.currentState?.validate() ?? false) {
                  Navigator.pop(context, _controller.text.trim());
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF171717),
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 50),
              ),
              child: Text(
                widget.actionLabel,
                maxLines: 2,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    ],
  );
}