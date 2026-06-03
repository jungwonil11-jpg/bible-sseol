import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database/daos.dart';
import '../data/models/bible_data.dart';
import '../providers/database_providers.dart';
import '../providers/reading_providers.dart';
import '../providers/settings_controller.dart';
import '../theme/app_theme.dart';
import 'error_view.dart';
import 'reader_screen.dart';

/// 책갈피 + 형광펜 모아보기. 구절 북마크 역할.
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
              Tab(text: '책갈피'),
              Tab(text: '형광펜'),
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
    final favorites = ref.watch(allFavoritesProvider);
    return favorites.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => ErrorView(
        error: e,
        stackTrace: st,
        compact: true,
        onRetry: () => ref.invalidate(allFavoritesProvider),
      ),
      data: (list) {
        if (list.isEmpty) {
          return const _EmptyHint(text: '아직 책갈피한 편이 없음');
        }
        return _FavoritesList(data: data, items: list);
      },
    );
  }
}

/// 책갈피 목록 — 드래그로 순서변경. 순서를 부드럽게 다루려고 로컬 사본을 들고,
/// 외부(삭제 등)로 목록이 바뀌면 다시 동기화한다.
class _FavoritesList extends ConsumerStatefulWidget {
  const _FavoritesList({required this.data, required this.items});

  final BibleData data;
  final List<ChapterFavorite> items;

  @override
  ConsumerState<_FavoritesList> createState() => _FavoritesListState();
}

class _FavoritesListState extends ConsumerState<_FavoritesList> {
  late List<ChapterFavorite> _items;

  @override
  void initState() {
    super.initState();
    _items = List.of(widget.items);
  }

  @override
  void didUpdateWidget(_FavoritesList old) {
    super.didUpdateWidget(old);
    final oldIds = old.items.map((f) => f.chapterId).toList();
    final newIds = widget.items.map((f) => f.chapterId).toList();
    if (!_listEquals(oldIds, newIds)) {
      _items = List.of(widget.items);
    }
  }

  // onReorderItem은 항목 제거 후 기준으로 newIndex를 이미 보정해 준다(별도 -1 불필요).
  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      _items.insert(newIndex, _items.removeAt(oldIndex));
    });
    ref
        .read(chapterFavoritesDaoProvider)
        .reorder(_items.map((f) => f.chapterId).toList());
  }

  Future<void> _remove(String chapterId) async {
    await ref.read(chapterFavoritesDaoProvider).remove(chapterId);
    ref.invalidate(allFavoritesProvider);
    ref.invalidate(chapterFavoriteProvider(chapterId));
  }

  @override
  Widget build(BuildContext context) {
    final colors = appColors(context);
    return ReorderableListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      itemCount: _items.length,
      onReorderItem: _onReorder,
      buildDefaultDragHandles: false,
      itemBuilder: (context, i) {
        final fav = _items[i];
        final found = _locate(widget.data, fav.chapterId);
        if (found == null) {
          return SizedBox.shrink(key: ValueKey('fav-${fav.chapterId}'));
        }
        final (book, index) = found;
        final chapter = book.chapters[index];
        return _CollectionTile(
          key: ValueKey('fav-${fav.chapterId}'),
          index: i,
          colors: colors,
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
          onRemove: () => _remove(fav.chapterId),
          onTap: () => _openReader(context, ref, book, index),
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
    final highlights = ref.watch(allHighlightsProvider);
    return highlights.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => ErrorView(
        error: e,
        stackTrace: st,
        compact: true,
        onRetry: () => ref.invalidate(allHighlightsProvider),
      ),
      data: (list) {
        if (list.isEmpty) {
          return const _EmptyHint(text: '아직 형광펜 친 구절이 없음');
        }
        return _HighlightsList(data: data, items: list);
      },
    );
  }
}

/// 형광펜 목록 — 드래그로 순서변경. (로컬 사본 동기화 방식은 책갈피와 동일)
class _HighlightsList extends ConsumerStatefulWidget {
  const _HighlightsList({required this.data, required this.items});

  final BibleData data;
  final List<Highlight> items;

  @override
  ConsumerState<_HighlightsList> createState() => _HighlightsListState();
}

class _HighlightsListState extends ConsumerState<_HighlightsList> {
  late List<Highlight> _items;

  @override
  void initState() {
    super.initState();
    _items = List.of(widget.items);
  }

  @override
  void didUpdateWidget(_HighlightsList old) {
    super.didUpdateWidget(old);
    final oldIds = old.items.map((h) => h.id).toList();
    final newIds = widget.items.map((h) => h.id).toList();
    if (!_listEquals(oldIds, newIds)) {
      _items = List.of(widget.items);
    }
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      _items.insert(newIndex, _items.removeAt(oldIndex));
    });
    ref.read(highlightsDaoProvider).reorder(_items.map((h) => h.id).toList());
  }

  Future<void> _remove(Highlight hl) async {
    await ref.read(highlightsDaoProvider).delete(hl.id);
    ref.invalidate(allHighlightsProvider);
    ref.invalidate(chapterHighlightsProvider(hl.chapterId));
  }

  @override
  Widget build(BuildContext context) {
    final colors = appColors(context);
    return ReorderableListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      itemCount: _items.length,
      onReorderItem: _onReorder,
      buildDefaultDragHandles: false,
      itemBuilder: (context, i) {
        final hl = _items[i];
        final found = _locate(widget.data, hl.chapterId);
        if (found == null) {
          return SizedBox.shrink(key: ValueKey('hl-${hl.id}'));
        }
        final (book, index) = found;
        final snippet = _highlightSnippet(book.chapters[index], hl);
        return _CollectionTile(
          key: ValueKey('hl-${hl.id}'),
          index: i,
          colors: colors,
          leading: Icon(
            Icons.highlight,
            color:
                highlightPalette[hl.color.clamp(0, highlightPalette.length - 1)],
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
          onRemove: () => _remove(hl),
          onTap: () => _openReader(context, ref, book, index),
        );
      },
    );
  }
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}

/// 모아보기 한 줄. 탭=열기 / X=삭제 / 우측 핸들 드래그=순서변경.
class _CollectionTile extends StatelessWidget {
  const _CollectionTile({
    required super.key,
    required this.index,
    required this.colors,
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.onRemove,
    required this.onTap,
  });

  final int index;
  final AppColors colors;
  final Widget leading;
  final Widget title;
  final Widget subtitle;
  final VoidCallback onRemove;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.line)),
      ),
      child: ListTile(
        leading: leading,
        title: title,
        subtitle: subtitle,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.close, color: colors.inkSoft, size: 20),
              onPressed: onRemove,
            ),
            ReorderableDragStartListener(
              index: index,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                child: Icon(Icons.drag_handle, color: colors.inkSoft),
              ),
            ),
          ],
        ),
        onTap: onTap,
      ),
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
