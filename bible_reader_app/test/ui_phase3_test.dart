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
        overrides: [
          ...dbOverrides(),
          // 설정의 _load(실 DB 비동기)가 뒤늦게 끝나며 chooseCanon 을 기본값으로
          // 덮어쓰지 않도록, 로드를 건너뛰고 정경을 고정한 컨트롤러로 대체한다.
          settingsControllerProvider.overrideWith(
            () => _FixedSettingsController('protestant'),
          ),
        ],
        child: MaterialApp(
          theme: buildAppTheme(theme: readingThemes.first),
          home: LibraryScreen(data: data),
        ),
      ),
    );
    await tester.pump();

    // 정경 권수 헤더는 서재에서 제거됨(온보딩/설정으로 일원화). 여기선 canon
    // 필터링 동작만 검증한다 — 개신교에선 추가 권(토비트)이 빠져 안 보인다.
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

    // 추가 권은 별도 섹션이 아니라 구약 흐름에 끼어 나타남 (라벨 없음, 책만 등장)
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

/// 설정 DB 로드(_load)를 건너뛰고 정경만 고정하는 테스트용 컨트롤러.
/// chooseCanon 등 변경 동작은 상위(SettingsController) 구현을 그대로 쓴다.
class _FixedSettingsController extends SettingsController {
  _FixedSettingsController(this._initialCanon);

  final String _initialCanon;

  @override
  AppSettings build() => AppSettings(canon: _initialCanon, loaded: true);

  @override
  Future<void> chooseCanon(String canon) async {
    // 위젯 테스트에서 실 sqlite write 가 행(hang)나는 것을 피하려고, DB 쓰기
    // 없이 상태만 바꾼다. (정경 전환의 UI 반영만 검증하면 충분.)
    state = state.copyWith(canon: canon, canonChosen: true);
  }
}
