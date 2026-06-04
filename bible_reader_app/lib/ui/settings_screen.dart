import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/books_providers.dart';
import '../providers/database_providers.dart';
import '../providers/reading_providers.dart';
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

    // 섹션이 기본값과 같은지 — 같으면 헤더의 '기본값' 링크를 숨긴다.
    final displayIsDefault =
        settings.themeTone == defaultThemeTone && settings.brightness == 1.0;
    final bodyIsDefault = settings.fontFamily == defaultFontFamily &&
        settings.fontScale == 1.0 &&
        settings.lineHeight == defaultLineHeight &&
        settings.pageMargin == defaultPageMargin &&
        settings.letterSpacing == defaultLetterSpacing &&
        settings.wordSpacing == defaultWordSpacing;

    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: Column(
        children: [
          // ── 상단 고정 라이브 프리뷰 ──────────────
          _LivePreview(settings: settings, colors: colors),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
              children: [
                // ── 화면 (테마 + 밝기) ──
                const _GroupHeader('화면'),
                _RowGroup(
                  colors: colors,
                  footer: _DefaultCheck(
                    isDefault: displayIsDefault,
                    onReset: controller.resetDisplay,
                  ),
                  rows: [
                    _ThemeToneBar(
                      colors: colors,
                      tone: settings.themeTone,
                      onChanged: controller.setThemeTone,
                    ),
                    _SliderTile(
                      colors: colors,
                      label: '밝기',
                      valueText: '${(settings.brightness * 100).round()}%',
                      min: 0.0,
                      max: 1.0,
                      value: settings.brightness,
                      onChanged: controller.setBrightness,
                      leading: Icon(Icons.brightness_low,
                          color: colors.inkSoft, size: 18),
                      trailing: Icon(Icons.brightness_high,
                          color: colors.ink, size: 20),
                    ),
                  ],
                ),

                // ── 본문 (글씨체 + 크기 + 줄간격 + 여백) ──
                const _GroupHeader('본문'),
                _RowGroup(
                  colors: colors,
                  footer: _DefaultCheck(
                    isDefault: bodyIsDefault,
                    onReset: controller.resetBody,
                  ),
                  rows: [
                    _FontChips(
                      colors: colors,
                      fontFamily: settings.fontFamily,
                      onChanged: controller.setFontFamily,
                    ),
                    _SliderTile(
                      colors: colors,
                      label: '글자 크기',
                      valueText: '${(settings.fontScale * 100).round()}%',
                      min: fontScaleMin,
                      max: fontScaleMax,
                      value: settings.fontScale.clamp(fontScaleMin, fontScaleMax),
                      onChanged: controller.setFontScale,
                      leading: Text('A',
                          style: TextStyle(color: colors.inkSoft, fontSize: 15)),
                      trailing:
                          Text('A', style: TextStyle(color: colors.ink, fontSize: 21)),
                    ),
                    _SliderTile(
                      colors: colors,
                      label: '줄 간격',
                      valueText: settings.lineHeight.toStringAsFixed(2),
                      min: lineHeightMin,
                      max: lineHeightMax,
                      value:
                          settings.lineHeight.clamp(lineHeightMin, lineHeightMax),
                      onChanged: controller.setLineHeight,
                      leading: Icon(Icons.density_small,
                          color: colors.inkSoft, size: 18),
                      trailing: Icon(Icons.density_large,
                          color: colors.ink, size: 20),
                    ),
                    _SliderTile(
                      colors: colors,
                      label: '자간',
                      valueText: settings.letterSpacing.toStringAsFixed(1),
                      min: letterSpacingMin,
                      max: letterSpacingMax,
                      value: settings.letterSpacing
                          .clamp(letterSpacingMin, letterSpacingMax),
                      onChanged: controller.setLetterSpacing,
                      leading: Text('AA',
                          style: TextStyle(
                              color: colors.inkSoft,
                              fontSize: 14,
                              letterSpacing: 0)),
                      trailing: Text('AA',
                          style: TextStyle(
                              color: colors.ink, fontSize: 14, letterSpacing: 4)),
                    ),
                    _SliderTile(
                      colors: colors,
                      label: '어간',
                      valueText: settings.wordSpacing.toStringAsFixed(1),
                      min: wordSpacingMin,
                      max: wordSpacingMax,
                      value: settings.wordSpacing
                          .clamp(wordSpacingMin, wordSpacingMax),
                      onChanged: controller.setWordSpacing,
                      leading: Text('A A',
                          style: TextStyle(
                              color: colors.inkSoft,
                              fontSize: 14,
                              wordSpacing: 0)),
                      trailing: Text('A A',
                          style: TextStyle(
                              color: colors.ink, fontSize: 14, wordSpacing: 6)),
                    ),
                    _SliderTile(
                      colors: colors,
                      label: '좌우 여백',
                      valueText:
                          '${(((settings.pageMargin - pageMarginMin) / (pageMarginMax - pageMarginMin)) * 100).round()}%',
                      min: pageMarginMin,
                      max: pageMarginMax,
                      value:
                          settings.pageMargin.clamp(pageMarginMin, pageMarginMax),
                      onChanged: controller.setPageMargin,
                      leading: Icon(Icons.format_indent_increase,
                          color: colors.inkSoft, size: 18),
                      trailing: Icon(Icons.crop_portrait,
                          color: colors.ink, size: 20),
                    ),
                  ],
                ),

                // ── 정경 ──
                const _GroupHeader('정경'),
                _RowGroup(
                  colors: colors,
                  rows: [
                    if (data != null)
                      _NavTile(
                        colors: colors,
                        icon: Icons.menu_book_outlined,
                        title: data.canonInfo[settings.canon]?.name ?? '정경',
                        subtitle: '탭하여 변경',
                        // 홈버튼의 "현관"과 같은 화면으로 — 진입점은 둘, 화면은 하나.
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => CanonSelectScreen(
                              data: data,
                              mode: CanonSelectMode.home,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                // ── 앱 ──
                const _GroupHeader('앱'),
                _RowGroup(
                  colors: colors,
                  rows: [
                    _NavTile(
                      colors: colors,
                      icon: Icons.info_outline,
                      title: '정보',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AboutScreen()),
                      ),
                    ),
                  ],
                ),

                // ── 모든 기록 초기화 (DB 초기화) ──
                const SizedBox(height: 24),
                _RowGroup(
                  colors: colors,
                  rows: [
                    _ResetAllTile(
                      colors: colors,
                      onReset: () => _confirmAndWipeData(context, ref),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 모든 기록 초기화 — 체크박스 게이트 다이얼로그로 한 번 더 확인한 뒤 DB를 비운다.
Future<void> _confirmAndWipeData(BuildContext context, WidgetRef ref) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (_) => const _ResetDataDialog(),
  );
  if (ok == true) {
    await _wipeAllData(ref);
  }
}

/// 읽기 데이터(이어보기·읽음·책갈피·형광펜)를 전부 삭제하고 설정을 기본값으로.
/// 정경 선택·온보딩 플래그는 건드리지 않는다. 이후 관련 화면 상태를 새로고침.
Future<void> _wipeAllData(WidgetRef ref) async {
  await ref.read(readingProgressDaoProvider).clear();
  await ref.read(chapterReadStatusDaoProvider).clear();
  await ref.read(chapterFavoritesDaoProvider).clear();
  await ref.read(highlightsDaoProvider).clear();
  await ref.read(settingsControllerProvider.notifier).resetAll();

  // 화면에 보이는 파생 상태들(서재·통계·모아보기·이어보기) 새로고침.
  ref.invalidate(lastReadProvider);
  ref.invalidate(bookProgressProvider);
  ref.invalidate(allReadStatusProvider);
  ref.invalidate(bookReadStatusProvider);
  ref.invalidate(bookReadCountProvider);
  ref.invalidate(chapterFavoriteProvider);
  ref.invalidate(allFavoritesProvider);
  ref.invalidate(chapterHighlightsProvider);
  ref.invalidate(allHighlightsProvider);
}

/// '모든 기록 초기화' 확인 다이얼로그 — 지워질 항목을 명시하고,
/// '이해함' 체크를 켜야 [초기화] 버튼이 활성화된다(무심코 삭제 방지).
class _ResetDataDialog extends StatefulWidget {
  const _ResetDataDialog();

  @override
  State<_ResetDataDialog> createState() => _ResetDataDialogState();
}

class _ResetDataDialogState extends State<_ResetDataDialog> {
  bool _ack = false;

  @override
  Widget build(BuildContext context) {
    final colors = appColors(context);
    return AlertDialog(
      title: const Text('모든 기록 초기화'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('아래 기록이 영구 삭제되며 되돌릴 수 없습니다.'),
          const SizedBox(height: 10),
          Text(
            '· 이어보기 위치\n· 읽은 표시·통계\n· 책갈피\n· 형광펜',
            style: TextStyle(color: colors.inkSoft, height: 1.6),
          ),
          const SizedBox(height: 10),
          const Text('테마·글씨체는 기본값으로 돌아가고, 정경 선택은 유지됩니다.'),
          const SizedBox(height: 6),
          InkWell(
            onTap: () => setState(() => _ack = !_ack),
            child: Row(
              children: [
                Checkbox(
                  value: _ack,
                  onChanged: (v) => setState(() => _ack = v ?? false),
                ),
                const Expanded(child: Text('모두 영구 삭제됨을 이해함')),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('취소'),
        ),
        TextButton(
          onPressed: _ack ? () => Navigator.pop(context, true) : null,
          child: const Text('초기화'),
        ),
      ],
    );
  }
}

/// 상단 고정 프리뷰 — 현재 테마/글씨체/크기/줄간격/여백을 실제 본문처럼 즉시 반영.
/// 설정을 만지면 여기서 바로 결과가 보인다(Apple Books식).
class _LivePreview extends StatelessWidget {
  const _LivePreview({required this.settings, required this.colors});

  final AppSettings settings;
  final AppColors colors;

  static const _sample =
      '천지창조는 우주 스타트업 같은 거임. 자본금 0원, 직원 0명에서 시작함. '
      '첫 줄부터 "빛이 있으라" 한마디로 우주가 부팅됨. 이게 우리가 아는 그 창세기의 시작임.';

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 156,
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.paper,
        border: Border(bottom: BorderSide(color: colors.line)),
      ),
      child: ClipRect(
        child: Padding(
          padding: EdgeInsets.fromLTRB(settings.pageMargin, 16, settings.pageMargin, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'EPISODE 01',
                style: handTextStyle(
                  color: colors.accentSoft,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: Text(
                  _sample,
                  style: TextStyle(
                    fontFamily: settings.fontFamily,
                    color: colors.ink,
                    fontSize: 17 * settings.fontScale,
                    height: settings.lineHeight,
                    letterSpacing: settings.letterSpacing,
                    wordSpacing: settings.wordSpacing,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// iOS insetGrouped식 섹션 헤더(카드 위 작은 회색 라벨).
class _GroupHeader extends StatelessWidget {
  const _GroupHeader(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 22, 8, 7),
      child: Text(
        text,
        style: TextStyle(
          color: appColors(context).inkSoft,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

/// '기본값' 체크박스 — value=지금 기본값인가. 기본값이면 체크(상태 표시),
/// 변경됐으면 체크 풀림 + 캡션 강조(탭하면 그 영역을 기본값으로 복원).
/// 이미 기본값이면 탭 무시(되돌릴 게 없음).
class _DefaultCheck extends StatelessWidget {
  const _DefaultCheck({required this.isDefault, required this.onReset});

  final bool isDefault;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final colors = appColors(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: isDefault ? null : onReset,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 17,
            height: 17,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isDefault ? colors.accent : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: isDefault ? colors.accent : colors.inkSoft,
                width: 1.4,
              ),
            ),
            child: isDefault
                ? Icon(Icons.check, size: 13, color: colors.onAccent)
                : null,
          ),
          const SizedBox(width: 5),
          Text(
            '기본값',
            style: TextStyle(
              color: isDefault ? colors.inkSoft : colors.accent,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// 모든 기록 초기화 행(체크박스 게이트 다이얼로그를 거친다).
class _ResetAllTile extends StatelessWidget {
  const _ResetAllTile({required this.colors, required this.onReset});

  final AppColors colors;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onReset,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(Icons.restart_alt, color: colors.accent, size: 22),
            const SizedBox(width: 14),
            Text(
              '모든 기록 초기화',
              style: TextStyle(color: colors.ink, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

BoxDecoration _groupDecoration(AppColors colors) => BoxDecoration(
      color: colors.paperEdge,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: colors.line),
    );

/// 슬라이더/네비 같은 행들을 담는 그룹 카드. 행 사이에 들여쓴 구분선을 넣는다.
/// footer가 있으면 구분선 아래 우측 정렬로 붙인다(섹션 기본값 체크박스 등).
class _RowGroup extends StatelessWidget {
  const _RowGroup({required this.colors, required this.rows, this.footer});

  final AppColors colors;
  final List<Widget> rows;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final visible = rows.where((w) => w is! SizedBox).toList();
    final children = <Widget>[];
    for (var i = 0; i < visible.length; i++) {
      children.add(visible[i]);
      if (i != visible.length - 1) {
        children.add(Divider(
          height: 1,
          thickness: 1,
          indent: 16,
          color: colors.line,
        ));
      }
    }
    if (footer != null) {
      children.add(Divider(height: 1, thickness: 1, color: colors.line));
      children.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 9, 16, 9),
          child: Align(alignment: Alignment.centerRight, child: footer),
        ),
      );
    }
    return Container(
      decoration: _groupDecoration(colors),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

/// 테마 톤 바 — 라이트→세피아→다크 얇은 그라데이션 트랙 위 thumb로 한 줄에 고른다.
/// 비균등 단계로 스냅(themeToneStops). 다른 슬라이더와 두께·레이아웃을 통일.
class _ThemeToneBar extends StatelessWidget {
  const _ThemeToneBar({
    required this.colors,
    required this.tone,
    required this.onChanged,
  });

  final AppColors colors;
  final double tone;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final light = readingThemes[0].colors.paper;
    final sepia = readingThemes[1].colors.paper;
    final night = readingThemes[2].colors.paper;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('테마', style: TextStyle(color: colors.ink, fontSize: 15)),
          Row(
            children: [
              Icon(Icons.light_mode, color: colors.inkSoft, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // 얇은 그라데이션 트랙(라이트→세피아→다크).
                    Container(
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(color: colors.line),
                        gradient: LinearGradient(
                          colors: [light, sepia, night],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 0,
                        activeTrackColor: Colors.transparent,
                        inactiveTrackColor: Colors.transparent,
                        thumbColor: colors.accent,
                        overlayColor: colors.accent.withValues(alpha: 0.12),
                        overlayShape:
                            const RoundSliderOverlayShape(overlayRadius: 14),
                      ),
                      child: Slider(
                        value: tone.clamp(0.0, 1.0),
                        // 비균등 단계(themeToneStops)로 스냅 — 죽은 회색 구간 건너뜀.
                        onChanged: (v) => onChanged(snapThemeTone(v)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.dark_mode, color: colors.ink, size: 20),
            ],
          ),
        ],
      ),
    );
  }
}

/// 글씨체 스텝 슬라이더 — 6개 글씨체 지점에 스냅. 우측에 현재 글씨체 이름을
/// 그 글씨체로 렌더해 보여주고, 끌면 상단 라이브 프리뷰가 문장 전체로 반영한다.
/// 글씨체 선택 칩. 슬라이더(스텝)였으나 "현재값이 안 보이고 바로 못 고른다"는
/// 피드백으로 버튼식 전환 — 6종이 한눈에 보이고 탭 1번. 칩 라벨은 각자 자기
/// 글씨체로 렌더해 버튼 자체가 미리보기가 되게 한다.
/// 균등폭 격자: 좁은 화면(폰) 3×2, 넓은 화면(데스크탑·태블릿) 6×1 한 줄 —
/// 행 전체를 채워 슬라이더들과 같은 폭 리듬을 유지한다(가운데 붕 뜸 방지).
class _FontChips extends StatelessWidget {
  const _FontChips({
    required this.colors,
    required this.fontFamily,
    required this.onChanged,
  });

  final AppColors colors;
  final String? fontFamily;
  final ValueChanged<String?> onChanged;

  /// 6칸 한 줄이 무리 없는 최소 폭(칩당 ~100 + 간격). 미만이면 3×2.
  static const _sixColumnMinWidth = 640.0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('글씨체', style: TextStyle(color: colors.ink, fontSize: 15)),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final cols =
                  constraints.maxWidth >= _sixColumnMinWidth ? 6 : 3;
              final rows = <Widget>[];
              for (var i = 0; i < fontFamilyOptions.length; i += cols) {
                if (i > 0) {
                  rows.add(const SizedBox(height: 8));
                }
                rows.add(
                  Row(
                    children: [
                      for (var j = i;
                          j < i + cols && j < fontFamilyOptions.length;
                          j++) ...[
                        if (j > i) const SizedBox(width: 8),
                        Expanded(
                          child: _chip(
                            fontFamilyOptions[j],
                            fontFamilyOptions[j].$2 == fontFamily,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }
              return Column(children: rows);
            },
          ),
        ],
      ),
    );
  }

  Widget _chip((String, String?) option, bool selected) {
    return InkWell(
      onTap: () => onChanged(option.$2),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? colors.accent.withValues(alpha: 0.08)
              : colors.paperEdge,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? colors.accent : colors.line,
            width: selected ? 1.6 : 1,
          ),
        ),
        // 긴 이름(나눔스퀘어)이 좁은 칸에서 넘치지 않게 살짝만 줄여 맞춘다.
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            option.$1,
            style: TextStyle(
              fontFamily: option.$2,
              color: colors.ink,
              fontSize: 15,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

/// 라벨 + 값 표시 + 슬라이더 한 행. (양 끝 보조 아이콘 선택)
class _SliderTile extends StatelessWidget {
  const _SliderTile({
    required this.colors,
    required this.label,
    required this.valueText,
    required this.min,
    required this.max,
    required this.value,
    required this.onChanged,
    this.leading,
    this.trailing,
  });

  final AppColors colors;
  final String label;
  final String valueText;
  final double min;
  final double max;
  final double value;
  final ValueChanged<double> onChanged;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label, style: TextStyle(color: colors.ink, fontSize: 15)),
              const Spacer(),
              Text(
                valueText,
                style: TextStyle(
                  color: colors.inkSoft,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Row(
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: 6)],
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 2,
                    overlayShape:
                        const RoundSliderOverlayShape(overlayRadius: 14),
                  ),
                  child: Slider(
                    value: value,
                    min: min,
                    max: max,
                    activeColor: colors.accent,
                    inactiveColor: colors.line,
                    onChanged: onChanged,
                  ),
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 6), trailing!],
            ],
          ),
        ],
      ),
    );
  }
}

/// 탭하면 다른 화면으로 가는 네비 행(정경/정보 등).
class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.colors,
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  final AppColors colors;
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: colors.accent, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(color: colors.ink, fontSize: 16)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!,
                        style: TextStyle(color: colors.inkSoft, fontSize: 13)),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: colors.inkSoft, size: 20),
          ],
        ),
      ),
    );
  }
}
