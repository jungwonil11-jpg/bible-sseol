import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database/daos.dart';
import '../data/models/bible_data.dart';
import '../providers/artworks_providers.dart';
import '../providers/books_providers.dart';
import '../providers/database_providers.dart';
import '../providers/reading_providers.dart';
import '../providers/settings_controller.dart';
import '../theme/app_theme.dart';
import 'chapter_artwork.dart';
import 'global_app_bar_actions.dart';
import 'mouse_nav.dart';
import 'ornament.dart';

/// 하이라이트 색 팔레트(인덱스로 DB에 저장). 라이트/세피아/다크 공통 파스텔.
const highlightPalette = <Color>[
  Color(0xFFFFD54F), // 노랑
  Color(0xFFF48FB1), // 분홍
  Color(0xFF81D4FA), // 파랑
  Color(0xFFA5D6A7), // 초록
];

Color _hlBackground(int i) =>
    highlightPalette[i.clamp(0, highlightPalette.length - 1)]
        .withValues(alpha: 0.42);

class ReaderScreen extends ConsumerStatefulWidget {
  const ReaderScreen({
    super.key,
    required this.book,
    required this.initialChapterIndex,
    required this.selectedCanon,
    this.initialScrollOffset = 0,
    this.initialBlockIndex = -1,
    this.searchHighlight,
  });

  final BibleBook book;
  final int initialChapterIndex;
  final String selectedCanon;
  final double initialScrollOffset;

  /// 검색 결과에서 진입한 경우, 스크롤해서 보여줄 블록 인덱스(-1이면 없음).
  final int initialBlockIndex;

  /// 검색 결과 진입 시 본문에서 배경 강조할 검색어(null이면 강조 없음).
  final String? searchHighlight;

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  late int _chapterIndex;
  late final ScrollController _scrollController;
  // 검색 진입 시 스크롤 목표 블록에 부착하는 키.
  final GlobalKey _searchTargetKey = GlobalKey();
  ProviderContainer? _container;
  int _lastSaveMs = 0;
  bool _markedRead = false;

  BibleChapter get _chapter => widget.book.chapters[_chapterIndex];

