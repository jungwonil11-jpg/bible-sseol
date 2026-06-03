// secret_key.dart 의 템플릿. (실제 키 파일은 .gitignore 됨 — 공개 repo엔 이 example만 있다.)
//
// 빌드하려면 이 파일을 같은 폴더에 `secret_key.dart` 로 복사하고 키를 채운다:
//   1) 키 생성:
//      python -c "import secrets,base64; print(base64.b64encode(secrets.token_bytes(32)).decode())"
//   2) 아래 상수에 붙여넣기
//   3) 평문 본문(assets/books.json)을 암호화해 assets/books.json.enc 생성:
//      dart run tool/encrypt_books.dart
//
// ★키를 잃으면 books.json.enc 복호화 불가 → 본문 영영 못 읽음. 백업 필수.
const String kBibleAesKeyBase64 = 'PUT_YOUR_BASE64_AES256_KEY_HERE=';
