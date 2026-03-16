import 'package:flutter/material.dart';
import '../../Localizations/l10n/translations/app_localizations.dart';
import '../Widgets/outline_button.dart';

class ZGregorianRangePicker {
  final DateTime start;
  final DateTime end;

  ZGregorianRangePicker(this.start, this.end);

  bool contains(DateTime date) {
    return date.isAfter(start.subtract(const Duration(days: 1))) &&
        date.isBefore(end.add(const Duration(days: 1)));
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

class GregorianDateRangePicker extends StatefulWidget {
  final ValueChanged<ZGregorianRangePicker> onRangeSelected;
  final ZGregorianRangePicker? initialRange;
  final int minYear;
  final int maxYear;

  const GregorianDateRangePicker({
    super.key,
    required this.onRangeSelected,
    this.initialRange,
    this.minYear = 1900,
    this.maxYear = 2100,
  });

  @override
  GregorianDateRangePickerState createState() => GregorianDateRangePickerState();
}

class GregorianDateRangePickerState extends State<GregorianDateRangePicker> {
  late ZGregorianRangePicker _selectedRange;
  late DateTime _currentMonth;
  late DateTime _today;
  final List<String> _weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  bool _showYearSelector = false;
  bool _showQuickOptions = true;
  late int _selectedYear;
  DateTime? _startDate;
  DateTime? _endDate;
  late ScrollController _yearScrollController;

  // Track selected quick option
  QuickOption _selectedQuickOption = QuickOption.none;

  @override
  void initState() {
    super.initState();
    _today = DateTime.now();
    _selectedRange =
        widget.initialRange ?? ZGregorianRangePicker(_today, _today);
    _currentMonth =
        DateTime(_selectedRange.start.year, _selectedRange.start.month, 1);
    _selectedYear = _selectedRange.start.year;
    _startDate = _selectedRange.start;
    _endDate = _selectedRange.end;
    _yearScrollController = ScrollController();

    // Determine which quick option matches the initial range
    _determineInitialQuickOption();
  }

  void _determineInitialQuickOption() {
    if (_startDate == null || _endDate == null) {
      _selectedQuickOption = QuickOption.none;
      return;
    }

    // Create date objects without time components for comparison
    final todayDate = DateTime(_today.year, _today.month, _today.day);
    final startDateOnly = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
    final endDateOnly = DateTime(_endDate!.year, _endDate!.month, _endDate!.day);

    // Check Today
    if (startDateOnly == todayDate && endDateOnly == todayDate) {
      _selectedQuickOption = QuickOption.today;
      return;
    }

    // Check Yesterday
    final yesterday = todayDate.subtract(const Duration(days: 1));
    if (startDateOnly == yesterday && endDateOnly == yesterday) {
      _selectedQuickOption = QuickOption.yesterday;
      return;
    }

    // Check Last Week
    final lastWeekEnd = todayDate.subtract(const Duration(days: 1));
    final lastWeekStart = todayDate.subtract(const Duration(days: 7));
    if (startDateOnly == lastWeekStart && endDateOnly == lastWeekEnd) {
      _selectedQuickOption = QuickOption.lastWeek;
      return;
    }

    // Check Last 90 Days
    final last90DaysEnd = todayDate.subtract(const Duration(days: 1));
    final last90DaysStart = todayDate.subtract(const Duration(days: 90));
    if (startDateOnly == last90DaysStart && endDateOnly == last90DaysEnd) {
      _selectedQuickOption = QuickOption.last90Days;
      return;
    }

    // Check This Month
    final thisMonthStart = DateTime(_today.year, _today.month, 1);
    if (startDateOnly == thisMonthStart && endDateOnly == todayDate) {
      _selectedQuickOption = QuickOption.thisMonth;
      return;
    }

    // Check Last Month
    final lastMonthEnd = DateTime(_today.year, _today.month, 0);
    final lastMonthStart = DateTime(_today.year, _today.month - 1, 1);
    if (startDateOnly == lastMonthStart && endDateOnly == lastMonthEnd) {
      _selectedQuickOption = QuickOption.lastMonth;
      return;
    }

    // Check Last Year
    final lastYearEnd = DateTime(_today.year - 1, 12, 31);
    final lastYearStart = DateTime(_today.year - 1, 1, 1);
    if (startDateOnly == lastYearStart && endDateOnly == lastYearEnd) {
      _selectedQuickOption = QuickOption.lastYear;
      return;
    }

    // Check This Year
    final thisYearStart = DateTime(_today.year, 1, 1);
    if (startDateOnly == thisYearStart && endDateOnly == todayDate) {
      _selectedQuickOption = QuickOption.thisYear;
      return;
    }

    // Check All Time
    final allTimeStart = DateTime(2000, 1, 1);
    if (startDateOnly == allTimeStart && endDateOnly == todayDate) {
      _selectedQuickOption = QuickOption.allTime;
      return;
    }

    _selectedQuickOption = QuickOption.none;
  }

  @override
  void dispose() {
    _yearScrollController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2,'0')}/${date.day.toString().padLeft(2,'0')}';
  }

