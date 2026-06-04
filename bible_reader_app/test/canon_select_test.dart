import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:bible_reader_app/data/database/app_database.dart';
import 'package:bible_reader_app/data/models/bible_data.dart';
import 'package:bible_reader_app/providers/database_providers.dart';
import 'package:bible_reader_app/theme/app_theme.dart';
import 'package:bible_reader_app/ui/canon_select_screen.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  dbOverrides() {
    final db = AppDatabase(
      databaseFactory: databaseFactoryFfi,
      databasePath: inMemoryDatabasePath,
    );
    return [appDatabaseProvider.overrideWithValue(db)];
  }

  testWidgets('온보딩: 정경 3종 카드가 모두 보임', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: dbOverrides(),
        child: MaterialApp(
          theme: buildToneTheme(tone: 0),
          home: CanonSelectScreen(data: _fixture(), mode: CanonSelectMode.onboarding),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('개신교'), findsOneWidget);
    expect(find.text('천주교'), findsOneWidget);
    expect(find.text('정교회'), findsOneWidget);
  });

  testWidgets('정경 카드 탭 → 설명 다이얼로그 + "이 정경으로 읽기"', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: dbOverrides(),
        child: MaterialApp(
          theme: buildToneTheme(tone: 0),
          home: CanonSelectScreen(data: _fixture(), mode: CanonSelectMode.onboarding),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('개신교'));
    await tester.pumpAndSettle();

    expect(find.text('개신교 설명입니다.'), findsOneWidget);
    expect(find.text('이 정경으로 읽기'), findsOneWidget);
  });

  testWidgets('현관 모드: ✕ 닫기 버튼 + 현재 정경에 "지금 읽는 중" 표시', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: dbOverrides(),
        child: MaterialApp(
          theme: buildToneTheme(tone: 0),
          home: CanonSelectScreen(data: _fixture(), mode: CanonSelectMode.home),
        ),
      ),
    );
    await tester.pump();

    expect(find.byIcon(Icons.close), findsOneWidget);
    // 기본 정경(개신교)이 현재 읽는 중으로 표시된다.
    expect(find.text('66권 · 지금 읽는 중'), findsOneWidget);
    expect(find.text('73권'), findsOneWidget);
  });
}

BibleData _fixture() {
  CanonInfo info(String name, int total, String desc) => CanonInfo(
    name: name,
    denominations: '',
    oldCount: 0,
    newCount: 0,
    total: total,
    desc: desc,
    extra: const [],
  );
  return BibleData(
    schemaVersion: 1,
    generatedFrom: 'test',
    canonInfo: {
      'protestant': info('개신교', 66, '개신교 설명입니다.'),
      'catholic': info('천주교', 73, '천주교 설명입니다.'),
      'orthodox': info('정교회', 76, '정교회 설명입니다.'),
    },
    deutMeta: const [],
    books: const [],
  );
}
