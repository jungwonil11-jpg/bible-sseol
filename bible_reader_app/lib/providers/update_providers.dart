import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ui/error_view.dart' show kAppVersion;
import 'database_providers.dart';

/// 데스크탑 배포 저장소. 릴리스 latest 고정 URL은 항상 최신 릴리스로 간다.
const kReleasesLatestUrl =
    'https://github.com/jungwonil11-jpg/bible-sseol/releases/latest';
const _latestApiUrl =
    'https://api.github.com/repos/jungwonil11-jpg/bible-sseol/releases/latest';

/// 새 데스크탑 버전 정보.
class UpdateInfo {
  const UpdateInfo({required this.tag, required this.version, required this.url});

  /// 릴리스 태그 그대로 (예: v1.0.2-desktop) — 배너 dismiss 기록 키.
  final String tag;

  /// 표시용 버전 (예: 1.0.2).
  final String version;

  /// 릴리스 페이지 URL.
  final String url;
}

/// 태그 문자열에서 semver(x.y.z) 추출. 못 찾으면 null.
List<int>? _parseVersion(String s) {
  final m = RegExp(r'(\d+)\.(\d+)\.(\d+)').firstMatch(s);
  if (m == null) {
    return null;
  }
  return [int.parse(m[1]!), int.parse(m[2]!), int.parse(m[3]!)];
}

bool _isNewer(List<int> a, List<int> b) {
  for (var i = 0; i < 3; i++) {
    if (a[i] != b[i]) {
      return a[i] > b[i];
    }
  }
  return false;
}

/// 실행 시 1회, GitHub 릴리스 latest 태그를 확인해 현재 버전보다 새 데스크탑
/// 버전이 있으면 알려준다. 데스크탑 전용(모바일은 스토어가 업데이트 담당).
/// 오프라인 단독 앱 철학 유지: 실패는 전부 침묵(null), 보내는 정보 0,
/// 타임아웃 5초. 유저를 기다리게 하는 경로에 끼어들지 않는다.
final updateInfoProvider = FutureProvider<UpdateInfo?>((ref) async {
  final isDesktop = !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.macOS);
  if (!isDesktop) {
    return null;
  }
  final current = _parseVersion(kAppVersion);
  if (current == null) {
    return null;
  }
  try {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
    try {
      final request = await client.getUrl(Uri.parse(_latestApiUrl));
      // GitHub API는 User-Agent가 없으면 403을 준다.
      request.headers.set(HttpHeaders.userAgentHeader, 'bible-sseol-app');
      request.headers.set(HttpHeaders.acceptHeader, 'application/vnd.github+json');
      final response = await request.close().timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) {
        return null;
      }
      final body = await response
          .transform(utf8.decoder)
          .join()
          .timeout(const Duration(seconds: 5));
      final json = jsonDecode(body) as Map<String, dynamic>;
      final tag = json['tag_name'] as String? ?? '';
      final latest = _parseVersion(tag);
      if (latest == null || !_isNewer(latest, current)) {
        return null;
      }
      return UpdateInfo(
        tag: tag,
        version: latest.join('.'),
        url: (json['html_url'] as String?) ?? kReleasesLatestUrl,
      );
    } finally {
      client.close();
    }
  } catch (_) {
    return null; // 오프라인/차단/형식 오류 — 전부 조용히 없음 처리.
  }
});

const _kDismissedUpdateTag = 'dismissed_update_tag';

/// 유저가 배너를 닫은 릴리스 태그 — 그 버전은 다시 알리지 않는다.
final dismissedUpdateTagProvider = FutureProvider<String?>((ref) async {
  return ref.watch(settingsDaoProvider).get(_kDismissedUpdateTag);
});

/// 배너 닫기: 태그를 기록하고 관련 상태를 새로고침.
Future<void> dismissUpdate(WidgetRef ref, String tag) async {
  await ref.read(settingsDaoProvider).set(_kDismissedUpdateTag, tag);
  ref.invalidate(dismissedUpdateTagProvider);
}
