import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/training_session.dart';
import '../database/dao.dart';

class CalendarState {
  final DateTime currentMonth;
  final Map<String, List<TrainingSession>> sessionsByDate;
  final DateTime? selectedDate;
  final List<TrainingSession>? selectedDateSessions;

  const CalendarState({
    required this.currentMonth,
    this.sessionsByDate = const {},
    this.selectedDate,
    this.selectedDateSessions,
  });

  CalendarState copyWith({
    DateTime? currentMonth,
    Map<String, List<TrainingSession>>? sessionsByDate,
    DateTime? selectedDate,
    List<TrainingSession>? selectedDateSessions,
  }) =>
      CalendarState(
        currentMonth: currentMonth ?? this.currentMonth,
        sessionsByDate: sessionsByDate ?? this.sessionsByDate,
        selectedDate: selectedDate ?? this.selectedDate,
        selectedDateSessions: selectedDateSessions ?? this.selectedDateSessions,
      );
}

class CalendarNotifier extends StateNotifier<CalendarState> {
  final Dao _dao = Dao();

  CalendarNotifier() : super(CalendarState(currentMonth: DateTime.now())) {
    loadMonth(DateTime.now());
  }

  Future<void> loadMonth(DateTime month) async {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

    final allSessions = await _dao.getSessions(limit: 200);
    final monthSessions = allSessions.where((s) {
      return s.startedAt.isAfter(start.subtract(const Duration(days: 1))) &&
          s.startedAt.isBefore(end.add(const Duration(days: 1)));
    }).toList();

    final Map<String, List<TrainingSession>> byDate = {};
    for (final session in monthSessions) {
      final key = _dateKey(session.startedAt);
      byDate.putIfAbsent(key, () => []).add(session);
    }

    state = state.copyWith(
      currentMonth: month,
      sessionsByDate: byDate,
    );
  }

  Future<void> selectDate(DateTime date) async {
    final key = _dateKey(date);
    final sessions = state.sessionsByDate[key] ?? [];
    state = state.copyWith(selectedDate: date, selectedDateSessions: sessions);
  }

  String _dateKey(DateTime dt) => '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  bool hasTraining(DateTime date) {
    return state.sessionsByDate.containsKey(_dateKey(date));
  }
}

final calendarProvider = StateNotifierProvider<CalendarNotifier, CalendarState>((ref) {
  return CalendarNotifier();
});
