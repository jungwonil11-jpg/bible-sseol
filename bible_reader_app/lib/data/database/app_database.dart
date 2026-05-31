import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase({DatabaseFactory? databaseFactory, String? databasePath})
    : this._(databaseFactory, databasePath);

  AppDatabase._(this._databaseFactory, this._databasePath);

  static const databaseName = 'bible_reader.db';
  static const databaseVersion = 3;

  final DatabaseFactory? _databaseFactory;
  final String? _databasePath;
  Database? _database;

  Future<Database> get database async {
    final existing = _database;
    if (existing != null) {
      return existing;
    }
    final opened = await _open();
    _database = opened;
    return opened;
  }

  Future<void> close() async {
    final existing = _database;
    if (existing == null) {
      return;
    }
    await existing.close();
    _database = null;
  }

  Future<Database> _open() async {
    final factory = _databaseFactory ?? databaseFactory;
    final dbPath = _databasePath ?? await _defaultDatabasePath();
    return factory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: databaseVersion,
        onCreate: _create,
        onUpgrade: _upgrade,
      ),
    );
  }

  Future<String> _defaultDatabasePath() async {
    // 웹은 실제 파일 경로가 없다. FFI 웹 팩토리가 이 이름을 IndexedDB 키로 쓰므로
    // 문서 디렉토리를 조회하지 않고 DB 이름만 그대로 넘긴다.
    if (kIsWeb) {
      return databaseName;
    }
    final dir = await getApplicationDocumentsDirectory();
    return p.join(dir.path, databaseName);
  }

  Future<void> _create(Database db, int version) async {
    for (final statement in schemaStatements) {
      await db.execute(statement);
    }
  }

  Future<void> _upgrade(Database db, int oldVersion, int newVersion) async {
    // v2: 하이라이트에 색상(팔레트 인덱스) 추가. 기존 하이라이트는 0(첫 색)으로.
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE highlights ADD COLUMN color INTEGER NOT NULL DEFAULT 0',
      );
    }
    // v3: 하이라이트에 메모(선택) 추가.
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE highlights ADD COLUMN note TEXT');
    }
  }
}

const schemaStatements = <String>[
  '''
CREATE TABLE reading_progress (
  book_id TEXT NOT NULL,
  chapter_id TEXT NOT NULL,
  scroll_offset REAL NOT NULL DEFAULT 0,
  updated_at INTEGER NOT NULL,
  PRIMARY KEY (book_id)
)
''',
  '''
CREATE TABLE chapter_read_status (
  chapter_id TEXT PRIMARY KEY,
  book_id TEXT NOT NULL,
  is_read INTEGER NOT NULL DEFAULT 0,
  updated_at INTEGER NOT NULL
)
''',
  '''
CREATE INDEX idx_chapter_read_status_book_id
ON chapter_read_status(book_id)
''',
  '''
CREATE TABLE chapter_favorites (
  chapter_id TEXT PRIMARY KEY,
  book_id TEXT NOT NULL,
  created_at INTEGER NOT NULL
)
''',
  '''
CREATE INDEX idx_chapter_favorites_book_id
ON chapter_favorites(book_id)
''',
  '''
CREATE TABLE highlights (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  chapter_id TEXT NOT NULL,
  block_index INTEGER NOT NULL,
  item_index INTEGER,
  start_offset INTEGER NOT NULL,
  end_offset INTEGER NOT NULL,
  color INTEGER NOT NULL DEFAULT 0,
  note TEXT,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
)
''',
  '''
CREATE INDEX idx_highlights_chapter_id
ON highlights(chapter_id)
''',
  '''
CREATE TABLE settings (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL,
  updated_at INTEGER NOT NULL
)
''',
];
