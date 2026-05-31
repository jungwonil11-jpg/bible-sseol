import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/bible_data.dart';
import '../providers/settings_controller.dart';
import 'collections_screen.dart';
import 'search_screen.dart';
import 'settings_screen.dart';

/// 서재 상단의 전역 액션(검색·모아보기·다크모드·설정).
/// 본문(reader)·책 상세 등 깊은 화면에서도 동일하게 따라다니도록 한 곳에 모음.
/// 화면마다 같은 코드를 복붙하지 않게 공통 위젯 목록으로 제공한다.
List<Widget> globalAppBarActions(
  BuildContext context,
  WidgetRef ref,
  BibleData data,
) {
  final settings = ref.watch(settingsControllerProvider);
  final controller = ref.read(settingsControllerProvider.notifier);
  final isNight = settings.readingTheme == 'night';
  return [
    IconButton(
      tooltip: '검색',
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => SearchScreen(data: data)),
      ),
      icon: const Icon(Icons.search),
    ),
    IconButton(
      tooltip: '모아보기',
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => CollectionsScreen(data: data)),
      ),
      icon: const Icon(Icons.collections_bookmark_outlined),
    ),
    IconButton(
      tooltip: isNight ? '라이트 모드' : '다크 모드',
      onPressed: controller.toggleDarkMode,
      icon: Icon(isNight ? Icons.light_mode : Icons.dark_mode),
    ),
    IconButton(
      tooltip: '설정',
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const SettingsScreen()),
      ),
      icon: const Icon(Icons.settings_outlined),
    ),
  ];
}
