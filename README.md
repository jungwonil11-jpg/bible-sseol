# 성경전체썰읽으실분

> 성경 76권을 **친구가 반말로 풀어주는 "썰"** 톤으로 읽는 가벼운 ebook.

잉크·세피아 톤의 차분한 리더 앱입니다. **Android와 Windows 데스크탑**에서, 본문 글꼴과 읽기 테마 톤을 취향대로 골라 읽을 수 있습니다.

<p>
  <a href="https://apps.microsoft.com/detail/9pfjk276k4wc?mode=direct">
    <img src="https://get.microsoft.com/images/ko%20dark.svg" width="220" alt="Microsoft Store에서 다운로드" />
  </a>
</p>

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.12-0175C2?logo=dart&logoColor=white)
![Platform](https://img.shields.io/badge/platform-Android-3DDC84?logo=android&logoColor=white)
![Platform](https://img.shields.io/badge/platform-Windows-0078D6?logo=windows&logoColor=white)
![License](https://img.shields.io/badge/license-MIT-green)

<!-- 스크린샷은 출시용 자산 준비 후 추가 예정 (서재 / 책 상세 / 본문 / 다크모드) -->

---

## 제작 이유

딱딱한 번역체 대신 음슴체로, 사건과 흐름은 원문을 최대한 살리되 흥미있게 각색했습니다.

'흥미' vs '수많은 고민들' 중에서 저는 이 책은 '흥미'를 골랐습니다. 흥미가 떨어지면 이 방대한 책을 도저히 읽을 엄두가 나지 않는다고 당장 저부터 느꼈기 때문입니다.

처음에는 저 혼자 읽으려고 만들었지만, 한 사람이라도 이 책을 통해 성경에 흥미를 가지게 되어 더 좋은 길로 나아가길 바라는 마음에 세상에 내놓습니다.

---

## 다운로드

- **Windows** — [Microsoft Store에서 설치](https://apps.microsoft.com/detail/9pfjk276k4wc)하세요. 코드 서명·자동 업데이트가 적용되어 SmartScreen 경고 없이 설치됩니다.
- **Android** — 비공개 테스트 진행 중입니다.

> 예전 GitHub Releases의 무서명 `.zip` 배포는 종료했습니다. Windows 배포는 Microsoft Store로 일원화되었습니다.

---

## 주요 기능

| 기능 | 설명 |
|---|---|
| **정경 3종 지원** | 개신교(66권) / 천주교(73권) / 정교회(76권). 선택한 정경에 맞는 책과 전통 순서로 읽힙니다. |
| **편별 명화** | 각 편마다 어울리는 퍼블릭 도메인 명화를 곁들였습니다. 탭하면 원본을 확대해 보고, 작가·작품·소장처도 확인할 수 있습니다. |
| **이어보기** | 마지막으로 읽던 편과 스크롤 위치를 복원합니다. |
| **읽음 표시 · 진행률** | 편별 읽음 처리, 책별 진행률 표시. |
| **책갈피 · 형광펜** | 편 즐겨찾기, 본문 드래그 선택 후 형광펜(4색)으로 강조. |
| **전체 검색** | 선택한 정경 범위 내 본문 검색 + 결과 하이라이트. |
| **모아보기** | 즐겨찾기한 편과 형광펜으로 표시한 구절을 한 화면에서 모아 봅니다. |
| **읽기 통계** | 정경별 진행률, 연속 읽기(스트릭) · 출석 달력. |
| **읽기 환경 설정** | 읽기 테마 3종(라이트/세피아/다크), 본문 글꼴 5종, 글자 크기·줄 간격·자간·여백·화면 밝기까지 세밀 조절. 설정은 기기에 영속 저장. |
| **반응형 레이아웃** | 폰은 화면에 꽉 차게, 데스크탑·태블릿 등 큰 화면에서는 본문·서재를 가운데 폭으로 모아 읽기 좋게. |

---

## 기술 스택

- **Flutter / Dart** — 단일 코드베이스로 Android + Windows 데스크탑 동시 지원 (폭 구간 기반 반응형)
- **Riverpod** — 상태 관리
- **sqflite (SQLite)** — 읽기 진행률·즐겨찾기·밑줄 등 로컬 영속화
- 무채색·세피아 기반 읽기 테마(라이트 / 세피아 / 다크) + 본문 글꼴 5종 선택 — 군더더기 없는 문학적 톤

---

## 프로젝트 구조

```
bible_reader_app/          Flutter 앱 (메인)
  lib/
    ui/                    화면 — 서재 / 책 상세 / 본문 뷰어 / 검색 / 설정 / 컬렉션
    data/                  모델 · SQLite 데이터베이스 · 리포지토리
    providers/             Riverpod 프로바이더 (책 · 읽기 상태 · 설정)
    theme/                 디자인 토큰 · 테마
  assets/                  폰트 · 폰트 라이선스 고지

merge_books.py             books_src/*.js → books.js 병합
convert_to_json.py         books.js → 앱용 books.json 변환
canon_meta.py              정경(개신교/천주교/정교회) 메타 단일 소스
```

> **전체 본문(`books.js` · `books_src/` · 전체 `books.json`)은 저작 콘텐츠로 이 저장소에 포함하지 않습니다.**
> 공개되는 것은 앱 코드, 빌드 파이프라인, 그리고 바로 실행해 볼 수 있는 **창세기 샘플**입니다.

---

## 직접 빌드 · 실행

전체 본문(76권)은 저작 콘텐츠라 포함하지 않지만, **창세기 1권과 편별 명화를 샘플로 포함**해 두어 클론하면 그대로 빌드·실행됩니다.

```bash
cd bible_reader_app
flutter pub get
flutter run -d windows        # Windows 데스크탑
# flutter run -d <기기id>     # Android
```

샘플은 창세기만 표시됩니다. 전체 76권은 [Microsoft Store](https://apps.microsoft.com/detail/9pfjk276k4wc) 정식 버전에서 읽을 수 있습니다.

<details>
<summary>본문 데이터 파이프라인 (원본 보유자용)</summary>

본문 원본(`books_src/`)을 가진 경우의 데이터 빌드 절차입니다. 앱은 평문이 아니라 **AES-256 암호화본(`books.json.enc`)** 만 읽습니다.

```bash
python merge_books.py        # books_src/*.js → books.js
python convert_to_json.py    # books.js → assets/books.json
cd bible_reader_app && dart run tool/encrypt_books.dart   # → assets/books.json.enc
```
</details>

---

## 콘텐츠 / 면책

- 본문은 **AI가 성경을 의역·각색한 콘텐츠**입니다. 정식 번역본이 아닙니다. 앱 최초 진입 시 이 점을 알리는 동의 화면을 거칩니다.
- 신학적 정통성이나 교리적 정확성을 보증하지 않습니다. 깊이 있는 학습·신앙 생활에는 정식 성경과 교단의 공식 자료를 함께 보시길 권합니다.
- 정경 분류·권수는 전통적 구분을 참고했으며, 세부 입장은 교단마다 다를 수 있습니다.

---

## 라이선스

- **앱 코드** — [MIT License](LICENSE).
- **폰트** — Gamja Flower, 나눔명조/고딕/스퀘어, 마루 부리 모두 SIL Open Font License 1.1(OFL). 상업적 사용·임베드·재배포 허용(폰트 자체의 유료 판매만 금지). 고지 원문은 `bible_reader_app/assets/licenses/` 참고.
- **수록 명화** — Wikimedia Commons의 퍼블릭 도메인(PD-Art) 회화입니다. 앱 내 정보 화면에서 작가·작품·소장처를 고지합니다.
- **본문 콘텐츠** — 저작권 보유. 전체 본문은 저장소에 포함하지 않으며 MIT 적용 대상이 아닙니다. 저장소에 포함된 창세기 샘플 본문도 코드(MIT)와 별개로 본문 저작권이 유지됩니다.
