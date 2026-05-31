import 'package:flutter_test/flutter_test.dart';

import 'package:bible_reader_app/data/database/daos.dart';
import 'package:bible_reader_app/data/models/bible_data.dart';
import 'package:bible_reader_app/ui/stats_logic.dart';

void main() {
  group('readingStreak', () {
    final now = DateTime(2026, 6, 1);
    DateTime ago(int d) => now.subtract(Duration(days: d));

    test('빈 기록은 0', () {
      expect(readingStreak(const [], now: now), 0);
    });

    test('오늘 읽으면 1일', () {
      expect(readingStreak([_read('a', 'x', now)], now: now), 1);
    });

    test('오늘+어제 연속이면 2일', () {
      expect(
        readingStreak([_read('a', 'x', now), _read('b', 'x', ago(1))], now: now),
        2,
      );
    });

    test('오늘 공백·어제만 있으면 1일(어제부터 인정)', () {
      expect(readingStreak([_read('a', 'x', ago(1))], now: now), 1);
    });

    test('오늘·어제 둘 다 공백이면 0(끊김)', () {
      expect(readingStreak([_read('a', 'x', ago(2))], now: now), 0);
    });

    test('중간이 끊기면 연속 구간만 센다', () {
      final list = [
        _read('a', 'x', now),
        _read('b', 'x', ago(1)),
        // ago(2) 공백
        _read('c', 'x', ago(3)),
      ];
      expect(readingStreak(list, now: now), 2);
    });

    test('같은 날 여러 편을 읽어도 하루로 센다', () {
      final list = [
        _read('a', 'x', now),
        _read('b', 'x', now),
        _read('c', 'x', ago(1)),
      ];
      expect(readingStreak(list, now: now), 2);
    });
  });

  group('computeReadingStats', () {
    final data = _fixture();
    final day = DateTime(2026, 6, 1);

    test('개신교: 천주교 전용 책(토비트) 제외', () {
      final s = computeReadingStats(data, 'protestant', [
        _read('genesis:1', 'genesis', day),
      ]);
      expect(s.totalBooks, 1); // genesis만
      expect(s.totalChapters, 2); // genesis 2편
      expect(s.readChapters, 1);
      expect(s.readBooks, 1);
    });

    test('천주교: 토비트 포함', () {
      final s = computeReadingStats(data, 'catholic', [
        _read('genesis:1', 'genesis', day),
        _read('tobit:1', 'tobit', day),
      ]);
      expect(s.totalBooks, 2);
      expect(s.totalChapters, 3); // genesis 2 + tobit 1
      expect(s.readChapters, 2);
      expect(s.readBooks, 2);
    });

    test('선택 정경 밖의 책을 읽은 기록은 카운트 안 됨', () {
      // 개신교 선택인데 토비트(천주교 전용)를 읽은 기록 → 제외
      final s = computeReadingStats(data, 'protestant', [
        _read('tobit:1', 'tobit', day),
      ]);
      expect(s.readChapters, 0);
      expect(s.readBooks, 0);
    });
  });
}

ChapterReadStatus _read(String chapterId, String bookId, DateTime day) {
  return ChapterReadStatus(
    chapterId: chapterId,
    bookId: bookId,
    isRead: true,
    updatedAt: day.millisecondsSinceEpoch,
  );
}

BibleData _fixture() {
  return BibleData(
    schemaVersion: 1,
    generatedFrom: 'test',
    canonInfo: const {},
    deutMeta: const [],
    books: [
      _book('genesis', '창세기', 'old', ['protestant', 'catholic', 'orthodox'], 2),
      _book('tobit', '토비트', 'deut', ['catholic', 'orthodox'], 1),
    ],
  );
}

BibleBook _book(
  String id,
  String title,
  String testament,
  List<String> canon,
  int chapterCount,
) {
  return BibleBook(
    id: id,
    title: title,
    testament: testament,
    order: 1,
    sortOrder: 1,
    canon: canon,
    ref: '',
    chapters: [
      for (var i = 1; i <= chapterCount; i++)
        BibleChapter(id: '$id:$i', num: i, title: '', ref: '', blocks: const []),
    ],
  );
}
