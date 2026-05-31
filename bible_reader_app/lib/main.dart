import 'dart:async';

import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform, LicenseRegistry, LicenseEntryWithLineBreaks;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import 'providers/books_providers.dart';
import 'providers/settings_controller.dart';
import 'theme/app_theme.dart';
import 'ui/canon_select_screen.dart';
import 'ui/disclaimer_dialog.dart';
import 'ui/library_screen.dart';
import 'ui/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // 번들된 OFL 글꼴들의 라이선스 전문을 앱 라이선스 페이지(showLicensePage)에 등록.
  LicenseRegistry.addLicense(() async* {
    for (final path in const [
      'assets/licenses/FONTS_NOTICE.txt',
      'assets/licenses/Nanum-OFL.txt',
      'assets/licenses/GamjaFlower-OFL.txt',
    ]) {
      yield LicenseEntryWithLineBreaks(
        const ['fonts'],
        await rootBundle.loadString(path),
      );
    }
  });
  // 플랫폼별 sqflite 백엔드 선택. 안드로이드/iOS는 기본 팩토리가 자동 설정되지만
  // 웹은 WASM 기반 FFI 웹 팩토리, 데스크탑은 네이티브 FFI 팩토리를 직접 지정해야 한다.
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  } else if (defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux ||
      defaultTargetPlatform == TargetPlatform.macOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  runApp(const ProviderScope(child: BibleReaderApp()));
}

class BibleReaderApp extends ConsumerWidget {
  const BibleReaderApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeId = ref.watch(
      settingsControllerProvider.select((s) => s.readingTheme),
    );
    final fontFamily = ref.watch(
      settingsControllerProvider.select((s) => s.fontFamily),
    );
    final brightness = ref.watch(
      settingsControllerProvider.select((s) => s.brightness),
    );
    // 밝기 = 인앱 딜밍. 전 화면(다이얼로그 포함) 위에 검정 오버레이를 덮어 어둡게.
    final dim = ((1.0 - brightness) * dimMax).clamp(0.0, dimMax);
    return MaterialApp(
      title: '성경 전체 썰 읽으실분',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(
        theme: readingThemeById(themeId),
        fontFamily: fontFamily,
      ),
      builder: (context, child) => Stack(
        children: [
          ?child,
          if (dim > 0)
            Positioned.fill(
              child: IgnorePointer(
                child: ColoredBox(color: Colors.black.withValues(alpha: dim)),
              ),
            ),
        ],
      ),
      home: const _SplashGate(),
    );
  }
}

/// 시작 스플래시 게이트: 3초 후(또는 탭 시) 서재로 넘어간다.
class _SplashGate extends StatefulWidget {
  const _SplashGate();

  @override
  State<_SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<_SplashGate> {
  bool _done = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 3), _finish);
  }

  void _finish() {
    if (mounted && !_done) {
      setState(() => _done = true);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_done) {
      return const _Home();
    }
    return SplashView(onSkip: _finish);
  }
}

class _Home extends ConsumerStatefulWidget {
  const _Home();

  @override
  ConsumerState<_Home> createState() => _HomeState();
}

class _HomeState extends ConsumerState<_Home> {
  bool _disclaimerHandled = false;

  void _maybeShowDisclaimer(AppSettings settings) {
    if (_disclaimerHandled || !settings.loaded || settings.disclaimerAgreed) {
      return;
    }
    _disclaimerHandled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }
      final dontShowAgain = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => DisclaimerDialog(
          onAgree: (dontShow) => Navigator.of(context).pop(dontShow),
        ),
      );
      // '다시 보지 않기'를 체크하고 동의한 경우에만 영속화 → 다음 실행부터 생략.
      // 체크 안 했으면 이번 세션만 통과하고 다음 실행 때 다시 뜬다.
      if (dontShowAgain == true) {
        await ref.read(settingsControllerProvider.notifier).agreeDisclaimer();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsControllerProvider);
    _maybeShowDisclaimer(settings);
    final data = ref.watch(bibleDataProvider);
    return data.when(
      data: (bible) => settings.canonChosen
          ? LibraryScreen(data: bible)
          : CanonSelectScreen(data: bible, onboarding: true),
      error: (error, stackTrace) => _LoadFailure(error: error),
      loading: () => const _LoadingScreen(),
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 18),
            Text(
              '불러오는 중',
              style: handTextStyle(
                color: appColors(context).accent,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadFailure extends StatelessWidget {
  const _LoadFailure({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    final colors = appColors(context);
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            '데이터 로드 실패\n$error',
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.ink),
          ),
        ),
      ),
    );
  }
}
