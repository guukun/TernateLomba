import 'package:flutter/material.dart';

import '../config/appTheme.dart';

class FloatingNavigationBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const FloatingNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const List<_NavigationItem> _items = [
    _NavigationItem(
      label: 'Beranda',
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
    ),
    _NavigationItem(
      label: 'Lomba Saya',
      icon: Icons.card_giftcard_outlined,
      activeIcon: Icons.card_giftcard_rounded,
    ),
    _NavigationItem(
      label: 'Ajukan',
      icon: Icons.explore_outlined,
      activeIcon: Icons.explore_rounded,
    ),
    _NavigationItem(
      label: 'Profil',
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final safeIndex = currentIndex.clamp(0, _items.length - 1);

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              // Panel utama tetap putih.
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: AppColors.fieldBorder, width: 1),
              boxShadow: [
                BoxShadow(
                  color: AppColors.navy.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: List.generate(_items.length, (index) {
                final item = _items[index];
                final selected = index == safeIndex;

                return Expanded(
                  child: Semantics(
                    button: true,
                    selected: selected,
                    label: item.label,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(28),
                        onTap: () => onTap(index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          constraints: const BoxConstraints(minHeight: 50),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 2,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            // Indikator menu aktif berwarna biru muda.
                            // Menu aktif menggunakan biru solid.
                            color: selected
                                ? AppColors.primary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AnimatedScale(
                                scale: selected ? 1.08 : 1,
                                duration: const Duration(milliseconds: 220),
                                child: Icon(
                                  selected ? item.activeIcon : item.icon,
                                  size: 22,
                                  color: selected
                                      ? Colors.white
                                      : AppColors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 180),
                                style: TextStyle(
                                  color: selected
                                      ? Colors.white
                                      : AppColors.grey,
                                  fontSize: 10,
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                                child: Text(
                                  item.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
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
