import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bible_reader_app/data/database/daos.dart';
import 'package:bible_reader_app/data/models/bible_data.dart';
import 'package:bible_reader_app/providers/reading_providers.dart';
import 'package:bible_reader_app/theme/app_theme.dart';
import 'package:bible_reader_app/ui/book_detail_screen.dart';
import 'package:bible_reader_app/ui/collections_screen.dart';
import 'package:bible_reader_app/ui/disclaimer_dialog.dart';

// 위젯 테스트는 실DB 대신 프로바이더를 고정값으로 override한다.
// (실 sqlite I/O는 pumpAndSettle와 안 맞아 행. DAO CRUD는 database_test.dart에서 검증.)
void main() {
  testWidgets('읽음 상태가 책 상세 진행률/체크로 반영됨', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bookReadStatusProvider('genesis').overrideWith(
            (ref) async => [
              ChapterReadStatus(
                chapterId: 'genesis:1',
                bookId: 'genesis',
                isRead: true,
                updatedAt: 0,
              ),
            ],
          ),
        ],
        child: MaterialApp(
          theme: buildAppTheme(theme: readingThemes.first),
          home: BookDetailScreen(book: _genesis, selectedCanon: 'protestant'),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('2편 중 1편 읽음'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });

  testWidgets('즐겨찾기 + 하이라이트가 모아보기에 나타남', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          allFavoritesProvider.overrideWith(
            (ref) async => [
              ChapterFavorite(
                chapterId: 'genesis:1',
                bookId: 'genesis',
                createdAt: 0,
              ),
            ],
          ),
          allHighlightsProvider.overrideWith(
            (ref) async => [
              Highlight(
                id: 1,
                chapterId: 'genesis:2',
                blockIndex: 0,
                startOffset: 0,
                endOffset: 4,
                createdAt: 0,
                updatedAt: 0,
              ),
            ],
          ),
        ],
        child: MaterialApp(
          theme: buildAppTheme(theme: readingThemes.first),
          home: CollectionsScreen(data: _data),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    // 즐겨찾기 탭
    expect(find.text('창세기 · 1편'), findsOneWidget);

    // 하이라이트 탭으로 전환
    await tester.tap(find.text('하이라이트'));
    await tester.pump();
    await tester.pump();
    // genesis:2 블록0 0~4 → '천지창조'
    expect(find.textContaining('천지창조'), findsOneWidget);
  });

  testWidgets('디스클레이머 모달 표시 + 동의 콜백', (tester) async {
    var agreed = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(theme: readingThemes.first),
        home: Scaffold(
          body: DisclaimerDialog(onAgree: (_) => agreed = true),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('📖 읽기 전에'), findsOneWidget);
    expect(find.textContaining('AI 기반으로 각색'), findsOneWidget);
    expect(find.textContaining('교단의 신학 해석이 아닙니다'), findsOneWidget);

    await tester.tap(find.text('동의하고 시작하기'));
    await tester.pump();
    expect(agreed, isTrue);
  });
}

const _genesis = BibleBook(
  id: 'genesis',
  title: '창세기',
  testament: 'old',
  order: 1,
  sortOrder: 1,
  canon: ['protestant', 'catholic', 'orthodox'],
  ref: '전 2편',
  chapters: [
    BibleChapter(
      id: 'genesis:1',
      num: 1,
      title: '천지창조',
      ref: '창세기 1장',
      blocks: [ContentBlock(type: ContentBlockType.p, text: '태초에')],
    ),
    BibleChapter(
      id: 'genesis:2',
      num: 2,
      title: '에덴',
      ref: '창세기 2장',
      blocks: [ContentBlock(type: ContentBlockType.p, text: '천지창조 끝나고')],
    ),
  ],
);

final _data = BibleData(
  schemaVersion: 1,
  generatedFrom: 'test',
  canonInfo: const {
    'protestant': CanonInfo(
      name: '개신교',
      denominations: '장로교',
      oldCount: 39,
      newCount: 27,
      total: 66,
      desc: '개신교 정경',
      extra: [],
    ),
  },
  deutMeta: const [],
  books: const [_genesis],
);
