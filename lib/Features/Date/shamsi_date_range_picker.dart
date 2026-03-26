import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart';
import '../../Localizations/l10n/translations/app_localizations.dart';
import '../Widgets/outline_button.dart';

class JalaliRange {
  final Jalali start;
  final Jalali end;

  JalaliRange(this.start, this.end);

  bool contains(Jalali date) {
    return date.toGregorian().toDateTime().millisecondsSinceEpoch >=
        start.toGregorian().toDateTime().millisecondsSinceEpoch &&
        date.toGregorian().toDateTime().millisecondsSinceEpoch <=
            end.toGregorian().toDateTime().millisecondsSinceEpoch;
  }

  @override
  String toString() =>
      '${start.year}/${start.month}/${start.day} - ${end.year}/${end.month}/${end.day}';
}

enum QuickOption {
  none,
  today,
  yesterday,
  lastWeek,
  last90Days,
  thisMonth,
  lastMonth,
  lastYear,
  thisYear,
  allTime,
}

class AfghanDateRangePicker extends StatefulWidget {
  final ValueChanged<JalaliRange> onRangeSelected;
  final JalaliRange? initialRange;
  final int minYear;
  final int maxYear;

  const AfghanDateRangePicker({
    super.key,
    required this.onRangeSelected,
    this.initialRange,
    this.minYear = 1300,
    this.maxYear = 1500,
  });

  @override
  AfghanDateRangePickerState createState() => AfghanDateRangePickerState();
}

class AfghanDateRangePickerState extends State<AfghanDateRangePicker> {
  late JalaliRange _selectedRange;
  late Jalali _currentMonth;
  late Jalali _today;
  final List<String> _weekdays = ['ش', 'ی', 'د', 'س', 'چ', 'پ', 'ج'];

  bool _showYearSelector = false;
  bool _showQuickOptions = true;
  late int _selectedYear;
  Jalali? _startDate;
  Jalali? _endDate;
  late ScrollController _yearScrollController;

  QuickOption _selectedQuickOption = QuickOption.none;

  @override
  void initState() {
    super.initState();
    _today = Jalali.now();
    _selectedRange = widget.initialRange ?? JalaliRange(_today, _today);
    _currentMonth = Jalali(_selectedRange.start.year, _selectedRange.start.month, 1);
    _selectedYear = _selectedRange.start.year;
    _startDate = _selectedRange.start;
    _endDate = _selectedRange.end;
    _yearScrollController = ScrollController();

    _determineInitialQuickOption();
  }

  void _determineInitialQuickOption() {
    if (_startDate == null || _endDate == null) {
      _selectedQuickOption = QuickOption.none;
      return;
    }

    try {
      final todayDate = Jalali(_today.year, _today.month, _today.day);
      final startDateOnly = Jalali(_startDate!.year, _startDate!.month, _startDate!.day);
      final endDateOnly = Jalali(_endDate!.year, _endDate!.month, _endDate!.day);

      // Check Today
      if (startDateOnly == todayDate && endDateOnly == todayDate) {
        _selectedQuickOption = QuickOption.today;
        return;
      }

      // Check Yesterday
      final yesterday = _getYesterday(todayDate);
      if (startDateOnly == yesterday && endDateOnly == yesterday) {
        _selectedQuickOption = QuickOption.yesterday;
        return;
      }

      // Check Last Week
      final lastWeekEnd = _getYesterday(todayDate);
      final lastWeekStart = _getDaysAgo(todayDate, 7);
      if (startDateOnly == lastWeekStart && endDateOnly == lastWeekEnd) {
        _selectedQuickOption = QuickOption.lastWeek;
        return;
      }

      // Check Last 90 Days
      final last90DaysEnd = _getYesterday(todayDate);
      final last90DaysStart = _getDaysAgo(todayDate, 90);
      if (startDateOnly == last90DaysStart && endDateOnly == last90DaysEnd) {
        _selectedQuickOption = QuickOption.last90Days;
        return;
      }

      // Check This Month
      final thisMonthStart = Jalali(_today.year, _today.month, 1);
      if (startDateOnly == thisMonthStart && endDateOnly == todayDate) {
        _selectedQuickOption = QuickOption.thisMonth;
        return;
      }

      // Check Last Month - FIXED: Proper month calculation
      int lastMonthYear = _today.year;
      int lastMonthMonth = _today.month - 1;
      if (lastMonthMonth < 1) {
        lastMonthMonth = 12;
        lastMonthYear--;
      }

      if (lastMonthYear >= widget.minYear) {
        final lastMonthStart = Jalali(lastMonthYear, lastMonthMonth, 1);
        final lastMonthEnd = Jalali(lastMonthYear, lastMonthMonth, _getMonthLength(lastMonthYear, lastMonthMonth));

        if (startDateOnly == lastMonthStart && endDateOnly == lastMonthEnd) {
          _selectedQuickOption = QuickOption.lastMonth;
          return;
        }
      }

      // Check Last Year
      final lastYear = _today.year - 1;
      if (lastYear >= widget.minYear) {
        final lastYearStart = Jalali(lastYear, 1, 1);
        final lastYearEnd = Jalali(lastYear, 12, _getMonthLength(lastYear, 12));

        if (startDateOnly == lastYearStart && endDateOnly == lastYearEnd) {
          _selectedQuickOption = QuickOption.lastYear;
          return;
        }
      }

      // Check This Year
      final thisYearStart = Jalali(_today.year, 1, 1);
      if (startDateOnly == thisYearStart && endDateOnly == todayDate) {
        _selectedQuickOption = QuickOption.thisYear;
        return;
      }

      // Check All Time
      final allTimeStart = Jalali(widget.minYear, 1, 1);
      if (startDateOnly == allTimeStart && endDateOnly == todayDate) {
        _selectedQuickOption = QuickOption.allTime;
        return;
      }

      _selectedQuickOption = QuickOption.none;
    } catch (e) {
      debugPrint('Error determining quick option: $e');
      _selectedQuickOption = QuickOption.none;
    }
  }

