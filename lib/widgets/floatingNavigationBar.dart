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

  List<_NavigationItem> get _items => [
    const _NavigationItem(
      label: 'Beranda',
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
    ),
    const _NavigationItem(
      label: 'Lomba Saya',
      icon: Icons.card_giftcard_outlined,
      activeIcon: Icons.card_giftcard_rounded,
    ),
    const _NavigationItem(
      label: 'Ajukan',
      icon: Icons.explore_outlined,
      activeIcon: Icons.explore_rounded,
    ),
    if (isAdmin)
      const _NavigationItem(
        label: 'Pengajuan',
        icon: Icons.fact_check_outlined,
        activeIcon: Icons.fact_check_rounded,
      ),
    const _NavigationItem(
      label: 'Profil',
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final items = _items;
    final safeIndex = currentIndex.clamp(0, items.length - 1);

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Container(
            height: 68,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(40),
              border: Border.all(color: AppColors.fieldBorder, width: 1),
              boxShadow: [
                BoxShadow(
                  color: AppColors.navy.withValues(alpha: 0.09),
                  blurRadius: 20,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: List.generate(items.length, (index) {
                final item = items[index];
                final selected = index == safeIndex;

                return Expanded(
                  flex: selected ? 24 : 15,
                  child: Semantics(
                    button: true,
                    selected: selected,
                    label: item.label,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(35),
                        onTap: () => onTap(index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 280),
                          curve: Curves.easeInOutCubic,
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.primary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(35),
                          ),
                          child: Center(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              switchInCurve: Curves.easeOut,
                              switchOutCurve: Curves.easeIn,
                              child: selected
                                  ? Row(
                                      key: ValueKey('active_$index'),
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          item.activeIcon,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                        const SizedBox(width: 7),
                                        Flexible(
                                          child: Text(
                                            item.label,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                  : Icon(
                                      item.icon,
                                      key: ValueKey('inactive_$index'),
                                      color: AppColors.grey,
                                      size: 25,
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
    );
  }
}

class _NavigationItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;

  const _NavigationItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}