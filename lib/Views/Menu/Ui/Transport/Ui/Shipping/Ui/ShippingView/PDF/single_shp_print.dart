import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart' as pw;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:zaitoon_petroleum/Features/Date/shamsi_converter.dart';
import 'package:zaitoon_petroleum/Features/Other/extensions.dart';
import 'package:zaitoon_petroleum/Features/PrintSettings/print_services.dart';
import 'package:zaitoon_petroleum/Features/PrintSettings/report_model.dart';
import '../model/shp_details_model.dart';

class ShippingDetailsPdfServices extends PrintServices {
  final pdf = pw.Document();

  Future<void> createDocument({
    required ShippingDetailsModel shippingDetails,
    required String language,
    required pw.PageOrientation orientation,
    required ReportModel company,
    required pw.PdfPageFormat pageFormat,
  }) async {
    try {
      final document = await generateShippingDetails(
        report: company,
        shippingDetails: shippingDetails,
        language: language,
        orientation: orientation,
        pageFormat: pageFormat,
      );

      await saveDocument(
        suggestedName: "Shipping_Details_${shippingDetails.shpId}_${DateTime.now().toIso8601String()}.pdf",
        pdf: document,
      );
    } catch (e) {
      throw e.toString();
    }
  }

  Future<void> printDocument({
    required ShippingDetailsModel shippingDetails,
    required String language,
    required pw.PageOrientation orientation,
    required ReportModel company,
    required Printer selectedPrinter,
    required pw.PdfPageFormat pageFormat,
    required int copies,
    required String pages,
  }) async {
    try {
      final document = await generateShippingDetails(
        report: company,
        shippingDetails: shippingDetails,
        language: language,
        orientation: orientation,
        pageFormat: pageFormat,
      );

      for (int i = 0; i < copies; i++) {
        await Printing.directPrintPdf(
          printer: selectedPrinter,
          onLayout: (pw.PdfPageFormat format) async {
            return document.save();
          },
        );

        if (i < copies - 1) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }
    } catch (e) {
      throw e.toString();
    }
  }

  Future<pw.Document> printPreview({
    required String language,
    required ReportModel company,
    required pw.PageOrientation orientation,
    required ShippingDetailsModel shippingDetails,
    required pw.PdfPageFormat pageFormat,
  }) async {
    return generateShippingDetails(
      report: company,
      language: language,
      orientation: orientation,
      shippingDetails: shippingDetails,
      pageFormat: pageFormat,
    );
  }

