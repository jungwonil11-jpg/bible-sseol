import 'package:flutter/material.dart';

/// 앱 시작 스플래시. 풀스크린 이미지(cover)로 띄우고, 탭하면 즉시 넘어간다.
/// 자동 전환(3초)은 상위 게이트가 타이머로 처리한다.
class SplashView extends StatelessWidget {
  const SplashView({super.key, required this.onSkip});

  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSkip,
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: const Color(0xFF2A2438),
        body: SizedBox.expand(
          child: Image.asset('assets/splash.png', fit: BoxFit.cover),
        ),
      ),
    );
  }
}
