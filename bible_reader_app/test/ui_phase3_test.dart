import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:bible_reader_app/data/database/app_database.dart';
import 'package:bible_reader_app/data/models/bible_data.dart';
import 'package:bible_reader_app/providers/database_providers.dart';
import 'package:bible_reader_app/providers/settings_controller.dart';
import 'package:bible_reader_app/theme/app_theme.dart';
import 'package:bible_reader_app/ui/library_screen.dart';
import 'package:bible_reader_app/ui/reader_screen.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  dbOverrides() {
    final db = AppDatabase(
      databaseFactory: databaseFactoryFfi,
      databasePath: inMemoryDatabasePath,
    );
    return [appDatabaseProvider.overrideWithValue(db)];
  }

  testWidgets('library filters books by selected canon', (
    tester,
  ) async {
    final data = _fixtureData();

    await tester.pumpWidget(
      ProviderScope(
        overrides: dbOverrides(),
        child: MaterialApp(
          theme: buildAppTheme(theme: readingThemes.first),
          home: LibraryScreen(data: data),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('개신교 66권'), findsOneWidget);
    // 개신교에선 제2경전 책(토비트)이 canon 필터로 빠져 안 보임
    expect(find.text('토비트'), findsNothing);

    // 정경을 천주교로 전환(서재 칩 제거됨 → 설정 컨트롤러 직접 호출).
    final container = ProviderScope.containerOf(
      tester.element(find.byType(LibraryScreen)),
    );
    await container
        .read(settingsControllerProvider.notifier)
        .chooseCanon('catholic');
    await tester.pump();
    await tester.pump();

    expect(find.text('천주교 73권'), findsOneWidget);
    // 제2경전은 별도 섹션이 아니라 구약 흐름에 끼어 나타남 (라벨 없음, 책만 등장)
    expect(find.text('제2경전'), findsNothing);
    expect(find.text('토비트'), findsOneWidget);
  });

  testWidgets('reader hides and shows canonExtra by canon', (tester) async {
    final esther = _fixtureData().books.singleWhere(
      (book) => book.id == 'esther',
    );
    const label = '✦ 천주교·정교회 추가분 — 추가본 A · 모르드개의 꿈';

    await tester.pumpWidget(
      ProviderScope(
        overrides: dbOverrides(),
        child: MaterialApp(
          theme: buildAppTheme(theme: readingThemes.first),
          home: const ReaderScreen(
            book: _esther,
            initialChapterIndex: 0,
            selectedCanon: 'protestant',
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text(label), findsNothing);

    await tester.pumpWidget(
      ProviderScope(
        overrides: dbOverrides(),
        child: MaterialApp(
          theme: buildAppTheme(theme: readingThemes.first),
          home: ReaderScreen(
            book: esther,
            initialChapterIndex: 0,
            selectedCanon: 'catholic',
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text(label), findsOneWidget);
  });
}

const _esther = BibleBook(
  id: 'esther',
  title: '에스더',
  testament: 'old',
  order: 17,
  sortOrder: 17,
  canon: ['protestant', 'catholic', 'orthodox'],
  ref: '전 1편',
  chapters: [
    BibleChapter(
      id: 'esther:1',
      num: 1,
      title: '추가본 테스트',
      ref: '에스더 1장',
      blocks: [
        ContentBlock(type: ContentBlockType.p, text: '본문'),
        ContentBlock(
          type: ContentBlockType.p,
          text: '추가본',
          canon: ['catholic', 'orthodox'],
          canonExtra: true,
          canonExtraLabel: '✦ 천주교·정교회 추가분 — 추가본 A · 모르드개의 꿈',
        ),
      ],
    ),
  ],
);

BibleData _fixtureData() {
  return BibleData(
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
      'catholic': CanonInfo(
        name: '천주교',
        denominations: '로마 가톨릭',
        oldCount: 46,
        newCount: 27,
        total: 73,
        desc: '천주교 정경',
        extra: ['토비트'],
      ),
      'orthodox': CanonInfo(
        name: '정교회',
        denominations: '정교회',
        oldCount: 49,
        newCount: 27,
        total: 76,
        desc: '정교회 정경',
        extra: ['시편 151편'],
      ),
    },
    deutMeta: const [],
    books: [
      _book('genesis', '창세기', 'old', 1, ['protestant', 'catholic', 'orthodox']),
      _book('matthew', '마태복음', 'new', 40, [
        'protestant',
        'catholic',
        'orthodox',
      ]),
      _book('tobit', '토비트', 'deut', 16.1, ['catholic', 'orthodox']),
      _esther,
    ],
  );
}

BibleBook _book(
  String id,
  String title,
  String testament,
  double order,
  List<String> canon,
) {
  return BibleBook(
    id: id,
    title: title,
    testament: testament,
    order: order,
    sortOrder: order,
    canon: canon,
    ref: '전 1편',
    chapters: [
      BibleChapter(
        id: '$id:1',
        num: 1,
        title: '1편',
        ref: '$title 1장',
        blocks: const [ContentBlock(type: ContentBlockType.p, text: '본문')],
      ),
    ],
  );
}
