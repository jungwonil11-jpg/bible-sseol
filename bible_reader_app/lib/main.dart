import 'dart:async';

import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform, FlutterError, FlutterErrorDetails, PlatformDispatcher, LicenseRegistry, LicenseEntryWithLineBreaks;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:window_manager/window_manager.dart';

import 'providers/books_providers.dart';
import 'providers/settings_controller.dart';
import 'theme/app_theme.dart';
import 'ui/canon_select_screen.dart';
import 'ui/disclaimer_dialog.dart';
import 'ui/error_view.dart';
import 'ui/library_screen.dart';
import 'ui/mouse_nav.dart';
import 'ui/splash_screen.dart';

/// 가장 최근에 잡힌 에러 — zone/비동기에서 잡힌 에러를 제보 화면이 참고할 수 있게
/// 보관한다(빌드 중 에러는 ErrorWidget.builder가 details로 직접 받는다).
Object? lastError;
StackTrace? lastStackTrace;

void _recordError(Object error, StackTrace? stack) {
  lastError = error;
  lastStackTrace = stack;
}

Future<void> main() async {
  // 전역 에러 가드: 어디서 터지든 빨간/회색 기본 화면 대신 앱 톤 안내 화면을 띄우고,
  // 마지막 에러를 보관해 유저가 제보 메일에 담아 보낼 수 있게 한다.
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    _recordError(details.exception, details.stack);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    _recordError(error, stack);
    return true;
  };
  ErrorWidget.builder = (FlutterErrorDetails details) =>
      RawErrorView(error: details.exception, stackTrace: details.stack);

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
  final isDesktop = !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.macOS);
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  } else if (isDesktop) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  // 데스크탑은 읽기 좋게 세로로 약간 긴 창으로 띄운다(가로 풀스크린은 본문 폭
  // 제한 때문에 양옆만 비므로 지양). 유저가 키우면 본문은 가운데 폭으로 유지된다.
  if (isDesktop) {
    await windowManager.ensureInitialized();
    const windowOptions = WindowOptions(
      size: Size(1080, 820),
      minimumSize: Size(600, 520),
      center: true,
      title: '성경 전체 썰 읽으실분',
      titleBarStyle: TitleBarStyle.normal,
    );
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }
  runApp(const ProviderScope(child: BibleReaderApp()));
}

class BibleReaderApp extends ConsumerWidget {
  const BibleReaderApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeTone = ref.watch(
      settingsControllerProvider.select((s) => s.themeTone),
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
      navigatorKey: MouseNav.navigatorKey,
      theme: buildToneTheme(
        tone: themeTone,
        fontFamily: fontFamily,
      ),
      // Listener: 마우스 사이드 버튼(뒤로/앞으로) 전역 감지 — 데스크탑용.
      builder: (context, child) => Listener(
        onPointerDown: MouseNav.onPointerDown,
        behavior: HitTestBehavior.translucent,
        child: Stack(
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
          : CanonSelectScreen(data: bible, mode: CanonSelectMode.onboarding),
      error: (error, stackTrace) => Scaffold(
        body: ErrorView(
          error: error,
          stackTrace: stackTrace,
          onRetry: () => ref.invalidate(bibleDataProvider),
        ),
      ),
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

