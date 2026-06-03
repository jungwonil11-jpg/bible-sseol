// 평문 본문(assets/books.json)을 AES-256-CBC 로 암호화해 assets/books.json.enc 를
// 만든다. 앱(BooksRepository)이 같은 `encrypt` 패키지·같은 키로 복호화한다.
//
// 실행(프로젝트 루트 bible_reader_app 에서):
//   dart run tool/encrypt_books.dart
//
// 출력 형식: [IV 16바이트][CBC 암호문]. 매 실행 IV 는 새로 난수 생성된다.
// 평문(books.json)을 고치면 이 스크립트를 다시 돌려 .enc 를 갱신해야 한다.
import 'dart:io';

import 'package:encrypt/encrypt.dart';

import 'package:bible_reader_app/data/repositories/secret_key.dart';

void main() {
  const plainPath = 'assets/books.json';
  const outPath = 'assets/books.json.enc';

  final plainFile = File(plainPath);
  if (!plainFile.existsSync()) {
    stderr.writeln('평문 본문이 없음: $plainPath (먼저 convert_to_json.py 로 생성)');
    exitCode = 1;
    return;
  }

  final plain = plainFile.readAsStringSync();
  final key = Key.fromBase64(kBibleAesKeyBase64);
  final iv = IV.fromSecureRandom(16);
  final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
  final encrypted = encrypter.encrypt(plain, iv: iv);

  final out = <int>[...iv.bytes, ...encrypted.bytes];
  File(outPath).writeAsBytesSync(out);

  stdout.writeln(
    '암호화 완료: ${plain.length}자 → ${out.length}바이트 → $outPath',
  );
}