  Jalali _getYesterday(Jalali date) {
    try {
      final gregorian = date.toGregorian();
      final yesterdayGreg = gregorian.toDateTime().subtract(const Duration(days: 1));
      return Jalali.fromGregorian(
          Gregorian(yesterdayGreg.year, yesterdayGreg.month, yesterdayGreg.day)
      );
    } catch (e) {
      debugPrint('Error getting yesterday: $e');
      return date;
    }
  }

  Jalali _getDaysAgo(Jalali date, int days) {
    try {
      final gregorian = date.toGregorian();
      final daysAgoGreg = gregorian.toDateTime().subtract(Duration(days: days));
      return Jalali.fromGregorian(
          Gregorian(daysAgoGreg.year, daysAgoGreg.month, daysAgoGreg.day)
      );
    } catch (e) {
      debugPrint('Error getting days ago: $e');
      return date;
    }
  }

  int _getMonthLength(int year, int month) {
    try {
      final jalali = Jalali(year, month, 1);
      return jalali.monthLength;
    } catch (e) {
      debugPrint('Error getting month length for year $year, month $month: $e');
      return 30; // Default fallback
    }
  }

  @override
  void dispose() {
    _yearScrollController.dispose();
    super.dispose();
  }

  String _toPersianNumbers(String input) {
    const english = ['0','1','2','3','4','5','6','7','8','9'];
    const persian = ['۰','۱','۲','۳','۴','۵','۶','۷','۸','۹'];
    for (int i = 0; i < english.length; i++) {
      input = input.replaceAll(english[i], persian[i]);
    }
    return input;
  }

  String _formatDate(Jalali date) {
    final day = _toPersianNumbers(date.day.toString().padLeft(2,'0'));
    final month = _toPersianNumbers(date.month.toString().padLeft(2,'0'));
    final year = _toPersianNumbers(date.year.toString());
    return '$year/$month/$day';
  }

  String _formatRange(Jalali? start, Jalali? end) {
    if (start == null && end == null) return AppLocalizations.of(context)!.selectKeyword;
    if (start == null) return ' تا ${_formatDate(end!)}';
    if (end == null) return ' از ${_formatDate(start)}';
    return '${_formatDate(start)} | ${_formatDate(end)}';
  }

