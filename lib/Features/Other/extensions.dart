import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:zaitoonpro/Localizations/l10n/translations/app_localizations.dart';

// Font Scaler based on screen size
extension FontScaler on BuildContext {
  double scaledFont(double multiplier, {double min = 12, double max = 20}) {
    final size = MediaQuery.of(this).size.width * multiplier;
    return size.clamp(min, max);
  }
}
// Helper extension for compact amount formatting
extension CompactAmount on double {
  String toCompactAmount() {
    if (this >= 1000000) {
      return '\$${(this / 1000000).toStringAsFixed(1)}M';
    } else if (this >= 1000) {
      return '\$${(this / 1000).toStringAsFixed(1)}K';
    }
    return '\$${toStringAsFixed(0)}';
  }
}
//Get the first letter of a word
extension GetFirstLetterExtension on String {
  /// Returns the first letter(s) of a name:
  /// - If 1 or 2 words: returns first letter of each.
  /// - If 3+ words: returns first letter of first and last words.
  String get getFirstLetter {
    final words = split(RegExp(r'\s+'))
        .where((word) => word.trim().isNotEmpty)
        .toList();

    if (words.isEmpty) return '';

    if (words.length == 1) {
      return words.first[0];
    } else if (words.length == 2) {
      return '${words[0][0]} ${words[1][0]}';
    } else {
      return '${words.first[0]} ${words.last[0]}';
    }
  }
}

// Open Features/Other/extensions.dart
// If firstWhereOrNull doesn't exist, add it:
extension ListExtensions<T> on List<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}

//Amount Formats
extension NumberFormatting on Object? {
  /// Converts string or number to double with optional decimal rounding
  /// [decimal] - number of decimal places to round to (default: null = no rounding)
  double toDoubleAmount({int? decimal}) {
    if (this == null) return 0;

    double result;
    if (this is num) {
      result = (this as num).toDouble();
    } else if (this is String) {
      final clean = (this as String)
          .replaceAll(',', '')
          .replaceAll(' ', '');
      result = double.tryParse(clean) ?? 0;
    } else {
      result = 0;
    }

    // Apply decimal rounding if specified
    if (decimal != null) {
      return double.parse(result.toStringAsFixed(decimal));
    }
    return result;
  }

  /// Formats number with commas and decimals
  String toAmount({int decimal = 2}) {
    final value = toDoubleAmount();
    final parts = value.toStringAsFixed(decimal).split('.');

    final integerPart = parts[0].replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (_) => ',',
    );

    return decimal > 0
        ? '$integerPart.${parts[1]}'
        : integerPart;
  }

  /// Formats number as integer (no decimals)
  String toAmountInt() {
    return toAmount(decimal: 0);
  }
}


extension AmountCleaner on String {
  String get cleanAmount => replaceAll(RegExp(r'[^\d.]'), '');
}

extension CurrencyRateFormatter on Object? {
  String toExchangeRate() {
    double rate;

    // Parse input to double
    if (this is String) {
      rate = double.tryParse(this as String) ?? 0.00;
    } else if (this is num) {
      rate = (this as num).toDouble();
    } else {
      return ""; // Return empty string for unsupported types
    }

    // Format with up to 8 decimal places
    final formatted = rate.toStringAsFixed(8);

    // Trim trailing zeros and optional decimal point
    final trimmed = formatted.replaceAll(RegExp(r'(\.?0+)$'), '');

    // If we removed all decimals, add .0 to indicate it's a rate
    return trimmed.contains('.') ? trimmed : '$trimmed.0';
  }
}

extension TimeAgoDateTime on DateTime {
  String toTimeAgo() {
    final now = DateTime.now();
    final diff = now.difference(this);

    if (diff.inSeconds < 10) {
      return 'just now';
    }

    if (diff.inMinutes < 1) {
      return '${diff.inSeconds} seconds ago';
    }

    if (diff.inMinutes < 60) {
      return _plural(diff.inMinutes, 'minute');
    }

    if (diff.inHours < 24) {
      return _plural(diff.inHours, 'hour');
    }

    if (diff.inDays == 1) {
      return 'yesterday';
    }

    if (diff.inDays < 7) {
      return _plural(diff.inDays, 'day');
    }

    final weeks = (diff.inDays / 7).floor();
    if (weeks < 4) {
      return _plural(weeks, 'week');
    }

    final months = (diff.inDays / 30).floor();
    if (months < 12) {
      return _plural(months, 'month');
    }

    final years = (diff.inDays / 365).floor();
    return _plural(years, 'year');
  }
}

extension TimeAgoString on String {
  String toTimeAgo({
    String pattern = 'yyyy-MM-dd HH:mm:ss',
  }) {
    try {
      final date = DateFormat(pattern).parse(this);
      return date.toTimeAgo();
    } catch (_) {
      return this;
    }
  }
}

extension ReminderDueExtension on DateTime {

  String toDueStatus(AppLocalizations tr) {
    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(year, month, day);

    final diff = due.difference(today).inDays;

    if (diff == 0) return tr.dueToday;

    if (diff == 1) return tr.dueTomorrow;

    if (diff > 1) {
      return "${tr.dueType} $diff ${diff == 1 ? tr.dayTitle : tr.daysTitle}";
    }

    final overdue = diff.abs();

    if (overdue == 1) return tr.overdueByOne;

    return "${tr.overdueBy} $overdue ${tr.daysTitle}";
  }
}


String _plural(int value, String unit) {
  return value == 1
      ? '1 $unit ago'
      : '$value ${unit}s ago';
}