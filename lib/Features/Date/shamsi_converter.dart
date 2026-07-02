import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:intl/intl.dart';

class AfghanShamsiConverter {

  // Add this to your AfghanShamsiConverter class
  static String formatJalali(Jalali jalali, {String format = 'yyyy/mm/dd'}) {
    final month = jalali.month.toString().padLeft(2, '0');
    final day = jalali.day.toString().padLeft(2, '0');

    return format
        .replaceAll('yyyy', jalali.year.toString())
        .replaceAll('mm', month)
        .replaceAll('m', jalali.month.toString())
        .replaceAll('dd', day)
        .replaceAll('d', jalali.day.toString());
  }

  /// Convert various input types to Jalali date
  static Jalali toJalali(dynamic input) {
    if (input is DateTime) {
      return Jalali.fromDateTime(input);
    } else if (input is String) {
      // Try parsing different string formats
      final dateTime = DateTime.tryParse(input);
      if (dateTime != null) {
        return Jalali.fromDateTime(dateTime);
      }

      // Handle custom string formats if needed
      // Example: "1402/5/15" or "1402-05-15"
      final parts = input.split(RegExp(r'[/-]'));
      if (parts.length == 3) {
        final year = int.tryParse(parts[0]);
        final month = int.tryParse(parts[1]);
        final day = int.tryParse(parts[2]);
        if (year != null && month != null && day != null) {
          return Jalali(year, month, day);
        }
      }
    }

    throw ArgumentError('Unsupported input type for Afghan Shamsi conversion');
  }

  /// Afghan month names in Dari
  static const Map<int, String> shamsiMonths = {
    1: 'حمل',   // Hamal (Farvardin)
    2: 'ثور',   // Sawr (Ordibehesht)
    3: 'جوزا',  // Jawza (Khordad)
    4: 'سرطان', // Saratan (Tir)
    5: 'اسد',   // Asad (Mordad)
    6: 'سنبله', // Sonbola (Shahrivar)
    7: 'میزان', // Mizan (Mehr)
    8: 'عقرب',  // Aqrab (Aban)
    9: 'قوس',   // Qaws (Azar)
    10: 'جدی',  // Jadi (Dey)
    11: 'دلو',  // Dalwa (Bahman)
    12: 'حوت',  // Hut (Esfand)
  };

  /// Afghan weekday names in Dari
  static const Map<int, String> shamsiWeekdays = {
    1: 'شنبه',   // Saturday
    2: 'یکشنبه',  // Sunday
    3: 'دوشنبه', // Monday
    4: 'سه‌شنبه',  // Tuesday
    5: 'چهارشنبه',     // Wednesday
    6: 'پنجشنبه',     // Thursday
    7: 'جمعه',   // Friday
  };

  /// Helper function to convert English digits to Persian
  static String toPersianNumbers(String input) {
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const farsi = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];

    for (int i = 0; i < english.length; i++) {
      input = input.replaceAll(english[i], farsi[i]);
    }
    return input;
  }

  /// Format Jalali date as compact string
  static String formatCompact(Jalali j) {
    return toPersianNumbers('${j.year}/${j.month}/${j.day}');
  }

  /// Format Jalali date as full string
  static String formatFull(Jalali j) {
    return '${shamsiWeekdays[j.weekDay]}، ${toPersianNumbers('${j.day}')} ${shamsiMonths[j.month]} ${toPersianNumbers('${j.year}')}';
  }

  /// Format Jalali date with leading zeros
  static String formatWithLeadingZeros(Jalali j) {
    return toPersianNumbers('${j.year}/${j.month.toString().padLeft(2, '0')}/${j.day.toString().padLeft(2, '0')}');
  }
}

extension DateTimeExtensions on dynamic {
  DateTime? get _dateTime {
    if (this is DateTime) return this as DateTime;
    if (this is String) return DateTime.tryParse(this as String);
    return null;
  }

  static String _twoDigits(int n) => n.toString().padLeft(2, "0");

  /// Formats the date as YYYY-MM-DD
  String toFormattedDate() {
    final date = _dateTime;
    return date != null
        ? "${date.year}-${_twoDigits(date.month)}-${_twoDigits(date.day)}"
        : "";
  }
}

