import 'package:flutter/material.dart';

import '../config/appTheme.dart';

/// TernateLomba Mono Edition: minimal, premium, editorial.
class TLPlayful {
  static BoxDecoration card(
    BuildContext context, {
    Color? tint,
    double radius = 26,
  }) {
    final p = context.tl;
    final background = tint == null
        ? p.surface
        : Color.alphaBlend(tint.withValues(alpha: .08), p.surface);
    return BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: p.fieldBorder),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: .035),
          blurRadius: 22,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  static Widget title(
    BuildContext context,
    String text, {
    String? suffix,
    VoidCallback? onTap,
  }) {
    final p = context.tl;
    return Padding(
      padding: const EdgeInsets.fromLTRB(21, 26, 21, 13),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: p.primary,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              text,
              maxLines: 2,
              style: TextStyle(
                color: p.navy,
                fontWeight: FontWeight.w900,
                letterSpacing: -.85,
                height: 1.08,
                fontSize: 24,
              ),
            ),
          ),
          if (suffix != null)
            TextButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.arrow_forward_rounded, size: 17),
              label: Text(
                suffix,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
        ],
      ),
    );
  }

  static Widget decoratedHeading(
    BuildContext context, {
    required String title,
    required String subtitle,
    required Color accent,
    required IconData icon,
  }) {
    final p = context.tl;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(17, 18, 17, 6),
      decoration: card(context, tint: accent, radius: 32),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -16,
            top: -16,
            child: Container(
              width: 132,
              height: 132,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: .08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 20,
            bottom: 20,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: p.primary,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: p.fieldBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: p.fieldBorder),
                  ),
                  child: Text(
                    'LOCK IN  ·  LEVEL UP',
                    style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 1.1,
                      color: p.navy,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 250),
                  child: Text(
                    title,
                    maxLines: 3,
                    style: TextStyle(
                      color: p.navy,
                      fontSize: 31,
                      height: 1.0,
                      letterSpacing: -1.45,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 270),
                  child: Text(
                    subtitle,
                    maxLines: 4,
                    style: TextStyle(
                      fontSize: 12.8,
                      height: 1.5,
                      color: p.grey,
                    ),
                  ),
                ),
                const SizedBox(height: 17),
                Row(
                  children: [
                    Container(
                      width: 72,
                      height: 5,
                      decoration: BoxDecoration(
                        color: p.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(width: 7),
                    Container(
                      width: 22,
                      height: 5,
                      decoration: BoxDecoration(
                        color: p.creamDark,
                        borderRadius: BorderRadius.circular(10),
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

  static Widget pageHeader(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color accent,
    required VoidCallback onBack,
    String eyebrow = 'TERNATELOMBA',
  }) {
    final p = context.tl;
    return Padding(
      padding: const EdgeInsets.fromLTRB(17, 15, 17, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Material(
                color: p.surface,
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  onTap: onBack,
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      border: Border.all(color: p.fieldBorder),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 17,
                      color: p.navy,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  eyebrow.toUpperCase(),
                  style: TextStyle(
                    letterSpacing: 2,
                    fontWeight: FontWeight.w900,
                    fontSize: 10.5,
                    color: p.navy,
                  ),
                ),
              ),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: p.primary,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
            ],
          ),
          const SizedBox(height: 19),
          Container(
            width: double.infinity,
            decoration: card(context, tint: accent, radius: 30),
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: p.fieldBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'FOCUS  •  COMPETE  •  ACHIEVE',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        letterSpacing: .8,
                        fontSize: 9,
                        color: p.navy,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: TextStyle(
                      color: p.navy,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      height: 1.04,
                      letterSpacing: -1.15,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    description,
                    style: TextStyle(
                      color: p.grey,
                      fontSize: 12.6,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 17),
                  Container(
                    width: 74,
                    height: 5,
                    decoration: BoxDecoration(
                      color: p.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget statusPill(
    BuildContext context,
    String label,
    Color accent, {
    IconData? icon,
  }) {
    final p = context.tl;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: Color.alphaBlend(accent.withValues(alpha: .08), p.surface),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: p.fieldBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: p.navy, size: 14),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: TextStyle(
              color: p.navy,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  static Widget empty(
    BuildContext context, {
    required String title,
    required String message,
    required IconData icon,
    Color? accent,
    String? actionText,
    VoidCallback? onAction,
  }) {
    final p = context.tl;
    final color = accent ?? p.creamDark;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      padding: const EdgeInsets.fromLTRB(25, 31, 25, 30),
      decoration: card(context, tint: color, radius: 30),
      child: Column(
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: p.primary,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(icon, color: Colors.white, size: 40),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 21,
              color: p.navy,
              fontWeight: FontWeight.w900,
              letterSpacing: -.5,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(height: 1.55, fontSize: 13, color: p.grey),
          ),
          if (actionText != null && onAction != null) ...[
            const SizedBox(height: 21),
            FilledButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: Text(actionText),
            ),
          ],
        ],
      ),
    );
  }
}
