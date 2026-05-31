import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/books_providers.dart';
import '../providers/settings_controller.dart';
import '../theme/app_theme.dart';
import 'about_screen.dart';
import 'canon_select_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = appColors(context);
    final settings = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);
    final data = ref
        .watch(bibleDataProvider)
        .maybeWhen(data: (d) => d, orElse: () => null);
    // 카드 3개를 한 줄에. 좌우 패딩 24*2 + 카드 사이 간격 2*10 을 뺀 폭을 3등분.
    final cardWidth = (MediaQuery.of(context).size.width - 48 - 20) / 3;

    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        children: [
          // ── 밝기 ──────────────────────────────
          _SectionLabel('밝기'),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.brightness_low, color: colors.inkSoft, size: 20),
              Expanded(
                child: Slider(
                  value: settings.brightness,
                  min: 0.0,
                  max: 1.0,
                  activeColor: colors.accent,
                  inactiveColor: colors.line,
                  onChanged: controller.setBrightness,
                ),
              ),
              Icon(Icons.brightness_high, color: colors.ink, size: 22),
            ],
          ),
          const SizedBox(height: 24),

          // ── 본문 글자 크기 (슬라이더 + 미리보기) ──
          _SectionLabel('본문 글자 크기'),
          const SizedBox(height: 4),
          Row(
            children: [
              Text('A', style: TextStyle(color: colors.inkSoft, fontSize: 15)),
              Expanded(
                child: Slider(
                  value: settings.fontScale.clamp(fontScaleMin, fontScaleMax),
                  min: fontScaleMin,
                  max: fontScaleMax,
                  activeColor: colors.accent,
                  inactiveColor: colors.line,
                  onChanged: controller.setFontScale,
                ),
              ),
              Text('A', style: TextStyle(color: colors.ink, fontSize: 24)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.quoteBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '미리보기: 천지창조는 우주 스타트업 같은 거임. 자본금 0원에서 시작함.',
              style: TextStyle(
                color: colors.ink,
                fontSize: 17 * settings.fontScale,
                height: 1.8,
              ),
            ),
          ),
          const SizedBox(height: 28),

          // ── 글씨체 ─────────────────────────────
          _SectionLabel('글씨체'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 14,
            children: [
              for (final (label, family) in fontFamilyOptions)
                _SwatchCard(
                  width: cardWidth,
                  previewText: label,
                  selected: settings.fontFamily == family,
                  onTap: () => controller.setFontFamily(family),
                  boxColor: colors.paperEdge,
                  previewColor: colors.ink,
                  borderColor: colors.line,
                  previewStyle: TextStyle(
                    fontFamily: family,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 28),

          // ── 테마 ──────────────────────────────
          _SectionLabel('테마'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 14,
            children: [
              for (final theme in readingThemes)
                _SwatchCard(
                  width: cardWidth,
                  previewText: theme.label,
                  selected: settings.readingTheme == theme.id,
                  onTap: () => controller.setReadingTheme(theme.id),
                  boxColor: theme.colors.paper,
                  previewColor: theme.colors.ink,
                  borderColor: colors.line,
                  previewStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 28),

          // ── 정경 ───────────────────────────────
          _SectionLabel('정경'),
          const SizedBox(height: 4),
          if (data != null)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.menu_book_outlined, color: colors.accent),
              title: Text(
                data.canonInfo[settings.canon]?.name ?? '정경',
                style: TextStyle(color: colors.ink, fontSize: 16),
              ),
              subtitle: Text(
                '탭하여 변경',
                style: TextStyle(color: colors.inkSoft),
              ),
              trailing: Icon(Icons.chevron_right, color: colors.inkSoft, size: 20),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CanonSelectScreen(data: data, onboarding: false),
                ),
              ),
            ),
          const SizedBox(height: 28),

          // ── 앱 정보 ─────────────────────────────
          _SectionLabel('앱'),
          const SizedBox(height: 4),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.info_outline, color: colors.accent),
            title: Text(
              '정보',
              style: TextStyle(color: colors.ink, fontSize: 16),
            ),
            trailing: Icon(Icons.chevron_right, color: colors.inkSoft, size: 20),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AboutScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

/// 애플북스식 스와치 카드 — 박스 안에 이름/샘플을 그 폰트·테마색으로 렌더.
/// 선택 시 테두리 강조. 긴 이름은 FittedBox로 자동 축소해 넘침 방지.
class _SwatchCard extends StatelessWidget {
  const _SwatchCard({
    required this.width,
    required this.previewText,
    required this.selected,
    required this.onTap,
    required this.boxColor,
    required this.previewColor,
    required this.previewStyle,
    required this.borderColor,
  });

  final double width;
  final String previewText;
  final bool selected;
  final VoidCallback onTap;
  final Color boxColor;
  final Color previewColor;
  final TextStyle previewStyle;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final colors = appColors(context);
    return SizedBox(
      width: width,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 56,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: boxColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? colors.accent : borderColor,
              width: selected ? 2 : 1,
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              previewText,
              maxLines: 1,
              style: previewStyle.copyWith(color: previewColor),
            ),
          ),
        ),
      ),
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
