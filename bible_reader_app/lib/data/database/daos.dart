import 'package:sqflite/sqflite.dart';

import 'app_database.dart';

int nowMillis() => DateTime.now().millisecondsSinceEpoch;

class ReadingProgress {
  const ReadingProgress({
    required this.bookId,
    required this.chapterId,
    required this.scrollOffset,
    required this.updatedAt,
  });

  factory ReadingProgress.fromMap(Map<String, Object?> map) {
    return ReadingProgress(
      bookId: map['book_id'] as String,
      chapterId: map['chapter_id'] as String,
      scrollOffset: (map['scroll_offset'] as num).toDouble(),
      updatedAt: map['updated_at'] as int,
    );
  }

  final String bookId;
  final String chapterId;
  final double scrollOffset;
  final int updatedAt;
}

class ReadingProgressDao {
  const ReadingProgressDao(this._db);

  final AppDatabase _db;

  Future<void> upsert({
    required String bookId,
    required String chapterId,
    required double scrollOffset,
    int? updatedAt,
  }) async {
    final db = await _db.database;
    await db.insert('reading_progress', {
      'book_id': bookId,
      'chapter_id': chapterId,
      'scroll_offset': scrollOffset,
      'updated_at': updatedAt ?? nowMillis(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<ReadingProgress?> getByBook(String bookId) async {
    final db = await _db.database;
    final rows = await db.query(
      'reading_progress',
      where: 'book_id = ?',
      whereArgs: [bookId],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return ReadingProgress.fromMap(rows.single);
  }

  Future<List<ReadingProgress>> listAll() async {
    final db = await _db.database;
    final rows = await db.query('reading_progress', orderBy: 'updated_at DESC');
    return rows.map(ReadingProgress.fromMap).toList(growable: false);
  }

  Future<void> delete(String bookId) async {
    final db = await _db.database;
    await db.delete(
      'reading_progress',
      where: 'book_id = ?',
      whereArgs: [bookId],
    );
  }

  /// 이어보기 기록 전부 삭제(앱 초기화용).
  Future<void> clear() async {
    final db = await _db.database;
    await db.delete('reading_progress');
  }
}

class ChapterReadStatus {
  const ChapterReadStatus({
    required this.chapterId,
    required this.bookId,
    required this.isRead,
    required this.updatedAt,
  });

  factory ChapterReadStatus.fromMap(Map<String, Object?> map) {
    return ChapterReadStatus(
      chapterId: map['chapter_id'] as String,
      bookId: map['book_id'] as String,
      isRead: (map['is_read'] as int) == 1,
      updatedAt: map['updated_at'] as int,
    );
  }

  final String chapterId;
  final String bookId;
  final bool isRead;
  final int updatedAt;
}

class ChapterReadStatusDao {
  const ChapterReadStatusDao(this._db);

  final AppDatabase _db;

  Future<void> setRead({
    required String bookId,
    required String chapterId,
    required bool isRead,
    int? updatedAt,
  }) async {
    final db = await _db.database;
    await db.insert('chapter_read_status', {
      'chapter_id': chapterId,
      'book_id': bookId,
      'is_read': isRead ? 1 : 0,
      'updated_at': updatedAt ?? nowMillis(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<ChapterReadStatus?> get(String chapterId) async {
    final db = await _db.database;
    final rows = await db.query(
      'chapter_read_status',
      where: 'chapter_id = ?',
      whereArgs: [chapterId],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return ChapterReadStatus.fromMap(rows.single);
  }

  Future<List<ChapterReadStatus>> listByBook(String bookId) async {
    final db = await _db.database;
    final rows = await db.query(
      'chapter_read_status',
      where: 'book_id = ?',
      whereArgs: [bookId],
      orderBy: 'chapter_id ASC',
    );
    return rows.map(ChapterReadStatus.fromMap).toList(growable: false);
  }

  /// 전체 읽음 상태(통계용). 최근 읽은 순.
  Future<List<ChapterReadStatus>> listAll() async {
    final db = await _db.database;
    final rows = await db.query(
      'chapter_read_status',
      orderBy: 'updated_at DESC',
    );
    return rows.map(ChapterReadStatus.fromMap).toList(growable: false);
  }

  Future<void> delete(String chapterId) async {
    final db = await _db.database;
    await db.delete(
      'chapter_read_status',
      where: 'chapter_id = ?',
      whereArgs: [chapterId],
    );
  }

  /// 읽음 표시 전부 삭제(앱 초기화용). 통계·스트릭도 여기서 계산되므로 같이 0이 된다.
  Future<void> clear() async {
    final db = await _db.database;
    await db.delete('chapter_read_status');
  }
}

class ChapterFavorite {
  const ChapterFavorite({
    required this.chapterId,
    required this.bookId,
    required this.createdAt,
  });

  factory ChapterFavorite.fromMap(Map<String, Object?> map) {
    return ChapterFavorite(
      chapterId: map['chapter_id'] as String,
      bookId: map['book_id'] as String,
      createdAt: map['created_at'] as int,
    );
  }

  final String chapterId;
  final String bookId;
  final int createdAt;
}

class ChapterFavoritesDao {
  const ChapterFavoritesDao(this._db);

  final AppDatabase _db;

  Future<void> add({
    required String bookId,
    required String chapterId,
    int? createdAt,
  }) async {
    final db = await _db.database;
    // 새 즐겨찾기는 맨 위로(현재 sort_order 최솟값 -1).
    final min = await db.rawQuery(
      'SELECT COALESCE(MIN(sort_order), 0) AS m FROM chapter_favorites',
    );
    final sortOrder = (min.first['m'] as int) - 1;
    await db.insert('chapter_favorites', {
      'chapter_id': chapterId,
      'book_id': bookId,
      'created_at': createdAt ?? nowMillis(),
      'sort_order': sortOrder,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<bool> exists(String chapterId) async {
    final db = await _db.database;
    final rows = await db.query(
      'chapter_favorites',
      columns: ['chapter_id'],
      where: 'chapter_id = ?',
      whereArgs: [chapterId],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<List<ChapterFavorite>> listAll() async {
    final db = await _db.database;
    final rows = await db.query(
      'chapter_favorites',
      orderBy: 'sort_order ASC',
    );
    return rows.map(ChapterFavorite.fromMap).toList(growable: false);
  }

  /// 수동 정렬 순서 반영. orderedChapterIds 순서대로 sort_order를 0..n-1로 다시 매긴다.
  Future<void> reorder(List<String> orderedChapterIds) async {
    final db = await _db.database;
    final batch = db.batch();
    for (var i = 0; i < orderedChapterIds.length; i++) {
      batch.update(
        'chapter_favorites',
        {'sort_order': i},
        where: 'chapter_id = ?',
        whereArgs: [orderedChapterIds[i]],
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> remove(String chapterId) async {
    final db = await _db.database;
    await db.delete(
      'chapter_favorites',
      where: 'chapter_id = ?',
      whereArgs: [chapterId],
    );
  }

  /// 책갈피 전부 삭제(앱 초기화용).
  Future<void> clear() async {
    final db = await _db.database;
    await db.delete('chapter_favorites');
  }
}

class Highlight {
  const Highlight({
    required this.id,
    required this.chapterId,
    required this.blockIndex,
    required this.startOffset,
    required this.endOffset,
    required this.createdAt,
    required this.updatedAt,
    this.itemIndex,
    this.color = 0,
  });

  factory Highlight.fromMap(Map<String, Object?> map) {
    return Highlight(
      id: map['id'] as int,
      chapterId: map['chapter_id'] as String,
      blockIndex: map['block_index'] as int,
      itemIndex: map['item_index'] as int?,
      startOffset: map['start_offset'] as int,
      endOffset: map['end_offset'] as int,
      color: (map['color'] as int?) ?? 0,
      createdAt: map['created_at'] as int,
      updatedAt: map['updated_at'] as int,
    );
  }

  final int id;
  final String chapterId;
  final int blockIndex;
  final int? itemIndex;
  final int startOffset;
  final int endOffset;
  final int color; // 하이라이트 색 팔레트 인덱스(0~3)
  final int createdAt;
  final int updatedAt;
}

class HighlightsDao {
  const HighlightsDao(this._db);

  final AppDatabase _db;

  Future<int> create({
    required String chapterId,
    required int blockIndex,
    required int startOffset,
    required int endOffset,
    int? itemIndex,
    int color = 0,
    int? createdAt,
  }) async {
    final db = await _db.database;
    final timestamp = createdAt ?? nowMillis();
    // 새 하이라이트는 모아보기 맨 위로(현재 sort_order 최솟값 -1).
    final min = await db.rawQuery(
      'SELECT COALESCE(MIN(sort_order), 0) AS m FROM highlights',
    );
    final sortOrder = (min.first['m'] as int) - 1;
    return db.insert('highlights', {
      'chapter_id': chapterId,
      'block_index': blockIndex,
      'item_index': itemIndex,
      'start_offset': startOffset,
      'end_offset': endOffset,
      'color': color,
      'sort_order': sortOrder,
      'created_at': timestamp,
      'updated_at': timestamp,
    });
  }

  Future<List<Highlight>> listByChapter(String chapterId) async {
    final db = await _db.database;
    final rows = await db.query(
      'highlights',
      where: 'chapter_id = ?',
      whereArgs: [chapterId],
      orderBy: 'block_index ASC, item_index ASC, start_offset ASC',
    );
    return rows.map(Highlight.fromMap).toList(growable: false);
  }

  Future<List<Highlight>> listAll() async {
    final db = await _db.database;
    final rows = await db.query('highlights', orderBy: 'sort_order ASC');
    return rows.map(Highlight.fromMap).toList(growable: false);
  }

  /// 수동 정렬 순서 반영. orderedIds 순서대로 sort_order를 0..n-1로 다시 매긴다.
  Future<void> reorder(List<int> orderedIds) async {
    final db = await _db.database;
    final batch = db.batch();
    for (var i = 0; i < orderedIds.length; i++) {
      batch.update(
        'highlights',
        {'sort_order': i},
        where: 'id = ?',
        whereArgs: [orderedIds[i]],
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> delete(int id) async {
    final db = await _db.database;
    await db.delete('highlights', where: 'id = ?', whereArgs: [id]);
  }

  /// 형광펜 전부 삭제(앱 초기화용).
  Future<void> clear() async {
    final db = await _db.database;
    await db.delete('highlights');
  }
}

class SettingEntry {
  const SettingEntry({
    required this.key,
    required this.value,
    required this.updatedAt,
  });

  factory SettingEntry.fromMap(Map<String, Object?> map) {
    return SettingEntry(
      key: map['key'] as String,
      value: map['value'] as String,
      updatedAt: map['updated_at'] as int,
    );
  }

  final String key;
  final String value;
  final int updatedAt;
}

class SettingsDao {
  const SettingsDao(this._db);

  final AppDatabase _db;

  Future<void> set(String key, String value, {int? updatedAt}) async {
    final db = await _db.database;
    await db.insert('settings', {
      'key': key,
      'value': value,
      'updated_at': updatedAt ?? nowMillis(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String?> get(String key) async {
    final db = await _db.database;
    final rows = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return rows.single['value'] as String;
  }

  Future<List<SettingEntry>> listAll() async {
    final db = await _db.database;
    final rows = await db.query('settings', orderBy: 'key ASC');
    return rows.map(SettingEntry.fromMap).toList(growable: false);
  }

  Future<void> delete(String key) async {
    final db = await _db.database;
    await db.delete('settings', where: 'key = ?', whereArgs: [key]);
  }
}
