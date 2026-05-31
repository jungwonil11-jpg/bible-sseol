import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:bible_reader_app/data/database/app_database.dart';
import 'package:bible_reader_app/data/database/daos.dart';

void main() {
  late AppDatabase appDatabase;

  setUpAll(() {
    sqfliteFfiInit();
  });

  setUp(() {
    appDatabase = AppDatabase(
      databaseFactory: databaseFactoryFfi,
      databasePath: inMemoryDatabasePath,
    );
  });

  tearDown(() async {
    await appDatabase.close();
  });

  test('performs CRUD on all local tables', () async {
    final progressDao = ReadingProgressDao(appDatabase);
    await progressDao.upsert(
      bookId: 'genesis',
      chapterId: 'genesis:1',
      scrollOffset: 128.5,
      updatedAt: 10,
    );
    final progress = await progressDao.getByBook('genesis');
    expect(progress?.chapterId, 'genesis:1');
    expect(progress?.scrollOffset, 128.5);
    await progressDao.delete('genesis');
    expect(await progressDao.getByBook('genesis'), isNull);

    final readDao = ChapterReadStatusDao(appDatabase);
    await readDao.setRead(
      bookId: 'genesis',
      chapterId: 'genesis:1',
      isRead: true,
      updatedAt: 20,
    );
    expect((await readDao.get('genesis:1'))?.isRead, isTrue);
    expect(await readDao.listByBook('genesis'), hasLength(1));
    await readDao.delete('genesis:1');
    expect(await readDao.get('genesis:1'), isNull);

    final favoritesDao = ChapterFavoritesDao(appDatabase);
    await favoritesDao.add(
      bookId: 'genesis',
      chapterId: 'genesis:1',
      createdAt: 30,
    );
    expect(await favoritesDao.exists('genesis:1'), isTrue);
    expect(await favoritesDao.listAll(), hasLength(1));
    await favoritesDao.remove('genesis:1');
    expect(await favoritesDao.exists('genesis:1'), isFalse);

    final highlightsDao = HighlightsDao(appDatabase);
    final highlightId = await highlightsDao.create(
      chapterId: 'genesis:1',
      blockIndex: 3,
      itemIndex: 1,
      startOffset: 2,
      endOffset: 8,
      createdAt: 40,
    );
    final highlights = await highlightsDao.listByChapter('genesis:1');
    expect(highlights.single.id, highlightId);
    expect(highlights.single.itemIndex, 1);
    await highlightsDao.delete(highlightId);
    expect(await highlightsDao.listByChapter('genesis:1'), isEmpty);

    final settingsDao = SettingsDao(appDatabase);
    await settingsDao.set('canon', 'protestant', updatedAt: 50);
    expect(await settingsDao.get('canon'), 'protestant');
    expect(await settingsDao.listAll(), hasLength(1));
    await settingsDao.delete('canon');
    expect(await settingsDao.get('canon'), isNull);
  });
}