extension ZSmartDateFormat on dynamic {
  DateTime? get _date => ZDateFormatter.parse(this);

  /// Jan
  String get monthShort =>
      _date == null ? '' : DateFormat('MMM').format(_date!);

  /// January
  String get monthFull =>
      _date == null ? '' : DateFormat('MMMM').format(_date!);

  /// 05
  String get day =>
      _date == null ? '' : DateFormat('dd').format(_date!);

  /// Wed
  String get weekDayShort =>
      _date == null ? '' : DateFormat('EEE').format(_date!);

  /// Wednesday
  String get weekDayFull =>
      _date == null ? '' : DateFormat('EEEE').format(_date!);

  /// 14:30
  String get time24 =>
      _date == null ? '' : DateFormat('HH:mm').format(_date!);

  /// 02:30 PM
  String get time12 =>
      _date == null ? '' : DateFormat('hh:mm a').format(_date!);

  /// Jan 05, Wed
  String get compact =>
      _date == null ? '' : DateFormat('MMM dd, EEE').format(_date!);

  /// Wed, Jan 05
  String get compactReverse =>
      _date == null ? '' : DateFormat('EEE, MMM dd').format(_date!);

  /// Wednesday, January 05
  String get fullReadable =>
      _date == null ? '' : DateFormat('EEEE, MMMM dd').format(_date!);

  /// Jan 05 • 14:30
  String get dateTimeShort =>
      _date == null ? '' : DateFormat('MMM dd • HH:mm').format(_date!);

  /// Custom formatter
  String format(String pattern) =>
      _date == null ? '' : DateFormat(pattern).format(_date!);
}


extension DateTimeFormatExtensions on DateTime {
  /// Returns date in 'yyyy-MM-dd' format (e.g., 2025-10-31)
  String get toDateString => DateFormat('yyyy-MM-dd').format(this);

  /// Returns time in 'HH:mm:ss' format (e.g., 22:29:00)
  String get toTimeString => DateFormat('HH:mm:ss').format(this);

  /// Returns full date-time in 'yyyy-MM-dd HH:mm:ss' format
  String get toFullDateTime => DateFormat('yyyy-MM-dd HH:mm:ss').format(this);
  String get toDateTime => DateFormat('dd/MM/yyyy, hh:mma').format(this);
  /// Returns localized readable format (e.g., Friday, Oct 31, 2025 – 10:29 PM)
  String get toReadable => DateFormat('EEEE, MMM d, yyyy – h:mm a').format(this);
}

extension AfghanShamsiDateConverter on DateTime {
  /// Convert to Afghan Shamsi (Jalali) date
  Jalali get toAfghanShamsi => AfghanShamsiConverter.toJalali(this);

  /// Format as compact Afghan date with Persian numbers (e.g., "۱۴۰۲/۵/۱۵")
  String get shamsiDateString => AfghanShamsiConverter.formatCompact(toAfghanShamsi);

  /// Full Afghan date format with Persian numbers (e.g., "دوشنبه، ۱۵ حمل ۱۴۰۲")
  String get shamsiFullDate => AfghanShamsiConverter.formatFull(toAfghanShamsi);

  /// Format with leading zeros and Persian numbers (e.g., "۱۴۰۲/۰۵/۱۵")
  String get shamsiDateFormatted => AfghanShamsiConverter.formatWithLeadingZeros(toAfghanShamsi);

  /// Get current Afghan month name
  String get shamsiMonthName => AfghanShamsiConverter.shamsiMonths[toAfghanShamsi.month] ?? '';

  /// Get current Afghan weekday name
  String get shamsiWeekdayName => AfghanShamsiConverter.shamsiWeekdays[toAfghanShamsi.weekDay] ?? '';
}

extension JalaliToGregorian on Jalali {
  /// Convert Jalali date to Gregorian DateTime
  DateTime toGregorian() {
    return toDateTime();
  }

  /// Convert Jalali date to Gregorian date string (yyyy-mm-dd format)
  String toGregorianString() {
    final dateTime = toDateTime();
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
  }

