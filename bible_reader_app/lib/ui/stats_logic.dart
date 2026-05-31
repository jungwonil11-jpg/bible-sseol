import '../data/database/daos.dart';
import '../data/models/bible_data.dart';

/// 읽기 통계 집계 결과(선택 정경 기준).
class ReadingStats {
  const ReadingStats({
    required this.readChapters,
    required this.totalChapters,
    required this.readBooks,
    required this.totalBooks,
    required this.streak,
  });

  final int readChapters;
  final int totalChapters;
  final int readBooks;
  final int totalBooks;
  final int streak;
}

/// 선택 정경 기준 집계. 스트릭은 정경 무관(전체 읽기 활동)으로 계산한다.
ReadingStats computeReadingStats(
  BibleData data,
  String canon,
  List<ChapterReadStatus> status, {
  DateTime? now,
}) {
  final canonBooks =
      data.books.where((b) => b.canon.contains(canon)).toList(growable: false);
  final bookIds = canonBooks.map((b) => b.id).toSet();
  final totalChapters =
      canonBooks.fold<int>(0, (sum, b) => sum + b.chapters.length);

  final readInCanon = status
      .where((s) => s.isRead && bookIds.contains(s.bookId))
      .toList(growable: false);
  final readChapters = readInCanon.length;
  final readBooks = readInCanon.map((s) => s.bookId).toSet().length;

  return ReadingStats(
    readChapters: readChapters,
    totalChapters: totalChapters,
    readBooks: readBooks,
    totalBooks: canonBooks.length,
    streak: readingStreak(
      status.where((s) => s.isRead).toList(growable: false),
      now: now,
    ),
  );
}

/// 읽음 표시한 날짜 기준 연속 일수. 오늘(또는 어제)부터 거꾸로 이어진 날 수.
/// [now]를 주입하면 테스트에서 고정 날짜로 검증할 수 있다.
int readingStreak(List<ChapterReadStatus> read, {DateTime? now}) {
  if (read.isEmpty) {
    return 0;
  }
  final days = <DateTime>{};
  for (final s in read) {
    final d = DateTime.fromMillisecondsSinceEpoch(s.updatedAt);
    days.add(DateTime(d.year, d.month, d.day));
  }
  final ref = now ?? DateTime.now();
  var cursor = DateTime(ref.year, ref.month, ref.day);
  if (!days.contains(cursor)) {
    // 오늘 안 읽었으면 어제부터 인정. 어제도 없으면 끊긴 것.
    cursor = cursor.subtract(const Duration(days: 1));
    if (!days.contains(cursor)) {
      return 0;
    }
  }
  var count = 0;
  while (days.contains(cursor)) {
    count++;
    cursor = cursor.subtract(const Duration(days: 1));
  }
  return count;
}
