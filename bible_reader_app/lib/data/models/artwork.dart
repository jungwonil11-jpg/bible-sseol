import 'dart:convert';

/// 편(章)에 곁들이는 퍼블릭 도메인 명화 한 점.
/// 데이터 출처: assets/art/artworks.json (본문 books.json과 분리).
class Artwork {
  const Artwork({
    required this.artist,
    required this.title,
    required this.year,
    required this.file,
    required this.license,
    required this.source,
    required this.commons,
  });

  factory Artwork.fromJson(Map<String, dynamic> json) {
    return Artwork(
      artist: json['artist'] as String? ?? '',
      title: json['title'] as String? ?? '',
      year: json['year'] as String? ?? '',
      file: json['file'] as String? ?? '',
      license: json['license'] as String? ?? '',
      source: json['source'] as String? ?? '',
      commons: json['commons'] as String? ?? '',
    );
  }

  final String artist;
  final String title;
  final String year;

  /// artworks.json에 기록된 상대 경로("art/MAT-1.jpg").
  final String file;
  final String license;
  final String source;

  /// Wikimedia Commons 원본 파일명(출처 추적용).
  final String commons;

  /// Flutter 번들 asset 경로.
  String get assetPath => 'assets/$file';
}

/// 책 id → 편 번호 → 명화 매핑. 편마다 명화가 있는 건 아니므로 lookup은 null 가능.
class ArtworkData {
  const ArtworkData(this._byBook);

  final Map<String, Map<int, Artwork>> _byBook;

  /// 해당 책·편의 명화. 없으면 null.
  Artwork? lookup(String bookId, int chapterNum) =>
      _byBook[bookId]?[chapterNum];

  /// 책 id → 편 번호 → 명화 전체 맵(읽기 전용). 출처 목록 화면 등에서 사용.
  Map<String, Map<int, Artwork>> get byBook => _byBook;

  factory ArtworkData.fromJsonString(String source) {
    final json = jsonDecode(source) as Map<String, dynamic>;
    final byBook = <String, Map<int, Artwork>>{};
    json.forEach((bookId, chapters) {
      // "_meta" 같은 메타 키와 형식이 안 맞는 항목은 건너뛴다.
      if (bookId.startsWith('_') || chapters is! Map<String, dynamic>) {
        return;
      }
      final perChapter = <int, Artwork>{};
      chapters.forEach((numStr, art) {
        final n = int.tryParse(numStr);
        if (n != null && art is Map<String, dynamic>) {
          perChapter[n] = Artwork.fromJson(art);
        }
      });
      byBook[bookId] = perChapter;
    });
    return ArtworkData(byBook);
  }
}
