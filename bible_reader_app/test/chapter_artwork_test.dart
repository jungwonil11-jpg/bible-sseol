import 'package:bible_reader_app/data/models/artwork.dart';
import 'package:bible_reader_app/theme/app_theme.dart';
import 'package:bible_reader_app/ui/chapter_artwork.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 편 명화가 본문(좌우 패딩이 있는 ListView) 안에서 빌드 중 예외 없이 렌더되는지.
/// 음수 마진(풀블리드)이 RenderPadding의 isNonNegative assert에 걸려 ErrorWidget이
/// 박히던 회귀를 방지한다.
void main() {
  testWidgets('ChapterArtwork는 좌우 패딩 ListView 안에서 예외 없이 렌더된다', (tester) async {
    const art = Artwork(
      artist: '미켈란젤로',
      title: '아담의 창조',
      year: 'c.1511',
      file: 'art/x.jpg',
      license: 'Public domain',
      source: 'Wikimedia Commons',
      commons: 'x.jpg',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: buildToneTheme(tone: 0),
        home: Scaffold(
          body: ListView(
            // reader_screen 과 동일한 좌우 패딩(defaultPageMargin) 환경.
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 36),
            children: const [ChapterArtwork(art: art, bleed: 20)],
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
