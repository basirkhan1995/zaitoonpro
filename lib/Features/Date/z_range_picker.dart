import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:zaitoon_petroleum/Features/Date/shamsi_converter.dart';
import 'package:zaitoon_petroleum/Features/Date/shamsi_date_range_picker.dart';
import 'gregorian_date_range_picker.dart';

class ZRangeDatePicker extends StatefulWidget {
  final String label;
  final String? startValue;
  final String? endValue;
  final double? height;
  final bool isActive;
  final bool disablePastDate;
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final ValueChanged<String> onStartDateChanged;
  final ValueChanged<String> onEndDateChanged;
  final EdgeInsetsGeometry? padding;
  final TextStyle? labelStyle;
  final TextStyle? gregorianTextStyle;
  final TextStyle? shamsiTextStyle;
  final int minYear;
  final int maxYear;
  final bool showSeparator;

  const ZRangeDatePicker({
    super.key,
    required this.label,
    this.startValue,
    this.endValue,
    this.initialStartDate,
    this.initialEndDate,
    required this.onStartDateChanged,
    required this.onEndDateChanged,
    this.padding,
    this.isActive = false,
    this.height,
    this.labelStyle,
    this.disablePastDate = false,
    this.gregorianTextStyle,
    this.shamsiTextStyle,
    this.minYear = 1900,
    this.maxYear = 2100,
    this.showSeparator = true,
  });

  @override
  State<ZRangeDatePicker> createState() => _ZRangeDatePickerState();
}

class _ZRangeDatePickerState extends State<ZRangeDatePicker> {
  late String selectedStartGregorianDate;
  late String selectedEndGregorianDate;

  @override
  void initState() {
    super.initState();
    _initializeDates();
  }

