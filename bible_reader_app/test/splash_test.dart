import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bible_reader_app/ui/splash_screen.dart';

void main() {
  testWidgets('스플래시를 탭하면 onSkip이 호출된다', (tester) async {
    var skipped = false;
    await tester.pumpWidget(
      MaterialApp(home: SplashView(onSkip: () => skipped = true)),
    );
    await tester.pump();

    await tester.tap(find.byType(SplashView));
    await tester.pump();

    expect(skipped, isTrue);
  });
}