  String _formatRange(DateTime? start, DateTime? end) {
    if (start == null && end == null) return AppLocalizations.of(context)!.selectDate;
    if (start == null) return 'to ${_formatDate(end!)}';
    if (end == null) return 'from ${_formatDate(start)}';
    return '${_formatDate(start)} - ${_formatDate(end)}';
  }

  void _onDateTapped(DateTime date) {
    setState(() {
      _selectedQuickOption = QuickOption.none; // Reset quick option when manually selecting

      if (_startDate == null || (_startDate != null && _endDate != null)) {
        _startDate = date;
        _endDate = null;
      } else if (_startDate != null && _endDate == null) {
        if (date.isBefore(_startDate!)) {
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
      _selectedRange = ZGregorianRangePicker(_startDate!, _endDate!);
    } else if (_startDate != null) {
      _selectedRange = ZGregorianRangePicker(_startDate!, _startDate!);
    } else {
      return;
    }

    _selectedYear = _selectedRange.start.year;
    widget.onRangeSelected(_selectedRange);
  }

  void _selectToday() {
    setState(() {
      _selectedQuickOption = QuickOption.today;
      _startDate = _today;
      _endDate = _today;
      _currentMonth = DateTime(_today.year, _today.month, 1);
      _selectedYear = _today.year;
    });
  }

  void _selectYesterday() {
    final yesterday = _today.subtract(const Duration(days: 1));
    setState(() {
      _selectedQuickOption = QuickOption.yesterday;
      _startDate = yesterday;
      _endDate = yesterday;
      _currentMonth = DateTime(yesterday.year, yesterday.month, 1);
      _selectedYear = yesterday.year;
    });
  }

  void _selectLastWeek() {
    final end = _today.subtract(const Duration(days: 1));
    final start = _today.subtract(const Duration(days: 7));
    setState(() {
      _selectedQuickOption = QuickOption.lastWeek;
      _startDate = start;
      _endDate = end;
      _currentMonth = DateTime(start.year, start.month, 1);
      _selectedYear = start.year;
    });
  }

  void _selectLast90Days() {
    final end = _today.subtract(const Duration(days: 1));
    final start = _today.subtract(const Duration(days: 90));
    setState(() {
      _selectedQuickOption = QuickOption.last90Days;
      _startDate = start;
      _endDate = end;
      _currentMonth = DateTime(start.year, start.month, 1);
      _selectedYear = start.year;
    });
  }

  void _selectThisMonth() {
    final start = DateTime(_today.year, _today.month, 1);
    final end = _today;
    setState(() {
      _selectedQuickOption = QuickOption.thisMonth;
      _startDate = start;
      _endDate = end;
      _currentMonth = DateTime(_today.year, _today.month, 1);
      _selectedYear = _today.year;
    });
  }

  void _selectThisYear() {
    final start = DateTime(_today.year, 1, 1);
    final end = _today;
    setState(() {
      _selectedQuickOption = QuickOption.thisYear;
      _startDate = start;
      _endDate = end;
      _currentMonth = DateTime(_today.year, _today.month, 1);
      _selectedYear = _today.year;
    });
  }

  void _selectAllTime() {
    final start = DateTime(2000, 1, 1);
    final end = _today;
    setState(() {
      _selectedQuickOption = QuickOption.allTime;
      _startDate = start;
      _endDate = end;
      _currentMonth = DateTime(_today.year, _today.month, 1);
      _selectedYear = _today.year;
    });
  }

  void _selectLastMonth() {
    final end = DateTime(_today.year, _today.month, 0);
    final start = DateTime(_today.year, _today.month - 1, 1);
    setState(() {
      _selectedQuickOption = QuickOption.lastMonth;
      _startDate = start;
      _endDate = end;
      _currentMonth = DateTime(start.year, start.month, 1);
      _selectedYear = start.year;
    });
  }

  void _selectLastYear() {
    final end = DateTime(_today.year - 1, 12, 31);
    final start = DateTime(_today.year - 1, 1, 1);
    setState(() {
      _selectedQuickOption = QuickOption.lastYear;
      _startDate = start;
      _endDate = end;
      _currentMonth = DateTime(start.year, start.month, 1);
      _selectedYear = start.year;
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

      _currentMonth = DateTime(newYear, newMonth, 1);
      _selectedYear = newYear;
    });
  }

  void _changeYear(int year) {
    setState(() {
      _selectedYear = year;
      _currentMonth = DateTime(year, _currentMonth.month, 1);
      _showYearSelector = false;
    });
  }

  void _scrollToSelectedYear() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final index = _selectedYear - widget.minYear;
      const rowHeight = 30.0;
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

  String _getMonthName(int month) {
    const months = [
      'January','February','March','April','May','June','July','August','September','October','November','December'
    ];
    return months[month-1];
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
    final color = Theme.of(context).colorScheme;
    final monthLength = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final firstWeekdayOfMonth = _currentMonth.weekday % 7;
    final tr = AppLocalizations.of(context)!;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: _showYearSelector ? 650 : (_showQuickOptions ? 500 : 370),
        height: 450,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.surface,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Column(
          children: [
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick Options Section (Left Side)
                  if (_showQuickOptions)...[
                    Container(
                      width: 140,
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              child: Column(
                                children: [
                                  _buildQuickOption(
                                    label: tr.today,
                                    onTap: _selectToday,
                                    option: QuickOption.today,
                                  ),
                                  _buildQuickOption(
                                    label: tr.yesterday,
                                    onTap: _selectYesterday,
                                    option: QuickOption.yesterday,
                                  ),
                                  _buildQuickOption(
                                    label: tr.lastWeek,
                                    onTap: _selectLastWeek,
                                    option: QuickOption.lastWeek,
                                  ),
                                  _buildQuickOption(
                                    label: tr.lastMonth,
                                    onTap: _selectLastMonth,
                                    option: QuickOption.lastMonth,
                                  ),
                                  _buildQuickOption(
                                    label: tr.lastThreeMonth,
                                    onTap: _selectLast90Days,
                                    option: QuickOption.last90Days,
                                  ),
                                  _buildQuickOption(
                                    label: tr.lastYear,
                                    onTap: _selectLastYear,
                                    option: QuickOption.lastYear,
                                  ),
                                  _buildQuickOption(
                                    label: tr.thisMonth,
                                    onTap: _selectThisMonth,
                                    option: QuickOption.thisMonth,
                                  ),
                                  _buildQuickOption(
                                    label: tr.thisYear,
                                    onTap: _selectThisYear,
                                    option: QuickOption.thisYear,
                                  ),
                                  _buildQuickOption(
                                    label: tr.allTime,
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
                    const SizedBox(width: 5),
                    VerticalDivider(width: 1, color: color.outlineVariant),
                    const SizedBox(width: 5),
                  ],

                  // Year Selector Section
                  if (_showYearSelector)...[
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 130,
                      child: GridView.builder(
                        controller: _yearScrollController,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 4,
                          crossAxisSpacing: 4,
                          childAspectRatio: 1.5,
                        ),
                        itemCount: widget.maxYear - widget.minYear + 1,
                        itemBuilder: (context,index){
                          final year = widget.minYear + index;
                          final selected = year == _selectedYear;
                          return InkWell(
                            onTap: ()=> _changeYear(year),
                            child: Container(
                              decoration: BoxDecoration(
                                color: selected ? color.primary : color.surface,
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Center(
                                child: Text(year.toString(),style: TextStyle(
                                  color: selected ? color.surface : color.primary,
                                  fontWeight: FontWeight.bold,
                                ),),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],

                  if (_showYearSelector) ...[
                    const SizedBox(width: 10),
                    VerticalDivider(width: 1, color: color.outlineVariant),
                    const SizedBox(width: 10),
                  ],

                  // Calendar Section
                  Expanded(
                    child: Column(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              // Selected range
                              Padding(
                                padding: const EdgeInsets.all(3.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _formatRange(_startDate,_endDate),
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: color.primary.withValues(alpha: .7),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
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
                                      tooltip: 'Toggle quick options',
                                    ),
                                  ],
                                ),
                              ),

                              // Month Navigation
                              Padding(
                                padding: const EdgeInsets.all(3.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    InkWell(
                                      onTap: (){
                                        setState((){
                                          _showYearSelector = !_showYearSelector;
                                          if(_showYearSelector) _scrollToSelectedYear();
                                        });
                                      },
                                      child: Text('${_getMonthName(_currentMonth.month)} | ${_currentMonth.year}',
                                        style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold,color: color.primary),
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        IconButton(onPressed: ()=>_navigateMonth(-1), icon: Icon(Icons.chevron_left)),
                                        IconButton(onPressed: ()=>_navigateMonth(1), icon: Icon(Icons.chevron_right)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 6),

                              // Weekday headers
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: _weekdays.map((d)=>Expanded(child: Center(child: Text(d,style: TextStyle(fontWeight: FontWeight.bold),)))).toList(),
                              ),
                              const SizedBox(height: 6),

                              // Calendar Grid
                              Expanded(
                                child: GridView.builder(
                                  physics: const NeverScrollableScrollPhysics(),
                                  padding: EdgeInsets.zero,
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 7,
                                    childAspectRatio: 1.1,
                                  ),
                                  itemCount: firstWeekdayOfMonth + monthLength - 1,
                                  itemBuilder: (context,index){
                                    if(index < firstWeekdayOfMonth) return const SizedBox.shrink();
                                    final day = index - firstWeekdayOfMonth + 1;
                                    final date = DateTime(_currentMonth.year,_currentMonth.month,day);
                                    final isStartDate = _startDate != null && date.isAtSameMomentAs(_startDate!);
                                    final isEndDate = _endDate != null && date.isAtSameMomentAs(_endDate!);
                                    final isInRange = _startDate != null &&
                                        _endDate != null &&
                                        date.isAfter(_startDate!) &&
                                        date.isBefore(_endDate!);

                                    Color? bg;
                                    BoxShape shape = BoxShape.rectangle;
                                    Border? border;

                                    if(isStartDate || isEndDate){
                                      bg = color.primary;
                                      shape = BoxShape.circle;
                                    } else if(isInRange){
                                      bg = color.primary.withAlpha(20);
                                    }

                                    final isToday = _today.year == date.year &&
                                        _today.month == date.month &&
                                        _today.day == date.day;

                                    if (isToday && !(isStartDate || isEndDate)) {
                                      border = Border.all(color: color.primary, width: 1);
                                    }

                                    return GestureDetector(
                                      onTap: () => _onDateTapped(date),
                                      child: Container(
                                        margin: const EdgeInsets.all(2),
                                        decoration: BoxDecoration(
                                          color: bg,
                                          shape: shape,
                                          border: border,
                                        ),
                                        child: Center(
                                          child: Text(
                                            day.toString(),
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: isStartDate || isEndDate
                                                  ? Colors.white
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
                        // Bottom Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ZOutlineButton(
                              onPressed: _clearSelection,
                              label: Text(AppLocalizations.of(context)!.cancel),
                            ),
                            const SizedBox(width: 8),
                            ZOutlineButton(
                              isActive: true,
                              onPressed: (_startDate != null) ? _confirmSelection : null,
                              label: Text(AppLocalizations.of(context)!.selectKeyword),
                            ),
                          ],
                        )
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