import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/bible_data.dart';
import '../providers/settings_controller.dart';
import '../theme/app_theme.dart';

const _canonKeys = ['protestant', 'catholic', 'orthodox'];

/// 정경 선택 화면의 진입 맥락.
enum CanonSelectMode {
  /// 최초 진입 온보딩 — 순서 랜덤(형평성), 못 빠져나감, 적용 후 안내 모달.
  onboarding,

  /// "현관" — 온보딩과 같은 인사 화면을 다시 보여주되, ✕로 안 고르고
  /// 나올 수 있고 현재 정경에 "지금 읽는 중"을 표시한다.
  /// 서재 홈버튼과 설정의 정경 행 양쪽에서 이 모드로 진입한다(화면 일원화).
  home,
}

/// 정경 선택 화면. 온보딩(최초 진입)과 현관(서재 홈버튼·설정) 두 모드.
class CanonSelectScreen extends ConsumerStatefulWidget {
  const CanonSelectScreen({
    super.key,
    required this.data,
    required this.mode,
  });

  final BibleData data;
  final CanonSelectMode mode;

  @override
  ConsumerState<CanonSelectScreen> createState() => _CanonSelectScreenState();
}

class _CanonSelectScreenState extends ConsumerState<CanonSelectScreen> {
  late final List<String> _order;

  bool get _onboarding => widget.mode == CanonSelectMode.onboarding;

  @override
  void initState() {
    super.initState();
    _order = [..._canonKeys];
    // 온보딩에선 순서 때문에 특정 정경이 우대받는 인상을 주지 않도록 랜덤 섞기.
    if (_onboarding) {
      _order.shuffle(Random());
    }
  }

  Future<void> _onTap(String key, CanonInfo info) async {
    final apply = await showDialog<bool>(
      context: context,
      builder: (ctx) => _CanonDetailDialog(
        info: info,
        onboarding: _onboarding,
      ),
    );
    if (apply != true) {
      return;
    }
    await ref.read(settingsControllerProvider.notifier).chooseCanon(key);
    if (!mounted) {
      return;
    }
    // 온보딩: canonChosen=true가 되면 상위 게이트가 서재로 전환한다.
    // 현관: 이 선택 화면을 닫고 이전 화면(서재/설정)으로 돌아간다.
    if (!_onboarding) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = appColors(context);
    final selected = ref.watch(settingsControllerProvider.select((s) => s.canon));
    return Scaffold(
      // 현관: 제목 없이 ✕만 — "구경만 하고 닫기"가 가능함을 드러낸다.
      appBar: _onboarding
          ? null
          : AppBar(
              leading: IconButton(
                tooltip: '닫기',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ),
      // 데스크탑·태블릿에서 카드가 가로로 끝없이 늘어나지 않게 가운데 폭으로.
      body: SafeArea(
        child: centerConstrained(
          maxWidth: kReaderMaxWidth,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
            children: [
              Text(
                '어떤 성경으로\n읽을까요?',
                style: handTextStyle(
                  color: colors.accent,
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '전통마다 범위가 조금씩 달라요.',
                style: TextStyle(color: colors.inkSoft, height: 1.5),
              ),
              const SizedBox(height: 28),
              for (final key in _order)
                _CanonCard(
                  info: widget.data.canonInfo[key]!,
                  // 현관에선 현재 읽는 정경을 강조 표시. 온보딩은 첫 선택이라 없음.
                  current: !_onboarding && key == selected,
                  onTap: () => _onTap(key, widget.data.canonInfo[key]!),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CanonCard extends StatelessWidget {
  const _CanonCard({
    required this.info,
    required this.current,
    required this.onTap,
  });

  final CanonInfo info;

  /// 현재 읽고 있는 정경 — 테두리 강조 + "지금 읽는 중" 표기.
  final bool current;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = appColors(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          decoration: BoxDecoration(
            color: colors.paperEdge,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: current ? colors.accent : colors.line,
              width: current ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      info.name,
                      style: handTextStyle(
                        color: colors.ink,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      current ? '${info.total}권 · 지금 읽는 중' : '${info.total}권',
                      style: TextStyle(color: colors.inkSoft, fontSize: 14),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: colors.inkSoft),
            ],
          ),
        ),
      ),
    );
  }
}

/// 정경 설명 다이얼로그. 온보딩이면 "이 정경으로 읽기" → 안내 페이지로 전환 후 확정.
/// 닫힐 때 적용 여부(true/false/null)를 반환한다.
class _CanonDetailDialog extends StatefulWidget {
  const _CanonDetailDialog({required this.info, required this.onboarding});

  final CanonInfo info;
  final bool onboarding;

  @override
  State<_CanonDetailDialog> createState() => _CanonDetailDialogState();
}

class _CanonDetailDialogState extends State<_CanonDetailDialog> {
  bool _applied = false;

  @override
  Widget build(BuildContext context) {
    final colors = appColors(context);
    final info = widget.info;

    // 온보딩 2단계: 적용 후 안내 페이지.
    if (_applied) {
      return AlertDialog(
        backgroundColor: colors.paperEdge,
        content: Text(
          '정경은 서재 왼쪽 위의 집 모양 버튼에서 언제든 바꿀 수 있어요.',
          style: TextStyle(color: colors.ink, height: 1.5),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('시작'),
          ),
        ],
      );
    }

    return AlertDialog(
      backgroundColor: colors.paperEdge,
      title: Text(
        '${info.name}  ·  ${info.total}권',
        style: handTextStyle(
          color: colors.accent,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (info.denominations.trim().isNotEmpty) ...[
              Text(
                info.denominations,
                style: TextStyle(color: colors.inkSoft, fontSize: 13),
              ),
              const SizedBox(height: 12),
            ],
            Text(
              info.desc,
              style: TextStyle(color: colors.ink, fontSize: 15, height: 1.6),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: () {
            if (widget.onboarding) {
              setState(() => _applied = true);
            } else {
              Navigator.of(context).pop(true);
            }
          },
          child: Text(widget.onboarding ? '이 정경으로 읽기' : '이 정경으로 변경'),
        ),
      ],
    );
  }
}
