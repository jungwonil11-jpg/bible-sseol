import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/bible_data.dart';
import '../providers/database_providers.dart';
import '../providers/reading_providers.dart';
import '../providers/settings_controller.dart';
import '../theme/app_theme.dart';
import 'attendance_calendar.dart';
import 'error_view.dart';
import 'reader_screen.dart';
import 'stats_logic.dart';

/// 읽기 통계(선택한 정경 기준).
/// 위: 어디까지 읽었나(조각모음 그리드, 읽은 편=색칠). 아래: 읽기 출석 달력.
class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key, required this.data});

  final BibleData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = appColors(context);
    final canon = ref.watch(settingsControllerProvider.select((s) => s.canon));
    final canonName = data.canonInfo[canon]?.name ?? '';
    final statusAsync = ref.watch(allReadStatusProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('완독하자!')),
      body: statusAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => ErrorView(
          error: e,
          stackTrace: st,
          onRetry: () => ref.invalidate(allReadStatusProvider),
        ),
        data: (status) {
          final s = computeReadingStats(data, canon, status);
          final pct = s.totalChapters == 0
              ? 0
              : (s.readChapters / s.totalChapters * 100).round();
          final readIds = {
            for (final st in status)
              if (st.isRead) st.chapterId,
          };
          final oldBooks = _canonBooks(data, canon, const ['old', 'deut']);
          final newBooks = _canonBooks(data, canon, const ['new']);

          return ListView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
            children: [
              Text(
                '$canonName 기준',
                style: handTextStyle(
                  color: colors.accent,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),

              // 전체 진행률
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '$pct%',
                          style: handTextStyle(
                            color: colors.ink,
                            fontSize: 40,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${s.readChapters} / ${s.totalChapters}편',
                          style: TextStyle(color: colors.inkSoft, fontSize: 15),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: s.totalChapters == 0
                            ? 0
                            : s.readChapters / s.totalChapters,
                        minHeight: 10,
                        backgroundColor: colors.line,
                        valueColor: AlwaysStoppedAnimation(colors.accent),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _StatBox(
                      label: '읽은 책',
                      value: '${s.readBooks} / ${s.totalBooks}',
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _StatBox(
                      label: '누적 읽은 편',
                      value: '${s.readChapters}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // 어디까지 읽었나 — 조각모음 그리드
              _SectionTitle(text: '어디까지 읽었나'),
              const SizedBox(height: 4),
              Text(
                '칸 하나 = 한 편. 누르면 그 편으로 가거나 읽음 표시를 바꿀 수 있음.',
                style: TextStyle(color: colors.inkSoft, fontSize: 12),
              ),
              const SizedBox(height: 14),
              if (oldBooks.isNotEmpty) ...[
                _GridCard(
                  label: '구약',
                  books: oldBooks,
                  readIds: readIds,
                  onTapCell: (book, index) =>
                      _showCellSheet(context, ref, oldBooks, book, index, canon),
                ),
                const SizedBox(height: 14),
              ],
              _GridCard(
                label: '신약',
                books: newBooks,
                readIds: readIds,
                onTapCell: (book, index) =>
                    _showCellSheet(context, ref, newBooks, book, index, canon),
              ),
              const SizedBox(height: 30),

              // 읽기 출석 — 달력 펼침
              _SectionTitle(text: '읽기 출석'),
              const SizedBox(height: 14),
              _Card(child: AttendanceCalendar(status: status)),
            ],
          );
        },
      ),
    );
  }
}

/// 선택 정경 + 지정 구분(구약/신약)에 속한 책을 sortOrder 순으로.
List<BibleBook> _canonBooks(
  BibleData data,
  String canon,
  List<String> testaments,
) {
  final books = data.books
      .where((b) =>
          testaments.contains(b.testament) && b.canon.contains(canon))
      .toList()
    ..sort((a, b) {
      final byOrder = a.sortOrder.compareTo(b.sortOrder);
      return byOrder != 0 ? byOrder : a.order.compareTo(b.order);
    });
  return books;
}

/// 평탄화된 편 위치 한 칸 = 어떤 책의 몇 번째 편인지.
class _FlatChapter {
  const _FlatChapter(this.book, this.index);
  final BibleBook book;
  final int index;
}

/// 그리드 셀(편) 탭 → 어떤 편인지 + 읽으러 가기 + 읽음/안읽음 수동 토글.
/// DB 자동 읽음 처리가 틀렸을 때 유저가 직접 바로잡는 출구.
/// 같은 섹션(구약/신약) 안에서 전편/후편으로 넘기며 연속 확인 가능.
void _showCellSheet(
  BuildContext context,
  WidgetRef ref,
  List<BibleBook> sectionBooks,
  BibleBook book,
  int index,
  String canon,
) {
  final colors = appColors(context);
  // 섹션 전체 편을 sortOrder 순서대로 한 줄로 펼친다(전편/후편 이동용).
  final flat = <_FlatChapter>[
    for (final b in sectionBooks)
      for (var i = 0; i < b.chapters.length; i++) _FlatChapter(b, i),
  ];
  final start = flat.indexWhere(
    (f) => f.book.id == book.id && f.index == index,
  );

  showModalBottomSheet<void>(
    context: context,
    backgroundColor: colors.paper,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _CellSheet(
      ref: ref,
      parentContext: context,
      flat: flat,
      startPos: start < 0 ? 0 : start,
      canon: canon,
    ),
  );
}

