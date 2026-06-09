import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/update_providers.dart' show kReleasesLatestUrl;
import '../theme/app_theme.dart';
import 'artwork_credits_screen.dart';
import 'disclaimer_dialog.dart' show disclaimerLines;
import 'error_view.dart' show kAppVersion, kFeedbackEmail;

const _appVersion = kAppVersion;
const _feedbackEmail = kFeedbackEmail;

bool get _isDesktop =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS);
const _privacyUrl =
    'https://jungwonil11-jpg.github.io/bible-sseol/privacy.html';
const _termsUrl = 'https://jungwonil11-jpg.github.io/bible-sseol/terms.html';

/// 앱 소개·제작 의도·면책·피드백·정책·오픈소스 라이선스를 모은 정보 화면.
/// 설정 화면에서 진입한다.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  /// 피드백 메일. 메일 본문에 앱 버전을 미리 넣어 제보 디버깅을 돕는다.
  Uri get _feedbackUri => Uri(
        scheme: 'mailto',
        path: _feedbackEmail,
        queryParameters: {
          'subject': '[성경전체썰읽으실분] 피드백',
          'body': '앱 버전: $_appVersion\n\n— 아래에 의견을 적어주세요 —\n',
        },
      );

  Future<void> _open(
    BuildContext context,
    Uri uri, {
    LaunchMode mode = LaunchMode.platformDefault,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    bool ok;
    try {
      ok = await launchUrl(uri, mode: mode);
    } catch (_) {
      ok = false;
    }
    if (!ok) {
      messenger.showSnackBar(
        const SnackBar(content: Text('실행할 수 있는 앱이 없습니다.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = appColors(context);
    return Scaffold(
      appBar: AppBar(title: const Text('정보')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        children: [
          // ── 만든 이야기 + 면책 (디스클레이머와 같은 문구) ──
          _SectionLabel('만든 이야기'),
          const SizedBox(height: 10),
          for (final line in disclaimerLines)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('· ', style: TextStyle(color: colors.accent)),
                  Expanded(
                    child: Text(
                      line,
                      style: TextStyle(
                        color: colors.ink,
                        fontSize: 15,
                        height: 1.55,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 28),

          // ── 소통 · 약관 ──
          _SectionLabel('소통하기'),
          const SizedBox(height: 4),
          _Item(
            icon: Icons.mail_outline,
            label: '피드백 보내기',
            onTap: () => _open(context, _feedbackUri),
          ),
          // 데스크탑은 스토어가 없어 업데이트 경로가 이 링크뿐이다.
          // (모바일은 플레이스토어가 담당하므로 표시하지 않는다.)
          if (_isDesktop)
            _Item(
              icon: Icons.file_download_outlined,
              label: '최신 버전 확인 (GitHub)',
              onTap: () => _open(
                context,
                Uri.parse(kReleasesLatestUrl),
                mode: LaunchMode.externalApplication,
              ),
            ),
          _Item(
            icon: Icons.shield_outlined,
            label: '개인정보처리방침',
            onTap: () => _open(
              context,
              Uri.parse(_privacyUrl),
              mode: LaunchMode.externalApplication,
            ),
          ),
          _Item(
            icon: Icons.description_outlined,
            label: '이용약관',
            onTap: () => _open(
              context,
              Uri.parse(_termsUrl),
              mode: LaunchMode.externalApplication,
            ),
          ),
          _Item(
            icon: Icons.copyright_outlined,
            label: '오픈소스 라이선스',
            onTap: () => showLicensePage(
              context: context,
              applicationName: '성경전체썰읽으실분',
              applicationVersion: '버전 $_appVersion',
              applicationLegalese: '© 2026 Victor',
            ),
          ),
          _Item(
            icon: Icons.palette_outlined,
            label: '수록 명화 출처',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const ArtworkCreditsScreen(),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Center(
            child: Text(
              '버전 $_appVersion',
              style: TextStyle(color: colors.inkSoft, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = appColors(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: colors.accent),
      title: Text(label, style: TextStyle(color: colors.ink, fontSize: 16)),
      trailing: Icon(Icons.chevron_right, color: colors.inkSoft, size: 20),
      onTap: onTap,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: handTextStyle(
        color: appColors(context).ink,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
