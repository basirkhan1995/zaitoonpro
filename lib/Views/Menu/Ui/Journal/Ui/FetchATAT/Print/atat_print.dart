import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart' as pw;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:zaitoon_petroleum/Features/Date/shamsi_converter.dart';
import 'package:zaitoon_petroleum/Features/Other/extensions.dart';
import 'package:zaitoon_petroleum/Features/PrintSettings/print_services.dart';
import 'package:zaitoon_petroleum/Features/PrintSettings/report_model.dart';
import '../../../../../../../../Features/PrintSettings/PaperSize/paper_size.dart';
import '../model/fetch_atat_model.dart';
import '../model/print_data_model.dart';

class AtatPrintSettings extends PrintServices {
  // Create document (Save PDF)
  Future<void> createDocument({
    required AtatPrintData printData,
    required String language,
    required pw.PageOrientation orientation,
    required ReportModel company,
    required pw.PdfPageFormat pageFormat,
  }) async {
    try {
      final document = await generateReport(
        printData: printData,
        language: language,
        orientation: orientation,
        company: company,
        pageFormat: pageFormat,
      );

      final fileName = 'transaction_${printData.transaction.trnReference ?? 'reference'}_${DateTime.now().millisecondsSinceEpoch}.pdf';

      await saveDocument(
        suggestedName: fileName,
        pdf: document,
      );
    } catch (e) {
      throw e.toString();
    }
  }

  // Print document (using Windows print dialog)
  Future<void> printDocument({
    required AtatPrintData printData,
    required String language,
    required pw.PageOrientation orientation,
    required ReportModel company,
    required Printer selectedPrinter,
    required pw.PdfPageFormat pageFormat,
    required int copies,
    required String pages,
  }) async {
    try {
      final cleanFormat = PdfFormatHelper.getPrinterFriendlyFormat(pageFormat);

      final document = await generateReport(
        printData: printData,
        language: language,
        orientation: orientation,
        company: company,
        pageFormat: cleanFormat,
      );

      final bytes = await document.save();

      final fileName = 'transaction_${printData.transaction.trnReference ?? 'reference'}_${DateTime.now().millisecondsSinceEpoch}.pdf';

      await Printing.sharePdf(
        bytes: bytes,
        filename: fileName,
      );
    } catch (e) {
      throw Exception('Failed to print: $e');
    }
  }

  // Print Preview
  Future<pw.Document> printPreview({
    required AtatPrintData printData,
    required String language,
    required pw.PageOrientation orientation,
    required ReportModel company,
    required pw.PdfPageFormat pageFormat,
  }) async {
    return generateReport(
      printData: printData,
      language: language,
      orientation: orientation,
      company: company,
      pageFormat: pageFormat,
    );
  }

