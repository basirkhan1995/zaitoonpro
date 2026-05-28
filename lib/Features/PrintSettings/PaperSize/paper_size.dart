import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pdf/pdf.dart' as pw;
import '../../../Localizations/l10n/translations/app_localizations.dart';
import '../../Generic/generic_drop.dart';
import '../bloc/PageSize/paper_size_cubit.dart';

class PdfFormatHelper {

  static const List<pw.PdfPageFormat> allFormats = [
    pw.PdfPageFormat.letter,
    pw.PdfPageFormat.a4,
    pw.PdfPageFormat.a5,
    pw.PdfPageFormat.roll80,
  ];

  // Default: hide roll80
  static List<pw.PdfPageFormat> get availableFormats =>
      getAvailableFormats(showRoll80: false);

  // Dynamic method to control roll80 visibility
  static List<pw.PdfPageFormat> getAvailableFormats({
    bool showRoll80 = false,
  }) {
    return allFormats.where((format) {
      if (format == pw.PdfPageFormat.roll80 && !showRoll80) {
        return false;
      }
      return true;
    }).toList();
  }

  static String? getDisplayName(pw.PdfPageFormat format) {
    if (format == pw.PdfPageFormat.letter) return 'Letter (216 × 279 mm)';
    if (format == pw.PdfPageFormat.a4) return 'A4 (210 × 297 mm)';
    if (format == pw.PdfPageFormat.a5) return 'A5 (148 × 210 mm)';
    if (format == pw.PdfPageFormat.roll80) return '80mm Roll';
    return null;
  }

  static String getFormatKey(pw.PdfPageFormat format) {
    if (format == pw.PdfPageFormat.letter) return 'letter';
    if (format == pw.PdfPageFormat.a4) return 'a4';
    if (format == pw.PdfPageFormat.a5) return 'a5';
    if (format == pw.PdfPageFormat.roll80) return 'roll_80mm';
    return 'letter';
  }

  static pw.PdfPageFormat getFormatFromKey(String key) {
    switch (key) {
      case 'a5':
        return pw.PdfPageFormat.a5;
      case 'letter':
        return pw.PdfPageFormat.letter;
      case 'roll_80mm':
        return pw.PdfPageFormat.roll80;
      case 'a4':
      default:
        return pw.PdfPageFormat.a4;
    }
  }

  static pw.PdfPageFormat getPrinterFriendlyFormat(pw.PdfPageFormat format) {
    if (format.width == format.width.roundToDouble() &&
        format.height == format.height.roundToDouble()) {
      return format;
    }
    return pw.PdfPageFormat(
      format.width.roundToDouble(),
      format.height.roundToDouble(),
      marginTop: format.marginTop,
      marginBottom: format.marginBottom,
      marginLeft: format.marginLeft,
      marginRight: format.marginRight,
    );
  }

  static bool isSameFormat(pw.PdfPageFormat a, pw.PdfPageFormat b) {
    const tolerance = 0.5;
    return (a.width - b.width).abs() < tolerance &&
        (a.height - b.height).abs() < tolerance;
  }

  static bool isA5(pw.PdfPageFormat format) {
    const tolerance = 1.0;
    return (format.width - 419.5).abs() < tolerance && (format.height - 595.2).abs() < tolerance;
  }

  static bool isA4(pw.PdfPageFormat format) {
    const tolerance = 1.0;
    return (format.width - 595.2).abs() < tolerance &&
        (format.height - 841.8).abs() < tolerance;
  }

  static bool isLetter(pw.PdfPageFormat format) {
    const tolerance = 1.0;
    return (format.width - 612).abs() < tolerance &&
        (format.height - 792).abs() < tolerance;
  }

  static bool isRoll80mm(pw.PdfPageFormat format) {
    return format == pw.PdfPageFormat.roll80;
  }
}

class PageFormatDropdown extends StatefulWidget {
  final Function(pw.PdfPageFormat) onFormatSelected;
  final pw.PdfPageFormat? initialFormat;
  final bool showRoll80;

  const PageFormatDropdown({
    super.key,
    required this.onFormatSelected,
    this.initialFormat,
    this.showRoll80 = false,
  });

  @override
  State<PageFormatDropdown> createState() => _PageFormatDropdownState();
}

class _PageFormatDropdownState extends State<PageFormatDropdown> {
  late pw.PdfPageFormat _selectedFormat;

  @override
  void initState() {
    super.initState();
    final paperSizeCubit = context.read<PaperSizeCubit>();
    _selectedFormat = paperSizeCubit.state;

    // If roll80 is hidden but currently selected, fallback to A4
    if (!widget.showRoll80 && _selectedFormat == pw.PdfPageFormat.roll80) {
      _selectedFormat = pw.PdfPageFormat.a4;
      // Optionally update the cubit
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<PaperSizeCubit>().setPaperSize(pw.PdfPageFormat.a4);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PaperSizeCubit, pw.PdfPageFormat>(
      builder: (context, paperSize) {
        // Update selected format when Cubit changes
        _selectedFormat = paperSize;
        // If roll80 is selected but shouldn't be shown, don't show the dropdown
        if (!widget.showRoll80 && _selectedFormat == pw.PdfPageFormat.roll80) {
          // Handle gracefully - could reset or just hide
          return const SizedBox.shrink();
        }
        return CustomDropdown<pw.PdfPageFormat>(
          title: AppLocalizations.of(context)!.paper,
          items: PdfFormatHelper.getAvailableFormats(showRoll80: widget.showRoll80),
          initialValue: PdfFormatHelper.getDisplayName(_selectedFormat),
          itemLabel: (format) => PdfFormatHelper.getDisplayName(format) ?? "",
          onItemSelected: (selected) async {
            setState(() {
              _selectedFormat = selected;
            });
            await context.read<PaperSizeCubit>().setPaperSize(selected);
            widget.onFormatSelected(selected);
          },
        );
      },
    );
  }
}