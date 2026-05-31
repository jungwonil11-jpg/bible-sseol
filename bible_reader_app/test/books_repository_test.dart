import 'package:flutter_test/flutter_test.dart';

import 'package:bible_reader_app/data/models/bible_data.dart';
import 'package:bible_reader_app/data/repositories/books_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads books.json from assets', () async {
    final data = await BooksRepository().loadBooks();

    expect(data.schemaVersion, 1);
    expect(data.books.length, 77);
    expect(data.books.where((book) => book.testament == 'old'), hasLength(39));
    expect(data.books.where((book) => book.testament == 'new'), hasLength(27));
    expect(data.books.where((book) => book.testament == 'deut'), hasLength(11));
    expect(data.books.expand((book) => book.chapters), hasLength(379));

    final esther = data.books.singleWhere((book) => book.id == 'esther');
    final canonExtraBlock = esther.chapters
        .expand((chapter) => chapter.blocks)
        .firstWhere((block) => block.canonExtra);
    expect(canonExtraBlock.canon, ['catholic', 'orthodox']);
    expect(canonExtraBlock.marks.first.type, 'strong');

    final genesis = data.books.singleWhere((book) => book.id == 'genesis');
    final listBlock = genesis.chapters.first.blocks.firstWhere(
      (block) => block.type == ContentBlockType.ul,
    );
    expect(listBlock.items, hasLength(5));
    expect(listBlock.items.first.marks.first.start, 0);
  });
}
