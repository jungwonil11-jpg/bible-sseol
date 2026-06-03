import 'package:encrypt/encrypt.dart';
import 'package:flutter/services.dart';

import '../models/bible_data.dart';
import 'secret_key.dart';

class BooksRepository {
  BooksRepository({AssetBundle? assetBundle})
    : _assetBundle = assetBundle ?? rootBundle;

  final AssetBundle _assetBundle;

  /// 본문은 AES-256-CBC 로 암호화돼 books.json.enc 로 번들된다(평문 books.json은
  /// git/release 에 포함하지 않음). 앞 16바이트가 IV, 나머지가 암호문.
  /// 암호화는 `dart run tool/encrypt_books.dart`, 키는 secret_key.dart.
  Future<BibleData> loadBooks() async {
    final raw = await _assetBundle.load('assets/books.json.enc');
    final bytes = raw.buffer.asUint8List(raw.offsetInBytes, raw.lengthInBytes);
    final iv = IV(bytes.sublist(0, 16));
    final cipher = Encrypted(bytes.sublist(16));
    final encrypter = Encrypter(
      AES(Key.fromBase64(kBibleAesKeyBase64), mode: AESMode.cbc),
    );
    final source = encrypter.decrypt(cipher, iv: iv);
    return BibleData.fromJsonString(source);
  }
}
