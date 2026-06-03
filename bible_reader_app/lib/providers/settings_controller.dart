import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_theme.dart';
import 'database_providers.dart';

/// 본문 글자 크기 — 슬라이더 연속값 범위(기본 1.0).
const fontScaleMin = 0.8;
const fontScaleMax = 1.6;

/// 리딩 테마 연속 톤. 0.0=라이트 → 0.5=세피아 → 1.0=다크.
const defaultThemeTone = 0.0;

/// 테마 슬라이더가 스냅하는 단계값. 균등 분할이 아니라 가독성 죽은 구간
/// (중간 회색 종이, 톤 0.63~0.78)을 건너뛰도록 비균등 배치한다.
/// 0.5(세피아)→0.85(다크그레이) 사이를 한 번에 점프해 그 구간에 stop을 두지 않는다.
const themeToneStops = <double>[0.0, 0.25, 0.5, 0.85, 1.0];

/// 임의의 톤을 가장 가까운 단계값으로 스냅.
double snapThemeTone(double value) {
  var best = themeToneStops.first;
  for (final s in themeToneStops) {
    if ((value - s).abs() < (value - best).abs()) {
      best = s;
    }
  }
  return best;
}

/// 본문 줄 간격(TextStyle.height) — 슬라이더 범위(기본 1.85).
const lineHeightMin = 1.4;
const lineHeightMax = 2.3;
const defaultLineHeight = 1.85;

/// 본문 좌우 여백(px) — 리더 본문 가로 패딩(기본 20).
const pageMarginMin = 12.0;
const pageMarginMax = 44.0;
const defaultPageMargin = 20.0;

/// 본문 자간(TextStyle.letterSpacing, px) — 글자 사이 간격(기본 0).
const letterSpacingMin = -0.5;
const letterSpacingMax = 2.0;
const defaultLetterSpacing = 0.0;

/// 본문 어간(TextStyle.wordSpacing, px) — 띄어쓰기 칸만 넓힘(기본 0).
const wordSpacingMin = 0.0;
const wordSpacingMax = 8.0;
const defaultWordSpacing = 0.0;

/// 화면 밝기 — 인앱 딜밍 오버레이. 1.0=가장 밝음(오버레이 없음), 0.0=가장 어두움.
/// 실제 검정 오버레이 불투명도는 (1 - brightness) * _dimMax 로 환산.
const dimMax = 0.6;

/// 글씨체 선택지. (라벨, ThemeData.fontFamily에 들어갈 패밀리명).
/// family가 null이면 시스템 기본 폰트를 쓴다. 기본값은 마루부리.
// 슬라이더 축 순서: 명조 → 고딕 → 손글씨 → 시스템. 기본(마루부리)이 맨 앞.
const fontFamilyOptions = <(String label, String? family)>[
  ('마루부리', 'MaruBuri'),
  ('나눔명조', 'NanumMyeongjo'),
  ('나눔스퀘어', 'NanumSquare'),
  ('나눔고딕', 'NanumGothic'),
  ('감자', 'GamjaFlower'),
  ('시스템', null),
];
const defaultFontFamily = 'MaruBuri';

/// '시스템'(family null)을 DB에 저장할 때 쓰는 표식. null과 미설정을 구분하기 위함.
const _systemFontToken = 'system';

class AppSettings {
  const AppSettings({
    this.canon = 'protestant',
    this.themeTone = defaultThemeTone,
    this.fontScale = 1.0,
    this.lineHeight = defaultLineHeight,
    this.pageMargin = defaultPageMargin,
    this.letterSpacing = defaultLetterSpacing,
    this.wordSpacing = defaultWordSpacing,
    this.brightness = 1.0,
    this.fontFamily = defaultFontFamily,
    this.disclaimerAgreed = false,
    this.canonChosen = false,
    this.loaded = false,
  });

  final String canon;

  /// 리딩 테마 연속 톤. 0.0=라이트 → 0.5=세피아 → 1.0=다크. 슬라이더 한 줄로 조절.
  final double themeTone;
  final double fontScale;

  /// 본문 줄 간격(TextStyle.height).
  final double lineHeight;

  /// 본문 좌우 여백(px). 리더 본문 ListView의 가로 패딩.
  final double pageMargin;

  /// 본문 자간(TextStyle.letterSpacing, px).
  final double letterSpacing;

  /// 본문 어간(TextStyle.wordSpacing, px) — 띄어쓰기 칸 폭.
  final double wordSpacing;

  /// 화면 밝기(1.0=밝음 ~ 0.0=어두움). 인앱 딜밍 오버레이로 적용.
  final double brightness;

  /// 앱 전체에 적용할 글씨체(ThemeData.fontFamily). null이면 시스템 기본.
  final String? fontFamily;

  /// 최초 진입 디스클레이머 모달에 동의했는지.
  final bool disclaimerAgreed;

