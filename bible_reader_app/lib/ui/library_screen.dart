import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/bible_data.dart';
import '../providers/reading_providers.dart';
import '../providers/settings_controller.dart';
import '../theme/app_theme.dart';
import 'book_detail_screen.dart';
import 'global_app_bar_actions.dart';
import 'reader_screen.dart';
import 'stats_screen.dart';

const canonKeys = ['protestant', 'catholic', 'orthodox'];

/// 한 권이 속하는 문학 그룹(개신교 최소단위 기준). 천주교/정교회는 이 그룹들을
/// 합쳐서 더 큰 섹션으로 보여준다(대+소예언서→예언서, 바울+히브리+공동→서간).
/// 데이터는 안 건드리고 화면에서만 쓰는 표 — id는 books.json 기준.
const _bookGroup = <String, String>{
  // 모세오경 / 오경
  'genesis': 'pentateuch', 'exodus': 'pentateuch', 'leviticus': 'pentateuch',
  'numbers': 'pentateuch', 'deuteronomy': 'pentateuch',
  // 역사서
  'joshua': 'history', 'judges': 'history', 'ruth': 'history',
  'samuel1': 'history', 'samuel2': 'history', 'kings1': 'history',
  'kings2': 'history', 'chronicles1': 'history', 'chronicles2': 'history',
  'ezra': 'history', 'nehemiah': 'history', 'esther': 'history',
  'tobit': 'history', 'judith': 'history', 'maccabees1': 'history',
  'maccabees2': 'history', 'maccabees3': 'history', 'esdras1': 'history',
  'manasseh': 'history',
  // 시가서 / 시서와 지혜서
  'job': 'poetry', 'psalms': 'poetry', 'proverbs': 'poetry',
  'ecclesiastes': 'poetry', 'song': 'poetry', 'wisdom': 'poetry',
  'sirach': 'poetry', 'psalm151': 'poetry',
  // 대예언서
  'isaiah': 'major_prophets', 'jeremiah': 'major_prophets',
  'lamentations': 'major_prophets', 'ezekiel': 'major_prophets',
  'daniel': 'major_prophets', 'baruch': 'major_prophets',
  // 소예언서
  'hosea': 'minor_prophets', 'joel': 'minor_prophets', 'amos': 'minor_prophets',
  'obadiah': 'minor_prophets', 'jonah': 'minor_prophets', 'micah': 'minor_prophets',
  'nahum': 'minor_prophets', 'habakkuk': 'minor_prophets',
  'zephaniah': 'minor_prophets', 'haggai': 'minor_prophets',
  'zechariah': 'minor_prophets', 'malachi': 'minor_prophets',
  // 복음서
  'matthew': 'gospels', 'mark': 'gospels', 'luke': 'gospels', 'john': 'gospels',
  // 사도행전
  'acts': 'acts',
  // 바울서신
  'romans': 'pauline', 'corinthians1': 'pauline', 'corinthians2': 'pauline',
  'galatians': 'pauline', 'ephesians': 'pauline', 'philippians': 'pauline',
  'colossians': 'pauline', 'thessalonians1': 'pauline',
  'thessalonians2': 'pauline', 'timothy1': 'pauline', 'timothy2': 'pauline',
  'titus': 'pauline', 'philemon': 'pauline',
  // 히브리서
  'hebrews': 'hebrews',
  // 공동서신 / 서간
  'james': 'general', 'peter1': 'general', 'peter2': 'general',
  'john1': 'general', 'john2': 'general', 'john3': 'general', 'jude': 'general',
  // 요한계시록 / 요한 묵시록
  'revelation': 'revelation',
};

/// (소제목, 묶을 그룹들) 순서대로. 천주교/정교회는 동일 레이아웃을 공유.
const _oldLayoutProtestant = <(String, List<String>)>[
  ('모세오경', ['pentateuch']),
  ('역사서', ['history']),
  ('시가서', ['poetry']),
  ('대예언서', ['major_prophets']),
  ('소예언서', ['minor_prophets']),
];
const _newLayoutProtestant = <(String, List<String>)>[
  ('복음서', ['gospels']),
  ('사도행전', ['acts']),
  ('바울서신', ['pauline']),
  ('히브리서', ['hebrews']),
  ('공동서신', ['general']),
  ('요한계시록', ['revelation']),
];
const _oldLayoutCatholic = <(String, List<String>)>[
  ('오경', ['pentateuch']),
  ('역사서', ['history']),
  ('시서와 지혜서', ['poetry']),
  ('예언서', ['major_prophets', 'minor_prophets']),
];
const _newLayoutCatholic = <(String, List<String>)>[
  ('복음서', ['gospels']),
  ('사도행전', ['acts']),
  ('서간', ['pauline', 'hebrews', 'general']),
  ('요한 묵시록', ['revelation']),
];
const _canonLayouts = <String, Map<String, List<(String, List<String>)>>>{
  'protestant': {'old': _oldLayoutProtestant, 'new': _newLayoutProtestant},
  'catholic': {'old': _oldLayoutCatholic, 'new': _newLayoutCatholic},
  'orthodox': {'old': _oldLayoutCatholic, 'new': _newLayoutCatholic},
};

