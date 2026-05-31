import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/bible_data.dart';
import '../providers/settings_controller.dart';
import '../theme/app_theme.dart';
import 'library_screen.dart' show booksMatchingCategory;
import 'reader_screen.dart';

/// 검색 결과 1건의 종류.
enum SearchHitType {
  passage, // 본문 매치
  book, // 책 제목 매치
  chapter, // 편 제목 매치
}

/// 검색 결과 1건.
class SearchHit {
  const SearchHit({
    required this.type,
    required this.book,
    required this.chapterIndex,
    this.blockIndex = -1,
    required this.snippet,
    required this.matchStart,
    required this.matchLen,
    this.note,
  });

  final SearchHitType type;
  final BibleBook book;
  final int chapterIndex; // book 타입은 0(첫 편)
  final int blockIndex; // passage만 의미, 그 외 -1
  final String snippet; // 하이라이트 대상 텍스트
  final int matchStart;
  final int matchLen;
  final String? note; // 분류 매치로 나온 책이면 그 분류 쿼리
}

/// 정경 필터를 반영한 통합 검색 — 책 제목 / 편 제목 / 본문.
/// 한 편에서 편 제목이 매치되면 본문 매치는 생략(중복 방지).
/// canonExtra 블록은 개신교 선택 시 본문에서 숨기므로 검색에서도 제외.
List<SearchHit> searchBible(
  BibleData data,
  String canon,
  String rawQuery, {
  int limit = 300,
}) {
  final query = rawQuery.trim().toLowerCase();
  if (query.isEmpty) {
    return const [];
  }
  // 타입별로 모아서 우선순위(분류 → 책 제목 → 편 제목 → 본문) 순으로 합친다.
  final categoryHits = <SearchHit>[];
  final bookHits = <SearchHit>[];
  final chapterHits = <SearchHit>[];
  final passageHits = <SearchHit>[];

  // 분류명(모세오경/역사서/예언서 등) 매치 → 해당 책들
  for (final book in booksMatchingCategory(rawQuery, canon, data.books)) {
    categoryHits.add(SearchHit(
      type: SearchHitType.book,
      book: book,
      chapterIndex: 0,
      snippet: book.title,
      matchStart: 0,
      matchLen: 0,
      note: rawQuery.trim(),
    ));
  }

  for (final book in data.books) {
    if (!book.canon.contains(canon)) {
      continue;
    }
    // 책 제목 매치
    final btIdx = book.title.toLowerCase().indexOf(query);
    if (btIdx >= 0) {
      bookHits.add(SearchHit(
        type: SearchHitType.book,
        book: book,
        chapterIndex: 0,
        snippet: book.title,
        matchStart: btIdx,
        matchLen: query.length,
      ));
    }
    for (var ci = 0; ci < book.chapters.length; ci++) {
      final chapter = book.chapters[ci];
      // 편 제목 매치 → 본문은 생략
      final ctIdx = chapter.title.toLowerCase().indexOf(query);
      if (ctIdx >= 0) {
        chapterHits.add(SearchHit(
          type: SearchHitType.chapter,
          book: book,
          chapterIndex: ci,
          snippet: chapter.title,
          matchStart: ctIdx,
          matchLen: query.length,
        ));
        continue;
      }
      // 본문 매치
      final hit = _firstHitInChapter(book, ci, chapter, canon, query);
      if (hit != null) {
        passageHits.add(hit);
      }
    }
  }

  final all = <SearchHit>[
    ...categoryHits,
    ...bookHits,
    ...chapterHits,
    ...passageHits,
  ];
  return all.length > limit ? all.sublist(0, limit) : all;
}

/// 결과 그룹 키(헤더 묶음용). 분류는 book 타입이지만 note로 구분.
String hitGroup(SearchHit h) {
  switch (h.type) {
    case SearchHitType.book:
      return h.note != null ? 'category' : 'book';
    case SearchHitType.chapter:
      return 'chapter';
    case SearchHitType.passage:
      return 'passage';
  }
}

const _groupLabels = <String, String>{
  'category': '분류',
  'book': '책',
  'chapter': '편 제목',
  'passage': '본문',
};

SearchHit? _firstHitInChapter(
  BibleBook book,
  int chapterIndex,
  BibleChapter chapter,
  String canon,
  String query,
) {
  for (var bi = 0; bi < chapter.blocks.length; bi++) {
    final block = chapter.blocks[bi];
    if (block.canonExtra && canon == 'protestant') {
      continue;
    }
    final texts = <String>[];
    final text = block.text;
    if (text != null && text.isNotEmpty) {
      texts.add(text);
    }
    for (final item in block.items) {
      texts.add(item.text);
    }
    for (final candidate in texts) {
      final idx = candidate.toLowerCase().indexOf(query);
      if (idx >= 0) {
        return _buildHit(book, chapterIndex, bi, candidate, idx, query.length);
      }
    }
  }
  return null;
}

