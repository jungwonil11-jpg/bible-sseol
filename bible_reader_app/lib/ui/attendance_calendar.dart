import 'package:flutter/material.dart';

import '../data/database/daos.dart';
import '../theme/app_theme.dart';
import 'stats_logic.dart';

/// 읽음 표시된 날을 달력으로 보여주는 출석부.
/// 총 읽은날 + 연속 읽은날 + 월 단위 달력(읽은 날 강조). 월 이동 가능.
/// 메인 화면 '연속 N일째' 버튼과 통계 화면에서 같은 위젯을 재사용한다.
class AttendanceCalendar extends StatefulWidget {
  const AttendanceCalendar({super.key, required this.status});

  final List<ChapterReadStatus> status;

  @override
  State<AttendanceCalendar> createState() => _AttendanceCalendarState();
}

class _AttendanceCalendarState extends State<AttendanceCalendar> {
  late DateTime _month; // 보고 있는 달의 1일.

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
  }

  void _shiftMonth(int delta) {
    setState(() => _month = DateTime(_month.year, _month.month + delta));
  }

  @override
  Widget build(BuildContext context) {
    final colors = appColors(context);
    final days = readDays(widget.status);
    final streak =
        readingStreak(widget.status.where((s) => s.isRead).toList());
    final today = DateTime.now();
    final todayKey = DateTime(today.year, today.month, today.day);

    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    // 일요일 시작(0=일 ~ 6=토). DateTime.weekday는 월=1..일=7.
    final leadingBlanks = DateTime(_month.year, _month.month, 1).weekday % 7;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _MiniStat(
                label: '총 읽은날',
                value: '${days.length}일',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MiniStat(
                label: '연속 읽은날',
                value: streak > 0 ? '$streak일' : '0일',
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        // 월 이동 헤더
        Row(
          children: [
            IconButton(
              onPressed: () => _shiftMonth(-1),
              icon: const Icon(Icons.chevron_left),
              color: colors.accentSoft,
            ),
            Expanded(
              child: Text(
                '${_month.year}년 ${_month.month}월',
                textAlign: TextAlign.center,
                style: handTextStyle(
                  color: colors.ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            IconButton(
              onPressed: () => _shiftMonth(1),
              icon: const Icon(Icons.chevron_right),
              color: colors.accentSoft,
            ),
          ],
        ),
        const SizedBox(height: 8),
        // 요일 헤더
        Row(
          children: [
            for (final w in const ['일', '월', '화', '수', '목', '금', '토'])
              Expanded(
                child: Center(
                  child: Text(
                    w,
                    style: TextStyle(color: colors.inkSoft, fontSize: 12),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        // 날짜 그리드
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
          children: [
            for (var i = 0; i < leadingBlanks; i++) const SizedBox.shrink(),
            for (var day = 1; day <= daysInMonth; day++)
              _DayCell(
                day: day,
                read: days.contains(DateTime(_month.year, _month.month, day)),
                isToday:
                    DateTime(_month.year, _month.month, day) == todayKey,
              ),
          ],
        ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.read,
    required this.isToday,
  });

  final int day;
  final bool read;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final colors = appColors(context);
    return Container(
      decoration: BoxDecoration(
        color: read ? colors.accent : Colors.transparent,
        shape: BoxShape.circle,
        border: isToday && !read
            ? Border.all(color: colors.accentSoft, width: 1.5)
            : null,
      ),
      child: Center(
        child: Text(
          '$day',
          style: TextStyle(
            color: read ? colors.onAccent : colors.inkSoft,
            fontSize: 13,
            fontWeight: read ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = appColors(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: colors.paperEdge,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: colors.inkSoft, fontSize: 12)),
          const SizedBox(height: 6),
          Text(
            value,
            style: handTextStyle(
              color: colors.ink,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// 메인 화면 '연속 N일째' 버튼이 띄우는 출석 달력 바텀시트.
Future<void> showAttendanceSheet(
  BuildContext context,
  List<ChapterReadStatus> status,
) {
  final colors = appColors(context);
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: colors.paper,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '읽기 출석',
                  style: handTextStyle(
                    color: appColors(ctx).ink,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 18),
                AttendanceCalendar(status: status),
              ],
            ),
          ),
        ),
      );
    },
  );
}