  /// Convert Jalali date to formatted Gregorian date string
  String toFormattedGregorianString({String format = 'yyyy-MM-dd'}) {
    final dateTime = toDateTime();
    return format
        .replaceAll('yyyy', dateTime.year.toString())
        .replaceAll('MM', dateTime.month.toString().padLeft(2, '0'))
        .replaceAll('M', dateTime.month.toString())
        .replaceAll('dd', dateTime.day.toString().padLeft(2, '0'))
        .replaceAll('d', dateTime.day.toString());
  }

  /// Convert Jalali date to localized Gregorian date string
  String toLocalizedGregorianString(BuildContext context) {
    final dateTime = toDateTime();
    return MaterialLocalizations.of(context).formatShortDate(dateTime);
  }
}

extension StringToAfghanShamsi on String {
  /// Convert string to Afghan Shamsi (Jalali) date
  Jalali get toAfghanShamsi => AfghanShamsiConverter.toJalali(this);

  /// Format as compact Afghan date with Persian numbers (e.g., "۱۴۰۲/۵/۱۵")
  String get shamsiDateString => AfghanShamsiConverter.formatCompact(toAfghanShamsi);

  /// Full Afghan date format with Persian numbers (e.g., "دوشنبه، ۱۵ حمل ۱۴۰۲")
  String get shamsiFullDate => AfghanShamsiConverter.formatFull(toAfghanShamsi);

  /// Format with leading zeros and Persian numbers (e.g., "۱۴۰۲/۰۵/۱۵")
  String get shamsiDateFormatted => AfghanShamsiConverter.formatWithLeadingZeros(toAfghanShamsi);

  /// Get month name from date string
  String get shamsiMonthName => AfghanShamsiConverter.shamsiMonths[toAfghanShamsi.month] ?? '';

  /// Get weekday name from date string
  String get shamsiWeekdayName => AfghanShamsiConverter.shamsiWeekdays[toAfghanShamsi.weekDay] ?? '';
}

extension JalaliFormatting on Jalali {
  /// Convert to compact Afghan date string (e.g., "1402/5/15")
  String toShamsiString() {
    return AfghanShamsiConverter.formatJalali(this, format: 'yyyy/m/d');
  }

  /// Convert to formatted Afghan date string with leading zeros (e.g., "1402/05/15")
  String toFormattedShamsiString() {
    return AfghanShamsiConverter.formatJalali(this, format: 'yyyy/mm/dd');
  }

  /// Convert to full Afghan date string (e.g., "دوشنبه، ۱۵ حمل ۱۴۰۲")
  String toFullShamsiString() {
    return AfghanShamsiConverter.formatFull(this);
  }

  /// Convert to Persian numbers string (e.g., "۱۴۰۲/۰۵/۱۵")
  String toPersianShamsiString() {
    return AfghanShamsiConverter.toPersianNumbers(toFormattedShamsiString());
  }
}

extension AfghanShamsiStringExtra on String {
  String get shamsiYear =>
      AfghanShamsiConverter.toPersianNumbers(
        toAfghanShamsi.year.toString(),
      );

  String get shamsiDayNumber =>
      AfghanShamsiConverter.toPersianNumbers(
        toAfghanShamsi.day.toString(),
      );

  String get shamsiWeekdayWithDay =>
      '$shamsiWeekdayName $shamsiDayNumber';

  String get shamsiFullNumericDate =>
      AfghanShamsiConverter.formatWithLeadingZeros(toAfghanShamsi);
}
extension AfghanShamsiExtraExtensions on DateTime {
  /// Weekday + Day number → شنبه ۱۳
  String get shamsiWeekdayWithDay {
    final j = toAfghanShamsi;
    final weekday =
        AfghanShamsiConverter.shamsiWeekdays[j.weekDay] ?? '';
    final day =
    AfghanShamsiConverter.toPersianNumbers(j.day.toString());
    return '$weekday $day';
  }

