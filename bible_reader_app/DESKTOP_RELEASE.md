# 데스크탑(Windows) 빌드 · 배포 절차

> 2026-06-03 작성. 데스크탑 반응형 + 본문 AES 암호화 적용 후 빌드/배포 가이드.
> 코드는 완료·정적검증 끝(analyze 클린, 복호화 단위테스트 통과). 아래는 Victor가 직접 실행.

---

## 0. 무엇이 바뀌었나 (이번 작업 요약)

- **반응형**: 큰 화면에서 본문(`kReaderMaxWidth=720`)·서재(`kLibraryMaxWidth=860`)가
  가로로 안 늘어나고 가운데 폭으로 모임. 데스크탑·태블릿·폴드 펼침 공통 적용
  (폭 구간 규칙이라 기기 종류 무관). 폰 세로는 영향 없음.
- **데스크탑 창**: `window_manager` 로 1080×820(최소 600×520), 가운데 띄움.
- **본문 암호화**: 평문 `books.json` 대신 AES-256-CBC 암호화본 `books.json.enc` 를 번들.
  앱이 런타임 복호화. 키는 `lib/data/repositories/secret_key.dart`(★git 미추적).
- **.gitignore**: `books.json` · `books.json.enc` · `assets/art/` · `secret_key.dart` 제외.

## 1. 사전 준비 (최초 1회)

- `lib/data/repositories/secret_key.dart` 가 있는지 확인(이미 생성됨, 키 박힘).
- ★**이 키를 keystore 와 함께 PC 밖에 백업.** 잃으면 `.enc` 복호화 불가 = 본문 영영 못 읽음.
- 다른 PC에서 빌드하려면 `secret_key.example.dart` 를 `secret_key.dart` 로 복사 후 같은 키 입력.

## 2. 빌드 전 매번 — 본문 암호화본 생성

본문(`books.json`)을 고쳤거나 `.enc` 가 없으면:

```bash
# (bible_reader_app 폴더에서)
python ..\convert_to_json.py       # books.js → assets/books.json (본문 수정 시에만)
dart run tool/encrypt_books.dart   # books.json → books.json.enc
```

> `.enc` 는 .gitignore 됨 → 클론/체크아웃에 안 따라옴. 빌드 직전 항상 이 명령으로 생성.

## 3. Windows 빌드 → zip

```bash
flutter build windows --release
```

산출물: `build/windows/x64/runner/Release/` 폴더(.exe + DLL들 + data/).
이 **Release 폴더 통째로 zip** 압축 → 예: `bible-ssul-windows-v1.0.0.zip`.

## 4. GitHub Releases 업로드

- public repo `bible-sseol` → Releases → Draft a new release.
- 태그(예 `v1.0.0-desktop`) + zip 드래그&드롭 첨부 → Publish.
- zip 안에 본문(암호화본)이 들어가지만 git 본체엔 안 들어감(Releases는 별개 저장소).

## 5. ★ 안드로이드 빌드도 영향 있음 (중요)

본문 로딩이 `.enc` 복호화로 바뀌었으므로 **안드 최종 빌드 전에도 2번(암호화)을 먼저** 해야 함.
안 하면 `.enc` 가 없어서 본문이 안 뜸.

```bash
dart run tool/encrypt_books.dart   # 먼저
flutter build appbundle            # 그 다음 (서명 자동)
```

## 6. git 정리 (커밋하기 전 1회)

`books.json` 이 이미 추적 중이라 .gitignore 만으론 안 빠짐. 추적 해제(파일은 유지):

```bash
git rm --cached assets/books.json
# art/ 가 이미 추적 중이면: git rm -r --cached assets/art
```

---

## 후속(미적용, 선택)

- 키보드 네비(←→ 페이지, Esc 뒤로), 마우스 가속 등은 안 넣음(마우스휠 스크롤은 기본 동작).
- macOS/Linux 빌드(폴더 미생성). 필요 시 `flutter create --platforms=macos,linux .`
- 데스크탑 실제 화면(본문 폭·창 크기·명화 풀폭) 눈으로 확인은 Victor 몫.
