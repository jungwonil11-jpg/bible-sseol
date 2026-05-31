# 성경, 친구가 풀어주는 썰

> 성경 79권을 **친구가 반말로 풀어주는 "썰"** 톤으로 읽는 ebook 리더.
> 딱딱한 번역체 대신 음슴체로, 사건과 흐름은 원문 그대로 살리되 말투만 입혔습니다.

잉크·세피아 톤의 차분한 안드로이드 리더 앱으로, 본문 글꼴과 읽기 테마를 취향대로 골라 읽을 수 있습니다.

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.12-0175C2?logo=dart&logoColor=white)
![Platform](https://img.shields.io/badge/platform-Android-3DDC84?logo=android&logoColor=white)
![License](https://img.shields.io/badge/license-MIT-green)

<!-- 스크린샷은 출시용 자산 준비 후 추가 예정 (서재 / 책 상세 / 본문 / 다크모드) -->

---

## 이게 뭔가요

성경을 처음 펼치면 번역체 문장과 낯선 지명·인명에 막혀 몇 장 못 가 덮게 됩니다.
이 앱은 그 진입장벽을 낮추는 것이 목표입니다. 각 권을 7~12편의 "썰"로 묶어,
**친구가 옆에서 풀어주듯 반말(음슴체)로** 들려줍니다.

- **사건 순서·내용은 원문 그대로.** 말투만 현대 구어체로 바꿉니다. 원문 왜곡은 하지 않습니다.
- **본문은 AI가 작성한 의역·해설입니다.** 정식 성경 번역본이 아니며, 특정 교단의 신학적 입장을 대변하지 않습니다. 앱 최초 진입 시 이 점을 알리는 동의 화면을 거칩니다.

---

## 주요 기능

| 기능 | 설명 |
|---|---|
| **정경 3종 지원** | 개신교(66권) / 천주교(73권) / 정교회(76권). 선택한 정경에 맞는 책과 전통 순서로 읽힙니다. |
| **이어보기** | 마지막으로 읽던 편과 스크롤 위치를 복원합니다. |
| **읽음 표시 · 진행률** | 편별 읽음 처리, 책별 진행률 표시. |
| **즐겨찾기 · 밑줄** | 편 즐겨찾기, 본문 드래그 선택 후 밑줄. |
| **전체 검색** | 선택한 정경 범위 내 본문 검색 + 결과 하이라이트. |
| **읽기 환경 설정** | 읽기 테마 3종(라이트/세피아/다크), 본문 글꼴 5종, 글자 크기 4단계. 설정은 기기에 영속 저장. |

---

## 기술 스택

- **Flutter / Dart** — 단일 코드베이스 안드로이드 앱
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

> **본문 텍스트(`books.js` · `books_src/` · `books.json`)는 저작 콘텐츠로, 이 저장소에 포함하지 않습니다.**
> 공개되는 것은 앱 코드와 빌드 파이프라인입니다.

---

## 빌드

본문 데이터(`assets/books.json`)는 저장소에 포함되지 않으므로, 앱을 직접 빌드해 실행하려면 별도의 데이터가 필요합니다. 코드 빌드 절차는 다음과 같습니다.

```bash
# 1) (데이터 보유 시) 본문 원본 → 앱용 JSON 생성
python merge_books.py
python convert_to_json.py

# 2) Flutter 앱 빌드
cd bible_reader_app
flutter pub get
flutter build appbundle      # 릴리스용 .aab
# 또는
flutter run                  # 로컬 실행
```

---

## 콘텐츠 / 면책

- 본문은 **AI가 성경을 의역·각색한 콘텐츠**입니다. 정식 번역본이 아닙니다.
- 신학적 정통성이나 교리적 정확성을 보증하지 않습니다. 깊이 있는 학습·신앙 생활에는 정식 성경과 교단의 공식 자료를 함께 보시길 권합니다.
- 정경 분류·권수는 전통적 구분을 참고했으며, 세부 입장은 교단마다 다를 수 있습니다.

---

## 라이선스

- **앱 코드** — [MIT License](LICENSE).
- **폰트** — Gamja Flower, 나눔명조/고딕/스퀘어, 마루 부리 모두 SIL Open Font License 1.1(OFL). 상업적 사용·임베드·재배포 허용(폰트 자체의 유료 판매만 금지). 고지 원문은 `bible_reader_app/assets/licenses/` 참고.
- **본문 콘텐츠** — 저작권 보유. 저장소에 포함하지 않으며 MIT 적용 대상이 아닙니다.
