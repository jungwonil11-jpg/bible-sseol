import 'package:flutter/material.dart';

class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.paper,
    required this.paperEdge,
    required this.ink,
    required this.inkSoft,
    required this.accent,
    required this.accentSoft,
    required this.onAccent,
    required this.line,
    required this.quoteBg,
  });

  final Color paper; // 화면 배경(책 종이)
  final Color paperEdge; // 카드/리스트 표면
  final Color ink; // 본문 글자
  final Color inkSoft; // 보조 글자
  final Color accent; // 강조(거의 잉크색 — 컬러를 쓰지 않는 무채색 톤)
  final Color accentSoft; // 죽인 강조(라벨/구분 보조)
  final Color onAccent; // accent 위에 올라가는 글자색(다크 테마 대응)
  final Color line; // 구분선
  final Color quoteBg; // 인용/박스 배경

  @override
  AppColors copyWith({
    Color? paper,
    Color? paperEdge,
    Color? ink,
    Color? inkSoft,
    Color? accent,
    Color? accentSoft,
    Color? onAccent,
    Color? line,
    Color? quoteBg,
  }) {
    return AppColors(
      paper: paper ?? this.paper,
      paperEdge: paperEdge ?? this.paperEdge,
      ink: ink ?? this.ink,
      inkSoft: inkSoft ?? this.inkSoft,
      accent: accent ?? this.accent,
      accentSoft: accentSoft ?? this.accentSoft,
      onAccent: onAccent ?? this.onAccent,
      line: line ?? this.line,
      quoteBg: quoteBg ?? this.quoteBg,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) {
      return this;
    }
    return AppColors(
      paper: Color.lerp(paper, other.paper, t)!,
      paperEdge: Color.lerp(paperEdge, other.paperEdge, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      inkSoft: Color.lerp(inkSoft, other.inkSoft, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      line: Color.lerp(line, other.line, t)!,
      quoteBg: Color.lerp(quoteBg, other.quoteBg, t)!,
    );
  }
}

/// 리딩 테마 하나 = 배경/글자색 조합 + 명암(라이트/다크). Apple Books 스타일.
class ReadingTheme {
  const ReadingTheme({
    required this.id,
    required this.label,
    required this.colors,
    required this.dark,
  });

  final String id;
  final String label;
  final AppColors colors;
  final bool dark;
}

/// 무채색/세피아 4종. 액센트는 컬러가 아니라 '거의 잉크색'으로 둬서
/// 제목·강조가 검정에 가깝게 보이는 문학적 톤을 만든다(컬러 최소화).
const readingThemes = <ReadingTheme>[
  ReadingTheme(
    id: 'original',
    label: '라이트',
    dark: false,
    colors: AppColors(
      paper: Color(0xfffbfaf8),
      paperEdge: Color(0xffffffff),
      ink: Color(0xff20201e),
      inkSoft: Color(0xff6f6a63),
      accent: Color(0xff35302a),
      accentSoft: Color(0xffa39c90),
      onAccent: Color(0xfffbfaf8),
      line: Color(0xffeae6e0),
      quoteBg: Color(0xfff3f1ec),
    ),
  ),
  ReadingTheme(
    id: 'sepia',
    label: '세피아',
    dark: false,
    colors: AppColors(
      paper: Color(0xffe4d5b7),
      paperEdge: Color(0xffece0c6),
      ink: Color(0xff443720),
      inkSoft: Color(0xff786a4e),
      accent: Color(0xff2c2415),
      accentSoft: Color(0xff97835f),
      onAccent: Color(0xffece0c6),
      line: Color(0xffd2c09a),
      quoteBg: Color(0xffdccda8),
    ),
  ),
  ReadingTheme(
    id: 'night',
    label: '나이트',
    dark: true,
    colors: AppColors(
      paper: Color(0xff0c0c0c),
      paperEdge: Color(0xff181818),
      ink: Color(0xffdad6ce),
      inkSoft: Color(0xff8b867d),
      accent: Color(0xffe8e2d6),
      accentSoft: Color(0xff6b645a),
      onAccent: Color(0xff0c0c0c),
      line: Color(0xff242424),
      quoteBg: Color(0xff161616),
    ),
  ),
];

const defaultReadingTheme = 'original';

ReadingTheme readingThemeById(String id) {
  for (final t in readingThemes) {
    if (t.id == id) {
      return t;
    }
  }
  return readingThemes.first;
}

/// 라이트(0.0) → 세피아(0.5) → 다크(1.0) 연속 톤. 테마를 슬라이더 한 줄로 고른다.
/// 단순 보간은 세피아↔다크 중간에서 종이·글자가 같이 회색이 돼 본문이 안 읽히므로,
/// 배경이 충분히 어두워지면 글자/강조색만 나이트(밝은 글자)로 갈아끼워 대비를 지킨다.
AppColors toneColors(double tone) {
  final t = tone.clamp(0.0, 1.0);
  final light = readingThemes[0].colors;
  final sepia = readingThemes[1].colors;
  final night = readingThemes[2].colors;
  final base = t <= 0.5
      ? light.lerp(sepia, t / 0.5)
      : sepia.lerp(night, (t - 0.5) / 0.5);
  if (base.paper.computeLuminance() < _darkPaperThreshold) {
    return base.copyWith(
      ink: night.ink,
      inkSoft: night.inkSoft,
      accent: night.accent,
      accentSoft: night.accentSoft,
      onAccent: night.onAccent,
    );
  }
  return base;
}

/// 톤이 다크 영역(어두운 종이)에 들어갔는지. 상태바 밝기·다크토글 판정에 쓴다.
bool toneIsDark(double tone) =>
    toneColors(tone).paper.computeLuminance() < _darkPaperThreshold;

const _darkPaperThreshold = 0.42;

/// 연속 톤(0~1)으로 앱 전체 테마를 만든다. main에서 themeTone을 받아 호출.
ThemeData buildToneTheme({required double tone, String? fontFamily}) {
  return _themeFromColors(
    colors: toneColors(tone),
    dark: toneIsDark(tone),
    fontFamily: fontFamily,
  );
}

ThemeData buildAppTheme({required ReadingTheme theme, String? fontFamily}) {
  return _themeFromColors(
    colors: theme.colors,
    dark: theme.dark,
    fontFamily: fontFamily,
  );
}

ThemeData _themeFromColors({
  required AppColors colors,
  required bool dark,
  String? fontFamily,
}) {
  final brightness = dark ? Brightness.dark : Brightness.light;
  final base = ThemeData(
    brightness: brightness,
    // 앱 전체 기본 글씨체. null이면 시스템 폰트. 제목/본문/버튼/칩이 모두 이걸 따른다.
    fontFamily: fontFamily,
    colorScheme: ColorScheme.fromSeed(
      seedColor: colors.accent,
      brightness: brightness,
    ),
    scaffoldBackgroundColor: colors.paper,
    useMaterial3: true,
    extensions: [colors],
  );
  return base.copyWith(
    appBarTheme: AppBarTheme(
      backgroundColor: colors.paper,
      foregroundColor: colors.ink,
      centerTitle: true,
      titleTextStyle: handTextStyle(
        fontFamily: fontFamily,
        color: colors.ink,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      elevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: colors.paperEdge,
      selectedColor: colors.accent,
      labelStyle: handTextStyle(
        fontFamily: fontFamily,
        color: colors.ink,
        fontSize: 16,
      ),
      side: BorderSide(color: colors.line),
    ),
    dividerTheme: DividerThemeData(color: colors.line),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        textStyle: handTextStyle(
          fontFamily: fontFamily,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        foregroundColor: colors.ink,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: colors.accent,
        foregroundColor: colors.onAccent,
        textStyle: handTextStyle(
          fontFamily: fontFamily,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}

AppColors appColors(BuildContext context) {
  return Theme.of(context).extension<AppColors>()!;
}

/// 큰 화면(데스크탑·태블릿·폴드 펼침)에서 본문/목록이 가로로 끝없이 늘어나지
/// 않도록 가운데에 모으는 최대 폭. 화면이 이보다 좁으면(폰) 그대로 꽉 채운다.
const double kReaderMaxWidth = 720;
const double kLibraryMaxWidth = 860;

/// [child] 를 화면 가운데 [maxWidth] 안으로 제한해 감싼다. 좁은 화면에선 영향 없음.
Widget centerConstrained({required double maxWidth, required Widget child}) {
  return Center(
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    ),
  );
}

/// 제목/헤더용 스타일. 글씨체는 ThemeData.fontFamily를 상속받도록 비워둔다.
/// (테마 정의 내부에서만 명시적 family를 넘겨 일관성을 보장한다.)
TextStyle handTextStyle({
  Color? color,
  double? fontSize,
  FontWeight? fontWeight,
  String? fontFamily,
}) {
  return TextStyle(
    fontFamily: fontFamily,
    color: color,
    fontSize: fontSize,
    fontWeight: fontWeight,
  );
}
