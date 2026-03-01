import 'package:flutter/material.dart';
import '../../Localizations/l10n/translations/app_localizations.dart';
import '../Widgets/button.dart';
import '../Widgets/outline_button.dart';

class GregorianDatePicker extends StatefulWidget {
  final ValueChanged<DateTime> onDateSelected;
  final DateTime? initialDate;
  final int minYear;
  final int maxYear;
  final bool disablePastDates;

  const GregorianDatePicker({
    super.key,
    required this.onDateSelected,
    this.initialDate,
    this.minYear = 1900,
    this.maxYear = 2100,
    this.disablePastDates = false,  
  });

  @override
  GregorianDatePickerState createState() => GregorianDatePickerState();
}

class GregorianDatePickerState extends State<GregorianDatePicker> {
  late DateTime _selectedDate;
  late DateTime _currentMonth;
  late DateTime _today;
  final List<String> _weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  bool _showYearSelector = false;
  late int _selectedYear;
  DateTime? _pendingSelection;

  late ScrollController _yearScrollController;

  @override
  void initState() {
    super.initState();
    _today = DateTime.now();

    // If past dates are disabled and initial date is in past, use today
    if (widget.disablePastDates && widget.initialDate != null && widget.initialDate!.isBefore(_today)) {
      _selectedDate = DateTime(_today.year, _today.month, _today.day);
    } else {
      _selectedDate = widget.initialDate ?? DateTime(_today.year, _today.month, _today.day);
    }

    _currentMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
    _selectedYear = _selectedDate.year;
    _yearScrollController = ScrollController();
  }

  @override
  void dispose() {
    _yearScrollController.dispose();
    super.dispose();
  }

  String _formatSelectedDate(DateTime date) {
    final weekday = _getWeekdayName(date.weekday);
    final month = _getMonthName(date.month);
    final year = date.year.toString();
    final day = date.day.toString().padLeft(2, '0');
    return '$weekday, $month $day $year';
  }

  String _getWeekdayName(int weekday) {
    const weekdays = {
      1: 'Sunday',
      2: 'Monday',
      3: 'Tuesday',
      4: 'Wednesday',
      5: 'Thursday',
      6: 'Friday',
      7: 'Saturday',
    };
    return weekdays[weekday] ?? '';
  }

