import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// 제목 아래 들어가는 책 장식 구분선(스워시). 폰트 글리프에 의존하지 않게
/// 가는 선 + 마름모를 위젯으로 직접 그린다. color 미지정 시 테마 accentSoft.
class Ornament extends StatelessWidget {
  const Ornament({super.key, this.color});

  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? appColors(context).accentSoft;
    Widget bar() => Container(width: 34, height: 1, color: c);
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          bar(),
          const SizedBox(width: 8),
          Transform.rotate(
            angle: 0.785398, // 45도 — 마름모
            child: Container(width: 5, height: 5, color: c),
          ),
          const SizedBox(width: 8),
          bar(),
        ],
      ),
    );
  }
}
