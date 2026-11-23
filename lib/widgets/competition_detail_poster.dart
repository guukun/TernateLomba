import 'package:flutter/material.dart';

/// Reusable poster for detail pages only. Catalog cards retain BoxFit.cover.
/// A natural-aspect image is capped to the available viewport height.
class CompetitionDetailPoster extends StatelessWidget {
  const CompetitionDetailPoster({
    super.key,
    required this.url,
    this.fallback,
    this.radius = 20,
    this.maxHeight = 480,
  });

  final String? url;
  final Widget? fallback;
  final double radius;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    final source = url?.trim() ?? '';
    final empty =
        fallback ??
        const Center(child: Icon(Icons.emoji_events_rounded, size: 42));
    if (source.isEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: SizedBox(height: 185, width: double.infinity, child: empty),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Stack(
        alignment: Alignment.topRight,
        children: [
          Container(
            width: double.infinity,
            constraints: BoxConstraints(maxHeight: maxHeight),
            color: const Color(0xFFF0EEEA),
            child: Image.network(
              source,
              width: double.infinity,
              fit: BoxFit.contain,
              gaplessPlayback: true,
              loadingBuilder: (context, child, loading) => loading == null
                  ? child
                  : SizedBox(
                      height: 185,
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loading.expectedTotalBytes == null
                              ? null
                              : loading.cumulativeBytesLoaded /
                                    loading.expectedTotalBytes!,
                        ),
                      ),
                    ),
              errorBuilder: (_, _, _) => SizedBox(height: 185, child: empty),
            ),
          ),
          Positioned(
            right: 12,
            top: 12,
            child: Material(
              color: const Color(0xFF171717),
              borderRadius: BorderRadius.circular(13),
              child: InkWell(
                borderRadius: BorderRadius.circular(13),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => _CompetitionPosterFullscreen(url: source),
                  ),
                ),
                child: const SizedBox(
                  width: 43,
                  height: 43,
                  child: Icon(
                    Icons.open_in_full_rounded,
                    color: Colors.white,
                    size: 21,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompetitionPosterFullscreen extends StatelessWidget {
  const _CompetitionPosterFullscreen({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 5,
                boundaryMargin: const EdgeInsets.all(80),
                child: Center(
                  child: Image.network(
                    url,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.broken_image_outlined,
                      size: 48,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 12,
              right: 16,
              child: Material(
                color: const Color(0xFF303030),
                borderRadius: BorderRadius.circular(14),
                child: IconButton(
                  tooltip: 'Tutup poster',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
