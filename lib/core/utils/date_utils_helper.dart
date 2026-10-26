import 'package:intl/intl.dart';

class DateRange {
  final DateTime start;
  final DateTime end;
  final String label;

  const DateRange({
    required this.start,
    required this.end,
    required this.label,
  });
}

class DateUtilsHelper {
  static final DateFormat _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');
  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  static final DateFormat _shortDateFormat = DateFormat('dd/MM');

  static String formatDateTime(DateTime? dt) {
    if (dt == null) return 'Vừa xong';
    return _dateTimeFormat.format(dt);
  }

  static String formatDate(DateTime? dt) {
    if (dt == null) return '';
    return _dateFormat.format(dt);
  }

  static String formatShortDate(DateTime? dt) {
    if (dt == null) return '';
    return _shortDateFormat.format(dt);
  }

  /// Lấy ngày Thứ Hai đầu tuần (00:00:00)
  static DateTime getStartOfWeek(DateTime date) {
    final monday = date.subtract(Duration(days: date.weekday - 1));
    return DateTime(monday.year, monday.month, monday.day, 0, 0, 0);
  }

  /// Lấy ngày Chủ Nhật cuối tuần (23:59:59)
  static DateTime getEndOfWeek(DateTime date) {
    final sunday = date.add(Duration(days: 7 - date.weekday));
    return DateTime(sunday.year, sunday.month, sunday.day, 23, 59, 59, 999);
  }

  /// Tính tuần thứ mấy trong năm (ISO 8601)
  static int getWeekNumber(DateTime date) {
    final dayOfYear = int.parse(DateFormat('D').format(date));
    final wday = date.weekday;
    final week = ((dayOfYear - wday + 10) / 7).floor();
    return week;
  }

  /// Lấy khoảng thời gian của một tháng
  static DateRange getMonthRange(int year, int month) {
    final start = DateTime(year, month, 1, 0, 0, 0);
    final end = (month == 12)
        ? DateTime(year + 1, 1, 1, 0, 0, 0).subtract(const Duration(milliseconds: 1))
        : DateTime(year, month + 1, 1, 0, 0, 0).subtract(const Duration(milliseconds: 1));
    return DateRange(
      start: start,
      end: end,
      label: 'Tháng $month/$year',
    );
  }

  /// Lấy khoảng thời gian của cả năm
  static DateRange getYearRange(int year) {
    final start = DateTime(year, 1, 1, 0, 0, 0);
    final end = DateTime(year + 1, 1, 1, 0, 0, 0).subtract(const Duration(milliseconds: 1));
    return DateRange(
      start: start,
      end: end,
      label: 'Năm $year',
    );
  }

  /// Danh sách các tuần gần đây (ví dụ: 8 tuần gần nhất)
  static List<DateRange> getRecentWeeks({int count = 12}) {
    final now = DateTime.now();
    final list = <DateRange>[];
    for (int i = 0; i < count; i++) {
      final targetDate = now.subtract(Duration(days: i * 7));
      final start = getStartOfWeek(targetDate);
      final end = getEndOfWeek(targetDate);
      final weekNum = getWeekNumber(targetDate);
      String label = 'Tuần $weekNum (${_shortDateFormat.format(start)} - ${_shortDateFormat.format(end)})';
      if (i == 0) label = 'Tuần này ($label)';
      if (i == 1) label = 'Tuần trước ($label)';
      list.add(DateRange(start: start, end: end, label: label));
    }
    return list;
  }
}