  void _initializeDates() {
    // Initialize start date
    if (widget.startValue != null && widget.startValue!.isNotEmpty) {
      selectedStartGregorianDate = widget.startValue!;
    } else if (widget.initialStartDate != null) {
      selectedStartGregorianDate = widget.initialStartDate!.toFormattedDate();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onStartDateChanged(selectedStartGregorianDate);
      });
    } else {
      selectedStartGregorianDate = DateTime.now().toFormattedDate();
    }

    // Initialize end date
    if (widget.endValue != null && widget.endValue!.isNotEmpty) {
      selectedEndGregorianDate = widget.endValue!;
    } else if (widget.initialEndDate != null) {
      selectedEndGregorianDate = widget.initialEndDate!.toFormattedDate();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onEndDateChanged(selectedEndGregorianDate);
      });
    } else {
      selectedEndGregorianDate = DateTime.now().toFormattedDate();
    }
  }

  @override
  void didUpdateWidget(covariant ZRangeDatePicker oldWidget) {
    super.didUpdateWidget(oldWidget);

    bool needsUpdate = false;

    // Update start date if changed externally
    if (widget.startValue != null &&
        widget.startValue != oldWidget.startValue &&
        widget.startValue != selectedStartGregorianDate) {
      selectedStartGregorianDate = widget.startValue!;
      needsUpdate = true;
    }

    // Update end date if changed externally
    if (widget.endValue != null &&
        widget.endValue != oldWidget.endValue &&
        widget.endValue != selectedEndGregorianDate) {
      selectedEndGregorianDate = widget.endValue!;
      needsUpdate = true;
    }

    if (needsUpdate) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.label.isNotEmpty) ...[
          Text(
            widget.label,
            style: widget.labelStyle ??
                Theme.of(context).textTheme.titleSmall?.copyWith(fontSize: 12),
          ),
          const SizedBox(height: 3),
        ],
        Container(
          padding: widget.padding ??
              const EdgeInsets.symmetric(horizontal: 8),
          height: widget.height ?? 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            color: Theme.of(context).colorScheme.surface,
            border: Border.all(
              color: color.outline.withValues(alpha: .3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Date section - Clickable area
              Expanded(
                child: Row(
                  children: [
                    // Start date - Click for Gregorian
                    Expanded(
                      child: GestureDetector(
                        onTap: widget.isActive ? null : () => _showRangePicker(isStart: true),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              selectedStartGregorianDate,
                              style: widget.gregorianTextStyle ??
                                  const TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              selectedStartGregorianDate.shamsiDateFormatted,
                              style: widget.shamsiTextStyle ??
                                  TextStyle(
                                    fontSize: 10,
                                    color: color.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Separator
                    if (widget.showSeparator)...[
                      VerticalDivider(),
                      SizedBox(width: 8),
                    ],

                    // End date - Click for Jalali
                    Expanded(
                      child: GestureDetector(
                        onTap: widget.isActive ? null : () => _showRangePicker(isStart: false),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              selectedEndGregorianDate,
                              style: widget.gregorianTextStyle ??
                                  const TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              selectedEndGregorianDate.shamsiDateFormatted,
                              style: widget.shamsiTextStyle ??
                                  TextStyle(
                                    fontSize: 10,
                                    color: color.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showRangePicker({required bool isStart}) {
    if (isStart) {
      _showGregorianRangePicker();
    } else {
      _showJalaliRangePicker();
    }
  }

  void _showGregorianRangePicker() {
    // Parse the current selected dates
    DateTime? initialStartPickerDate;
    DateTime? initialEndPickerDate;

    try {
      final startParts = selectedStartGregorianDate.split('-');
      if (startParts.length == 3) {
        initialStartPickerDate = DateTime(
          int.parse(startParts[0]),
          int.parse(startParts[1]),
          int.parse(startParts[2]),
        );
      }

      final endParts = selectedEndGregorianDate.split('-');
      if (endParts.length == 3) {
        initialEndPickerDate = DateTime(
          int.parse(endParts[0]),
          int.parse(endParts[1]),
          int.parse(endParts[2]),
        );
      }
    } catch (e) {
      initialStartPickerDate = widget.initialStartDate ?? DateTime.now();
      initialEndPickerDate = widget.initialEndDate ?? DateTime.now();
    }

    // Create initial range
    final initialRange = (initialStartPickerDate != null && initialEndPickerDate != null)
        ? ZGregorianRangePicker(initialStartPickerDate, initialEndPickerDate)
        : null;

    showDialog(
      context: context,
      builder: (_) => GregorianDateRangePicker(
        initialRange: initialRange,
        minYear: widget.minYear,
        maxYear: widget.maxYear,
        onRangeSelected: (range) {
          final startFormatted = range.start.toFormattedDate();
          final endFormatted = range.end.toFormattedDate();

          setState(() {
            selectedStartGregorianDate = startFormatted;
            selectedEndGregorianDate = endFormatted;
          });

          widget.onStartDateChanged(startFormatted);
          widget.onEndDateChanged(endFormatted);

          Navigator.of(context).pop(); // Close the dialog
        },
      ),
    );
  }

  void _showJalaliRangePicker() {
    Jalali? initialStartJalali;
    Jalali? initialEndJalali;

    try {
      final startParts = selectedStartGregorianDate.split('-');
      if (startParts.length == 3) {
        final startDateTime = DateTime(
          int.parse(startParts[0]),
          int.parse(startParts[1]),
          int.parse(startParts[2]),
        );
        initialStartJalali = startDateTime.toAfghanShamsi;
      }

      final endParts = selectedEndGregorianDate.split('-');
      if (endParts.length == 3) {
        final endDateTime = DateTime(
          int.parse(endParts[0]),
          int.parse(endParts[1]),
          int.parse(endParts[2]),
        );
        initialEndJalali = endDateTime.toAfghanShamsi;
      }
    } catch (e) {
      if (widget.initialStartDate != null) {
        initialStartJalali = widget.initialStartDate!.toAfghanShamsi;
      }
      if (widget.initialEndDate != null) {
        initialEndJalali = widget.initialEndDate!.toAfghanShamsi;
      }
    }

    // Create initial range for Jalali
    final initialRange = (initialStartJalali != null && initialEndJalali != null)
        ? JalaliRange(initialStartJalali, initialEndJalali)
        : null;

    showDialog(
      context: context,
      builder: (_) => AfghanDateRangePicker(
        initialRange: initialRange,
        minYear: widget.minYear - 621,
        maxYear: widget.maxYear - 621,
        onRangeSelected: (range) {
          final startFormatted = range.start.toGregorianString();
          final endFormatted = range.end.toGregorianString();

          setState(() {
            selectedStartGregorianDate = startFormatted;
            selectedEndGregorianDate = endFormatted;
          });

          widget.onStartDateChanged(startFormatted);
          widget.onEndDateChanged(endFormatted);

          Navigator.of(context).pop(); // Close the dialog
        },
      ),
    );
  }

  // Helper methods
  DateTime get startDate {
    try {
      final parts = selectedStartGregorianDate.split('-');
      return DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
    } catch (e) {
      return DateTime.now();
    }
  }

  DateTime get endDate {
    try {
      final parts = selectedEndGregorianDate.split('-');
      return DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
    } catch (e) {
      return DateTime.now();
    }
  }

  Jalali get startJalaliDate => startDate.toAfghanShamsi;
  Jalali get endJalaliDate => endDate.toAfghanShamsi;
}