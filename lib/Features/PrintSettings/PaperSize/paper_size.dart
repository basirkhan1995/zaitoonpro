import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pdf/pdf.dart' as pw;
import '../../../Localizations/l10n/translations/app_localizations.dart';
import '../../Generic/generic_drop.dart';
import '../bloc/PageSize/paper_size_cubit.dart';


class PdfFormatHelper {


  static const List<pw.PdfPageFormat> availableFormats = [
    pw.PdfPageFormat.a4,
    pw.PdfPageFormat.a5,
    pw.PdfPageFormat.letter,
  ];

  static String? getDisplayName(pw.PdfPageFormat format) {
    if (format == pw.PdfPageFormat.a4) return 'A4 (210 × 297 mm)';
    if (format == pw.PdfPageFormat.a5) return 'A5 (148 × 210 mm)';
    if (format == pw.PdfPageFormat.letter) return 'Letter (216 × 279 mm)';
    return null;
  }

  static String getFormatKey(pw.PdfPageFormat format) {
    if (format == pw.PdfPageFormat.a4) return 'a4';
    if (format == pw.PdfPageFormat.a5) return 'a5';
    if (format == pw.PdfPageFormat.letter) return 'letter';
    return 'a4';
  }

  static pw.PdfPageFormat getFormatFromKey(String key) {
    switch (key) {
      case 'a5':
        return pw.PdfPageFormat.a5;
      case 'letter':
        return pw.PdfPageFormat.letter;
      case 'a4':
      default:
        return pw.PdfPageFormat.a4;
    }
  }

  // Consider adding a small optimization:
  static pw.PdfPageFormat getPrinterFriendlyFormat(pw.PdfPageFormat format) {
    // Only round if needed (avoid unnecessary object creation)
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

// Add this helpful method:
  static bool isSameFormat(pw.PdfPageFormat a, pw.PdfPageFormat b) {
    const tolerance = 0.5;
    return (a.width - b.width).abs() < tolerance &&
        (a.height - b.height).abs() < tolerance;
  }

  // Check if format is A5 (within tolerance)
  static bool isA5(pw.PdfPageFormat format) {
    const tolerance = 1.0;
    return (format.width - 419.5).abs() < tolerance && (format.height - 595.2).abs() < tolerance;
  }

  // Check if format is A4
  static bool isA4(pw.PdfPageFormat format) {
    const tolerance = 1.0;
    return (format.width - 595.2).abs() < tolerance &&
        (format.height - 841.8).abs() < tolerance;
  }

  // Check if format is Letter
  static bool isLetter(pw.PdfPageFormat format) {
    const tolerance = 1.0;
    return (format.width - 612).abs() < tolerance &&
        (format.height - 792).abs() < tolerance;
  }
}

class PageFormatDropdown extends StatefulWidget {
  final Function(pw.PdfPageFormat) onFormatSelected;
  final pw.PdfPageFormat? initialFormat;

  const PageFormatDropdown({
    super.key,
    required this.onFormatSelected,
    this.initialFormat,
  });

  @override
  State<PageFormatDropdown> createState() => _PageFormatDropdownState();
}

class _PageFormatDropdownState extends State<PageFormatDropdown> {
  late pw.PdfPageFormat _selectedFormat;

  @override
  void initState() {
    super.initState();
    // Get the current paper size from Cubit
    final paperSizeCubit = context.read<PaperSizeCubit>();
    _selectedFormat = paperSizeCubit.state;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PaperSizeCubit, pw.PdfPageFormat>(
      builder: (context, paperSize) {
        // Update selected format when Cubit changes
        _selectedFormat = paperSize;

        return CustomDropdown<pw.PdfPageFormat>(
          title: AppLocalizations.of(context)!.paper,
          items: PdfFormatHelper.availableFormats,
          initialValue: PdfFormatHelper.getDisplayName(_selectedFormat),
          itemLabel: (format) => PdfFormatHelper.getDisplayName(format) ?? "",
          onItemSelected: (selected) async {
            // Update both local state and Cubit
            setState(() {
              _selectedFormat = selected;
            });

            // Save to SharedPreferences via Cubit
            await context.read<PaperSizeCubit>().setPaperSize(selected);

            // Notify parent
            widget.onFormatSelected(selected);
          },
        );
      },
    );
  }
}