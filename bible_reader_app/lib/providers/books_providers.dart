import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/bible_data.dart';
import '../data/repositories/books_repository.dart';

final booksRepositoryProvider = Provider<BooksRepository>((ref) {
  return BooksRepository();
});

final bibleDataProvider = FutureProvider<BibleData>((ref) async {
  return ref.watch(booksRepositoryProvider).loadBooks();
});
