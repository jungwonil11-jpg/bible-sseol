import 'package:flutter_test/flutter_test.dart';

import 'package:bible_reader_app/data/models/bible_data.dart';
import 'package:bible_reader_app/ui/search_screen.dart';

void main() {
  final data = _fixture();

  test('빈 쿼리는 결과 없음', () {
    expect(searchBible(data, 'protestant', '   '), isEmpty);
  });

  test('본문 단어 매치 + 스니펫 하이라이트 위치', () {
    final hits = searchBible(data, 'protestant', '천지창조');
    expect(hits, hasLength(1));
    final hit = hits.single;
    expect(hit.book.id, 'genesis');
    expect(hit.chapterIndex, 0);
    final matched = hit.snippet.substring(
      hit.matchStart,
      hit.matchStart + hit.matchLen,
    );
    expect(matched, '천지창조');
  });

  test('정경 필터 — 개신교에선 제2경전 책 안 잡힘', () {
    expect(searchBible(data, 'protestant', '토비트단어'), isEmpty);
    expect(searchBible(data, 'catholic', '토비트단어'), hasLength(1));
  });

  test('canonExtra 블록은 개신교에서 검색 제외, 천주교에선 포함', () {
    expect(searchBible(data, 'protestant', '추가본단어'), isEmpty);
    expect(searchBible(data, 'catholic', '추가본단어'), hasLength(1));
  });
}

BibleData _fixture() {
  return BibleData(
    schemaVersion: 1,
    generatedFrom: 'test',
    canonInfo: const {},
    deutMeta: const [],
    books: const [
      BibleBook(
        id: 'genesis',
        title: '창세기',
        testament: 'old',
        order: 1,
        sortOrder: 1,
        canon: ['protestant', 'catholic', 'orthodox'],
        ref: '전 1편',
        chapters: [
          BibleChapter(
            id: 'genesis:1',
            num: 1,
            title: '천지창조',
            ref: '창세기 1장',
            blocks: [
              ContentBlock(
                type: ContentBlockType.p,
                text: '태초에 신이 천지창조를 시작함. 우주 스타트업의 출발임.',
              ),
            ],
          ),
        ],
      ),
      BibleBook(
        id: 'esther',
        title: '에스더',
        testament: 'old',
        order: 17,
        sortOrder: 17,
        canon: ['protestant', 'catholic', 'orthodox'],
        ref: '전 1편',
        chapters: [
          BibleChapter(
            id: 'esther:1',
            num: 1,
            title: '에스더',
            ref: '에스더 1장',
            blocks: [
              ContentBlock(type: ContentBlockType.p, text: '평범한 본문'),
              ContentBlock(
                type: ContentBlockType.p,
                text: '추가본단어 들어간 그리스어 추가분',
                canon: ['catholic', 'orthodox'],
                canonExtra: true,
                canonExtraLabel: '추가분',
              ),
            ],
          ),
        ],
      ),
      BibleBook(
        id: 'tobit',
        title: '토비트',
        testament: 'deut',
        order: 16,
        sortOrder: 16.1,
        canon: ['catholic', 'orthodox'],
        ref: '전 1편',
        chapters: [
          BibleChapter(
            id: 'tobit:1',
            num: 1,
            title: '토비트',
            ref: '토비트 1장',
            blocks: [
              ContentBlock(type: ContentBlockType.p, text: '토비트단어 등장'),
            ],
          ),
        ],
      ),
    ],
  );
}