  /// 온보딩에서 정경을 한 번이라도 선택했는지(false면 정경 선택 화면을 띄운다).
  final bool canonChosen;

  /// SettingsDao에서 1차 로드가 끝났는지. 첫 프레임 깜빡임 방지용.
  final bool loaded;

  AppSettings copyWith({
    String? canon,
    double? themeTone,
    double? fontScale,
    double? lineHeight,
    double? pageMargin,
    double? letterSpacing,
    double? wordSpacing,
    double? brightness,
    // fontFamily는 null(시스템)을 명시적으로 설정할 수 있어야 해서 sentinel을 쓴다.
    // 인자를 안 넘기면 기존값 유지, null을 넘기면 시스템 폰트로.
    Object? fontFamily = _unset,
    bool? disclaimerAgreed,
    bool? canonChosen,
    bool? loaded,
  }) {
    return AppSettings(
      canon: canon ?? this.canon,
      themeTone: themeTone ?? this.themeTone,
      fontScale: fontScale ?? this.fontScale,
      lineHeight: lineHeight ?? this.lineHeight,
      pageMargin: pageMargin ?? this.pageMargin,
      letterSpacing: letterSpacing ?? this.letterSpacing,
      wordSpacing: wordSpacing ?? this.wordSpacing,
      brightness: brightness ?? this.brightness,
      fontFamily: identical(fontFamily, _unset)
          ? this.fontFamily
          : fontFamily as String?,
      disclaimerAgreed: disclaimerAgreed ?? this.disclaimerAgreed,
      canonChosen: canonChosen ?? this.canonChosen,
      loaded: loaded ?? this.loaded,
    );
  }
}

/// copyWith에서 "인자 미전달"과 "null로 설정"을 구분하기 위한 표식.
const Object _unset = Object();

/// 정경/다크모드/폰트크기를 settings 테이블에 영속화하는 컨트롤러.
class SettingsController extends Notifier<AppSettings> {
  static const _kCanon = 'canon';
  static const _kDark = 'dark_mode'; // 구버전 키 — 마이그레이션용으로만 읽는다.
  static const _kReadingTheme = 'reading_theme'; // 구버전 키 — 마이그레이션용.
  static const _kThemeTone = 'theme_tone';
  static const _kFontScale = 'font_scale';
  static const _kLineHeight = 'line_height';
  static const _kPageMargin = 'page_margin';
  static const _kLetterSpacing = 'letter_spacing';
  static const _kWordSpacing = 'word_spacing';
  static const _kBrightness = 'brightness';
  static const _kFontFamily = 'font_family';
  static const _kDisclaimer = 'disclaimer_agreed';
  static const _kCanonChosen = 'canon_chosen';

  @override
  AppSettings build() {
    _load();
    return const AppSettings();
  }

  Future<void> _load() async {
    final dao = ref.read(settingsDaoProvider);
    final canon = await dao.get(_kCanon);
    final themeTone = await dao.get(_kThemeTone);
    final readingTheme = await dao.get(_kReadingTheme);
    final dark = await dao.get(_kDark);
    final fontScale = await dao.get(_kFontScale);
    final lineHeight = await dao.get(_kLineHeight);
    final pageMargin = await dao.get(_kPageMargin);
    final letterSpacing = await dao.get(_kLetterSpacing);
    final wordSpacing = await dao.get(_kWordSpacing);
    final brightness = await dao.get(_kBrightness);
    final fontFamily = await dao.get(_kFontFamily);
    final disclaimer = await dao.get(_kDisclaimer);
    final canonChosen = await dao.get(_kCanonChosen);
    state = AppSettings(
      canon: canon ?? 'protestant',
      // theme_tone이 없으면 구버전 reading_theme/dark_mode를 톤으로 환산.
      // night/dark→1.0, sepia→0.5, 그 외→0.0(라이트).
      themeTone: themeTone != null
          ? (double.tryParse(themeTone) ?? defaultThemeTone)
          : (readingTheme == 'night' || (readingTheme == null && dark == '1')
              ? 1.0
              : (readingTheme == 'sepia' ? 0.5 : defaultThemeTone)),
      fontScale: fontScale == null
          ? 1.0
          : (double.tryParse(fontScale) ?? 1.0),
      lineHeight: lineHeight == null
          ? defaultLineHeight
          : (double.tryParse(lineHeight) ?? defaultLineHeight),
      pageMargin: pageMargin == null
          ? defaultPageMargin
          : (double.tryParse(pageMargin) ?? defaultPageMargin),
      letterSpacing: letterSpacing == null
          ? defaultLetterSpacing
          : (double.tryParse(letterSpacing) ?? defaultLetterSpacing),
      wordSpacing: wordSpacing == null
          ? defaultWordSpacing
          : (double.tryParse(wordSpacing) ?? defaultWordSpacing),
      brightness: brightness == null
          ? 1.0
          : (double.tryParse(brightness) ?? 1.0),
      fontFamily: fontFamily == null
          ? defaultFontFamily
          : (fontFamily == _systemFontToken ? null : fontFamily),
      disclaimerAgreed: disclaimer == '1',
      canonChosen: canonChosen == '1',
      loaded: true,
    );
  }

