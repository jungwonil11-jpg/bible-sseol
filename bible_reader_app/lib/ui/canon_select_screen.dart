import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/bible_data.dart';
import '../providers/settings_controller.dart';
import '../theme/app_theme.dart';

const _canonKeys = ['protestant', 'catholic', 'orthodox'];

/// 정경 선택 화면. 온보딩(최초 진입)과 설정 양쪽에서 쓴다.
/// - onboarding: 순서를 랜덤으로 섞고(형평성), 선택 후 "설정에서 바꿀 수 있다" 안내.
///   선택하면 `canonChosen`이 true가 되어 상위 게이트가 서재로 자동 전환한다.
/// - 설정: 고정 순서, 선택하면 바로 적용하고 화면을 닫는다(안내 생략).
class CanonSelectScreen extends ConsumerStatefulWidget {
  const CanonSelectScreen({
    super.key,
    required this.data,
    required this.onboarding,
  });

  final BibleData data;
  final bool onboarding;

  @override
  ConsumerState<CanonSelectScreen> createState() => _CanonSelectScreenState();
}

class _CanonSelectScreenState extends ConsumerState<CanonSelectScreen> {
  late final List<String> _order;

  @override
  void initState() {
    super.initState();
    _order = [..._canonKeys];
    // 온보딩에선 순서 때문에 특정 정경이 우대받는 인상을 주지 않도록 랜덤 섞기.
    if (widget.onboarding) {
      _order.shuffle(Random());
    }
  }

  Future<void> _onTap(String key, CanonInfo info) async {
    final apply = await showDialog<bool>(
      context: context,
      builder: (ctx) => _CanonDetailDialog(
        info: info,
        onboarding: widget.onboarding,
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
    // 설정: 이 선택 화면을 닫고 설정으로 돌아간다.
    if (!widget.onboarding) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = appColors(context);
    final selected = ref.watch(settingsControllerProvider.select((s) => s.canon));
    return Scaffold(
      appBar: widget.onboarding ? null : AppBar(title: const Text('정경 선택')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
          children: [
            if (widget.onboarding) ...[
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
            ],
            for (final key in _order)
              _CanonCard(
                info: widget.data.canonInfo[key]!,
                selected: !widget.onboarding && key == selected,
                onTap: () => _onTap(key, widget.data.canonInfo[key]!),
              ),
          ],
        ),
      ),
    );
  }
}

class _CanonCard extends StatelessWidget {
  const _CanonCard({
    required this.info,
    required this.selected,
    required this.onTap,
  });

  final CanonInfo info;
  final bool selected;
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
              color: selected ? colors.accent : colors.line,
              width: selected ? 2 : 1,
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
                      '${info.total}권',
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
          '정경은 설정에서 언제든 바꿀 수 있어요.',
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
