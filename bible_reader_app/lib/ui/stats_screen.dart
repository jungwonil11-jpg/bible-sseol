import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/bible_data.dart';
import '../providers/reading_providers.dart';
import '../providers/settings_controller.dart';
import '../theme/app_theme.dart';
import 'stats_logic.dart';

/// 읽기 통계(선택한 정경 기준). 진행률·누적 편·읽은 책·연속 읽기.
class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key, required this.data});

  final BibleData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = appColors(context);
    final canon = ref.watch(settingsControllerProvider.select((s) => s.canon));
    final canonName = data.canonInfo[canon]?.name ?? '';
    final statusAsync = ref.watch(allReadStatusProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('완독하자!')),
      body: statusAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (status) {
          final s = computeReadingStats(data, canon, status);
          final pct = s.totalChapters == 0
              ? 0
              : (s.readChapters / s.totalChapters * 100).round();
          return ListView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
            children: [
              Text(
                '$canonName 기준',
                style: handTextStyle(
                  color: colors.accent,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 24),

              // 전체 진행률
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '$pct%',
                          style: handTextStyle(
                            color: colors.ink,
                            fontSize: 40,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${s.readChapters} / ${s.totalChapters}편',
                          style: TextStyle(color: colors.inkSoft, fontSize: 15),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: s.totalChapters == 0
                            ? 0
                            : s.readChapters / s.totalChapters,
                        minHeight: 10,
                        backgroundColor: colors.line,
                        valueColor: AlwaysStoppedAnimation(colors.accent),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: _StatBox(
                      label: '읽은 책',
                      value: '${s.readBooks} / ${s.totalBooks}',
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _StatBox(
                      label: '누적 읽은 편',
                      value: '${s.readChapters}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              _Card(
                child: Row(
                  children: [
                    Icon(Icons.local_fire_department, color: colors.accent),
                    const SizedBox(width: 12),
                    Text(
                      '연속 읽기',
                      style: TextStyle(color: colors.ink, fontSize: 16),
                    ),
                    const Spacer(),
                    Text(
                      s.streak > 0 ? '${s.streak}일째' : '아직 없음',
                      style: handTextStyle(
                        color: colors.accent,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = appColors(context);
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: colors.inkSoft, fontSize: 13)),
          const SizedBox(height: 8),
          Text(
            value,
            style: handTextStyle(
              color: colors.ink,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = appColors(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.paperEdge,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.line),
      ),
      child: child,
    );
  }
}

