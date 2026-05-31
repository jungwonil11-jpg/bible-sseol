import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database/daos.dart';
import '../data/models/bible_data.dart';
import '../providers/database_providers.dart';
import '../providers/reading_providers.dart';
import '../providers/settings_controller.dart';
import '../theme/app_theme.dart';
import 'reader_screen.dart';

/// 즐겨찾기 + 밑줄 모아보기. 구절 북마크 역할.
class CollectionsScreen extends ConsumerWidget {
  const CollectionsScreen({super.key, required this.data});

  final BibleData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('모아보기'),
          bottom: const TabBar(
            tabs: [
              Tab(text: '즐겨찾기'),
              Tab(text: '하이라이트'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _FavoritesTab(data: data),
            _HighlightsTab(data: data),
          ],
        ),
      ),
    );
  }
}

class _FavoritesTab extends ConsumerWidget {
  const _FavoritesTab({required this.data});

  final BibleData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = appColors(context);
    final favorites = ref.watch(allFavoritesProvider);
    return favorites.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (list) {
        if (list.isEmpty) {
          return const _EmptyHint(text: '아직 즐겨찾기한 편이 없음');
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          itemCount: list.length,
          separatorBuilder: (_, _) => Divider(height: 1, color: colors.line),
          itemBuilder: (context, i) {
            final fav = list[i];
            final found = _locate(data, fav.chapterId);
            if (found == null) {
              return const SizedBox.shrink();
            }
            final (book, index) = found;
            final chapter = book.chapters[index];
            return ListTile(
              leading: Icon(Icons.bookmark, color: colors.accent),
              title: Text(
                '${book.title} · ${index + 1}편',
                style: TextStyle(color: colors.ink, fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                chapter.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: colors.inkSoft),
              ),
              trailing: IconButton(
                icon: Icon(Icons.close, color: colors.inkSoft, size: 20),
                onPressed: () async {
                  await ref
                      .read(chapterFavoritesDaoProvider)
                      .remove(fav.chapterId);
                  ref.invalidate(allFavoritesProvider);
                  ref.invalidate(chapterFavoriteProvider(fav.chapterId));
                },
              ),
              onTap: () => _openReader(context, ref, book, index),
            );
          },
        );
      },
    );
  }
}

class _HighlightsTab extends ConsumerWidget {
  const _HighlightsTab({required this.data});

  final BibleData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = appColors(context);
    final highlights = ref.watch(allHighlightsProvider);
    return highlights.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (list) {
        if (list.isEmpty) {
          return const _EmptyHint(text: '아직 하이라이트한 구절이 없음');
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          itemCount: list.length,
          separatorBuilder: (_, _) => Divider(height: 1, color: colors.line),
          itemBuilder: (context, i) {
            final hl = list[i];
            final found = _locate(data, hl.chapterId);
            if (found == null) {
              return const SizedBox.shrink();
            }
            final (book, index) = found;
            final snippet = _highlightSnippet(book.chapters[index], hl);
            return ListTile(
              leading: Icon(
                Icons.highlight,
                color: highlightPalette[
                    hl.color.clamp(0, highlightPalette.length - 1)],
              ),
              title: Text(
                snippet,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: colors.ink, height: 1.4),
              ),
              subtitle: Text(
                '${book.title} · ${index + 1}편',
                style: TextStyle(color: colors.inkSoft),
              ),
              trailing: IconButton(
                icon: Icon(Icons.close, color: colors.inkSoft, size: 20),
                onPressed: () async {
                  await ref.read(highlightsDaoProvider).delete(hl.id);
                  ref.invalidate(allHighlightsProvider);
                  ref.invalidate(chapterHighlightsProvider(hl.chapterId));
                },
              ),
              onTap: () => _openReader(context, ref, book, index),
            );
          },
        );
      },
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = appColors(context);
    return Center(
      child: Text(
        text,
        style: handTextStyle(color: colors.inkSoft, fontSize: 22),
      ),
    );
  }
}

void _openReader(
  BuildContext context,
  WidgetRef ref,
  BibleBook book,
  int chapterIndex,
) {
  final canon = ref.read(settingsControllerProvider).canon;
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => ReaderScreen(
        book: book,
        initialChapterIndex: chapterIndex,
        selectedCanon: canon,
      ),
    ),
  );
}

/// chapterId로 책 + 편 인덱스 찾기.
(BibleBook, int)? _locate(BibleData data, String chapterId) {
  for (final book in data.books) {
    for (var i = 0; i < book.chapters.length; i++) {
      if (book.chapters[i].id == chapterId) {
        return (book, i);
      }
    }
  }
  return null;
}

String _highlightSnippet(BibleChapter chapter, Highlight hl) {
  if (hl.blockIndex < 0 || hl.blockIndex >= chapter.blocks.length) {
    return '(구절 없음)';
  }
  final block = chapter.blocks[hl.blockIndex];
  String text;
  final itemIndex = hl.itemIndex;
  if (itemIndex != null) {
    if (itemIndex < 0 || itemIndex >= block.items.length) {
      return '(구절 없음)';
    }
    text = block.items[itemIndex].text;
  } else {
    text = block.text ?? '';
  }
  final start = hl.startOffset.clamp(0, text.length);
  final end = hl.endOffset.clamp(start, text.length);
  final snippet = text.substring(start, end).trim();
  return snippet.isEmpty ? '(빈 구절)' : snippet;
}