/// 바텀시트 본문. 전편/후편 버튼으로 위치(pos)를 바꾸면 같은 시트 안에서
/// 제목·읽음 상태가 갱신된다.
class _CellSheet extends StatefulWidget {
  const _CellSheet({
    required this.ref,
    required this.parentContext,
    required this.flat,
    required this.startPos,
    required this.canon,
  });

  final WidgetRef ref;
  final BuildContext parentContext;
  final List<_FlatChapter> flat;
  final int startPos;
  final String canon;

  @override
  State<_CellSheet> createState() => _CellSheetState();
}

class _CellSheetState extends State<_CellSheet> {
  late int _pos;
  // 읽음 상태 로컬 스냅샷. 토글하면 즉시 반영하고 provider도 invalidate한다.
  late final Set<String> _readIds;

  @override
  void initState() {
    super.initState();
    _pos = widget.startPos;
    _readIds = widget.ref.read(allReadStatusProvider).maybeWhen(
          data: (list) => {
            for (final s in list)
              if (s.isRead) s.chapterId,
          },
          orElse: () => <String>{},
        );
  }

  Future<void> _setRead(BibleBook book, BibleChapter chapter, bool read) async {
    final dao = widget.ref.read(chapterReadStatusDaoProvider);
    if (read) {
      await dao.setRead(bookId: book.id, chapterId: chapter.id, isRead: true);
    } else {
      await dao.delete(chapter.id);
    }
    widget.ref.invalidate(allReadStatusProvider);
    widget.ref.invalidate(bookReadStatusProvider(book.id));
    widget.ref.invalidate(bookReadCountProvider(book.id));
    if (!mounted) return;
    setState(() {
      if (read) {
        _readIds.add(chapter.id);
      } else {
        _readIds.remove(chapter.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = appColors(context);
    final cur = widget.flat[_pos];
    final book = cur.book;
    final index = cur.index;
    final chapter = book.chapters[index];
    final isRead = _readIds.contains(chapter.id);
    final hasPrev = _pos > 0;
    final hasNext = _pos < widget.flat.length - 1;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 전편 ◁ [제목] ▷ 후편
            Row(
              children: [
                IconButton(
                  onPressed: hasPrev ? () => setState(() => _pos--) : null,
                  icon: const Icon(Icons.chevron_left),
                  tooltip: '전편',
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '${book.title} · ${index + 1}편',
                        textAlign: TextAlign.center,
                        style:
                            TextStyle(color: colors.inkSoft, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        chapter.title,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: handTextStyle(
                          color: colors.ink,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: hasNext ? () => setState(() => _pos++) : null,
                  icon: const Icon(Icons.chevron_right),
                  tooltip: '후편',
                ),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(widget.parentContext).push(
                  MaterialPageRoute(
                    builder: (_) => ReaderScreen(
                      book: book,
                      initialChapterIndex: index,
                      selectedCanon: widget.canon,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.menu_book_outlined),
              label: const Text('읽으러 가기'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: isRead
                        ? null
                        : () => _setRead(book, chapter, true),
                    child: const Text('읽음으로'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: !isRead
                        ? null
                        : () => _setRead(book, chapter, false),
                    child: const Text('안읽음으로'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

typedef _CellTap = void Function(BibleBook book, int index);

/// 한 구분(구약/신약)의 모든 편을 조각모음 그리드로. 읽음=액센트, 안읽음=옅은 칸.
class _GridCard extends StatelessWidget {
  const _GridCard({
    required this.label,
    required this.books,
    required this.readIds,
    required this.onTapCell,
  });

  final String label;
  final List<BibleBook> books;
  final Set<String> readIds;
  final _CellTap onTapCell;

  @override
  Widget build(BuildContext context) {
    final colors = appColors(context);
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: handTextStyle(
              color: colors.ink,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 5,
            runSpacing: 5,
            children: [
              for (final book in books)
                for (var i = 0; i < book.chapters.length; i++)
                  _ChapterCell(
                    isRead: readIds.contains(book.chapters[i].id),
                    onTap: () => onTapCell(book, i),
                  ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChapterCell extends StatelessWidget {
  const _ChapterCell({required this.isRead, required this.onTap});

  final bool isRead;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = appColors(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 17,
        height: 17,
        decoration: BoxDecoration(
          color: isRead ? colors.accent : colors.line,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = appColors(context);
    return Text(
      text,
      style: handTextStyle(
        color: colors.ink,
        fontSize: 22,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = appColors(context);
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: colors.inkSoft, fontSize: 13)),
          const SizedBox(height: 8),
          Text(
            value,
            style: handTextStyle(
              color: colors.ink,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = appColors(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.paperEdge,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.line),
      ),
      child: child,
    );
  }
}
