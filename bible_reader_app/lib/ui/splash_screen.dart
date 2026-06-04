import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../data/models/artwork.dart';

/// 앱 시작 스플래시. 수록 명화 중 한 점을 랜덤으로 골라 전체 그림(크롭 없이)으로
/// 띄우고, 하단에 작가·작품명 캡션을 단다. 탭하면 즉시 넘어간다.
/// 자동 전환(3초)은 상위 게이트가 타이머로 처리한다.
class SplashView extends StatefulWidget {
  const SplashView({super.key, required this.onSkip});

  final VoidCallback onSkip;

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  static const _background = Color(0xFF2A2438); // 네이티브 런치 배경색과 동일

  Artwork? _artwork;

  @override
  void initState() {
    super.initState();
    _pickRandomArtwork();
  }

  Future<void> _pickRandomArtwork() async {
    try {
      final source = await rootBundle.loadString('assets/art/artworks.json');
      final all = ArtworkData.fromJsonString(source)
          .byBook
          .values
          .expand((chapters) => chapters.values)
          .toList();
      if (all.isEmpty || !mounted) {
        return;
      }
      setState(() => _artwork = all[Random().nextInt(all.length)]);
    } catch (_) {
      // 명화 로드 실패 시 배경색만 띄운다 — 스플래시는 장식이라 죽으면 안 됨.
    }
  }

  @override
  Widget build(BuildContext context) {
    final artwork = _artwork;
    return GestureDetector(
      onTap: widget.onSkip,
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: _background,
        body: artwork == null
            ? const SizedBox.expand()
            : SafeArea(
                child: Column(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                        child: Image.asset(
                          artwork.assetPath,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => const SizedBox.expand(),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
                      child: Text(
                        '${artwork.artist} — ${artwork.title}',
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xB3FFFFFF),
                          fontSize: 13,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
