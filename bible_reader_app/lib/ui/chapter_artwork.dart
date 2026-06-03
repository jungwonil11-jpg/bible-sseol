import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show OverflowBoxFit;

import '../data/models/artwork.dart';
import '../theme/app_theme.dart';

/// 편 헤더 아래에 놓이는 명화. 화면 끝까지 풀폭으로 전체 그림을 보여주고,
/// 탭하면 원본을 풀스크린으로 확대해 본다.
class ChapterArtwork extends StatelessWidget {
  const ChapterArtwork({super.key, required this.art, this.bleed = 0});

  final Artwork art;

  /// 본문 좌우 패딩(pageMargin)을 음수 마진으로 상쇄해 화면 끝까지 채우기 위한 폭(px).
  final double bleed;

  @override
  Widget build(BuildContext context) {
    final colors = appColors(context);
    return GestureDetector(
      onTap: () => _openViewer(context, art),
      child: Column(
        children: [
          // 본문 좌우 패딩(bleed)을 넘어 화면 끝까지 풀폭으로. 음수 마진은
          // Container/RenderPadding 의 isNonNegative assert 에 걸리므로(디버그
          // 빌드에서 예외), OverflowBox 로 가로 제약만 bleed 만큼 넓혀 채운다.
          // 높이는 자식 이미지(fitWidth 자연 비율)를 그대로 따른다.
          LayoutBuilder(
            builder: (context, constraints) {
              final fullWidth = constraints.maxWidth + 2 * bleed;
              return OverflowBox(
                minWidth: fullWidth,
                maxWidth: fullWidth,
                fit: OverflowBoxFit.deferToChild,
                child: Image.asset(
                  art.assetPath,
                  width: fullWidth,
                  fit: BoxFit.fitWidth,
                  // 이미지가 없으면 조용히 사라진다(레이아웃 깨짐 방지).
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.zoom_out_map, size: 13, color: colors.inkSoft),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  '${art.title} · ${art.artist}',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.inkSoft, fontSize: 12.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

void _openViewer(BuildContext context, Artwork art) {
  Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black,
      pageBuilder: (_, _, _) => _ArtworkViewer(art: art),
    ),
  );
}

/// 원본 풀스크린 뷰어 — 핀치 줌/패닝 + 하단 크레딧(라이선스 고지 의무 이행).
class _ArtworkViewer extends StatelessWidget {
  const _ArtworkViewer({required this.art});

  final Artwork art;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 5,
                child: Center(
                  child: Image.asset(art.assetPath, fit: BoxFit.contain),
                ),
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
                color: Colors.black.withValues(alpha: 0.55),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      art.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${art.artist} · ${art.year}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 12.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${art.source} · ${art.license}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
