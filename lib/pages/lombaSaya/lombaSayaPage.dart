import 'package:flutter/material.dart';

class LombaSayaPage extends StatefulWidget {
  const LombaSayaPage({super.key});

  @override
  State<LombaSayaPage> createState() => _LombaSayaPageState();
}

class _LombaSayaPageState extends State<LombaSayaPage> {
  int selectedTab = 0;

  static const Color primaryBlue = Color(0xFF2878FF);
  static const Color textColor = Color(0xFF263247);
  static const Color mutedColor = Color(0xFF98A5B8);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header halaman
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 22, 20, 22),
              child: Text(
                'Lomba Saya',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ),

            // Tab Lomba Diikuti dan Lomba Dibuat
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F4F8),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Row(
                children: [
                  _buildTab('Lomba Diikuti', 0),
                  _buildTab('Lomba Dibuat', 1),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Konten tab dengan animasi fade dan scale
            Expanded(
              child: ClipRect(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  reverseDuration: const Duration(milliseconds: 250),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    final scaleAnimation = Tween<double>(
                      begin: 0.96,
                      end: 1.0,
                    ).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                      ),
                    );

                    return FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(
                        scale: scaleAnimation,
                        child: child,
                      ),
                    );
                  },
                  child: KeyedSubtree(
                    key: ValueKey<int>(selectedTab),
                    child: selectedTab == 0
                        ? _buildLombaDiikuti()
                        : _buildLombaDibuat(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Tab dengan animasi perubahan warna
  Widget _buildTab(String title, int index) {
    final bool isSelected = selectedTab == index;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (selectedTab == index) return;

          setState(() {
            selectedTab = index;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.white
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected
                  ? FontWeight.bold
                  : FontWeight.w500,
              color: isSelected
                  ? textColor
                  : mutedColor,
            ),
            child: Text(
              title,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  // Tab Lomba Diikuti
  Widget _buildLombaDiikuti() {
    return _buildEmptyState(
      icon: Icons.emoji_events_outlined,
      title: 'Belum mengikuti lomba',
      description:
          'Kamu belum mengikuti lomba apa pun. '
          'Temukan lomba menarik di TernateLomba!',
    );
  }

  // Tab Lomba Dibuat
  Widget _buildLombaDibuat() {
    return _buildEmptyState(
      icon: Icons.add,
      title: 'Belum ada lomba yang dibuat',
      description:
          'Anda belum pernah membuat lomba. '
          'Mulai buat lomba dan bagikan kepada masyarakat '
          'Ternate!',
    );
  }

  // Tampilan kosong tanpa tombol
  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: 35,
          vertical: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ikon lingkaran
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF7FAFD),
                border: Border.all(
                  color: const Color(0xFFD7E2EF),
                  width: 2,
                ),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF9DAFC4),
                size: 34,
              ),
            ),

            const SizedBox(height: 22),

            // Judul kondisi kosong
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),

            const SizedBox(height: 10),

            // Deskripsi kondisi kosong
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                height: 1.6,
                color: mutedColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}