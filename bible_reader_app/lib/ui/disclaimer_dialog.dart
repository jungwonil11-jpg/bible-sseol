import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// 디스클레이머 모달과 정보 화면이 공유하는 안내 문구(제작 의도 + 면책).
/// 한 곳에서만 고치면 두 화면에 동시 반영된다.
const disclaimerLines = <String>[
  '이 앱은 성경을 너무 읽고 싶지만 어려워서 아직 못 읽은 사람들을 위하여 만들었습니다.',
  '성경 이야기를 친구가 풀어주는 커뮤니티 말투로, 어떻게 하면 쉽게 읽힐까 깊이 고민하며 AI 기반으로 각색했습니다.',
  '특유의 가벼운 말투이므로 불편하시면 바로 삭제 부탁드립니다.',
  '말투는 가볍지만, 성경의 흐름과 사건은 원문을 기준으로 빠짐없이 담았습니다.',
  '공식 성경 번역이나 교단의 신학 해석이 아닙니다.',
  '정확한 교리는 소속 교단의 성경을 참고하세요.',
];

/// 최초 진입 시 뜨는 디스클레이머. 동의해야만 닫힘(뒤로가기 차단).
/// '다시 보지 않기'를 체크하고 동의해야만 다음 실행부터 안 뜬다.
class DisclaimerDialog extends StatefulWidget {
  const DisclaimerDialog({super.key, required this.onAgree});

  /// 동의 시 호출. 인자는 '다시 보지 않기' 체크 여부.
  final ValueChanged<bool> onAgree;

  @override
  State<DisclaimerDialog> createState() => _DisclaimerDialogState();
}

class _DisclaimerDialogState extends State<DisclaimerDialog> {
  bool _dontShowAgain = false;

  @override
  Widget build(BuildContext context) {
    final colors = appColors(context);
    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: colors.paper,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '📖 읽기 전에',
                textAlign: TextAlign.center,
                style: handTextStyle(
                  color: colors.accent,
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 18),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final line in disclaimerLines)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
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
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () =>
                    setState(() => _dontShowAgain = !_dontShowAgain),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Checkbox(
                        value: _dontShowAgain,
                        onChanged: (v) =>
                            setState(() => _dontShowAgain = v ?? false),
                        activeColor: colors.accent,
                        checkColor: colors.onAccent,
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '다시 보지 않기',
                        style: TextStyle(color: colors.ink, fontSize: 15),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              FilledButton(
                onPressed: () => widget.onAgree(_dontShowAgain),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 6),
                  child: Text('동의하고 시작하기'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
