import 'package:flutter_test/flutter_test.dart';

import 'package:bible_reader_app/data/models/bible_data.dart';
import 'package:bible_reader_app/data/repositories/books_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // 공개 repo 번들은 '창세기 샘플'(전체 76권은 비공개, 샘플 전용 키로 암호화).
  // 암호화본(books.json.enc)이 샘플 키로 복호화되어 정상 구조로 로드되는지 검증한다.
  test('loads the bundled sample encrypted books asset', () async {
    final data = await BooksRepository().loadBooks();

    expect(data.schemaVersion, 1);
    expect(data.books, isNotEmpty);

    final genesis = data.books.singleWhere((book) => book.id == 'genesis');
    expect(genesis.testament, 'old');
    expect(genesis.chapters, isNotEmpty);

    // 복호화 결과가 구조화된 본문(목록 블록·마크)까지 온전한지 확인.
    final listBlock = genesis.chapters.first.blocks.firstWhere(
      (block) => block.type == ContentBlockType.ul,
    );
    expect(listBlock.items, hasLength(5));
    expect(listBlock.items.first.marks.first.start, 0);
  });
}