  /// Full numeric Shamsi date → ۱۴۰۴/۱۰/۱۰
  String get shamsiFullNumericDate {
    final j = toAfghanShamsi;
    return AfghanShamsiConverter.toPersianNumbers(
      '${j.year}/${j.month.toString().padLeft(2, '0')}/${j.day.toString().padLeft(2, '0')}',
    );
  }
}
extension DeadlineExtension on Object {
  /// Calculate days left until deadline
  /// Can accept DateTime, String (in various formats), or null
  /// Returns:
  ///   - positive number: days remaining
  ///   - 0: deadline is today
  ///   - negative number: days overdue
  ///   - null: if input is invalid or null
  int? get daysLeft {
    // Handle null
    DateTime? deadline;

    // If it's already DateTime
    if (this is DateTime) {
      deadline = this as DateTime;
    }
    // If it's a String, try to parse it
    else if (this is String) {
      final dateStr = this as String;

      // Try different date formats
      try {
        // Try ISO format (yyyy-MM-dd)
        if (dateStr.contains(RegExp(r'^\d{4}-\d{2}-\d{2}'))) {
          deadline = DateTime.parse(dateStr);
        }
        // Try dd/MM/yyyy format
        else if (dateStr.contains(RegExp(r'^\d{2}/\d{2}/\d{4}'))) {
          final parts = dateStr.split('/');
          deadline = DateTime(
            int.parse(parts[2]),
            int.parse(parts[1]),
            int.parse(parts[0]),
          );
        }
        // Try MM/dd/yyyy format
        else if (dateStr.contains(RegExp(r'^\d{2}-\d{2}-\d{4}'))) {
          final parts = dateStr.split('-');
          deadline = DateTime(
            int.parse(parts[2]),
            int.parse(parts[0]),
            int.parse(parts[1]),
          );
        }
        // Try timestamp (milliseconds since epoch)
        else if (RegExp(r'^\d+$').hasMatch(dateStr)) {
          deadline = DateTime.fromMillisecondsSinceEpoch(int.parse(dateStr));
        }
      } catch (e) {
        return null;
      }
    }

    if (deadline == null) return null;

    // Calculate days difference
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final deadlineDate = DateTime(deadline.year, deadline.month, deadline.day);

    return deadlineDate.difference(today).inDays;
  }

  /// Returns a user-friendly string describing days left until deadline
  String? get daysLeftText {
    final days = daysLeft;

    if (days == null) return null;

    if (days > 0) {
      return '$days روز باقی مانده';
    } else if (days == 0) {
      return 'مهلت امروز است';
    } else {
      return '${days.abs()} روز گذشته از مهلت';
    }
  }

  /// Returns a color based on how close the deadline is
  /// Returns null if deadline is invalid
  Color? get deadlineColor {
    final days = daysLeft;

    if (days == null) return null;

    if (days > 7) {
      return Colors.green;      // More than a week left
    } else if (days > 3) {
      return Colors.orange;     // Less than a week but more than 3 days
    } else if (days >= 0) {
      return Colors.deepOrange; // 3 days or less
    } else {
      return Colors.red;        // Overdue
    }
  }

  /// Returns an icon based on deadline status
  IconData? get deadlineIcon {
    final days = daysLeft;

    if (days == null) return null;

    if (days > 7) {
      return Icons.check_circle_outline;
    } else if (days > 3) {
      return Icons.access_time;
    } else if (days >= 0) {
      return Icons.warning_amber;
    } else {
      return Icons.error_outline;
    }
  }

  /// Returns true if the deadline is overdue
  bool get isOverdue {
    final days = daysLeft;
    return days != null && days < 0;
  }

  /// Returns true if the deadline is today
  bool get isToday {
    final days = daysLeft;
    return days != null && days == 0;
  }

  /// Returns true if the deadline is within the next [days] days
  bool isWithinDays(int days) {
    final daysLeft = this.daysLeft;
    return daysLeft != null && daysLeft >= 0 && daysLeft <= days;
  }
}

class ZDateFormatter {
  static DateTime? parse(dynamic value) {
    if (value == null) return null;

    if (value is DateTime) return value;

    if (value is String && value.isNotEmpty) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }

    return null;
  }
}
