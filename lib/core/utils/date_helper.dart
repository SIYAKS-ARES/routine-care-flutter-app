import 'package:intl/intl.dart';

class DateHelper {
  static String todaysDateFormatted() {
    final now = DateTime.now();
    return DateFormat('yyyyMMdd').format(now);
  }

  static DateTime createDateTimeObject(String yyyymmdd) {
    final year = int.parse(yyyymmdd.substring(0, 4));
    final month = int.parse(yyyymmdd.substring(4, 6));
    final day = int.parse(yyyymmdd.substring(6, 8));
    return DateTime(year, month, day);
  }

  static String convertDateTimeToString(DateTime dateTime) {
    return DateFormat('yyyyMMdd').format(dateTime);
  }

  static String formatDateForDisplay(DateTime dateTime) {
    return DateFormat('dd MMM yyyy').format(dateTime);
  }

  static String formatTimeForDisplay(DateTime dateTime) {
    return DateFormat('HH:mm').format(dateTime);
  }

  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  static DateTime getStartOfDay(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month, dateTime.day);
  }

  static DateTime getEndOfDay(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month, dateTime.day, 23, 59, 59);
  }
}
