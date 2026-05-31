import 'package:flutter/services.dart';

import '../models/bible_data.dart';

class BooksRepository {
  BooksRepository({AssetBundle? assetBundle})
    : _assetBundle = assetBundle ?? rootBundle;

  final AssetBundle _assetBundle;

  Future<BibleData> loadBooks() async {
    final source = await _assetBundle.loadString('assets/books.json');
    return BibleData.fromJsonString(source);
  }
}