  Future<void> agreeDisclaimer() async {
    if (state.disclaimerAgreed) {
      return;
    }
    state = state.copyWith(disclaimerAgreed: true);
    await ref.read(settingsDaoProvider).set(_kDisclaimer, '1');
  }

  Future<void> setCanon(String canon) async {
    if (canon == state.canon) {
      return;
    }
    state = state.copyWith(canon: canon);
    await ref.read(settingsDaoProvider).set(_kCanon, canon);
  }

  /// 온보딩/설정에서 정경 선택. 같은 정경을 골라도 '선택 완료'로 기록한다.
  Future<void> chooseCanon(String canon) async {
    state = state.copyWith(canon: canon, canonChosen: true);
    final dao = ref.read(settingsDaoProvider);
    await dao.set(_kCanon, canon);
    await dao.set(_kCanonChosen, '1');
  }

  /// 테마 톤(0=라이트 ~ 1=다크) 설정. 설정 화면 슬라이더용.
  Future<void> setThemeTone(double value) async {
    state = state.copyWith(themeTone: value);
    await ref.read(settingsDaoProvider).set(_kThemeTone, value.toString());
  }

  /// 라이트↔다크 빠른 토글. 상단 토글 버튼용. 현재 다크면 라이트(0)로, 아니면 다크(1)로.
  Future<void> toggleDarkMode() async {
    await setThemeTone(toneIsDark(state.themeTone) ? 0.0 : 1.0);
  }

  Future<void> setFontScale(double scale) async {
    state = state.copyWith(fontScale: scale);
    await ref.read(settingsDaoProvider).set(_kFontScale, scale.toString());
  }

  Future<void> setLineHeight(double value) async {
    state = state.copyWith(lineHeight: value);
    await ref.read(settingsDaoProvider).set(_kLineHeight, value.toString());
  }

  Future<void> setPageMargin(double value) async {
    state = state.copyWith(pageMargin: value);
    await ref.read(settingsDaoProvider).set(_kPageMargin, value.toString());
  }

  Future<void> setLetterSpacing(double value) async {
    state = state.copyWith(letterSpacing: value);
    await ref.read(settingsDaoProvider).set(_kLetterSpacing, value.toString());
  }

  Future<void> setWordSpacing(double value) async {
    state = state.copyWith(wordSpacing: value);
    await ref.read(settingsDaoProvider).set(_kWordSpacing, value.toString());
  }

  Future<void> setBrightness(double value) async {
    state = state.copyWith(brightness: value);
    await ref.read(settingsDaoProvider).set(_kBrightness, value.toString());
  }

  Future<void> setFontFamily(String? family) async {
    state = state.copyWith(fontFamily: family);
    await ref
        .read(settingsDaoProvider)
        .set(_kFontFamily, family ?? _systemFontToken);
  }

  /// 화면 섹션(테마·밝기)을 기본값으로 복원.
  Future<void> resetDisplay() async {
    state = state.copyWith(themeTone: defaultThemeTone, brightness: 1.0);
    final dao = ref.read(settingsDaoProvider);
    await dao.set(_kThemeTone, defaultThemeTone.toString());
    await dao.set(_kBrightness, '1.0');
  }

  /// 본문 섹션(글씨체·크기·줄간격·여백)을 기본값으로 복원.
  Future<void> resetBody() async {
    state = state.copyWith(
      fontFamily: defaultFontFamily,
      fontScale: 1.0,
      lineHeight: defaultLineHeight,
      pageMargin: defaultPageMargin,
      letterSpacing: defaultLetterSpacing,
      wordSpacing: defaultWordSpacing,
    );
    final dao = ref.read(settingsDaoProvider);
    await dao.set(_kFontFamily, defaultFontFamily);
    await dao.set(_kFontScale, '1.0');
    await dao.set(_kLineHeight, defaultLineHeight.toString());
    await dao.set(_kPageMargin, defaultPageMargin.toString());
    await dao.set(_kLetterSpacing, defaultLetterSpacing.toString());
    await dao.set(_kWordSpacing, defaultWordSpacing.toString());
  }

  /// 화면+본문 전체를 기본값으로. 정경 선택은 건드리지 않는다.
  Future<void> resetAll() async {
    await resetDisplay();
    await resetBody();
  }
}

final settingsControllerProvider =
    NotifierProvider<SettingsController, AppSettings>(SettingsController.new);