SearchHit _buildHit(
  BibleBook book,
  int chapterIndex,
  int blockIndex,
  String text,
  int idx,
  int queryLen,
) {
  const before = 24;
  const after = 70;
  final start = (idx - before).clamp(0, text.length);
  final end = (idx + queryLen + after).clamp(0, text.length);
  final prefix = start > 0 ? '…' : '';
  final suffix = end < text.length ? '…' : '';
  return SearchHit(
    type: SearchHitType.passage,
    book: book,
    chapterIndex: chapterIndex,
    blockIndex: blockIndex,
    snippet: '$prefix${text.substring(start, end)}$suffix',
    matchStart: (idx - start) + prefix.length,
    matchLen: queryLen,
  );
}

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key, required this.data});

  final BibleData data;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = appColors(context);
    final canon = ref.watch(settingsControllerProvider.select((s) => s.canon));
    final fontFamily = ref.watch(
      settingsControllerProvider.select((s) => s.fontFamily),
    );
    final hits = searchBible(widget.data, canon, _query);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          style: TextStyle(color: colors.ink, fontSize: 18),
          decoration: InputDecoration(
            hintText: '책·편 제목이나 본문 검색',
            hintStyle: TextStyle(color: colors.inkSoft),
            border: InputBorder.none,
          ),
          onChanged: (value) => setState(() => _query = value),
        ),
        actions: [
          if (_query.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _controller.clear();
                setState(() => _query = '');
              },
            ),
        ],
      ),
      body: _query.trim().isEmpty
          ? _Hint(text: '읽고 싶은 단어, 책, 편 검색')
          : hits.isEmpty
          ? _Hint(text: '"${_query.trim()}" 검색 결과 없음')
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '결과 ${hits.length}건',
                      style: TextStyle(color: colors.inkSoft),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(8, 4, 8, 32),
                    itemCount: hits.length,
                    itemBuilder: (context, i) {
                      final hit = hits[i];
                      final showHeader =
                          i == 0 || hitGroup(hits[i - 1]) != hitGroup(hit);
                      final tile = _HitTile(
                        hit: hit,
                        canon: canon,
                        fontFamily: fontFamily,
                      );
                      if (!showHeader) {
                        return tile;
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _GroupHeader(label: _groupLabels[hitGroup(hit)] ?? ''),
                          tile,
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class _HitTile extends StatelessWidget {
  const _HitTile({
    required this.hit,
    required this.canon,
    required this.fontFamily,
  });

  final SearchHit hit;
  final String canon;
  final String? fontFamily;

  /// 결과 종류별 컨텍스트 라벨(작은 제목 줄).
  String _contextLabel() {
    final chapter = hit.book.chapters[hit.chapterIndex];
    switch (hit.type) {
      case SearchHitType.book:
        return hit.note != null ? '📖 ${hit.note} · ${hit.book.title}' : '📖 책';
      case SearchHitType.chapter:
        return '✎ ${hit.book.title} · ${hit.chapterIndex + 1}편';
      case SearchHitType.passage:
        return '${hit.book.title} · ${hit.chapterIndex + 1}편  ${chapter.title}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = appColors(context);
    final snippet = hit.snippet;
    final mStart = hit.matchStart.clamp(0, snippet.length);
    final mEnd = (hit.matchStart + hit.matchLen).clamp(mStart, snippet.length);
    return ListTile(
      title: Text(
        _contextLabel(),
        style: TextStyle(
          color: colors.accent,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: RichText(
          text: TextSpan(
            style: TextStyle(
              color: colors.ink,
              fontSize: 15,
              height: 1.5,
              fontFamily: fontFamily,
            ),
            children: [
              TextSpan(text: snippet.substring(0, mStart)),
              TextSpan(
                text: snippet.substring(mStart, mEnd),
                style: TextStyle(
                  color: colors.accent,
                  fontWeight: FontWeight.w700,
                  backgroundColor: colors.accent.withValues(alpha: 0.18),
                ),
              ),
              TextSpan(text: snippet.substring(mEnd)),
            ],
          ),
        ),
      ),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ReaderScreen(
              book: hit.book,
              initialChapterIndex: hit.chapterIndex,
              initialBlockIndex: hit.blockIndex,
              selectedCanon: canon,
            ),
          ),
        );
      },
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = appColors(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 18, 12, 6),
      child: Text(
        label,
        style: handTextStyle(
          color: colors.accentSoft,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = appColors(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: handTextStyle(color: colors.inkSoft, fontSize: 22),
        ),
      ),
    );
  }
}
