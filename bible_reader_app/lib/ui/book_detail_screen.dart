import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/bible_data.dart';
import '../providers/books_providers.dart';
import '../providers/reading_providers.dart';
import '../theme/app_theme.dart';
import 'global_app_bar_actions.dart';
import 'ornament.dart';
import 'reader_screen.dart';

class BookDetailScreen extends ConsumerWidget {
  const BookDetailScreen({
    super.key,
    required this.book,
    required this.selectedCanon,
  });

  final BibleBook book;
  final String selectedCanon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = appColors(context);
    final data = ref
        .watch(bibleDataProvider)
        .maybeWhen(data: (d) => d, orElse: () => null);
    final readStatus = ref
        .watch(bookReadStatusProvider(book.id))
        .maybeWhen(data: (list) => list, orElse: () => const []);
    final readIds = {
      for (final s in readStatus)
        if (s.isRead) s.chapterId,
    };
    final total = book.chapters.length;
    final readCount = book.chapters
        .where((c) => readIds.contains(c.id))
        .length;

    return Scaffold(
      appBar: AppBar(
        title: Text(book.title),
        actions: data == null ? null : globalAppBarActions(context, ref, data),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 36),
        children: [
          const SizedBox(height: 8),
          Text(
            book.title,
            textAlign: TextAlign.center,
            style: handTextStyle(
              color: colors.ink,
              fontSize: 34,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            book.ref,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.inkSoft,
              fontSize: 14,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          Ornament(color: colors.accentSoft),
          const SizedBox(height: 22),
          Text(
            '$total편 중 $readCount편 읽음',
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.inkSoft, fontSize: 14),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : readCount / total,
              minHeight: 5,
              backgroundColor: colors.line,
              color: colors.accent,
            ),
          ),
          const SizedBox(height: 30),
          Text(
            '편 목록',
            style: handTextStyle(
              color: colors.ink,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Material(
            color: colors.paperEdge,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: colors.line),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < book.chapters.length; i++)
                  _ChapterTile(
                    book: book,
                    selectedCanon: selectedCanon,
                    chapterIndex: i,
                    isRead: readIds.contains(book.chapters[i].id),
                    showDivider: i != book.chapters.length - 1,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChapterTile extends StatelessWidget {
  const _ChapterTile({
    required this.book,
    required this.selectedCanon,
    required this.chapterIndex,
    required this.isRead,
    required this.showDivider,
  });

  final BibleBook book;
  final String selectedCanon;
  final int chapterIndex;
  final bool isRead;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final colors = appColors(context);
    final chapter = book.chapters[chapterIndex];
    final titleColor = isRead ? colors.inkSoft : colors.ink;
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: Text(
            (chapterIndex + 1).toString().padLeft(2, '0'),
            style: handTextStyle(
              color: isRead ? colors.inkSoft : colors.accentSoft,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          title: Text(
            chapter.title,
            style: TextStyle(
              color: titleColor,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Text(chapter.ref, style: TextStyle(color: colors.inkSoft)),
          trailing: isRead
              ? Icon(Icons.check_circle, color: colors.accent, size: 20)
              : Icon(Icons.chevron_right, color: colors.accentSoft),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ReaderScreen(
                  book: book,
                  initialChapterIndex: chapterIndex,
                  selectedCanon: selectedCanon,
                ),
              ),
            );
          },
        ),
        if (showDivider)
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Divider(height: 1, color: colors.line),
          ),
      ],
    );
  }
}