  Future<pw.Document> generateShippingDetails({
    required String language,
    required ReportModel report,
    required ShippingDetailsModel shippingDetails,
    required pw.PageOrientation orientation,
    required pw.PdfPageFormat pageFormat,
  }) async {
    final document = pw.Document();
    final prebuiltHeader = await header(report: report);

    final ByteData imageData = await rootBundle.load('assets/images/zaitoonLogo.png');
    final Uint8List imageBytes = imageData.buffer.asUint8List();
    final pw.MemoryImage logoImage = pw.MemoryImage(imageBytes);

    document.addPage(
      pw.MultiPage(
        maxPages: 1000,
        margin: const pw.EdgeInsets.symmetric(horizontal: 25, vertical: 10),
        pageFormat: pageFormat,
        textDirection: documentLanguage(language: language),
        orientation: orientation,
        build: (context) => [

          // Report Title
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              zText(
                text: tr(text: 'shippingReport', tr: language),
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                textAlign: _getTextAlignStart(language),
              ),
              // Date
              pw.Row(
                children: [
                  zText(
                    text: '${tr(text: 'date', tr: language)}: ',
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    textAlign: _getTextAlignStart(language),
                  ),
                  zText(
                    text: shippingDetails.shpMovingDate?.toFormattedDate() ?? '-',
                    fontSize: 10,
                    textAlign: _getTextAlignStart(language),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 5),

          pw.Row(
              children: [
                // Status as simple text
                pw.Row(
                  children: [
                    zText(
                      text: '${tr(text: 'status', tr: language)}: ',
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      textAlign: _getTextAlignStart(language),
                    ),
                    zText(
                      text: _getStatusText(shippingDetails.shpStatus ?? 0, language),
                      fontSize: 10,
                      textAlign: _getTextAlignStart(language),
                    ),
                  ],
                ),
                pw.SizedBox(width: 8),

                zText(
                  text: '#${shippingDetails.shpId}',
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  textAlign: _getTextAlignStart(language),
                ),
              ]
          ),
          pw.SizedBox(height: 15),

          // Basic Information
          zText(
            text: tr(text: 'shippingSummary', tr: language),
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            textAlign: _getTextAlignStart(language),
          ),
          pw.SizedBox(height: 5),

          _buildInfoLine(tr(text: 'customer', tr: language), shippingDetails.customer ?? '-', language),
          _buildInfoLine(tr(text: 'vehicle', tr: language), shippingDetails.vehicle ?? '-', language),
          _buildInfoLine(tr(text: 'product', tr: language), shippingDetails.proName ?? '-', language),
          _buildInfoLine(tr(text: 'unit', tr: language), shippingDetails.shpUnit ?? '-', language),
          pw.SizedBox(height: 10),

          // Route Information
          zText(
            text: tr(text: 'route', tr: language),
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            textAlign: _getTextAlignStart(language),
          ),
          pw.SizedBox(height: 5),

          _buildInfoLine(tr(text: 'from', tr: language), shippingDetails.shpFrom ?? '-', language),
          _buildInfoLine(tr(text: 'to', tr: language), shippingDetails.shpTo ?? '-', language),
          pw.SizedBox(height: 10),

          // Load Information
          zText(
            text: tr(text: 'shippingDetails', tr: language),
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            textAlign: _getTextAlignStart(language),
          ),
          pw.SizedBox(height: 5),

          _buildInfoLine(tr(text: 'loadingDate', tr: language), shippingDetails.shpMovingDate?.toFormattedDate() ?? '-', language),
          _buildInfoLine(tr(text: 'arrivalDate', tr: language), shippingDetails.shpArriveDate?.toFormattedDate() ?? '-', language),
          _buildInfoLine(tr(text: 'loadSize', tr: language), '${_parseAmount(shippingDetails.shpLoadSize).toAmount()} ${shippingDetails.shpUnit ?? ''}', language),
          _buildInfoLine(tr(text: 'unloadSize', tr: language), '${_parseAmount(shippingDetails.shpUnloadSize).toAmount()} ${shippingDetails.shpUnit ?? ''}', language),
          _buildInfoLine(tr(text: 'shippingRent', tr: language), _parseAmount(shippingDetails.shpRent).toAmount(), language),
          pw.SizedBox(height: 10),

          // Financial Summary
          zText(
            text: tr(text: 'financialSummary', tr: language),
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            textAlign: _getTextAlignStart(language),
          ),

          pw.SizedBox(height: 5),

          _buildInfoLine(tr(text: 'totalRevenue', tr: language), _parseAmount(shippingDetails.total).toAmount(), language, isBold: true),
          pw.SizedBox(height: 5),

          // Payments
          if (shippingDetails.pyment != null && shippingDetails.pyment!.isNotEmpty) ...[
            pw.SizedBox(height: 5),
            zText(
              text: tr(text: 'payment', tr: language),
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              textAlign: _getTextAlignStart(language),
            ),
            pw.SizedBox(height: 5),

            // Payment Header
            pw.Row(
              children: [
                pw.Expanded(flex: 3, child: zText(text: tr(text: 'accountName', tr: language), fontSize: 9, fontWeight: pw.FontWeight.bold, textAlign: _getTextAlignStart(language))),
                pw.Expanded(flex: 2, child: zText(text: tr(text: 'referenceNumber', tr: language), fontSize: 9, fontWeight: pw.FontWeight.bold, textAlign: _getTextAlignStart(language))),
                pw.Expanded(flex: 1, child: zText(text: tr(text: 'cash', tr: language), fontSize: 9, fontWeight: pw.FontWeight.bold, textAlign: _getTextAlignEnd(language))),
                pw.Expanded(flex: 1, child: zText(text: tr(text: 'credit', tr: language), fontSize: 9, fontWeight: pw.FontWeight.bold, textAlign: _getTextAlignEnd(language))),
                pw.Expanded(flex: 1, child: zText(text: tr(text: 'total', tr: language), fontSize: 9, fontWeight: pw.FontWeight.bold, textAlign: _getTextAlignEnd(language))),
              ],
            ),
            pw.SizedBox(height: 3),

            for (var payment in shippingDetails.pyment!) ...[
              _buildPaymentRow(payment, language),
              pw.SizedBox(height: 2),
            ],

            // Payment Total
            pw.Row(
              children: [
                pw.Spacer(flex: 5),
                pw.Expanded(flex: 2, child: zText(text: tr(text: 'total', tr: language), fontSize: 9, fontWeight: pw.FontWeight.bold, textAlign: _getTextAlignEnd(language))),
                pw.Expanded(flex: 1, child: zText(text: (_calculateTotalPayments(shippingDetails.pyment!)).toAmount(), fontSize: 9, fontWeight: pw.FontWeight.bold, textAlign: _getTextAlignEnd(language))),
              ],
            ),
          ],
          pw.SizedBox(height: 10),

          // Expenses
          if (shippingDetails.expenses != null && shippingDetails.expenses!.isNotEmpty) ...[
            zText(
              text: tr(text: 'expenses', tr: language),
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              textAlign: _getTextAlignStart(language),
            ),
            pw.SizedBox(height: 5),

            // Expense Header
            pw.Row(
              children: [
                pw.Expanded(flex: 1, child: zText(text: tr(text: 'account', tr: language), fontSize: 9, fontWeight: pw.FontWeight.bold, textAlign: _getTextAlignStart(language))),
                pw.Expanded(flex: 1, child: zText(text: tr(text: 'referenceNumber', tr: language), fontSize: 9, fontWeight: pw.FontWeight.bold, textAlign: _getTextAlignStart(language))),
                pw.Expanded(flex: 2, child: zText(text: tr(text: 'narration', tr: language), fontSize: 9, fontWeight: pw.FontWeight.bold, textAlign: _getTextAlignStart(language))),
                pw.Expanded(flex: 1, child: zText(text: tr(text: 'amount', tr: language), fontSize: 9, fontWeight: pw.FontWeight.bold, textAlign: _getTextAlignEnd(language))),
              ],
            ),
            pw.SizedBox(height: 3),

            for (var expense in shippingDetails.expenses!) ...[
              _buildExpenseRow(expense, language),
              pw.SizedBox(height: 2),
            ],

            // Expense Total
            pw.Row(
              children: [
                pw.Spacer(flex: 4),
                pw.Expanded(flex: 1, child: zText(text: tr(text: 'total', tr: language), fontSize: 9, fontWeight: pw.FontWeight.bold, textAlign: _getTextAlignEnd(language))),
                pw.Expanded(flex: 1, child: zText(text: _calculateTotalExpenses(shippingDetails.expenses!).toAmount(), fontSize: 9, fontWeight: pw.FontWeight.bold, textAlign: _getTextAlignEnd(language))),
              ],
            ),
          ],
          pw.SizedBox(height: 10),

          // Net Amount
          _buildInfoLine(tr(text: 'netAmount', tr: language),
              (_parseAmount(shippingDetails.total) - _calculateTotalExpenses(shippingDetails.expenses ?? [])).toAmount(),
              language, isBold: true, isHighlighted: true),
          pw.SizedBox(height: 15),

          // Remark
          if (shippingDetails.shpRemark != null && shippingDetails.shpRemark!.isNotEmpty) ...[
            zText(
              text: tr(text: 'remarks', tr: language),
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              textAlign: _getTextAlignStart(language),
            ),
            pw.SizedBox(height: 3),
            zText(
              text: shippingDetails.shpRemark!,
              fontSize: 9,
              textAlign: _getTextAlignStart(language),
            ),
          ],
          pw.SizedBox(height: 10),
        ],
        header: (context) => prebuiltHeader,
        footer: (context) => footer(
          report: report,
          context: context,
          language: language,
          logoImage: logoImage,
        ),
      ),
    );
    return document;
  }

  // Helper Methods for text alignment based on language
  pw.TextAlign _getTextAlignStart(String language) {
    return language == "en" ? pw.TextAlign.left : pw.TextAlign.right;
  }

  pw.TextAlign _getTextAlignEnd(String language) {
    return language == "en" ? pw.TextAlign.right : pw.TextAlign.left;
  }

  // Helper Methods
  pw.Widget _buildInfoLine(String label, String value, String language, {bool isBold = false, bool isHighlighted = false}) {
    return pw.Row(
      children: [
        pw.SizedBox(
          width: 160,
          child: zText(
            text: '$label:',
            fontSize: 10,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            textAlign: _getTextAlignStart(language),
          ),
        ),
        pw.Expanded(
          child: zText(
            text: value,
            fontSize: 10,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: isHighlighted ? pw.PdfColors.blue700 : null,
            textAlign: _getTextAlignStart(language),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildPaymentRow(Pyment payment, String language) {
    final cashAmount = _parseAmount(payment.cashAmount);
    final cardAmount = _parseAmount(payment.cardAmount);
    final totalPayment = cashAmount + cardAmount;

    return pw.Row(
      children: [
        pw.Expanded(
          flex: 3,
          child: zText(
            text: payment.accName ?? '-',
            fontSize: 9,
            textAlign: _getTextAlignStart(language),
          ),
        ),
        pw.Expanded(
          flex: 2,
          child: zText(
            text: payment.trdReference ?? '-',
            fontSize: 9,
            textAlign: _getTextAlignStart(language),
          ),
        ),
        pw.Expanded(
          flex: 1,
          child: zText(
            text: cashAmount.toAmount(),
            fontSize: 9,
            textAlign: _getTextAlignEnd(language),
          ),
        ),
        pw.Expanded(
          flex: 1,
          child: zText(
            text: cardAmount.toAmount(),
            fontSize: 9,
            textAlign: _getTextAlignEnd(language),
          ),
        ),
        pw.Expanded(
          flex: 1,
          child: zText(
            text: totalPayment.toAmount(),
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
            textAlign: _getTextAlignEnd(language),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildExpenseRow(Expense expense, String language) {
    return pw.Row(
      children: [
        pw.Expanded(
          flex: 1,
          child: zText(
            text: '${expense.accNumber}',
            fontSize: 9,
            textAlign: _getTextAlignStart(language),
          ),
        ),
        pw.Expanded(
          flex: 1,
          child: zText(
            text: expense.trdReference ?? '-',
            fontSize: 9,
            textAlign: _getTextAlignStart(language),
          ),
        ),
        pw.Expanded(
          flex: 2,
          child: zText(
            text: expense.narration ?? '-',
            fontSize: 9,
            textAlign: _getTextAlignStart(language),
          ),
        ),
        pw.Expanded(
          flex: 1,
          child: zText(
            text: "${_parseAmount(expense.amount).toAmount()} ${expense.currency ?? '-'}",
            fontSize: 9,
            textAlign: _getTextAlignEnd(language),
          ),
        ),
      ],
    );
  }

  double _parseAmount(String? value) {
    if (value == null || value.isEmpty) return 0;
    try {
      return double.parse(value.replaceAll(',', ''));
    } catch (e) {
      return 0;
    }
  }

  double _calculateTotalPayments(List<Pyment> payments) {
    return payments.fold(0, (sum, p) =>
    sum + _parseAmount(p.cashAmount) + _parseAmount(p.cardAmount));
  }

  double _calculateTotalExpenses(List<Expense> expenses) {
    return expenses.fold(0, (sum, e) => sum + _parseAmount(e.amount));
  }

  String _getStatusText(int status, String language) {
    switch (status) {
      case 1: return tr(text: 'completed', tr: language);
      case 0: return tr(text: 'pending', tr: language);
      default: return tr(text: 'unknown', tr: language);
    }
  }
}