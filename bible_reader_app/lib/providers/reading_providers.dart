import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database/daos.dart';
import 'database_providers.dart';

/// 책별 읽음 상태 목록. 진행률 + 편 리스트 체크 표시용.
final bookReadStatusProvider =
    FutureProvider.family<List<ChapterReadStatus>, String>((ref, bookId) async {
      return ref.watch(chapterReadStatusDaoProvider).listByBook(bookId);
    });

/// 전체 읽음 상태 (통계용).
final allReadStatusProvider = FutureProvider<List<ChapterReadStatus>>((ref) async {
  return ref.watch(chapterReadStatusDaoProvider).listAll();
});

/// 책별 진행률 (읽은 편 수 / 전체는 화면에서 chapters.length로 계산).
final bookReadCountProvider = FutureProvider.family<int, String>((
  ref,
  bookId,
) async {
  final list = await ref.watch(bookReadStatusProvider(bookId).future);
  return list.where((s) => s.isRead).length;
});

/// 특정 편이 즐겨찾기인지.
final chapterFavoriteProvider = FutureProvider.family<bool, String>((
  ref,
  chapterId,
) async {
  return ref.watch(chapterFavoritesDaoProvider).exists(chapterId);
});

/// 즐겨찾기 전체 (모아보기).
final allFavoritesProvider = FutureProvider<List<ChapterFavorite>>((ref) async {
  return ref.watch(chapterFavoritesDaoProvider).listAll();
});

/// 특정 편의 밑줄 목록. 본문 재칠용.
final chapterHighlightsProvider =
    FutureProvider.family<List<Highlight>, String>((ref, chapterId) async {
      return ref.watch(highlightsDaoProvider).listByChapter(chapterId);
    });

/// 밑줄 전체 (모아보기).
final allHighlightsProvider = FutureProvider<List<Highlight>>((ref) async {
  return ref.watch(highlightsDaoProvider).listAll();
});

/// 가장 최근에 읽던 위치 (이어보기 카드).
final lastReadProvider = FutureProvider<ReadingProgress?>((ref) async {
  final all = await ref.watch(readingProgressDaoProvider).listAll();
  return all.isEmpty ? null : all.first;
});

/// 책별 마지막 읽기 위치 (편 + 스크롤). 재오픈 시 복원용.
final bookProgressProvider =
    FutureProvider.family<ReadingProgress?, String>((ref, bookId) async {
      return ref.watch(readingProgressDaoProvider).getByBook(bookId);
    });
