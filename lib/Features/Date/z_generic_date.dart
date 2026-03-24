import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:zaitoonpro/Features/Date/shamsi_converter.dart';
import 'package:zaitoonpro/Features/Date/shamsi_date_picker.dart';
import 'gregorian_date_picker.dart';

class ZDatePicker extends StatefulWidget {
  final String label;
  final String? value;
  final double? height;
  final bool isActive;
  final bool disablePastDate;
  final DateTime? initialDate;
  final ValueChanged<String> onDateChanged;
  final EdgeInsetsGeometry? padding;
  final TextStyle? labelStyle;
  final TextStyle? gregorianTextStyle;
  final TextStyle? shamsiTextStyle;

  const ZDatePicker({
    super.key,
    required this.label,
    this.initialDate,
    required this.onDateChanged,
    this.value,
    this.padding,
    this.isActive = false,
    this.height,
    this.labelStyle,
    this.disablePastDate = false,
    this.gregorianTextStyle,
    this.shamsiTextStyle,
  });

  @override
  State<ZDatePicker> createState() => _ZDatePickerState();
}

class _ZDatePickerState extends State<ZDatePicker> {
  late String selectedGregorianDate;

  @override
  void initState() {
    super.initState();
    _initializeDate();
  }

  void _initializeDate() {
    // If value is provided, use it
    if (widget.value != null && widget.value!.isNotEmpty) {
      selectedGregorianDate = widget.value!;
    }
    // If initialDate is provided, use it
    else if (widget.initialDate != null) {
      selectedGregorianDate = widget.initialDate!.toFormattedDate();
      // Notify parent about the initial date
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onDateChanged(selectedGregorianDate);
      });
    }
    // Otherwise use current date
    else {
      selectedGregorianDate = DateTime.now().toFormattedDate();
    }
  }

  @override
  void didUpdateWidget(covariant ZDatePicker oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update if value changed externally
    if (widget.value != null &&
        widget.value != oldWidget.value &&
        widget.value != selectedGregorianDate) {
      setState(() {
        selectedGregorianDate = widget.value!;
      });
    }
    // Update if initialDate changed and no value is provided
    else if (widget.value == null &&
        widget.initialDate != null &&
        widget.initialDate != oldWidget.initialDate) {
      setState(() {
        selectedGregorianDate = widget.initialDate!.toFormattedDate();
      });
      widget.onDateChanged(selectedGregorianDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if(widget.label.isNotEmpty)...[
          Text(
            widget.label,
            style: widget.labelStyle ??
                Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontSize: 12),
          ),
          const SizedBox(height: 3),
        ],
        Container(
          padding: widget.padding ??
              const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Gregorian Date
                    GestureDetector(
                      onTap: widget.isActive ? null : _showGregorianDatePicker,
                      child: Text(
                        selectedGregorianDate,
                        style: widget.gregorianTextStyle ??
                            const TextStyle(fontSize: 12),
                      ),
                    ),

                    // Shamsi Date
                    GestureDetector(
                      onTap: widget.isActive ? null : _showShamsiDatePicker,
                      child: Text(
                        selectedGregorianDate.shamsiDateFormatted,
                        style: widget.shamsiTextStyle ??
                            TextStyle(
                              fontSize: 10,
                              color: color.primary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.calendar_month_rounded, color: color.secondary),
            ],
          ),
        ),
      ],
    );
  }

  void _showGregorianDatePicker() {
    // Parse the current selected date to pass as initial date to picker
    DateTime? initialPickerDate;
    try {
      // Assuming toFormattedDate returns "YYYY-MM-DD" format
      final parts = selectedGregorianDate.split('-');
      if (parts.length == 3) {
        initialPickerDate = DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
      }
    } catch (e) {
      // If parsing fails, use widget.initialDate or current date
      initialPickerDate = widget.initialDate ?? DateTime.now();
    }

    showDialog(
      context: context,
      builder: (_) => GregorianDatePicker(
        initialDate: initialPickerDate,
        disablePastDates: widget.disablePastDate,
        onDateSelected: (value) {
          final formatted = value.toFormattedDate();
          setState(() => selectedGregorianDate = formatted);
          widget.onDateChanged(formatted);
        },
      ),
    );
  }

  void _showShamsiDatePicker() {
    Jalali? initialJalaliDate;

    try {
      final parts = selectedGregorianDate.split('-');
      if (parts.length == 3) {
        final dateTime = DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
        initialJalaliDate = dateTime.toAfghanShamsi;
      }
    } catch (e) {
      if (widget.initialDate != null) {
        initialJalaliDate = widget.initialDate!.toAfghanShamsi;
      } else {
        initialJalaliDate = DateTime.now().toAfghanShamsi;
      }
    }

    showDialog(
      context: context,
      builder: (_) => AfghanDatePicker(
        initialDate: initialJalaliDate,
        disablePastDates: widget.disablePastDate,
        onDateSelected: (value) {
          final formatted = value.toGregorianString();
          setState(() => selectedGregorianDate = formatted);
          widget.onDateChanged(formatted);
        },
      ),
    );
  }
}