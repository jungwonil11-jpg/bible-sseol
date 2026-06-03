import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/artwork.dart';
import '../data/models/bible_data.dart';
import '../providers/artworks_providers.dart';
import '../providers/books_providers.dart';
import '../theme/app_theme.dart';

/// 수록 명화의 저작권 정책과 권별 출처 목록을 보여주는 화면.
/// 정보 화면 → "수록 명화 출처"에서 진입한다.
class ArtworkCreditsScreen extends ConsumerWidget {
  const ArtworkCreditsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = appColors(context);
    final art = ref
        .watch(artworkDataProvider)
        .maybeWhen(data: (d) => d, orElse: () => null);
    final bible = ref
        .watch(bibleDataProvider)
        .maybeWhen(data: (d) => d, orElse: () => null);

    return Scaffold(
      appBar: AppBar(title: const Text('수록 명화 출처')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        children: [
          // ── 저작권 정책 ──
          Text(
            '저작권 안내',
            style: handTextStyle(
              color: colors.ink,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          for (final line in _policyLines)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('· ', style: TextStyle(color: colors.accent)),
                  Expanded(
                    child: Text(
                      line,
                      style: TextStyle(
                        color: colors.ink,
                        fontSize: 14.5,
                        height: 1.55,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 28),

          // ── 권별 수록 목록 ──
          if (art == null || bible == null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  '목록을 불러오는 중…',
                  style: TextStyle(color: colors.inkSoft),
                ),
              ),
            )
          else ...[
            // 천주교·정교회 추가 권(testament 'deut')도 구약에 통합해 표시.
            _testamentBlock(
              '구약',
              _booksWithArt(bible, art, const {'old', 'deut'}),
              art,
              colors,
            ),
            _testamentBlock(
              '신약',
              _booksWithArt(bible, art, const {'new'}),
              art,
              colors,
            ),
          ],
        ],
      ),
    );
  }

  /// 해당 경(구약/신약)에서 명화가 있는 책만 정경 순서(sortOrder)로.
  /// 구약은 추가 권(deut) 통합을 위해 여러 testament를 받는다.
  List<BibleBook> _booksWithArt(
    BibleData bible,
    ArtworkData art,
    Set<String> testaments,
  ) {
    final list = bible.books
        .where(
          (b) =>
              testaments.contains(b.testament) && art.byBook.containsKey(b.id),
        )
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return list;
  }

  Widget _testamentBlock(
    String label,
    List<BibleBook> books,
    ArtworkData art,
    AppColors colors,
  ) {
    if (books.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: handTextStyle(
            color: colors.accent,
            fontSize: 19,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        for (final book in books) _bookCredits(book, art.byBook[book.id]!, colors),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _bookCredits(
    BibleBook book,
    Map<int, Artwork> chapters,
    AppColors colors,
  ) {
    final nums = chapters.keys.toList()..sort();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            book.title,
            style: TextStyle(
              color: colors.ink,
              fontSize: 15.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          for (final n in nums)
            Padding(
              padding: const EdgeInsets.only(top: 3, left: 2),
              child: Text(
                '$n편 · ${chapters[n]!.title} — ${chapters[n]!.artist}'
                '${chapters[n]!.year.isEmpty ? '' : ' (${chapters[n]!.year})'}',
                style: TextStyle(
                  color: colors.inkSoft,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

const _policyLines = <String>[
  '편마다 곁들인 그림은 모두 저작권이 소멸한 퍼블릭 도메인(자유 이용) 명화입니다.',
  '출처는 Wikimedia Commons이며, 평면 회화를 충실히 복제한 이미지(PD-Art)만 사용했습니다.',
  '각 그림은 작가·작품명·제작 시기와 함께 표시되며, 그림을 누르면 원본을 확대해 볼 수 있습니다.',
  '교리·신학적 해석과 무관하게, 해당 본문의 사건·장면을 다룬 고전 명화를 골랐습니다.',
];
