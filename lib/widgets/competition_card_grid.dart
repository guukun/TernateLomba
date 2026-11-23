import 'package:flutter/material.dart';

/// Layout katalog yang konsisten pada semua halaman lomba.
/// Jumlah kolom menyesuaikan ruang, bukan ukuran layar mentah.
class CompetitionCardGrid extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;
  final EdgeInsetsGeometry padding;
  final double cardHeight;
  final double spacing;

  const CompetitionCardGrid({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.padding = EdgeInsets.zero,
    this.cardHeight = 278,
    this.spacing = 12,
  });

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final twoColumns = constraints.maxWidth >= 300;
      return GridView.builder(
        padding: padding,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: twoColumns ? 2 : 1,
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
          mainAxisExtent: twoColumns ? cardHeight : cardHeight + 10,
        ),
        itemBuilder: itemBuilder,
      );
    },
  );
}
