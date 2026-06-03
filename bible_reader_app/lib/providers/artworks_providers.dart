import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/artwork.dart';

/// 편별 명화 메타(assets/art/artworks.json)를 1회 로드해 캐시한다.
final artworkDataProvider = FutureProvider<ArtworkData>((ref) async {
  final source = await rootBundle.loadString('assets/art/artworks.json');
  return ArtworkData.fromJsonString(source);
});
