import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_theme.dart';

/// 오류 제보가 도착할 개발자 메일. about_screen의 피드백 메일과 동일.
const kFeedbackEmail = 'jungwonil11@gmail.com';

/// 제보 메일 본문에 넣는 앱 버전. pubspec의 version(1.0.0+1)과 수기로 맞춘다.
const kAppVersion = '1.0.0';

/// MaterialApp/Theme 바깥에서도 안전하게 쓰는 기본색(Original 테마값).
const _rawPaper = Color(0xFFFBFAF8);
const _rawInk = Color(0xFF20201E);

/// 에러+스택을 사람이 읽을 수 있는 짧은 텍스트로. mailto URL이 너무 길어지지
/// 않도록 스택은 앞쪽 일부만, 전체 길이도 상한을 둔다.
String describeError(Object error, StackTrace? stack) {
  final buf = StringBuffer()
    ..writeln('앱 버전: $kAppVersion')
    ..writeln('플랫폼: ${defaultTargetPlatform.name}')
    ..writeln('에러: $error');
  if (stack != null) {
    final lines = stack.toString().split('\n');
    buf
      ..writeln('---')
      ..writeln(lines.take(15).join('\n'));
  }
  var text = buf.toString();
  const maxLen = 1500;
  if (text.length > maxLen) {
    text = '${text.substring(0, maxLen)}\n…(생략)';
  }
  return text;
}

/// 제보용 mailto. 에러 정보를 본문에 미리 채워, 유저는 보내기만 누르면 된다.
/// 자동 정보를 본문에 보이게 넣어, 유저가 무엇을 보내는지 직접 확인할 수 있게 한다.
Uri buildReportUri(Object error, StackTrace? stack) {
  return Uri(
    scheme: 'mailto',
    path: kFeedbackEmail,
    queryParameters: {
      'subject': '[성경 전체 썰 읽으실분] 오류 제보',
      'body': '여기에 한마디 적어주셔도 됩니다 (안 적으셔도 돼요).\n\n\n'
          '— 아래는 문제 해결을 위한 자동 정보입니다 —\n'
          '${describeError(error, stack)}',
    },
  );
}

/// 메일 앱 실행. 실패하면(가능하면) 스낵바로 안내. context에 ScaffoldMessenger가
/// 없을 수도 있으므로(에러 위젯이 트리 밖에 박힐 때) maybeOf로 안전하게 처리.
Future<void> _sendReport(
  BuildContext context,
  Object error,
  StackTrace? stack,
) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  bool ok;
  try {
    ok = await launchUrl(buildReportUri(error, stack));
  } catch (_) {
    ok = false;
  }
  if (!ok) {
    messenger?.showSnackBar(
      const SnackBar(content: Text('메일 앱을 열 수 없습니다.')),
    );
  }
}

/// 앱 톤(잉크·세피아)의 차분한 오류 화면. 테마 컨텍스트가 살아있는 곳
/// (데이터 로드 실패, AsyncValue 에러 핸들러 등)에서 사용한다.
///
/// [onRetry]가 있으면 '다시 시도' 버튼을 보인다. [compact]는 탭/리스트 안에
/// 인라인으로 들어갈 때 여백을 줄인다.
class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    required this.error,
    this.stackTrace,
    this.onRetry,
    this.compact = false,
  });

  final Object error;
  final StackTrace? stackTrace;
  final VoidCallback? onRetry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = appColors(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.all(compact ? 20 : 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.sentiment_dissatisfied_outlined,
              size: compact ? 40 : 56,
              color: colors.inkSoft,
            ),
            SizedBox(height: compact ? 12 : 18),
            Text(
              '잠깐, 문제가 생겼어요',
              textAlign: TextAlign.center,
              style: handTextStyle(
                color: colors.ink,
                fontSize: compact ? 18 : 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '잠시 후 다시 시도해 주세요.\n계속 이러면 아래로 알려주시면 고쳐둘게요.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.inkSoft, height: 1.5),
            ),
            SizedBox(height: compact ? 16 : 24),
            if (onRetry != null) ...[
              FilledButton(
                onPressed: onRetry,
                style: FilledButton.styleFrom(
                  backgroundColor: colors.accent,
                  foregroundColor: colors.onAccent,
                ),
                child: const Text('다시 시도'),
              ),
              const SizedBox(height: 8),
            ],
            OutlinedButton.icon(
              onPressed: () => _sendReport(context, error, stackTrace),
              icon: const Icon(Icons.mail_outline, size: 18),
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.ink,
                side: BorderSide(color: colors.line),
              ),
              label: const Text('오류 제보하기'),
            ),
          ],
        ),
      ),
    );
  }
}

/// ErrorWidget.builder용 — MaterialApp/Theme 바깥에 박힐 수 있어 테마에 의존하지
/// 않고 색을 하드코딩한다. 자체 Material/Directionality로 자립한다.
class RawErrorView extends StatelessWidget {
  const RawErrorView({super.key, required this.error, this.stackTrace});

  final Object error;
  final StackTrace? stackTrace;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Material(
        color: _rawPaper,
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.sentiment_dissatisfied_outlined,
                    size: 56,
                    color: _rawInk,
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    '잠깐, 문제가 생겼어요',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _rawInk,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    '앱을 다시 켜 주세요.\n계속 이러면 아래로 알려주시면 고쳐둘게요.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _rawInk, height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: () => _sendReport(context, error, stackTrace),
                    icon: const Icon(Icons.mail_outline, size: 18),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _rawInk,
                      side: const BorderSide(color: _rawInk),
                    ),
                    label: const Text('오류 제보하기'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