  bool _isSameDate(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  void _onDateTapped(DateTime date) {
    // Check if past dates are disabled and date is in past
    if (widget.disablePastDates && _isDateBeforeToday(date)) {
      return;
    }
    setState(() {
      _pendingSelection = date;
    });
  }

  void _confirmSelection() {
    if (_pendingSelection != null) {
      // Double-check that the pending selection is valid
      if (widget.disablePastDates && _isDateBeforeToday(_pendingSelection!)) {
        return;
      }

      setState(() {
        _selectedDate = _pendingSelection!;
        _selectedYear = _pendingSelection!.year;
      });
      widget.onDateSelected(_pendingSelection!);
      Navigator.of(context).pop();
    }
  }

  void _selectToday() {
    setState(() {
      _pendingSelection = _today;
      _selectedDate = _today;
      _currentMonth = DateTime(_today.year, _today.month, 1);
      _selectedYear = _today.year;
    });
  }

  void _navigateMonth(int offset) {
    setState(() {
      final newMonth = DateTime(_currentMonth.year, _currentMonth.month + offset, 1);

      // If past dates are disabled and trying to navigate to past months, limit to current month
      if (widget.disablePastDates) {
        if (newMonth.year < _today.year ||
            (newMonth.year == _today.year && newMonth.month < _today.month)) {
          _currentMonth = DateTime(_today.year, _today.month, 1);
          _selectedYear = _today.year;
          return;
        }
      }

      _currentMonth = newMonth;
      _selectedYear = newMonth.year;
    });
  }

  void _changeYear(int year) {
    // If past dates are disabled, don't allow selecting years before current year
    if (widget.disablePastDates && year < _today.year) {
      return;
    }

    setState(() {
      _selectedYear = year;

      // If we're in the current year, make sure we don't go to a past month
      if (widget.disablePastDates && year == _today.year) {
        final currentMonth = _currentMonth.month;
        if (currentMonth < _today.month) {
          _currentMonth = DateTime(year, _today.month, 1);
        } else {
          _currentMonth = DateTime(year, currentMonth, 1);
        }
      } else {
        _currentMonth = DateTime(year, _currentMonth.month, 1);
      }

      _showYearSelector = false;
    });
  }

  void _scrollToSelectedYear() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final index = _selectedYear - widget.minYear;
      final row = index ~/ 3; // because crossAxisCount = 3
      const rowHeight = 25.0; // approximate height per row
      final offset = (row * rowHeight) - 60; // center-ish
      if (_yearScrollController.hasClients) {
        _yearScrollController.animateTo(
          offset.clamp(0.0, _yearScrollController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // Helper method to check if a date is before today (ignoring time)
  bool _isDateBeforeToday(DateTime date) {
    final today = DateTime(_today.year, _today.month, _today.day);
    final compareDate = DateTime(date.year, date.month, date.day);
    return compareDate.isBefore(today);
  }

  // Helper method to check if a date is disabled
  bool _isDateDisabled(DateTime date) {
    return widget.disablePastDates && _isDateBeforeToday(date);
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme;
    final monthLength = _getMonthLength(_currentMonth.month, _currentMonth.year);
    final firstWeekdayOfMonth = _currentMonth.weekday;

    final showYearPanel = _showYearSelector;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: showYearPanel ? 500 : 340,
        height: 450,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: color.surface,
          borderRadius: BorderRadius.circular(5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .1),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          spacing: 10,
          children: [
            // LEFT: Year selector (slides in by width expansion)
            if (showYearPanel) ...[
              SizedBox(
                width: 180,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text(
                          locale.selectYear,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: color.primary.withValues(alpha: .7),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: GridView.builder(
                        controller: _yearScrollController,
                        padding: const EdgeInsets.all(8),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 2,
                          mainAxisSpacing: 4,
                          crossAxisSpacing: 4,
                        ),
                        itemCount: widget.maxYear - widget.minYear + 1,
                        itemBuilder: (context, index) {
                          final year = widget.minYear + index;
                          final isSelected = year == _selectedYear;
                          final isPastYear = widget.disablePastDates && year < _today.year;

                          return InkWell(
                            onTap: isPastYear ? null : () => _changeYear(year),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected ? color.primary : color.surface,
                                borderRadius: BorderRadius.circular(3),
                                border: Border.all(
                                  color: isPastYear ? color.outline.withValues(alpha: .3) : Colors.transparent,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  year.toString(),
                                  style: TextStyle(
                                    color: isSelected ? color.surface :
                                    isPastYear ? color.outline.withValues(alpha: .5) : color.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              VerticalDivider(width: 1, color: color.outlineVariant),
            ],

            // RIGHT: Calendar content
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.max, // allow Expanded children
                children: [
                  // Selected date display (header 1) — prevent overflow
                  Row(
                    spacing: 5,
                    children: [
                      Icon(Icons.calendar_month_rounded, color: color.outline),
                      Expanded(
                        child: Text(
                          _formatSelectedDate(_pendingSelection ?? _selectedDate),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: color.outline,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),

                  // Month/year nav (header 2) — prevent overflow
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setState(() => _showYearSelector = !_showYearSelector);
                              if (_showYearSelector) _scrollToSelectedYear();
                            },
                            child: Text(
                              '${_getMonthName(_currentMonth.month)} | ${_currentMonth.year}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: color.primary.withValues(alpha: .9),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              softWrap: false,
                            ),
                          ),
                        ),
                        IconButton(
                          iconSize: 20,
                          icon: Icon(Icons.chevron_left, color: color.secondary),
                          onPressed: () {
                            if (widget.disablePastDates) {
                              final prevMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
                              if (prevMonth.year < _today.year ||
                                  (prevMonth.year == _today.year && prevMonth.month < _today.month)) {
                                return;
                              }
                            }
                            _navigateMonth(-1);
                          },
                          tooltip: 'Previous month',
                        ),
                        IconButton(
                          iconSize: 20,
                          icon: Icon(Icons.chevron_right, color: color.secondary),
                          onPressed: () => _navigateMonth(1),
                          tooltip: 'Next month',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Middle area takes the remaining height; grid scrolls if needed
                  Expanded(
                    child: Column(
                      children: [
                        // Weekdays row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: _weekdays.map((day) {
                            return Expanded(
                              child: Center(
                                child: Text(
                                  day,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: color.primary.withValues(alpha: .7),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 6),

                        // Calendar grid fills remainder and is scrollable if tight
                        Expanded(
                          child: GridView.builder(
                            physics: const ClampingScrollPhysics(),
                            padding: EdgeInsets.zero,
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 7,
                              childAspectRatio: 1.1,
                            ),
                            itemCount: 42,
                            itemBuilder: (context, index) {
                              final dayOffset = index - (firstWeekdayOfMonth % 7);
                              final isCurrentMonthDay = dayOffset >= 0 && dayOffset < monthLength;
                              final day = isCurrentMonthDay ? dayOffset + 1 : null;
                              final date = isCurrentMonthDay
                                  ? DateTime(_currentMonth.year, _currentMonth.month, day!)
                                  : null;

                              final isSelected = date != null && _pendingSelection != null
                                  ? _isSameDate(date, _pendingSelection!)
                                  : date != null && _isSameDate(date, _selectedDate);
                              final isToday = date != null && _isSameDate(date, _today);
                              final isDisabled = date != null && _isDateDisabled(date);

                              return InkWell(
                                onTap: (date != null && !isDisabled) ? () => _onDateTapped(date) : null,
                                child: Container(
                                  margin: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? color.primary
                                        : isToday
                                        ? color.primary.withValues(alpha: .2)
                                        : isDisabled
                                        ? color.surface.withValues(alpha: .3)
                                        : null,
                                    shape: BoxShape.circle,
                                    border: isToday ? Border.all(color: color.primary, width: 1) : null,
                                  ),
                                  child: Center(
                                    child: Text(
                                      day != null ? day.toString() : '',
                                      style: TextStyle(
                                        color: isSelected
                                            ? color.surface
                                            : isToday
                                            ? color.primary
                                            : isDisabled
                                            ? color.outline.withValues(alpha: 0.5)
                                            : isCurrentMonthDay
                                            ? color.secondary
                                            : color.surface.withValues(alpha: .0),
                                        fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 5),

                  // Footer (fixed), stays visible
                  Row(
                    children: [
                      ZOutlineButton(
                        height: 30,
                        width: 90,
                        onPressed: _selectToday,
                        label: Text(locale.today),
                      ),
                      const SizedBox(width: 8),
                      ZButton(
                        width: 90,
                        height: 30,
                        onPressed: _pendingSelection != null ? _confirmSelection : null,
                        label: Text(locale.selectKeyword),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _getMonthLength(int month, int year) {
    if (month == 2) {
      return _isLeapYear(year) ? 29 : 28;
    } else if ([4, 6, 9, 11].contains(month)) {
      return 30;
    } else {
      return 31;
    }
  }

  bool _isLeapYear(int year) {
    return (year % 4 == 0) && (year % 100 != 0) || (year % 400 == 0);
  }

  String _getMonthName(int month) {
    const monthNames = {
      1: 'January',
      2: 'February',
      3: 'March',
      4: 'April',
      5: 'May',
      6: 'June',
      7: 'July',
      8: 'August',
      9: 'September',
      10: 'October',
      11: 'November',
      12: 'December',
    };
    return monthNames[month] ?? '';
  }
}