  @override
  void initState() {
    super.initState();
    MouseNav.register(_handleMouseNav);
    _chapterIndex = widget.initialChapterIndex;
    _scrollController = ScrollController()..addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 검색으로 진입했으면 해당 문단으로 스크롤, 아니면 이어보기 위치 복원.
      if (widget.initialBlockIndex >= 0) {
        final ctx = _searchTargetKey.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(
            ctx,
            alignment: 0.12,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
          );
          return;
        }
      }
      _restoreScroll(widget.initialScrollOffset);
      _maybeMarkShortChapter();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // dispose()에서 ref 직접 사용이 금지돼, 컨테이너를 필드에 저장해 둔다.
    _container = ProviderScope.containerOf(context, listen: false);
  }

  /// 마우스 사이드 버튼(뒤로/앞으로) + 키보드(←/→): 이전 편/다음 편.
  /// 위에 다른 화면(설정·검색 등)이 떠 있으면 건드리지 않고 전역 동작에 넘긴다.
  /// 1편에서 뒤로 버튼은 false를 반환해 전역 pop(책 상세로 나가기)에 위임한다.
  bool _handleMouseNav(bool isBack) {
    if (!mounted || !(ModalRoute.of(context)?.isCurrent ?? false)) {
      return false;
    }
    if (isBack) {
      if (_chapterIndex > 0) {
        _openChapter(_chapterIndex - 1);
        return true;
      }
      return false;
    }
    if (_chapterIndex < widget.book.chapters.length - 1) {
      _openChapter(_chapterIndex + 1);
    }
    return true; // 마지막 편의 앞으로 버튼은 그냥 무시(전역 동작 없음).
  }

  @override
  void dispose() {
    MouseNav.unregister(_handleMouseNav);
    final container = _container;
    if (container != null) {
      if (_scrollController.hasClients) {
        container
            .read(readingProgressDaoProvider)
            .upsert(
              bookId: widget.book.id,
              chapterId: _chapter.id,
              scrollOffset: _scrollController.offset,
            );
      }
      // 서재 이어보기/진행률 갱신.
      container.invalidate(lastReadProvider);
      container.invalidate(bookProgressProvider(widget.book.id));
      container.invalidate(bookReadStatusProvider(widget.book.id));
      // 통계·출석 달력이 보는 전체 읽음 상태도 갱신(안 하면 stale).
      container.invalidate(allReadStatusProvider);
    }
    _scrollController.dispose();
    super.dispose();
  }

  void _restoreScroll(double offset) {
    if (offset <= 0 || !_scrollController.hasClients) {
      return;
    }
    final max = _scrollController.position.maxScrollExtent;
    _scrollController.jumpTo(offset.clamp(0, max));
  }

  void _onScroll() {
    _saveProgress();
    if (!_markedRead && _scrollController.hasClients) {
      final pos = _scrollController.position;
      if (pos.pixels >= pos.maxScrollExtent - 80) {
        _markRead();
      }
    }
  }

  void _saveProgress({bool force = false}) {
    if (!_scrollController.hasClients) {
      return;
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    if (!force && now - _lastSaveMs < 700) {
      return;
    }
    _lastSaveMs = now;
    ref
        .read(readingProgressDaoProvider)
        .upsert(
          bookId: widget.book.id,
          chapterId: _chapter.id,
          scrollOffset: _scrollController.offset,
        );
  }

  Future<void> _markRead() async {
    _markedRead = true;
    await ref
        .read(chapterReadStatusDaoProvider)
        .setRead(
          bookId: widget.book.id,
          chapterId: _chapter.id,
          isRead: true,
        );
    ref.invalidate(bookReadStatusProvider(widget.book.id));
    // 통계·출석·메인 연속 버튼이 보는 전체 읽음 상태 즉시 갱신.
    ref.invalidate(allReadStatusProvider);
  }

  /// 한 화면에 다 들어오는 짧은 편은 스크롤이 안 생겨 _onScroll이 못 잡는다.
  /// 렌더 직후 더 스크롤할 게 없으면(=다 보이면) 읽음으로 처리한다.
  void _maybeMarkShortChapter() {
    if (_markedRead || !_scrollController.hasClients) {
      return;
    }
    if (_scrollController.position.maxScrollExtent <= 0) {
      _markRead();
    }
  }

  void _openChapter(int index) {
    _saveProgress(force: true);
    setState(() {
      _chapterIndex = index;
      _markedRead = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
      _maybeMarkShortChapter();
    });
  }

  Future<void> _toggleFavorite(bool currentlyFavorite) async {
    final dao = ref.read(chapterFavoritesDaoProvider);
    if (currentlyFavorite) {
      await dao.remove(_chapter.id);
    } else {
      await dao.add(bookId: widget.book.id, chapterId: _chapter.id);
    }
    ref.invalidate(chapterFavoriteProvider(_chapter.id));
    ref.invalidate(allFavoritesProvider);
  }

  /// 하이라이트 추가. 같은 블록/항목에서 겹치는 기존 하이라이트가 있으면 합쳐서
  /// 하나로 저장(중복 row 방지). 합쳐진 하이라이트는 새로 고른 색을 따른다.
  Future<void> _addHighlight(
    int blockIndex,
    int? itemIndex,
    int start,
    int end,
    int color,
  ) async {
    final dao = ref.read(highlightsDaoProvider);
    final current =
        ref.read(chapterHighlightsProvider(_chapter.id)).value ??
        const <Highlight>[];
    var s = start;
    var e = end;
    for (final h in current) {
      final sameSpot = h.blockIndex == blockIndex && h.itemIndex == itemIndex;
      if (sameSpot && h.startOffset <= e && h.endOffset >= s) {
        s = s < h.startOffset ? s : h.startOffset;
        e = e > h.endOffset ? e : h.endOffset;
        await dao.delete(h.id);
      }
    }
    await dao.create(
      chapterId: _chapter.id,
      blockIndex: blockIndex,
      itemIndex: itemIndex,
      startOffset: s,
      endOffset: e,
      color: color,
    );
    ref.invalidate(chapterHighlightsProvider(_chapter.id));
    ref.invalidate(allHighlightsProvider);
  }

  /// 하이라이트 제거(선택과 겹친 하이라이트들의 id).
  Future<void> _removeHighlights(List<int> ids) async {
    if (ids.isEmpty) {
      return;
    }
    final dao = ref.read(highlightsDaoProvider);
    for (final id in ids) {
      await dao.delete(id);
    }
    ref.invalidate(chapterHighlightsProvider(_chapter.id));
    ref.invalidate(allHighlightsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final colors = appColors(context);
    final fontScale = ref.watch(
      settingsControllerProvider.select((s) => s.fontScale),
    );
    final lineHeight = ref.watch(
      settingsControllerProvider.select((s) => s.lineHeight),
    );
    final letterSpacing = ref.watch(
      settingsControllerProvider.select((s) => s.letterSpacing),
    );
    final wordSpacing = ref.watch(
      settingsControllerProvider.select((s) => s.wordSpacing),
    );
    final pageMargin = ref.watch(
      settingsControllerProvider.select((s) => s.pageMargin),
    );
    final chapter = _chapter;
    final isFirst = _chapterIndex == 0;
    final isLast = _chapterIndex == widget.book.chapters.length - 1;
    final isFavorite = ref.watch(chapterFavoriteProvider(chapter.id));
    final data = ref
        .watch(bibleDataProvider)
        .maybeWhen(data: (d) => d, orElse: () => null);
    // 이 편에 곁들일 명화(없으면 null → 표시 안 함).
    final artwork = ref
        .watch(artworkDataProvider)
        .maybeWhen(
          data: (d) => d.lookup(widget.book.id, chapter.num),
          orElse: () => null,
        );
    final highlights = ref
        .watch(chapterHighlightsProvider(chapter.id))
        .maybeWhen(data: (list) => list, orElse: () => const <Highlight>[]);
    // 검색 강조는 진입한 편(initialChapterIndex)에서만. 다음/이전 편으로 넘어가면 끈다.
    final searchHighlight =
        _chapterIndex == widget.initialChapterIndex ? widget.searchHighlight : null;

    return Scaffold(
      appBar: AppBar(
        // 헤더 공간이 좁아(책갈피+전역 액션) 책 제목은 표시하지 않는다.
        actions: [
          IconButton(
            tooltip: '편 책갈피',
            onPressed: () => _toggleFavorite(
              isFavorite.maybeWhen(data: (v) => v, orElse: () => false),
            ),
            icon: Icon(
              isFavorite.maybeWhen(data: (v) => v, orElse: () => false)
                  ? Icons.bookmark
                  : Icons.bookmark_border,
            ),
          ),
          if (data != null) ...globalAppBarActions(context, ref, data),
        ],
      ),
      // 큰 화면(데스크탑·태블릿)에서 본문이 가로로 끝없이 늘어나지 않도록
      // 가운데 폭으로 모은다. 폰에선 그대로 꽉 찬다.
      body: centerConstrained(
        maxWidth: kReaderMaxWidth,
        child: ListView(
          controller: _scrollController,
          padding: EdgeInsets.fromLTRB(pageMargin, 10, pageMargin, 36),
          children: [
          Center(
            child: Text(
              'EPISODE ${(_chapterIndex + 1).toString().padLeft(2, '0')}',
              style: handTextStyle(
                color: colors.accentSoft,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            chapter.title,
            textAlign: TextAlign.center,
            style: handTextStyle(
              color: colors.accent,
              fontSize: 34,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            chapter.ref,
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.inkSoft),
          ),
          const SizedBox(height: 18),
          Ornament(color: colors.accentSoft),
          const SizedBox(height: 24),
          if (artwork != null) ...[
            ChapterArtwork(art: artwork, bleed: pageMargin),
            const SizedBox(height: 28),
          ],
          for (var i = 0; i < chapter.blocks.length; i++)
            _ContentBlockView(
              key: i == widget.initialBlockIndex ? _searchTargetKey : null,
              block: chapter.blocks[i],
              blockIndex: i,
              selectedCanon: widget.selectedCanon,
              fontScale: fontScale,
              lineHeight: lineHeight,
              letterSpacing: letterSpacing,
              wordSpacing: wordSpacing,
              highlights: highlights,
              onHighlight: _addHighlight,
              onRemoveHighlight: _removeHighlights,
              searchHighlight: searchHighlight,
            ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: isFirst
                      ? null
                      : () => _openChapter(_chapterIndex - 1),
                  child: const Text('이전편'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('목차'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: isLast
                      ? null
                      : () => _openChapter(_chapterIndex + 1),
                  child: const Text('다음편'),
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

typedef HighlightCallback =
    void Function(int blockIndex, int? itemIndex, int start, int end, int color);
typedef RemoveHighlightCallback = void Function(List<int> ids);

class _ContentBlockView extends StatelessWidget {
  const _ContentBlockView({
    super.key,
    required this.block,
    required this.blockIndex,
    required this.selectedCanon,
    required this.fontScale,
    required this.lineHeight,
    required this.letterSpacing,
    required this.wordSpacing,
    required this.highlights,
    required this.onHighlight,
    required this.onRemoveHighlight,
    this.searchHighlight,
  });

  final ContentBlock block;
  final int blockIndex;
  final String selectedCanon;
  final double fontScale;
  final double lineHeight;
  final double letterSpacing;
  final double wordSpacing;
  final List<Highlight> highlights;
  final HighlightCallback onHighlight;
  final RemoveHighlightCallback onRemoveHighlight;
  final String? searchHighlight;

  @override
  Widget build(BuildContext context) {
    if (block.canonExtra && selectedCanon == 'protestant') {
      return const SizedBox.shrink();
    }
    if (block.canonExtra) {
      return _CanonExtraBlock(
        block: block,
        blockIndex: blockIndex,
        fontScale: fontScale,
        lineHeight: lineHeight,
        letterSpacing: letterSpacing,
        wordSpacing: wordSpacing,
        highlights: highlights,
        onHighlight: onHighlight,
        onRemoveHighlight: onRemoveHighlight,
        searchHighlight: searchHighlight,
      );
    }
    return _renderBlock(
      context,
      block,
      blockIndex,
      appColors(context),
      fontScale,
      lineHeight,
      letterSpacing,
      wordSpacing,
      highlights,
      onHighlight,
      onRemoveHighlight,
      searchHighlight: searchHighlight,
    );
  }
}

class _CanonExtraBlock extends StatelessWidget {
  const _CanonExtraBlock({
    required this.block,
    required this.blockIndex,
    required this.fontScale,
    required this.lineHeight,
    required this.letterSpacing,
    required this.wordSpacing,
    required this.highlights,
    required this.onHighlight,
    required this.onRemoveHighlight,
    this.searchHighlight,
  });

  final ContentBlock block;
  final int blockIndex;
  final double fontScale;
  final double lineHeight;
  final double letterSpacing;
  final double wordSpacing;
  final List<Highlight> highlights;
  final HighlightCallback onHighlight;
  final RemoveHighlightCallback onRemoveHighlight;
  final String? searchHighlight;

  @override
  Widget build(BuildContext context) {
    final colors = appColors(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.quoteBg,
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: colors.accentSoft, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (block.canonExtraLabel != null) ...[
            Text(
              block.canonExtraLabel!,
              style: handTextStyle(
                color: colors.accent,
                fontSize: 19,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
          ],
          _renderBlock(
            context,
            block,
            blockIndex,
            colors,
            fontScale,
            lineHeight,
            letterSpacing,
            wordSpacing,
            highlights,
            onHighlight,
            onRemoveHighlight,
            insideCanonExtra: true,
            searchHighlight: searchHighlight,
          ),
        ],
      ),
    );
  }
}

Widget _renderBlock(
  BuildContext context,
  ContentBlock block,
  int blockIndex,
  AppColors colors,
  double fontScale,
  double lineHeight,
  double letterSpacing,
  double wordSpacing,
  List<Highlight> highlights,
  HighlightCallback onHighlight,
  RemoveHighlightCallback onRemoveHighlight, {
  bool insideCanonExtra = false,
  String? searchHighlight,
}) {
  switch (block.type) {
    case ContentBlockType.p:
      return Padding(
        padding: EdgeInsets.only(bottom: insideCanonExtra ? 0 : 16),
        child: _SelectableBlockText(
          text: block.text ?? '',
          marks: block.marks,
          highlights: _rangesFor(highlights, blockIndex, null),
          baseStyle:
              _bodyStyle(colors, fontScale, lineHeight, letterSpacing, wordSpacing),
          onHighlight: (s, e, color) => onHighlight(blockIndex, null, s, e, color),
          onRemoveHighlight: onRemoveHighlight,
          searchQuery: searchHighlight,
        ),
      );
    case ContentBlockType.quote:
      return Container(
        margin: EdgeInsets.only(bottom: insideCanonExtra ? 0 : 18),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: colors.quoteBg,
          borderRadius: BorderRadius.circular(6),
          border: Border(left: BorderSide(color: colors.accentSoft, width: 4)),
        ),
        child: _SelectableBlockText(
          text: block.text ?? '',
          marks: block.marks,
          highlights: _rangesFor(highlights, blockIndex, null),
          baseStyle:
              _bodyStyle(colors, fontScale, lineHeight, letterSpacing, wordSpacing),
          onHighlight: (s, e, color) => onHighlight(blockIndex, null, s, e, color),
          onRemoveHighlight: onRemoveHighlight,
          searchQuery: searchHighlight,
        ),
      );
    case ContentBlockType.ul:
    case ContentBlockType.ol:
      return Padding(
        padding: EdgeInsets.only(bottom: insideCanonExtra ? 0 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < block.items.length; i++)
              _ListItemText(
                ordered: block.type == ContentBlockType.ol,
                index: i,
                item: block.items[i],
                fontScale: fontScale,
                lineHeight: lineHeight,
                letterSpacing: letterSpacing,
                wordSpacing: wordSpacing,
                highlights: _rangesFor(highlights, blockIndex, i),
                onHighlight: (s, e, color) =>
                    onHighlight(blockIndex, i, s, e, color),
                onRemoveHighlight: onRemoveHighlight,
                searchQuery: searchHighlight,
              ),
          ],
        ),
      );
    case ContentBlockType.hr:
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Divider(color: colors.line, thickness: 1.2),
      );
  }
}

/// 해당 블록(+항목)에 속한 하이라이트 범위만 추출(id·색 포함).
List<_Range> _rangesFor(
  List<Highlight> highlights,
  int blockIndex,
  int? itemIndex,
) {
  return highlights
      .where((h) => h.blockIndex == blockIndex && h.itemIndex == itemIndex)
      .map((h) => _Range(h.startOffset, h.endOffset, id: h.id, color: h.color))
      .toList(growable: false);
}

typedef _HighlightSpanCallback = void Function(int start, int end, int color);

class _ListItemText extends StatelessWidget {
  const _ListItemText({
    required this.ordered,
    required this.index,
    required this.item,
    required this.fontScale,
    required this.lineHeight,
    required this.letterSpacing,
    required this.wordSpacing,
    required this.highlights,
    required this.onHighlight,
    required this.onRemoveHighlight,
    this.searchQuery,
  });

  final bool ordered;
  final int index;
  final ListBlockItem item;
  final double fontScale;
  final double lineHeight;
  final double letterSpacing;
  final double wordSpacing;
  final List<_Range> highlights;
  final _HighlightSpanCallback onHighlight;
  final RemoveHighlightCallback onRemoveHighlight;
  final String? searchQuery;

  @override
  Widget build(BuildContext context) {
    final colors = appColors(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: ordered ? 30 : 22,
            child: Text(
              ordered ? '${index + 1}.' : '•',
              style: _bodyStyle(
                      colors, fontScale, lineHeight, letterSpacing, wordSpacing)
                  .copyWith(color: colors.accent),
            ),
          ),
          Expanded(
            child: _SelectableBlockText(
              text: item.text,
              marks: item.marks,
              highlights: highlights,
              baseStyle:
                  _bodyStyle(colors, fontScale, lineHeight, letterSpacing, wordSpacing),
              onHighlight: onHighlight,
              onRemoveHighlight: onRemoveHighlight,
              searchQuery: searchQuery,
            ),
          ),
        ],
      ),
    );
  }
}

class _Range {
  const _Range(this.start, this.end, {this.id, this.color = 0});
  final int start;
  final int end;
  final int? id; // 저장된 하이라이트면 그 id(검색 강조 범위는 null)
  final int color; // 하이라이트 색 인덱스
}

/// 본문 한 덩어리. 드래그 선택 → 컨텍스트 메뉴(하이라이트 / 하이라이트 지우기) → 저장/삭제.
/// strong 강조 + 하이라이트(색별) + 검색어 배경을 문자 경계 단위로 병합해 렌더.
class _SelectableBlockText extends StatelessWidget {
  const _SelectableBlockText({
    required this.text,
    required this.marks,
    required this.highlights,
    required this.baseStyle,
    required this.onHighlight,
    required this.onRemoveHighlight,
    this.searchQuery,
  });

  final String text;
  final List<TextMark> marks;
  final List<_Range> highlights;
  final TextStyle baseStyle;
  final _HighlightSpanCallback onHighlight;
  final RemoveHighlightCallback onRemoveHighlight;
  final String? searchQuery;

  /// 하이라이트 색 선택 바텀시트. 고른 색 인덱스를 반환(취소 시 null).
  Future<int?> _pickColor(BuildContext context) {
    final colors = appColors(context);
    return showModalBottomSheet<int>(
      context: context,
      backgroundColor: colors.paperEdge,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '형광펜 색',
                  style: handTextStyle(
                    color: colors.ink,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    for (var i = 0; i < highlightPalette.length; i++)
                      GestureDetector(
                        onTap: () => Navigator.of(ctx).pop(i),
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: highlightPalette[i],
                            shape: BoxShape.circle,
                            border: Border.all(color: colors.line, width: 1.5),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = appColors(context);
    final searchColor = colors.accent.withValues(alpha: 0.45);
    return SelectableText.rich(
      TextSpan(
        style: baseStyle,
        children: _buildSpans(searchColor),
      ),
      textAlign: TextAlign.justify,
      contextMenuBuilder: (context, editableTextState) {
        final selection = editableTextState.textEditingValue.selection;
        final items = <ContextMenuButtonItem>[
          ...editableTextState.contextMenuButtonItems,
        ];
        if (selection.isValid && !selection.isCollapsed) {
          final selStart = selection.start;
          final selEnd = selection.end;
          // 선택과 겹치는 기존 하이라이트.
          final overlap = highlights
              .where((h) =>
                  h.id != null && h.start < selEnd && h.end > selStart)
              .map((h) => h.id!)
              .toList();
          if (overlap.isNotEmpty) {
            // 하이라이트 위를 선택 → 지우기(토글).
            items.insert(
              0,
              ContextMenuButtonItem(
                label: '형광펜 지우기',
                onPressed: () {
                  onRemoveHighlight(overlap);
                  ContextMenuController.removeAny();
                },
              ),
            );
          } else {
            items.insert(
              0,
              ContextMenuButtonItem(
                label: '형광펜',
                onPressed: () async {
                  ContextMenuController.removeAny();
                  final color = await _pickColor(context);
                  if (color != null) {
                    onHighlight(selStart, selEnd, color);
                  }
                },
              ),
            );
          }
        }
        return AdaptiveTextSelectionToolbar.buttonItems(
          anchors: editableTextState.contextMenuAnchors,
          buttonItems: items,
        );
      },
    );
  }

  /// 검색어가 본문에 등장하는 모든 [start, end) 범위.
  List<_Range> _searchRanges(int length) {
    final q = searchQuery?.toLowerCase();
    if (q == null || q.isEmpty) {
      return const [];
    }
    final ranges = <_Range>[];
    final lower = text.toLowerCase();
    var from = 0;
    while (true) {
      final idx = lower.indexOf(q, from);
      if (idx < 0) {
        break;
      }
      ranges.add(_Range(idx, (idx + q.length).clamp(0, length)));
      from = idx + q.length;
    }
    return ranges;
  }

  List<TextSpan> _buildSpans(Color searchColor) {
    final length = text.length;
    if (length == 0) {
      return const [TextSpan(text: '')];
    }
    final searchRanges = _searchRanges(length);
    final bounds = <int>{0, length};
    for (final m in marks) {
      bounds.add(m.start.clamp(0, length));
      bounds.add(m.end.clamp(0, length));
    }
    for (final h in highlights) {
      bounds.add(h.start.clamp(0, length));
      bounds.add(h.end.clamp(0, length));
    }
    for (final r in searchRanges) {
      bounds.add(r.start.clamp(0, length));
      bounds.add(r.end.clamp(0, length));
    }
    final sorted = bounds.toList()..sort();
    final spans = <TextSpan>[];
    for (var i = 0; i < sorted.length - 1; i++) {
      final s = sorted[i];
      final e = sorted[i + 1];
      if (s >= e) {
        continue;
      }
      final isStrong = marks.any(
        (m) => m.type == 'strong' && m.start <= s && m.end >= e,
      );
      final hl = highlights.where((h) => h.start <= s && h.end >= e);
      final isHighlight = hl.isNotEmpty;
      final colorIdx = isHighlight ? hl.first.color : 0;
      final isSearch = searchRanges.any((r) => r.start <= s && r.end >= e);
      spans.add(
        TextSpan(
          text: text.substring(s, e),
          style: TextStyle(
            // 강조는 컬러 대신 굵기로만(무채색 문학 톤).
            fontWeight: isStrong ? FontWeight.w700 : null,
            // 하이라이트: 고른 색 배경. 검색 강조보다 우선.
            backgroundColor: isHighlight
                ? _hlBackground(colorIdx)
                : (isSearch ? searchColor : null),
          ),
        ),
      );
    }
    return spans;
  }
}

TextStyle _bodyStyle(
  AppColors colors,
  double fontScale,
  double lineHeight,
  double letterSpacing,
  double wordSpacing,
) {
  return TextStyle(
    color: colors.ink,
    fontSize: 17 * fontScale,
    height: lineHeight,
    letterSpacing: letterSpacing,
    wordSpacing: wordSpacing,
  );
}
