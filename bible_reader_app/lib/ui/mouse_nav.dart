import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// 마우스 사이드 버튼(뒤로 XButton1 / 앞으로 XButton2) 내비게이션.
///
/// 앱 최상위 Listener가 [onPointerDown]으로 이벤트를 받고,
/// 화면이 자체 동작을 원하면 [register]로 핸들러를 등록한다
/// (본문 뷰어의 이전/다음 편 이동). 아무 핸들러도 처리하지 않으면
/// 기본 동작: 뒤로 버튼 = Navigator pop, 앞으로 버튼 = 무시.
class MouseNav {
  MouseNav._();

  /// MaterialApp에 연결하는 내비게이터 키 — 기본 pop 동작에 사용.
  static final navigatorKey = GlobalKey<NavigatorState>();

  /// 등록 순서 = 화면 스택 순서. 위(나중 등록)부터 처리 기회를 준다.
  /// 핸들러는 (isBack) => 처리했으면 true. 자기 라우트가 최상단이
  /// 아니면(위에 다른 화면이 떠 있으면) false를 반환할 것.
  static final _handlers = <bool Function(bool isBack)>[];

  static void register(bool Function(bool isBack) handler) =>
      _handlers.add(handler);

  static void unregister(bool Function(bool isBack) handler) =>
      _handlers.remove(handler);

  static void onPointerDown(PointerDownEvent event) {
    final isBack = event.buttons & kBackMouseButton != 0;
    final isForward = event.buttons & kForwardMouseButton != 0;
    if (!isBack && !isForward) {
      return;
    }
    for (final handler in _handlers.reversed) {
      if (handler(isBack)) {
        return;
      }
    }
    if (isBack) {
      navigatorKey.currentState?.maybePop();
    }
  }
}

/// 키보드 내비게이션(데스크탑): ← 이전 편 / → 다음 편 / Esc 뒤로.
///
/// MaterialApp builder의 최상위 Focus가 [onKeyEvent]로 버블링된 키를 받는다
/// — 텍스트 필드·본문 선택이 키를 소비하면 여기까지 안 오므로 충돌 없음.
/// ←/→는 [MouseNav]에 등록된 핸들러(본문 뷰어의 이전/다음 편)를 그대로 쓰고,
/// Esc는 최상단이 일반 화면(PageRoute)일 때만 뒤로 간다 — 다이얼로그·바텀시트는
/// barrierDismissible 기본 동작에 맡긴다(동의 다이얼로그가 Esc로 닫히면 안 됨).
class KeyNav {
  KeyNav._();

  /// MaterialApp.navigatorObservers에 연결 — Esc 처리 시 최상단 라우트 판별용.
  static final observer = _TopRouteObserver();

  static KeyEventResult onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored; // 키 반복(꾹 누름)으로 편이 휙휙 넘어가는 것 방지
    }
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.escape) {
      final navigator = MouseNav.navigatorKey.currentState;
      if (navigator != null &&
          KeyNav.observer.topRoute is PageRoute &&
          navigator.canPop()) {
        navigator.maybePop();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }
    final isBack = key == LogicalKeyboardKey.arrowLeft;
    if (!isBack && key != LogicalKeyboardKey.arrowRight) {
      return KeyEventResult.ignored;
    }
    for (final handler in MouseNav._handlers.reversed) {
      if (handler(isBack)) {
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored; // 뷰어 밖에선 ←/→ 무동작
  }
}

/// 내비게이터 최상단 라우트 추적 — Esc가 다이얼로그까지 닫지 않게 하는 가드용.
class _TopRouteObserver extends NavigatorObserver {
  Route<dynamic>? topRoute;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      topRoute = route;

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      topRoute = previousRoute;

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      topRoute = previousRoute;

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      topRoute = newRoute;
}