typedef _BookGroupSection = ({String label, List<BibleBook> books});

/// 이미 sortOrder로 정렬된 책 목록을 정경 레이아웃 순서대로 그룹핑한다.
/// 비어있는 섹션(해당 정경에 책이 없는 그룹)은 건너뛴다.
List<_BookGroupSection> _groupBooks(
  List<BibleBook> books,
  String canon,
  String testamentKey,
) {
  final layout = _canonLayouts[canon]![testamentKey]!;
  final byGroup = <String, List<BibleBook>>{};
  for (final book in books) {
    final group = _bookGroup[book.id];
    if (group == null) {
      continue;
    }
    byGroup.putIfAbsent(group, () => []).add(book);
  }
  final sections = <_BookGroupSection>[];
  for (final (label, groups) in layout) {
    final merged = <BibleBook>[];
    for (final group in groups) {
      merged.addAll(byGroup[group] ?? const []);
    }
    if (merged.isNotEmpty) {
      sections.add((label: label, books: merged));
    }
  }
  return sections;
}

/// 쿼리가 분류명(모세오경/역사서/시가서/예언서/복음서/서간 등)과 매치되면
/// 그 분류에 속한 현재 정경의 책들을 sortOrder 순으로 반환. 매치 없으면 빈 목록.
/// 정경마다 라벨이 달라서(모세오경↔오경, 대/소예언서↔예언서) 현재 정경 레이아웃을 본다.
List<BibleBook> booksMatchingCategory(
  String rawQuery,
  String canon,
  List<BibleBook> books,
) {
  final q = rawQuery.trim().toLowerCase();
  if (q.length < 2) {
    return const [];
  }
  final layouts = _canonLayouts[canon];
  if (layouts == null) {
    return const [];
  }
  final matchedGroups = <String>{};
  for (final sections in layouts.values) {
    for (final (label, groups) in sections) {
      final l = label.toLowerCase();
      if (l.contains(q) || q.contains(l)) {
        matchedGroups.addAll(groups);
      }
    }
  }
  if (matchedGroups.isEmpty) {
    return const [];
  }
  final result = books
      .where((b) =>
          b.canon.contains(canon) && matchedGroups.contains(_bookGroup[b.id]))
      .toList();
  result.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  return result;
}

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key, required this.data});

  final BibleData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = appColors(context);
    final settings = ref.watch(settingsControllerProvider);
    final selectedCanon = settings.canon;
    final canonInfo = data.canonInfo[selectedCanon]!;
    // 구약 + 제2경전을 한 묶음으로 합침. 천주교/정교회에선 제2경전이 별도
    // 등급이 아니라 구약의 일부이므로, sortOrder로 정렬해 구약 흐름에 끼워넣는다.
    // 개신교는 canon 필터로 제2경전이 자연히 빠져 구약 39권만 남는다.
    final oldBooks = _booksFor(const ['old', 'deut'], selectedCanon);
    final newBooks = _booksFor(const ['new'], selectedCanon);

    return Scaffold(
      appBar: AppBar(
        title: const Text('성경 전체 썰 읽으실분'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_outlined),
            tooltip: '읽기 통계',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => StatsScreen(data: data)),
            ),
          ),
          ...globalAppBarActions(context, ref, data),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
        children: [
          Text(
            '${canonInfo.name} ${canonInfo.total}권',
            style: handTextStyle(
              color: colors.ink,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 22),
          _ContinueCard(data: data),
          _TestamentSection(
            title: '구약',
            sections: _groupBooks(oldBooks, selectedCanon, 'old'),
            selectedCanon: selectedCanon,
          ),
          _TestamentSection(
            title: '신약',
            sections: _groupBooks(newBooks, selectedCanon, 'new'),
            selectedCanon: selectedCanon,
          ),
        ],
      ),
    );
  }

  List<BibleBook> _booksFor(List<String> testaments, String canon) {
    final books =
        data.books
            .where(
              (book) =>
                  testaments.contains(book.testament) &&
                  book.canon.contains(canon),
            )
            .toList()
          ..sort((a, b) {
            final byOrder = a.sortOrder.compareTo(b.sortOrder);
            return byOrder != 0 ? byOrder : a.order.compareTo(b.order);
          });
    return books;
  }
}

