import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pdf/pdf.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PaperSizeCubit extends Cubit<PdfPageFormat> {
  static const String _paperSizeKey = 'selected_paper_size';

  PaperSizeCubit() : super(PdfPageFormat.a4) {
    _loadSavedPaperSize();
  }

  Future<void> _loadSavedPaperSize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedSize = prefs.getString(_paperSizeKey);

      if (savedSize != null) {
        final format = _getFormatFromString(savedSize);
        emit(format);
      }
    } catch (e) {
      // If error occurs, keep default (A4)
      emit(PdfPageFormat.a4);
    }
  }

  Future<void> setPaperSize(PdfPageFormat size) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sizeString = _getStringFromFormat(size);
      await prefs.setString(_paperSizeKey, sizeString);
      emit(size);
    } catch (e) {
      // If saving fails, still emit the size
      emit(size);
    }
  }

  String _getStringFromFormat(PdfPageFormat format) {
    if (format == PdfPageFormat.letter) return 'letter';
    if (format == PdfPageFormat.a4) return 'a4';
    if (format == PdfPageFormat.a5) return 'a5';
    return 'letter'; // default
  }

  PdfPageFormat _getFormatFromString(String format) {
    switch (format) {
      case 'a5':
        return PdfPageFormat.a5;
      case 'letter':
        return PdfPageFormat.letter;
      case 'a4':
      default:
        return PdfPageFormat.a4;
    }
  }
}