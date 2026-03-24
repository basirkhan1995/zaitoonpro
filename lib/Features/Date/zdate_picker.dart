import 'package:flutter/material.dart';
import 'package:zaitoonpro/Features/Date/shamsi_converter.dart';
import 'package:zaitoonpro/Features/Date/shamsi_date_picker.dart';
import 'gregorian_date_picker.dart';

class GenericDatePicker extends StatefulWidget {
  final String label;
  final double? height;
  final String? initialGregorianDate;
  final bool isActive;
  final ValueChanged<String> onDateChanged;
  final EdgeInsetsGeometry? padding;
  final TextStyle? labelStyle;
  final TextStyle? gregorianTextStyle;
  final TextStyle? shamsiTextStyle;

  const GenericDatePicker({
    super.key,
    required this.label,
    required this.onDateChanged,
    this.initialGregorianDate,
    this.padding,
    this.isActive = false,
    this.height,
    this.labelStyle,
    this.gregorianTextStyle,
    this.shamsiTextStyle,
  });

  @override
  State<GenericDatePicker> createState() => _GenericDatePickerState();
}

class _GenericDatePickerState extends State<GenericDatePicker> {
  late String selectedGregorianDate;

  @override
  void initState() {
    super.initState();
    selectedGregorianDate = widget.initialGregorianDate ??
        DateTime.now().toFormattedDate();
  }

  @override
  Widget build(BuildContext context) {

    final color = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: widget.labelStyle ??
              Theme.of(context).textTheme.titleSmall?.copyWith(fontSize: 12),
        ),
        const SizedBox(height: 3),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          height: widget.height ?? 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            border: Border.all(
              color: color.outline.withValues(alpha: .4),
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
    showDialog(
      context: context,
      builder: (context) {
        return GregorianDatePicker(
          onDateSelected: (value) {
            setState(() {
              selectedGregorianDate = value.toFormattedDate();
            });
            widget.onDateChanged(selectedGregorianDate);
          },
        );
      },
    );
  }

  void _showShamsiDatePicker() {
    showDialog(
      context: context,
      builder: (context) {
        return AfghanDatePicker(
          onDateSelected: (value) {
            setState(() {
              selectedGregorianDate = value.toGregorianString();
            });
            widget.onDateChanged(selectedGregorianDate);
          },
        );
      },
    );
  }
}