/// 마지막으로 읽던 편으로 바로 점프하는 카드.
class _ContinueCard extends ConsumerWidget {
  const _ContinueCard({required this.data});

  final BibleData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = appColors(context);
    final lastRead = ref.watch(lastReadProvider);
    return lastRead.maybeWhen(
      orElse: () => const SizedBox.shrink(),
      data: (progress) {
        if (progress == null) {
          return const SizedBox.shrink();
        }
        final found = _locate(data, progress.bookId, progress.chapterId);
        if (found == null) {
          return const SizedBox.shrink();
        }
        final (book, index) = found;
        return Padding(
          padding: const EdgeInsets.only(bottom: 26),
          child: Material(
            color: colors.paperEdge,
            borderRadius: BorderRadius.circular(12),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ReaderScreen(
                    book: book,
                    initialChapterIndex: index,
                    selectedCanon: ref.read(settingsControllerProvider).canon,
                    initialScrollOffset: progress.scrollOffset,
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                child: Row(
                  children: [
                    Icon(Icons.play_arrow_rounded, color: colors.accent, size: 26),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '이어보기',
                            style: TextStyle(
                              color: colors.inkSoft,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${book.title} · ${index + 1}편 ${book.chapters[index].title}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.ink,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: colors.accentSoft, size: 20),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 구약 / 신약 큰 제목 + 그 아래 문학 그룹별 접이식 섹션들.
class _TestamentSection extends StatelessWidget {
  const _TestamentSection({
    required this.title,
    required this.sections,
    required this.selectedCanon,
  });

  final String title;
  final List<_BookGroupSection> sections;
  final String selectedCanon;

  @override
  Widget build(BuildContext context) {
    final colors = appColors(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: handTextStyle(
                  color: colors.ink,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Divider(color: colors.line, height: 1)),
            ],
          ),
          const SizedBox(height: 4),
          for (final section in sections)
            _GroupTile(
              label: section.label,
              books: section.books,
              selectedCanon: selectedCanon,
            ),
        ],
      ),
    );
  }
}

/// 문학 그룹 하나 = 접이식 박스. 기본 펼침, PageStorageKey로 접힘 상태 유지.
class _GroupTile extends StatelessWidget {
  const _GroupTile({
    required this.label,
    required this.books,
    required this.selectedCanon,
  });

  final String label;
  final List<BibleBook> books;
  final String selectedCanon;

  @override
  Widget build(BuildContext context) {
    final colors = appColors(context);
    // 카드/보더 없이 평평하게. 기본 펼침, 접힘 상태는 PageStorageKey로 유지.
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        key: PageStorageKey('group-$label'),
        initiallyExpanded: true,
        shape: const Border(),
        collapsedShape: const Border(),
        tilePadding: EdgeInsets.zero,
        iconColor: colors.accentSoft,
        collapsedIconColor: colors.accentSoft,
        childrenPadding: EdgeInsets.zero,
        title: Row(
          children: [
            Text(
              label,
              style: handTextStyle(
                color: colors.ink,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${books.length}',
              style: TextStyle(color: colors.inkSoft, fontSize: 13),
            ),
          ],
        ),
        children: [
          for (var i = 0; i < books.length; i++)
            _BookListTile(
              book: books[i],
              selectedCanon: selectedCanon,
              showDivider: i != books.length - 1,
            ),
        ],
      ),
    );
  }
}

class _BookListTile extends ConsumerWidget {
  const _BookListTile({
    required this.book,
    required this.selectedCanon,
    required this.showDivider,
  });

  final BibleBook book;
  final String selectedCanon;
  final bool showDivider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = appColors(context);
    final readCount = ref
        .watch(bookReadCountProvider(book.id))
        .maybeWhen(data: (n) => n, orElse: () => 0);
    final total = book.chapters.length;
    final done = readCount >= total && total > 0;
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.fromLTRB(8, 4, 4, 4),
          dense: true,
          title: Text(
            book.title,
            style: TextStyle(
              color: done ? colors.inkSoft : colors.ink,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            readCount > 0 ? '${book.ref} · $readCount/$total편' : book.ref,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: colors.inkSoft, fontSize: 12),
          ),
          trailing: done
              ? Icon(Icons.check, color: colors.accentSoft, size: 18)
              : null,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    BookDetailScreen(book: book, selectedCanon: selectedCanon),
              ),
            );
          },
        ),
        if (showDivider)
          Divider(height: 1, color: colors.line, indent: 8),
      ],
    );
  }
}

(BibleBook, int)? _locate(BibleData data, String bookId, String chapterId) {
  for (final book in data.books) {
    if (book.id != bookId) {
      continue;
    }
    for (var i = 0; i < book.chapters.length; i++) {
      if (book.chapters[i].id == chapterId) {
        return (book, i);
      }
    }
  }
  return null;
}
