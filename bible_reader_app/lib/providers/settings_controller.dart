import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_theme.dart';
import 'database_providers.dart';

/// 본문 글자 크기 — 슬라이더 연속값 범위(기본 1.0).
const fontScaleMin = 0.8;
const fontScaleMax = 1.6;

/// 화면 밝기 — 인앱 딜밍 오버레이. 1.0=가장 밝음(오버레이 없음), 0.0=가장 어두움.
/// 실제 검정 오버레이 불투명도는 (1 - brightness) * _dimMax 로 환산.
const dimMax = 0.6;

/// 글씨체 선택지. (라벨, ThemeData.fontFamily에 들어갈 패밀리명).
/// family가 null이면 시스템 기본 폰트를 쓴다. 기본값은 마루부리.
const fontFamilyOptions = <(String label, String? family)>[
  ('시스템', null),
  ('마루부리', 'MaruBuri'),
  ('감자', 'GamjaFlower'),
  ('나눔스퀘어', 'NanumSquare'),
  ('나눔고딕', 'NanumGothic'),
  ('나눔명조', 'NanumMyeongjo'),
];
const defaultFontFamily = 'MaruBuri';

/// '시스템'(family null)을 DB에 저장할 때 쓰는 표식. null과 미설정을 구분하기 위함.
const _systemFontToken = 'system';

class AppSettings {
  const AppSettings({
    this.canon = 'protestant',
    this.readingTheme = defaultReadingTheme,
    this.fontScale = 1.0,
    this.brightness = 1.0,
    this.fontFamily = defaultFontFamily,
    this.disclaimerAgreed = false,
    this.canonChosen = false,
    this.loaded = false,
  });

  final String canon;

  /// 리딩 테마 id (original/sepia/night). 다크모드는 night로 흡수.
  final String readingTheme;
  final double fontScale;

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
    String? readingTheme,
    double? fontScale,
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
      readingTheme: readingTheme ?? this.readingTheme,
      fontScale: fontScale ?? this.fontScale,
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
  static const _kReadingTheme = 'reading_theme';
  static const _kFontScale = 'font_scale';
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
    final readingTheme = await dao.get(_kReadingTheme);
    final dark = await dao.get(_kDark);
    final fontScale = await dao.get(_kFontScale);
    final brightness = await dao.get(_kBrightness);
    final fontFamily = await dao.get(_kFontFamily);
    final disclaimer = await dao.get(_kDisclaimer);
    final canonChosen = await dao.get(_kCanonChosen);
    state = AppSettings(
      canon: canon ?? 'protestant',
      // reading_theme가 없으면 구버전 dark_mode를 보고 night/original로 흡수.
      readingTheme: readingTheme ??
          (dark == '1' ? 'night' : defaultReadingTheme),
      fontScale: fontScale == null
          ? 1.0
          : (double.tryParse(fontScale) ?? 1.0),
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

  Future<void> setReadingTheme(String id) async {
    if (id == state.readingTheme) {
      return;
    }
    state = state.copyWith(readingTheme: id);
    await ref.read(settingsDaoProvider).set(_kReadingTheme, id);
  }

  /// 라이트(original)↔다크(night) 빠른 토글. 상단 토글 버튼용.
  Future<void> toggleDarkMode() async {
    final next = state.readingTheme == 'night' ? defaultReadingTheme : 'night';
    await setReadingTheme(next);
  }

  Future<void> setFontScale(double scale) async {
    state = state.copyWith(fontScale: scale);
    await ref.read(settingsDaoProvider).set(_kFontScale, scale.toString());
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
}

final settingsControllerProvider =
    NotifierProvider<SettingsController, AppSettings>(SettingsController.new);
