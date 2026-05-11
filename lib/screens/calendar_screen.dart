import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/calendar_provider.dart';
import '../models/exercise.dart';
import 'package:intl/intl.dart';

class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(calendarProvider);
    final notifier = ref.read(calendarProvider.notifier);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Month header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () {
                      notifier.loadMonth(
                        DateTime(state.currentMonth.year, state.currentMonth.month - 1, 1),
                      );
                    },
                  ),
                  Text(
                    DateFormat('yyyy年 M月').format(state.currentMonth),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () {
                      notifier.loadMonth(
                        DateTime(state.currentMonth.year, state.currentMonth.month + 1, 1),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Day headers
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  _DayHeader('一'),
                  _DayHeader('二'),
                  _DayHeader('三'),
                  _DayHeader('四'),
                  _DayHeader('五'),
                  _DayHeader('六'),
                  _DayHeader('日'),
                ],
              ),
            ),

            // Calendar grid
            Expanded(
              child: _CalendarGrid(
                month: state.currentMonth,
                markedDates: state.sessionsByDate.keys.toSet(),
                selectedDate: state.selectedDate,
                onDateSelected: notifier.selectDate,
              ),
            ),

            // Selected day details
            if (state.selectedDateSessions != null && state.selectedDateSessions!.isNotEmpty)
              Container(
                constraints: const BoxConstraints(maxHeight: 180),
                padding: const EdgeInsets.all(12),
                color: const Color(0xFF1A1A1A),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                        Text(
                          DateFormat('M月d日 训练记录').format(state.selectedDate!),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                      ] +
                      state.selectedDateSessions!
                          .map((s) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  'Cycle ${s.cycleNumber} | ${s.startedAt.hour}:${s.startedAt.minute.toString().padLeft(2, '0')} '
                                  '${s.duration != null ? "| ${s.duration!.inMinutes}分钟" : ""}',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ))
                          .toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  final String text;
  const _DayHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(text, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  final DateTime month;
  final Set<String> markedDates;
  final DateTime? selectedDate;
  final void Function(DateTime) onDateSelected;

  const _CalendarGrid({
    required this.month,
    required this.markedDates,
    required this.selectedDate,
    required this.onDateSelected,
  });

  String _dateKey(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);
    final firstWeekday = firstDay.weekday; // 1=Mon

    final cells = <Widget>[];
    // Empty cells before first day
    for (int i = 1; i < firstWeekday; i++) {
      cells.add(const _DayCell.empty());
    }
    // Day cells
    final today = DateTime.now();
    for (int d = 1; d <= lastDay.day; d++) {
      final date = DateTime(month.year, month.month, d);
      final key = _dateKey(date);
      final isToday = today.year == date.year && today.month == date.month && today.day == date.day;
      final hasTraining = markedDates.contains(key);
      final isSelected = selectedDate != null &&
          selectedDate!.year == date.year &&
          selectedDate!.month == date.month &&
          selectedDate!.day == date.day;

      cells.add(_DayCell(
        day: d,
        isToday: isToday,
        hasTraining: hasTraining,
        isSelected: isSelected,
        onTap: () => onDateSelected(date),
      ));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: GridView.count(
        crossAxisCount: 7,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
        childAspectRatio: 1,
        physics: const NeverScrollableScrollPhysics(),
        children: cells,
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final int? day;
  final bool isToday;
  final bool hasTraining;
  final bool isSelected;
  final VoidCallback? onTap;

  const _DayCell.empty()
      : day = null,
        isToday = false,
        hasTraining = false,
        isSelected = false,
        onTap = null;

  const _DayCell({
    required this.day,
    required this.isToday,
    required this.hasTraining,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (day == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF4CAF50).withOpacity(0.3)
              : isToday
                  ? const Color(0xFF4CAF50).withOpacity(0.1)
                  : null,
          borderRadius: BorderRadius.circular(8),
          border: isSelected ? Border.all(color: const Color(0xFF4CAF50)) : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$day',
              style: TextStyle(
                color: isToday ? const Color(0xFF4CAF50) : Colors.white,
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
            if (hasTraining)
              Container(
                width: 5,
                height: 5,
                margin: const EdgeInsets.only(top: 2),
                decoration: const BoxDecoration(
                  color: Color(0xFF4CAF50),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
