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
- **.gitignore**: `books.json.enc`(생성 산출물) · `secret_key.dart`(AES 키) 제외.
  ※본문(`books.json`)·명화(`assets/art/`)는 **private 본진에선 git 추적 유지가 맞음** — 공개 repo 보호는 `bible-sseol` 쪽 .gitignore가 담당. (초기엔 본진도 제외로 적혀 있었으나 Codex 오분석이라 2026-06-04 정정.)
- **(후속 2026-06-03) DB 경로**: 데스크탑은 Documents 가 아니라 앱 전용 지원 디렉토리에 저장
  (Windows: `%APPDATA%\…(앱 식별자)\bible_reader.db`). 테스트 중 DB 초기화하려면 여길 지울 것.
- **(후속 2026-06-03) exe 아이콘**: `flutter_launcher_icons` windows 설정으로 앱 아이콘 적용됨.

## 1. 사전 준비 (최초 1회)

- `lib/data/repositories/secret_key.dart` 가 있는지 확인(이미 생성됨, 키 박힘).
- ★**이 키를 keystore 와 함께 PC 밖에 백업.** 잃으면 `.enc` 복호화 불가 = 본문 영영 못 읽음. (✅2026-06-04 백업 완료)
- 다른 PC에서 빌드하려면 `secret_key.example.dart` 를 `secret_key.dart` 로 복사 후 같은 키 입력.

## 2. 빌드 전 매번 — 본문 암호화본 생성

본문(`books.json`)을 고쳤거나 `.enc` 가 없으면:

```bash
# (bible_reader_app 폴더에서)
python ..\convert_to_json.py       # books.js → assets/books.json (본문 수정 시에만)
dart run tool/encrypt_books.dart   # books.json → books.json.enc
```

> `.enc` 는 .gitignore 됨(생성 산출물) → 클론/체크아웃에 안 따라옴. 빌드 직전 항상 이 명령으로 생성.

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

## 4-1. MS Store 제출용 MSIX 빌드 (2026-06-07 추가)

> Partner Center에 `성경전체썰읽으실분` 예약 완료(2026-06-07). Identity 값은 `pubspec.yaml`의 `msix_config`에 박혀 있음(Partner Center 제품 ID와 일치 필수 — 바뀌면 양쪽 다 수정).

```bash
# (bible_reader_app 폴더에서 — 2번 암호화 선행은 동일)
dart run tool/encrypt_books.dart
flutter build windows --release
dart run msix:create --store
```

- 산출물: `build/windows/x64/runner/Release/bible_reader_app.msix`
- `--store` = 스토어 업로드 전용(로컬 서명 안 함). **이 msix는 더블클릭 설치 안 됨** — Partner Center 제출용으로만 쓰는 게 정상.
- 업로드: Partner Center → 성경전체썰읽으실분 → 제출 시작 → 패키지에 `.msix` 업로드 + 등록정보(설명·스샷·정책 URL) 작성 → 제출.
- 버전 올릴 때: `pubspec.yaml`의 `version`과 `msix_config.msix_version`(x.x.x.0 형식) 둘 다 갱신.
- GitHub Releases zip 배포(3~4번)는 병행 유지 — zip은 SAC 환경에서 계속 차단되므로 SAC 유저는 스토어로 안내.

## 5. ★ 안드로이드 빌드도 영향 있음 (중요)

본문 로딩이 `.enc` 복호화로 바뀌었으므로 **안드 최종 빌드 전에도 2번(암호화)을 먼저** 해야 함.
안 하면 `.enc` 가 없어서 본문이 안 뜸.

```bash
dart run tool/encrypt_books.dart   # 먼저
flutter build appbundle            # 그 다음 (서명 자동)
```

---

## 후속(미적용, 선택)

- ~~키보드 네비~~ → 적용됨(2026-06-07): ←/→ 이전·다음 편, Esc 뒤로(`mouse_nav.dart`의 `KeyNav`). 마우스휠 스크롤은 기본 동작.
- macOS/Linux 빌드(폴더 미생성). 필요 시 `flutter create --platforms=macos,linux .`
- 데스크탑 실제 화면(본문 폭·창 크기·명화 풀폭) 눈으로 확인은 Victor 몫.
