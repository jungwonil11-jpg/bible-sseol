import 'package:flutter/gestures.dart';
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