  // Main report generator
  Future<pw.Document> generateReport({
    required AtatPrintData printData,
    required String language,
    required pw.PageOrientation orientation,
    required ReportModel company,
    required pw.PdfPageFormat pageFormat,
  }) async {
    final document = pw.Document();
    final prebuiltHeader = await header(report: company);

    // Load logo
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
        header: (context) => prebuiltHeader,
        footer: (context) => footer(
          report: company,
          context: context,
          language: language,
          logoImage: logoImage,
        ),
        build: (context) => [
          // Report Title
          _buildTitle(printData, language),
          pw.SizedBox(height: 10),

          // Transaction Header Information
          _buildTransactionHeader(printData, language),
          pw.SizedBox(height: 15),

          // Debit Section
          _buildDebitSection(printData, language),
          pw.SizedBox(height: 10),

          // Credit Section
          _buildCreditSection(printData, language),
          pw.SizedBox(height: 15),

          // Grand Total Section
          _buildGrandTotalSection(printData, language),

        ],
      ),
    );

    return document;
  }

  // Report Title
  pw.Widget _buildTitle(AtatPrintData printData, String language) {
    String transactionType = _getTransactionType(printData.transaction.trnType ?? '', language);

    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            zText(
              text: transactionType.toUpperCase(),
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
            pw.SizedBox(height: 4),
            zText(
              text: '${tr(text: 'referenceNumber', tr: language)}: ${printData.transaction.trnReference ?? ''}',
              fontSize: 10,
              color: pw.PdfColors.grey600,
            ),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            zText(
              text: '${tr(text: 'date', tr: language)}: ${printData.reportDate.toFullDateTime}',
              fontSize: 8,
              color: pw.PdfColors.grey600,
            ),
          ],
        ),
      ],
    );
  }

  String _getTransactionType(String code, String language) {
    switch (code) {
      case "SLRY": return tr(text: 'postSalary', tr: language);
      case "ATAT": return tr(text: 'accountTransfer', tr: language);
      case "CRFX": return tr(text: 'fxTransaction', tr: language);
      case "PLCL": return tr(text: 'profitAndLoss', tr: language);
      default: return code;
    }
  }

  // Transaction Header Information
  pw.Widget _buildTransactionHeader(AtatPrintData printData, String language) {
    final transaction = printData.transaction;
    final status = transaction.trnStatus == 1
        ? tr(text: 'authorized', tr: language)
        : tr(text: 'pending', tr: language);

    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: pw.PdfColors.grey50,
        border: pw.Border.all(color: pw.PdfColors.grey300, width: 0.5),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            flex: 1,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildInfoRow(tr(text: 'branch', tr: language), transaction.trdBranch?.toString() ?? 'N/A'),
                _buildInfoRow(tr(text: 'maker', tr: language), transaction.maker ?? 'N/A'),
                if (transaction.checker != null && transaction.checker!.isNotEmpty)
                  _buildInfoRow(tr(text: 'checker', tr: language), transaction.checker!),
              ],
            ),
          ),
          pw.Expanded(
            flex: 1,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildInfoRow(tr(text: 'status', tr: language), status,
                    color: transaction.trnStatus == 1 ? pw.PdfColors.green700 : pw.PdfColors.orange700),
                _buildInfoRow(tr(text: 'date', tr: language),
                    transaction.trnEntryDate?.toFullDateTime ?? 'N/A'),
                _buildInfoRow(tr(text: 'type', tr: language), transaction.type ?? 'N/A'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildInfoRow(String label, String value, {pw.PdfColor? color}) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 80,
            child: zText(
              text: '$label:',
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: pw.PdfColors.grey700,
            ),
          ),
          pw.Expanded(
            child: zText(
              text: value,
              fontSize: 9,
              color: color ?? pw.PdfColors.black,
            ),
          ),
        ],
      ),
    );
  }

  // Debit Section
  pw.Widget _buildDebitSection(AtatPrintData printData, String language) {
    final transaction = printData.transaction;
    final debitItems = transaction.debit ?? [];

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 6),
          decoration: pw.BoxDecoration(
            color: pw.PdfColors.green50,
            borderRadius: const pw.BorderRadius.only(
              topLeft: pw.Radius.circular(4),
              topRight: pw.Radius.circular(4),
            ),
          ),
          child: pw.Row(
            children: [
              pw.Expanded(
                flex: 3,
                child: zText(
                  text: '${tr(text: 'debitEntries', tr: language)} (${debitItems.length})',
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: pw.PdfColors.green700,
                ),
              ),
              zText(
                text: '${tr(text: 'total', tr: language)}: ${_calculateTotal(debitItems).toAmount()}',
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: pw.PdfColors.green700,
              ),
            ],
          ),
        ),

        if (debitItems.isEmpty)
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: pw.PdfColors.grey300, width: 0.5),
            ),
            child: zText(
              text: tr(text: 'noDebitEntries', tr: language),
              fontSize: 9,
              color: pw.PdfColors.grey600,
            ),
          )
        else
          pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: pw.PdfColors.grey300, width: 0.5),
            ),
            child: pw.Column(
              children: [
                // Header
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                  decoration: pw.BoxDecoration(
                    color: pw.PdfColors.grey100,
                  ),
                  child: pw.Row(
                    children: [
                      pw.Expanded(
                        flex: 2,
                        child: zText(
                          text: tr(text: 'accountName', tr: language),
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Expanded(
                        flex: 1,
                        child: zText(
                          text: tr(text: 'accountNumber', tr: language),
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                      pw.Expanded(
                        flex: 1,
                        child: zText(
                          text: tr(text: 'amount', tr: language),
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ),

                // Items
                ...debitItems.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return pw.Container(
                    padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                    decoration: pw.BoxDecoration(
                      border: pw.Border(
                        bottom: pw.BorderSide(
                          color: pw.PdfColors.grey200,
                          width: 0.3,
                        ),
                      ),
                      color: index.isOdd ? pw.PdfColors.grey50 : pw.PdfColors.white,
                    ),
                    child: pw.Row(
                      children: [
                        pw.Expanded(
                          flex: 2,
                          child: zText(
                            text: item.accName ?? 'N/A',
                            fontSize: 9,
                          ),
                        ),
                        pw.Expanded(
                          flex: 1,
                          child: zText(
                            text: item.trdAccount?.toString() ?? '',
                            fontSize: 9,
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                        pw.Expanded(
                          flex: 1,
                          child: pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.end,
                            children: [
                              zText(
                                text: (double.tryParse(item.trdAmount ?? '0') ?? 0).toAmount(),
                                fontSize: 9,
                                fontWeight: pw.FontWeight.bold,
                                color: pw.PdfColors.green700,
                              ),
                              pw.SizedBox(width: 4),
                              zText(
                                text: item.trdCcy ?? '',
                                fontSize: 8,
                                color: pw.PdfColors.grey600,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                // Debit Total
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                  decoration: pw.BoxDecoration(
                    color: pw.PdfColors.green50,
                    border: pw.Border(
                      top: pw.BorderSide(color: pw.PdfColors.green200, width: 0.5),
                    ),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.end,
                    children: [
                      zText(
                        text: '${tr(text: 'totalDebit', tr: language)}:',
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                      pw.SizedBox(width: 20),
                      pw.Row(
                        children: [
                          zText(
                            text: _calculateTotal(debitItems).toAmount(),
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: pw.PdfColors.green700,
                          ),
                          pw.SizedBox(width: 4),
                          zText(
                            text: debitItems.isNotEmpty ? (debitItems.first.trdCcy ?? '') : '',
                            fontSize: 9,
                          ),
                        ],
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

  // Credit Section
  pw.Widget _buildCreditSection(AtatPrintData printData, String language) {
    final transaction = printData.transaction;
    final creditItems = transaction.credit ?? [];

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 6),
          decoration: pw.BoxDecoration(
            color: pw.PdfColors.red50,
            borderRadius: const pw.BorderRadius.only(
              topLeft: pw.Radius.circular(4),
              topRight: pw.Radius.circular(4),
            ),
          ),
          child: pw.Row(
            children: [
              pw.Expanded(
                flex: 3,
                child: zText(
                  text: '${tr(text: 'creditEntries', tr: language)} (${creditItems.length})',
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: pw.PdfColors.red700,
                ),
              ),
              zText(
                text: '${tr(text: 'total', tr: language)}: ${_calculateTotal(creditItems).toAmount()}',
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: pw.PdfColors.red700,
              ),
            ],
          ),
        ),

        if (creditItems.isEmpty)
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: pw.PdfColors.grey300, width: 0.5),
            ),
            child: zText(
              text: tr(text: 'noCreditEntries', tr: language),
              fontSize: 9,
              color: pw.PdfColors.grey600,
            ),
          )
        else
          pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: pw.PdfColors.grey300, width: 0.5),
            ),
            child: pw.Column(
              children: [
                // Header
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                  decoration: pw.BoxDecoration(
                    color: pw.PdfColors.grey100,
                  ),
                  child: pw.Row(
                    children: [
                      pw.Expanded(
                        flex: 2,
                        child: zText(
                          text: tr(text: 'accountName', tr: language),
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Expanded(
                        flex: 1,
                        child: zText(
                          text: tr(text: 'accountNumber', tr: language),
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                      pw.Expanded(
                        flex: 1,
                        child: zText(
                          text: tr(text: 'amount', tr: language),
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ),

                // Items
                ...creditItems.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return pw.Container(
                    padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                    decoration: pw.BoxDecoration(
                      border: pw.Border(
                        bottom: pw.BorderSide(
                          color: pw.PdfColors.grey200,
                          width: 0.3,
                        ),
                      ),
                      color: index.isOdd ? pw.PdfColors.grey50 : pw.PdfColors.white,
                    ),
                    child: pw.Row(
                      children: [
                        pw.Expanded(
                          flex: 2,
                          child: zText(
                            text: item.accName ?? 'N/A',
                            fontSize: 9,
                          ),
                        ),
                        pw.Expanded(
                          flex: 1,
                          child: zText(
                            text: item.trdAccount?.toString() ?? '',
                            fontSize: 9,
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                        pw.Expanded(
                          flex: 1,
                          child: pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.end,
                            children: [
                              zText(
                                text: (double.tryParse(item.trdAmount ?? '0') ?? 0).toAmount(),
                                fontSize: 9,
                                fontWeight: pw.FontWeight.bold,
                                color: pw.PdfColors.red700,
                              ),
                              pw.SizedBox(width: 4),
                              zText(
                                text: item.trdCcy ?? '',
                                fontSize: 8,
                                color: pw.PdfColors.grey600,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                // Credit Total
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                  decoration: pw.BoxDecoration(
                    color: pw.PdfColors.red50,
                    border: pw.Border(
                      top: pw.BorderSide(color: pw.PdfColors.red200, width: 0.5),
                    ),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.end,
                    children: [
                      zText(
                        text: '${tr(text: 'totalCredit', tr: language)}:',
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                      pw.SizedBox(width: 20),
                      pw.Row(
                        children: [
                          zText(
                            text: _calculateTotal(creditItems).toAmount(),
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: pw.PdfColors.red700,
                          ),
                          pw.SizedBox(width: 4),
                          zText(
                            text: creditItems.isNotEmpty ? (creditItems.first.trdCcy ?? '') : '',
                            fontSize: 9,
                          ),
                        ],
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

  // Currency Summary Section

  // Grand Total Section
  pw.Widget _buildGrandTotalSection(AtatPrintData printData, String language) {
    final sysTotal = printData.systemTotal;
    final isBalanced = sysTotal.totalDebitSys == sysTotal.totalCreditSys;

    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: isBalanced ? pw.PdfColors.green50 : pw.PdfColors.orange50,
        border: pw.Border.all(
          color: isBalanced ? pw.PdfColors.green200 : pw.PdfColors.orange200,
          width: 0.5,
        ),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              zText(
                text: '${tr(text: 'grandTotal', tr: language)} (${printData.baseCcy ?? ''})',
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: isBalanced ? pw.PdfColors.green700 : pw.PdfColors.orange700,
              ),
              pw.SizedBox(width: 10),
              if (isBalanced)
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: pw.BoxDecoration(
                    color: pw.PdfColors.green700,
                    borderRadius: pw.BorderRadius.circular(2),
                  ),
                  child: zText(
                    text: tr(text: 'balanced', tr: language),
                    fontSize: 8,
                    color: pw.PdfColors.white,
                  ),
                ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildTotalItem(
                  label: tr(text: 'totalDebit', tr: language),
                  value: sysTotal.totalDebitSys,
                  symbol: printData.baseCcy ?? '',
                  color: pw.PdfColors.green700,
                ),
              ),
              pw.SizedBox(width: 20),
              pw.Expanded(
                child: _buildTotalItem(
                  label: tr(text: 'totalCredit', tr: language),
                  value: sysTotal.totalCreditSys,
                  symbol: printData.baseCcy ?? '',
                  color: pw.PdfColors.red700,
                ),
              ),
              pw.SizedBox(width: 20),
              pw.Expanded(
                child: _buildTotalItem(
                  label: tr(text: 'netAmount', tr: language),
                  value: sysTotal.netAmountSys,
                  symbol: printData.baseCcy ?? '',
                  color: isBalanced ? pw.PdfColors.green700 : pw.PdfColors.orange700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  pw.Widget _buildTotalItem({
    required String label,
    required double value,
    required String symbol,
    required pw.PdfColor color,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        zText(
          text: label,
          fontSize: 8,
          color: pw.PdfColors.grey600,
        ),
        pw.SizedBox(height: 2),
        pw.Row(
          children: [
            zText(
              text: value.toAmount(),
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
            pw.SizedBox(width: 4),
            zText(
              text: symbol,
              fontSize: 9,
            ),
          ],
        ),
      ],
    );
  }

  // Helper method to get currency color

  // Helper methods
  double _calculateTotal(List<Records>? items) {
    if (items == null) return 0;
    double total = 0;
    for (var item in items) {
      total += double.tryParse(item.trdAmount ?? '0') ?? 0;
    }
    return total;
  }


}