  Widget _buildBorderedRangeText(Jalali? start, Jalali? end) {
    final text = _formatRange(start, end);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 5),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          fontFamily: "NotoNaskh",
          color: Theme.of(context).colorScheme.primary.withValues(alpha: .7),
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  bool _isSameDate(Jalali date1, Jalali date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  void _onDateTapped(Jalali date) {
    setState(() {
      _selectedQuickOption = QuickOption.none;

      if (_startDate == null || (_startDate != null && _endDate != null)) {
        _startDate = date;
        _endDate = null;
      } else if (_startDate != null && _endDate == null) {
        if (date.toGregorian().toDateTime().millisecondsSinceEpoch <
            _startDate!.toGregorian().toDateTime().millisecondsSinceEpoch) {
          _endDate = _startDate;
          _startDate = date;
        } else {
          _endDate = date;
        }
      }
    });
  }

  void _confirmSelection() {
    if (_startDate != null && _endDate != null) {
      _selectedRange = JalaliRange(_startDate!, _endDate!);
    } else if (_startDate != null) {
      _selectedRange = JalaliRange(_startDate!, _startDate!);
    } else {
      return;
    }
    _selectedYear = _selectedRange.start.year;
    widget.onRangeSelected(_selectedRange);
  }

  void _selectToday() {
    setState(() {
      _selectedQuickOption = QuickOption.today;
      _startDate = Jalali(_today.year, _today.month, _today.day);
      _endDate = Jalali(_today.year, _today.month, _today.day);
      _currentMonth = Jalali(_today.year, _today.month, 1);
      _selectedYear = _today.year;
    });
  }

  void _selectYesterday() {
    final yesterday = _getYesterday(_today);
    setState(() {
      _selectedQuickOption = QuickOption.yesterday;
      _startDate = yesterday;
      _endDate = yesterday;
      _currentMonth = Jalali(yesterday.year, yesterday.month, 1);
      _selectedYear = yesterday.year;
    });
  }

  void _selectLastWeek() {
    final end = _getYesterday(_today);
    final start = _getDaysAgo(_today, 7);
    setState(() {
      _selectedQuickOption = QuickOption.lastWeek;
      _startDate = start;
      _endDate = end;
      _currentMonth = Jalali(start.year, start.month, 1);
      _selectedYear = start.year;
    });
  }

  void _selectLast90Days() {
    final end = _getYesterday(_today);
    final start = _getDaysAgo(_today, 90);
    setState(() {
      _selectedQuickOption = QuickOption.last90Days;
      _startDate = start;
      _endDate = end;
      _currentMonth = Jalali(start.year, start.month, 1);
      _selectedYear = start.year;
    });
  }

  void _selectThisMonth() {
    final start = Jalali(_today.year, _today.month, 1);
    final end = Jalali(_today.year, _today.month, _today.day);
    setState(() {
      _selectedQuickOption = QuickOption.thisMonth;
      _startDate = start;
      _endDate = end;
      _currentMonth = Jalali(_today.year, _today.month, 1);
      _selectedYear = _today.year;
    });
  }

  void _selectLastMonth() {
    int lastMonthYear = _today.year;
    int lastMonthMonth = _today.month - 1;
    if (lastMonthMonth < 1) {
      lastMonthMonth = 12;
      lastMonthYear--;
    }

    final lastMonthStart = Jalali(lastMonthYear, lastMonthMonth, 1);
    final lastMonthEnd = Jalali(lastMonthYear, lastMonthMonth, _getMonthLength(lastMonthYear, lastMonthMonth));

    setState(() {
      _selectedQuickOption = QuickOption.lastMonth;
      _startDate = lastMonthStart;
      _endDate = lastMonthEnd;
      _currentMonth = Jalali(lastMonthStart.year, lastMonthStart.month, 1);
      _selectedYear = lastMonthStart.year;
    });
  }

  void _selectLastYear() {
    final lastYear = _today.year - 1;
    final lastYearStart = Jalali(lastYear, 1, 1);
    final lastYearEnd = Jalali(lastYear, 12, _getMonthLength(lastYear, 12));

    setState(() {
      _selectedQuickOption = QuickOption.lastYear;
      _startDate = lastYearStart;
      _endDate = lastYearEnd;
      _currentMonth = Jalali(lastYearStart.year, lastYearStart.month, 1);
      _selectedYear = lastYearStart.year;
    });
  }

  void _selectThisYear() {
    final start = Jalali(_today.year, 1, 1);
    final end = Jalali(_today.year, _today.month, _today.day);
    setState(() {
      _selectedQuickOption = QuickOption.thisYear;
      _startDate = start;
      _endDate = end;
      _currentMonth = Jalali(_today.year, _today.month, 1);
      _selectedYear = _today.year;
    });
  }

  void _selectAllTime() {
    final start = Jalali(widget.minYear, 1, 1);
    final end = Jalali(_today.year, _today.month, _today.day);
    setState(() {
      _selectedQuickOption = QuickOption.allTime;
      _startDate = start;
      _endDate = end;
      _currentMonth = Jalali(_today.year, _today.month, 1);
      _selectedYear = _today.year;
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedQuickOption = QuickOption.none;
      _startDate = null;
      _endDate = null;
    });
    Navigator.of(context).pop();
  }

  void _navigateMonth(int offset) {
    setState(() {
      int newMonth = _currentMonth.month + offset;
      int newYear = _currentMonth.year;

      if (newMonth > 12) {
        newMonth = 1;
        newYear++;
      } else if (newMonth < 1) {
        newMonth = 12;
        newYear--;
      }

      if (newYear >= widget.minYear && newYear <= widget.maxYear) {
        _currentMonth = Jalali(newYear, newMonth, 1);
        _selectedYear = newYear;
      }
    });
  }

  void _changeYear(int year) {
    setState(() {
      _selectedYear = year;
      if (year >= widget.minYear && year <= widget.maxYear) {
        _currentMonth = Jalali(year, _currentMonth.month, 1);
      }
      _showYearSelector = false;
    });
  }

  void _scrollToSelectedYear() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final index = _selectedYear - widget.minYear;
      const rowHeight = 35.0;
      final offset = (index ~/ 3) * rowHeight - 50;
      if (_yearScrollController.hasClients) {
        _yearScrollController.animateTo(
          offset.clamp(0.0, _yearScrollController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _getAfghanMonthName(int month) {
    const monthNames = {
      1: 'حمل',
      2: 'ثور',
      3: 'جوزا',
      4: 'سرطان',
      5: 'اسد',
      6: 'سنبله',
      7: 'میزان',
      8: 'عقرب',
      9: 'قوس',
      10: 'جدی',
      11: 'دلو',
      12: 'حوت',
    };
    return monthNames[month] ?? '';
  }

  bool _isQuickOptionSelected(QuickOption option) {
    return _selectedQuickOption == option;
  }

  Widget _buildQuickOption({
    required String label,
    required VoidCallback onTap,
    required QuickOption option,
  }) {
    final color = Theme.of(context).colorScheme;
    final isSelected = _isQuickOptionSelected(option);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: () {
          onTap();
          setState(() {});
        },
        borderRadius: BorderRadius.circular(4),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? color.primary.withValues(alpha: .1) : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isSelected ? color.primary.withValues(alpha: .1) : Colors.transparent,
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? color.primary : color.onSurface,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme;

    int monthLength;
    int firstWeekdayOfMonth;

    try {
      monthLength = _currentMonth.monthLength;
      firstWeekdayOfMonth = _currentMonth.weekDay;
    } catch (e) {
      debugPrint('Error getting month data: $e');
      monthLength = 30;
      firstWeekdayOfMonth = 1;
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: _showYearSelector ? 650 : (_showQuickOptions ? 500 : 400),
        height: 480,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: color.surface,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_showQuickOptions)
                    Container(
                      width: 140,
                      padding: const EdgeInsets.all(5),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              child: Column(
                                children: [
                                  _buildQuickOption(
                                    label: locale.today,
                                    onTap: _selectToday,
                                    option: QuickOption.today,
                                  ),
                                  _buildQuickOption(
                                    label: locale.yesterday,
                                    onTap: _selectYesterday,
                                    option: QuickOption.yesterday,
                                  ),
                                  _buildQuickOption(
                                    label: locale.lastWeek,
                                    onTap: _selectLastWeek,
                                    option: QuickOption.lastWeek,
                                  ),
                                  _buildQuickOption(
                                    label: locale.lastMonth,
                                    onTap: _selectLastMonth,
                                    option: QuickOption.lastMonth,
                                  ),
                                  _buildQuickOption(
                                    label: locale.lastThreeMonth,
                                    onTap: _selectLast90Days,
                                    option: QuickOption.last90Days,
                                  ),
                                  _buildQuickOption(
                                    label: locale.thisMonth,
                                    onTap: _selectThisMonth,
                                    option: QuickOption.thisMonth,
                                  ),
                                  _buildQuickOption(
                                    label: locale.lastYear,
                                    onTap: _selectLastYear,
                                    option: QuickOption.lastYear,
                                  ),
                                  _buildQuickOption(
                                    label: locale.thisYear,
                                    onTap: _selectThisYear,
                                    option: QuickOption.thisYear,
                                  ),
                                  _buildQuickOption(
                                    label: locale.allTime,
                                    onTap: _selectAllTime,
                                    option: QuickOption.allTime,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (_showQuickOptions) ...[
                    const SizedBox(width: 5),
                    SizedBox(
                      height: double.infinity,
                      child: VerticalDivider(width: 1, color: color.outlineVariant),
                    ),
                    const SizedBox(width: 5),
                  ],

                  if (_showYearSelector) ...[
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 130,
                      height: double.infinity,
                      child: GridView.builder(
                        controller: _yearScrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 4,
                          crossAxisSpacing: 4,
                          childAspectRatio: 1,
                        ),
                        itemCount: widget.maxYear - widget.minYear + 1,
                        itemBuilder: (context, index) {
                          final year = widget.minYear + index;
                          final selected = year == _selectedYear;
                          return InkWell(
                            onTap: () => _changeYear(year),
                            child: Container(
                              decoration: BoxDecoration(
                                color: selected ? color.primary : color.surface,
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Center(
                                child: Text(
                                  _toPersianNumbers(year.toString()),
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: selected ? color.surface : color.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: double.infinity,
                      child: VerticalDivider(width: 1, color: color.outlineVariant),
                    ),
                    const SizedBox(width: 10),
                  ],

                  Expanded(
                    child: Column(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(3.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: _buildBorderedRangeText(_startDate, _endDate),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        _showQuickOptions ? Icons.menu_open : Icons.menu,
                                        size: 20,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _showQuickOptions = !_showQuickOptions;
                                        });
                                      },
                                      tooltip: 'نمایش/مخفی کردن گزینه‌ها',
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(3.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    InkWell(
                                      onTap: () {
                                        setState(() {
                                          _showYearSelector = !_showYearSelector;
                                          if (_showYearSelector) _scrollToSelectedYear();
                                        });
                                      },
                                      child: Text(
                                        '${_getAfghanMonthName(_currentMonth.month)} | ${_toPersianNumbers(_selectedYear.toString())}',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: color.primary,
                                        ),
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: Icon(Icons.chevron_left),
                                          onPressed: () => _navigateMonth(-1),
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.chevron_right),
                                          onPressed: () => _navigateMonth(1),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: _weekdays
                                    .map((d) => Expanded(
                                  child: Center(
                                    child: Text(
                                      d,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: color.primary.withAlpha(180),
                                      ),
                                    ),
                                  ),
                                ))
                                    .toList(),
                              ),
                              const SizedBox(height: 6),
                              Expanded(
                                child: GridView.builder(
                                  physics: const NeverScrollableScrollPhysics(),
                                  padding: EdgeInsets.zero,
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 7,
                                    childAspectRatio: 1,
                                  ),
                                  itemCount: firstWeekdayOfMonth + monthLength - 1,
                                  itemBuilder: (context, index) {
                                    if (index < firstWeekdayOfMonth - 1) return const SizedBox.shrink();
                                    final day = index - firstWeekdayOfMonth + 2;

                                    Jalali? date;
                                    try {
                                      date = Jalali(_currentMonth.year, _currentMonth.month, day);
                                    } catch (e) {
                                      return const SizedBox.shrink();
                                    }

                                    final isStartDate = _startDate != null && _isSameDate(date, _startDate!);
                                    final isEndDate = _endDate != null && _isSameDate(date, _endDate!);
                                    final isInRange = _startDate != null && _endDate != null &&
                                        date.toGregorian().toDateTime().isAfter(_startDate!.toGregorian().toDateTime().subtract(const Duration(days: 1))) &&
                                        date.toGregorian().toDateTime().isBefore(_endDate!.toGregorian().toDateTime().add(const Duration(days: 1)));

                                    Color? background;
                                    BoxShape shape = BoxShape.rectangle;
                                    if (isStartDate || isEndDate) {
                                      background = color.primary;
                                      shape = BoxShape.circle;
                                    } else if (isInRange) {
                                      background = color.primary.withAlpha(20);
                                    }

                                    bool isToday = false;
                                    try {
                                      isToday = _isSameDate(date, _today);
                                    } catch (e) {
                                      isToday = false;
                                    }

                                    return GestureDetector(
                                      onTap: () => _onDateTapped(date ?? _today),
                                      child: Container(
                                        margin: EdgeInsets.zero,
                                        decoration: BoxDecoration(
                                          color: background,
                                          shape: shape,
                                          border: isToday ? Border.all(color: color.primary, width: 1) : null,
                                        ),
                                        child: Center(
                                          child: Text(
                                            _toPersianNumbers(day.toString()),
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: isStartDate || isEndDate
                                                  ? color.surface
                                                  : isToday
                                                  ? color.primary
                                                  : color.secondary,
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
                        Padding(
                          padding: const EdgeInsets.only(right: 8, bottom: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              ZOutlineButton(
                                onPressed: _clearSelection,
                                label: Text(locale.cancel),
                              ),
                              const SizedBox(width: 8),
                              ZOutlineButton(
                                isActive: true,
                                onPressed: (_startDate != null) ? _confirmSelection : null,
                                label: Text(locale.selectKeyword),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}