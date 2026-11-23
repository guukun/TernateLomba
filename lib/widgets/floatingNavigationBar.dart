import 'package:flutter/material.dart';

import '../config/appTheme.dart';

class FloatingNavigationBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool isAdmin;

  const FloatingNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.isAdmin = false,
  });

  List<({String label, IconData icon, IconData active})> get _tabs => isAdmin
      ? [
          (
            label: 'Home',
            icon: Icons.home_outlined,
            active: Icons.home_rounded,
          ),
          (
            label: 'Favorit',
            icon: Icons.favorite_border_rounded,
            active: Icons.favorite_rounded,
          ),
          (
            label: 'Lomba',
            icon: Icons.emoji_events_outlined,
            active: Icons.emoji_events_rounded,
          ),
          (
            label: 'Pengajuan',
            icon: Icons.fact_check_outlined,
            active: Icons.fact_check_rounded,
          ),
          (
            label: 'Chat',
            icon: Icons.forum_outlined,
            active: Icons.forum_rounded,
          ),
          (
            label: 'Profil',
            icon: Icons.person_outline_rounded,
            active: Icons.person_rounded,
          ),
        ]
      : [
          (
            label: 'Home',
            icon: Icons.home_outlined,
            active: Icons.home_rounded,
          ),
          (
            label: 'Favorit',
            icon: Icons.favorite_border_rounded,
            active: Icons.favorite_rounded,
          ),
          (
            label: 'Lomba',
            icon: Icons.emoji_events_outlined,
            active: Icons.emoji_events_rounded,
          ),
          (
            label: 'Chat',
            icon: Icons.forum_outlined,
            active: Icons.forum_rounded,
          ),
          (
            label: 'Profil',
            icon: Icons.person_outline_rounded,
            active: Icons.person_rounded,
          ),
        ];

  // TERNATELOMBA_SMOOTH_MOTION_V1
  @override
  Widget build(BuildContext context) {
    final p = context.tl;
    final tabs = _tabs;
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(24, 0, 24, 12),
      child: Align(
        alignment: Alignment.bottomCenter,
        heightFactor: 1,
        child: SizedBox(
          width: double.infinity,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: p.fieldBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .16),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(7),
              child: SizedBox(
                height: 78,
                child: Row(
                  children: List.generate(tabs.length, (index) {
                    final item = tabs[index];
                    final selected = currentIndex == index;
                    return Expanded(
                      flex: selected ? 18 : 10,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Center(
                          child: SizedBox(
                            height: 68, // Tall selector, proportional to the Ajukan Lomba CTA.
                            width: double.infinity,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(23),
                                onTap: () => onTap(index),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 210),
                                  curve: Curves.easeOutCubic,
                                  width: double.infinity,
                                  height: 68,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? p.primary
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(23),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 3,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        AnimatedScale(
                                          scale: selected ? 1.0 : 0.92,
                                          duration: const Duration(
                                            milliseconds: 180,
                                          ),
                                          curve: Curves.easeOutCubic,
                                          child: Icon(
                                            selected ? item.active : item.icon,
                                            color: selected
                                                ? Colors.white
                                                : p.navy,
                                            size: selected ? 24 : 23,
                                          ),
                                        ),
                                        if (selected) ...[
                                          const SizedBox(width: 7),
                                          Flexible(
                                            child: Text(
                                              item.label,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}