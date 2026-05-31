import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database/app_database.dart';
import '../data/database/daos.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});

final readingProgressDaoProvider = Provider<ReadingProgressDao>((ref) {
  return ReadingProgressDao(ref.watch(appDatabaseProvider));
});

final chapterReadStatusDaoProvider = Provider<ChapterReadStatusDao>((ref) {
  return ChapterReadStatusDao(ref.watch(appDatabaseProvider));
});

final chapterFavoritesDaoProvider = Provider<ChapterFavoritesDao>((ref) {
  return ChapterFavoritesDao(ref.watch(appDatabaseProvider));
});

final highlightsDaoProvider = Provider<HighlightsDao>((ref) {
  return HighlightsDao(ref.watch(appDatabaseProvider));
});

final settingsDaoProvider = Provider<SettingsDao>((ref) {
  return SettingsDao(ref.watch(appDatabaseProvider));
});
