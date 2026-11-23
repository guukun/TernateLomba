import 'package:flutter/material.dart';

/// Compact shared editorial card for all competition lists.
/// Only the poster expands; the white information panel hugs its content.
class CompetitionPosterCard extends StatelessWidget {
  final String title;
  final String? posterUrl;
  final String category;
  final String organizer;
  final String? date;
  final String? meta;
  final String? secondaryMeta;
  final String? status;

  /// Kuota terkini dari API: jumlah peserta Diterima / kapasitas.
  final String? liveQuota;

  /// Pada Lomba Diikuti/Dibuat indikator berada di kanan judul.
  final bool liveQuotaBesideTitle;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;
  final bool isFavorite;
  final bool showFavorite;
  final bool compact;
  final double height;

  const CompetitionPosterCard({
    super.key,
    required this.title,
    this.posterUrl,
    this.category = 'Kompetisi',
    this.organizer = '',
    this.date,
    this.meta,
    this.secondaryMeta,
    this.status,
    this.liveQuota,
    this.liveQuotaBesideTitle = false,
    this.onTap,
    this.onFavorite,
    this.isFavorite = false,
    this.showFavorite = false,
    this.compact = false,
    this.height = 278,
  });

  static const _ink = Color(0xFF171717);
  static const _outline = Color(0xFFE2DDD5);

  @override
  Widget build(BuildContext context) {
    final hasPoster = posterUrl?.trim().isNotEmpty == true;
    final hasStatus = status?.trim().isNotEmpty == true;
    final hasDate = date?.trim().isNotEmpty == true;
    final hasMeta = meta?.trim().isNotEmpty == true;
    final hasSecondary = secondaryMeta?.trim().isNotEmpty == true;
    final hasLiveQuota = liveQuota?.trim().isNotEmpty == true;
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _outline, width: 1.2),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (hasPoster)
                      Image.network(
                        posterUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _fallback(),
                      )
                    else
                      _fallback(),
                    // Kedua chip selalu menempel pada dua ujung poster,
                    // dengan ruang masing-masing agar tak saling bertabrakan.
                    Positioned(
                      left: 9,
                      right: 9,
                      top: 9,
                      child: Row(
                        children: [
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: _pill(
                                category.trim().isEmpty
                                    ? 'Kompetisi'
                                    : category.trim(),
                              ),
                            ),
                          ),
                          if (hasStatus)
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: _pill(status!.trim()),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (showFavorite)
                      Positioned(
                        right: 9,
                        bottom: 9,
                        child: Semantics(
                          button: true,
                          label: isFavorite
                              ? 'Hapus dari favorit'
                              : 'Simpan ke favorit',
                          child: Material(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              onTap: onFavorite,
                              borderRadius: BorderRadius.circular(12),
                              child: SizedBox(
                                height: 34,
                                width: 34,
                                child: Icon(
                                  isFavorite
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded,
                                  size: 19,
                                  color: _ink,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.fromLTRB(
                  compact ? 10 : 13,
                  10,
                  compact ? 10 : 13,
                  11,
                ),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: _outline)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: _ink,
                              fontWeight: FontWeight.w800,
                              fontSize: compact ? 14 : 16,
                              height: 1.08,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                        if (hasLiveQuota && liveQuotaBesideTitle) ...[
                          const SizedBox(width: 5),
                          _liveQuotaBadge(liveQuota!.trim()),
                        ],
                      ],
                    ),
                    if (organizer.trim().isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        organizer.trim(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: const Color(0xFF77736E),
                          fontSize: compact ? 10 : 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    if (hasDate || hasMeta || hasSecondary) ...[
                      const SizedBox(height: 8),
                      const Divider(
                        height: 1,
                        thickness: 1,
                        color: Color(0xFFF0ECE7),
                      ),
                      const SizedBox(height: 7),
                    ],
                    if (hasDate || hasMeta)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (hasDate)
                            Expanded(
                              flex: hasMeta ? 6 : 1,
                              child: _metadata(
                                Icons.calendar_today_outlined,
                                date!.trim(),
                              ),
                            ),
                          if (hasDate && hasMeta) const SizedBox(width: 5),
                          if (hasMeta)
                            Expanded(
                              flex: hasDate ? 5 : 1,
                              child: _metadata(
                                Icons.sell_outlined,
                                meta!.trim(),
                                alignEnd: hasDate,
                              ),
                            ),
                        ],
                      ),
                    if (hasLiveQuota && !liveQuotaBesideTitle) ...[
                      SizedBox(height: hasDate || hasMeta ? 5 : 7),
                      _liveQuotaBadge(liveQuota!.trim()),
                    ],
                    if (hasSecondary) ...[
                      SizedBox(height: hasDate || hasMeta ? 5 : 0),
                      Text(
                        secondaryMeta!.trim(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          height: 1.18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF57534F),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _liveQuotaBadge(String value) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0xFFF2F0EC),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.circle, color: _ink, size: 5),
        const SizedBox(width: 4),
        Text(
          'Kuota $value',
          maxLines: 1,
          style: const TextStyle(
            color: _ink,
            fontWeight: FontWeight.w800,
            fontSize: 9,
          ),
        ),
      ],
    ),
  );

  Widget _metadata(IconData icon, String value, {bool alignEnd = false}) {
    return Row(
      mainAxisAlignment: alignEnd
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: const Color(0xFF77736E)),
        const SizedBox(width: 3),
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Color(0xFF343331),
            ),
          ),
        ),
      ],
    );
  }

  Widget _fallback() => const ColoredBox(
    color: Color(0xFFEEECE8),
    child: Center(
      child: Icon(
        Icons.emoji_events_outlined,
        size: 40,
        color: Color(0xFF55534F),
      ),
    ),
  );

  Widget _pill(String value) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(13),
      border: Border.all(color: const Color(0xFFE7E2D9)),
    ),
    child: Text(
      value,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: _ink,
        fontSize: 10,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}
