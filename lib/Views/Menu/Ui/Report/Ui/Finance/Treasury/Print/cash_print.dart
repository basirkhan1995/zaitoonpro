import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart' as pw;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:zaitoon_petroleum/Features/Date/shamsi_converter.dart';
import 'package:zaitoon_petroleum/Features/Other/extensions.dart';
import 'package:zaitoon_petroleum/Features/PrintSettings/print_services.dart';
import 'package:zaitoon_petroleum/Features/PrintSettings/report_model.dart';
import '../../../../../../../../Features/PrintSettings/PaperSize/paper_size.dart';
import '../model/cash_balance_model.dart';
import 'feature_model.dart';

class CashBalancesPrintSettings extends PrintServices {

  // Create document (Save PDF)
  Future<void> createDocument({
    required CashBalancesPrintData printData,
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

      final fileName = printData.reportType == 'single'
          ? 'cash_balance_${printData.selectedBranchName ?? 'branch'}_${DateTime.now().millisecondsSinceEpoch}.pdf'
          : 'all_cash_balances_${DateTime.now().millisecondsSinceEpoch}.pdf';

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
    required CashBalancesPrintData printData,
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

      final fileName = printData.reportType == 'single'
          ? 'cash_balance_${printData.selectedBranchName ?? 'branch'}_${DateTime.now().millisecondsSinceEpoch}.pdf'
          : 'all_cash_balances_${DateTime.now().millisecondsSinceEpoch}.pdf';

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
    required CashBalancesPrintData printData,
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
    required CashBalancesPrintData printData,
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

          // Summary by Currency Section
          _buildCurrencySummary(printData, language),
          pw.SizedBox(height: 15),

          // Grand Total Section
          _buildGrandTotalSection(printData, language),
          pw.SizedBox(height: 20),

          // Branch Details Header
          _buildBranchDetailsHeader(printData, language),
          pw.SizedBox(height: 5),

          // Branch Details
          ..._buildBranchDetails(printData, language),
        ],
      ),
    );

    return document;
  }

  // Report Title
  pw.Widget _buildTitle(CashBalancesPrintData printData, String language) {
    String title;
    if (printData.reportType == 'single') {
      title = '${tr(text: 'cashBalances', tr: language)} - ${printData.selectedBranchName ?? ''}';
    } else {
      title = '${tr(text: 'cashBalances', tr: language)} - ${tr(text: 'allBranches', tr: language)}';
    }

    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        zText(
          text: title.toUpperCase(),
          fontSize: 16,
          fontWeight: pw.FontWeight.bold,
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            zText(
              text: '${tr(text: 'date', tr: language)}: ${printData.reportDate.toFormattedDate}',
              fontSize: 8,
              color: pw.PdfColors.grey600,
            ),
            zText(
              text: '${tr(text: 'time', tr: language)}: ${_formatTime(printData.reportDate)}',
              fontSize: 8,
              color: pw.PdfColors.grey600,
            ),
          ],
        ),
      ],
    );
  }

  // Currency Summary Section
  pw.Widget _buildCurrencySummary(CashBalancesPrintData printData, String language) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: pw.PdfColors.grey300, width: 0.5),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          zText(
            text: tr(text: 'summaryByCurrency', tr: language),
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
          ),
          pw.Divider(height: 10, thickness: 0.5),

          // Table Header
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 4),
            decoration: pw.BoxDecoration(
              color: pw.PdfColors.grey100,
            ),
            child: pw.Row(
              children: [
                pw.Expanded(
                  flex: 1,
                  child: zText(
                    text: tr(text: 'currency', tr: language),
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Expanded(
                  flex: 1,
                  child: zText(
                    text: tr(text: 'openingBalance', tr: language),
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                    textAlign: pw.TextAlign.right,
                  ),
                ),
                pw.Expanded(
                  flex: 1,
                  child: zText(
                    text: tr(text: 'closingBalance', tr: language),
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                    textAlign: pw.TextAlign.right,
                  ),
                ),
                pw.Expanded(
                  flex: 1,
                  child: zText(
                    text: tr(text: 'cashFlow', tr: language),
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                    textAlign: pw.TextAlign.right,
                  ),
                ),
              ],
            ),
          ),

          // Currency Rows
          ...printData.currencyTotals.entries.map((entry) {
            final currency = entry.key;
            final data = entry.value;
            final isPositive = data.cashFlow >= 0;

            return pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 4),
              decoration: pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: pw.PdfColors.grey200, width: 0.3),
                ),
              ),
              child: pw.Row(
                children: [
                  // Currency
                  pw.Expanded(
                    flex: 1,
                    child: pw.Row(
                      children: [
                        pw.Container(
                          width: 6,
                          height: 6,
                          decoration: pw.BoxDecoration(
                            color: _getCurrencyColor(currency),
                            shape: pw.BoxShape.circle,
                          ),
                        ),
                        pw.SizedBox(width: 4),
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              zText(
                                text: currency,
                                fontSize: 9,
                                fontWeight: pw.FontWeight.bold,
                              ),
                              zText(
                                text: data.name,
                                fontSize: 7,
                                color: pw.PdfColors.grey600,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Opening Balance - Show currency code instead of symbol
                  pw.Expanded(
                    flex: 1,
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.end,
                      children: [
                        zText(
                          text: data.totalOpening.toAmount(),
                          fontSize: 9,
                          textAlign: pw.TextAlign.right,
                        ),
                        pw.SizedBox(width: 4),
                        zText(
                          text: currency, // Changed from data.symbol to currency
                          fontSize: 8,
                          color: pw.PdfColors.grey600,
                        ),
                      ],
                    ),
                  ),

                  // Closing Balance - Show currency code instead of symbol
                  pw.Expanded(
                    flex: 1,
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.end,
                      children: [
                        zText(
                          text: data.totalClosing.toAmount(),
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          textAlign: pw.TextAlign.right,
                        ),
                        pw.SizedBox(width: 4),
                        zText(
                          text: currency, // Changed from data.symbol to currency
                          fontSize: 8,
                          color: pw.PdfColors.grey600,
                        ),
                      ],
                    ),
                  ),

                  // Cash Flow - Show currency code instead of symbol
                  pw.Expanded(
                    flex: 1,
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.end,
                      children: [
                        zText(
                          text: data.cashFlow.toAmount(),
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: isPositive ? pw.PdfColors.green700 : pw.PdfColors.red700,
                          textAlign: pw.TextAlign.right,
                        ),
                        pw.SizedBox(width: 4),
                        zText(
                          text: currency, // Changed from data.symbol to currency
                          fontSize: 8,
                          color: isPositive ? pw.PdfColors.green700 : pw.PdfColors.red700,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // Helper method to get currency color
  pw.PdfColor _getCurrencyColor(String currency) {
    switch (currency.toUpperCase()) {
      case 'USD':
        return pw.PdfColors.green700;
      case 'AFN':
        return pw.PdfColors.blue700;
      case 'INR':
        return pw.PdfColors.orange700;
      case 'BRL':
        return pw.PdfColors.yellow700;
      case 'CAD':
        return pw.PdfColors.red700;
      case 'EUR':
        return pw.PdfColors.blue500;
      case 'GBP':
        return pw.PdfColors.purple700;
      case 'JPY':
        return pw.PdfColors.pink700;
      case 'CNY':
        return pw.PdfColors.red500;
      default:
        return pw.PdfColors.grey700;
    }
  }

  // Grand Total Section (System Equivalent)
  pw.Widget _buildGrandTotalSection(CashBalancesPrintData printData, String language) {
    final sysTotal = printData.systemTotal;
    final isPositive = sysTotal.cashFlowSys >= 0;

    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: pw.PdfColors.purple50,
        border: pw.Border.all(color: pw.PdfColors.purple200, width: 0.5),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          zText(
            text: '${tr(text: 'grandTotal', tr: language)} (${printData.baseCcy ?? ''})',
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: pw.PdfColors.purple700,
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildTotalItem(
                  label: tr(text: 'openingBalance', tr: language),
                  value: sysTotal.totalOpeningSys,
                  symbol: printData.baseCcy ?? '',
                  color: pw.PdfColors.grey700,
                ),
              ),
              pw.SizedBox(width: 20),
              pw.Expanded(
                child: _buildTotalItem(
                  label: tr(text: 'closingBalance', tr: language),
                  value: sysTotal.totalClosingSys,
                  symbol: printData.baseCcy ?? '',
                  color: pw.PdfColors.purple700,
                ),
              ),
              pw.SizedBox(width: 20),
              pw.Expanded(
                child: _buildTotalItem(
                  label: tr(text: 'cashFlow', tr: language),
                  value: sysTotal.cashFlowSys,
                  symbol: printData.baseCcy ?? '',
                  color: isPositive ? pw.PdfColors.green700 : pw.PdfColors.red700,
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
              text: symbol, // This is the base currency code (e.g., "USD", "AFN", etc.)
              fontSize: 9,
            ),
          ],
        ),
      ],
    );
  }

  // Branch Details Header
  pw.Widget _buildBranchDetailsHeader(CashBalancesPrintData printData, String language) {
    if (printData.reportType == 'single') {
      return pw.SizedBox();
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        zText(
          text: tr(text: 'branchWiseDetails', tr: language),
          fontSize: 12,
          fontWeight: pw.FontWeight.bold,
        ),
        pw.SizedBox(height: 8),
      ],
    );
  }

  // Branch Details
  List<pw.Widget> _buildBranchDetails(CashBalancesPrintData printData, String language) {
    final List<pw.Widget> widgets = [];

    for (int i = 0; i < printData.branches.length; i++) {
      final branch = printData.branches[i];

      widgets.add(
        pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 15),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Branch Header
              _buildBranchHeader(branch, i + 1, language),
              pw.SizedBox(height: 5),

              // Branch Records Table
              _buildBranchRecordsTable(branch, printData.baseCcy ?? '', language),
            ],
          ),
        ),
      );
    }

    return widgets;
  }

  // Branch Header
  pw.Widget _buildBranchHeader(CashBalancesModel branch, int index, String language) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      decoration: pw.BoxDecoration(
        color: pw.PdfColors.blue50,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Row(
        children: [
          pw.Container(
            width: 20,
            height: 20,
            decoration: pw.BoxDecoration(
              color: pw.PdfColors.blue700,
              shape: pw.BoxShape.circle,
            ),
            child: pw.Center(
              child: zText(
                text: index.toString(),
                fontSize: 10,
                color: pw.PdfColors.white,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                zText(
                  text: branch.brcName ?? 'Unnamed Branch',
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                ),
                pw.SizedBox(height: 2),
                pw.Row(
                  children: [
                    zText(
                      text: '${tr(text: 'phone', tr: language)}: ${branch.brcPhone ?? 'N/A'}',
                      fontSize: 8,
                      color: pw.PdfColors.grey600,
                    ),
                    pw.SizedBox(width: 15),
                    zText(
                      text: '${tr(text: 'address', tr: language)}: ${branch.address ?? 'N/A'}',
                      fontSize: 8,
                      color: pw.PdfColors.grey600,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Branch Records Table
  pw.Widget _buildBranchRecordsTable(CashBalancesModel branch, String baseCcy, String language) {
    if (branch.records == null || branch.records!.isEmpty) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(8),
        child: zText(
          text: tr(text: 'noRecords', tr: language),
          fontSize: 9,
          color: pw.PdfColors.grey600,
          textAlign: pw.TextAlign.center,
        ),
      );
    }

    // Calculate branch totals
    double branchOpeningSys = 0;
    double branchClosingSys = 0;

    for (var record in branch.records!) {
      branchOpeningSys += double.tryParse(record.openingSysEquivalent ?? '0') ?? 0;
      branchClosingSys += double.tryParse(record.closingSysEquivalent ?? '0') ?? 0;
    }

    return pw.Column(
      children: [
        // Table Header
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          decoration: pw.BoxDecoration(
            color: pw.PdfColors.grey100,
            border: pw.Border(
              bottom: pw.BorderSide(color: pw.PdfColors.grey400, width: 0.5),
            ),
          ),
          child: pw.Row(
            children: [
              pw.Expanded(
                flex: 1,
                child: zText(
                  text: tr(text: 'currency', tr: language),
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Expanded(
                flex: 1,
                child: zText(
                  text: tr(text: 'opening', tr: language),
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                  textAlign: pw.TextAlign.right,
                ),
              ),
              pw.Expanded(
                flex: 1,
                child: zText(
                  text: '${tr(text: 'opening', tr: language)} (Sys)',
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                  textAlign: pw.TextAlign.right,
                ),
              ),
              pw.Expanded(
                flex: 1,
                child: zText(
                  text: tr(text: 'closing', tr: language),
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                  textAlign: pw.TextAlign.right,
                ),
              ),
              pw.Expanded(
                flex: 1,
                child: zText(
                  text: '${tr(text: 'closing', tr: language)} (Sys)',
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                  textAlign: pw.TextAlign.right,
                ),
              ),
              pw.Expanded(
                flex: 1,
                child: zText(
                  text: tr(text: 'cashFlow', tr: language),
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                  textAlign: pw.TextAlign.right,
                ),
              ),
            ],
          ),
        ),

        // Records
        ...branch.records!.map((record) {
          final opening = double.tryParse(record.openingBalance ?? '0') ?? 0;
          final closing = double.tryParse(record.closingBalance ?? '0') ?? 0;
          final openingSys = double.tryParse(record.openingSysEquivalent ?? '0') ?? 0;
          final closingSys = double.tryParse(record.closingSysEquivalent ?? '0') ?? 0;
          final cashFlow = closing - opening;
          final isPositive = cashFlow >= 0;
          final currencyCode = record.trdCcy ?? '';

          return pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 4),
            decoration: pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: pw.PdfColors.grey200, width: 0.3),
              ),
            ),
            child: pw.Row(
              children: [
                // Currency
                pw.Expanded(
                  flex: 1,
                  child: pw.Row(
                    children: [
                      pw.Container(
                        width: 6,
                        height: 6,
                        decoration: pw.BoxDecoration(
                          color: _getCurrencyColor(currencyCode),
                          shape: pw.BoxShape.circle,
                        ),
                      ),
                      pw.SizedBox(width: 4),
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            zText(
                              text: currencyCode,
                              fontSize: 8,
                              fontWeight: pw.FontWeight.bold,
                            ),
                            zText(
                              text: record.ccyName ?? '',
                              fontSize: 6,
                              color: pw.PdfColors.grey600,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Opening - Show currency code instead of symbol
                pw.Expanded(
                  flex: 1,
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.end,
                    children: [
                      zText(
                        text: opening.toAmount(),
                        fontSize: 8,
                      ),
                      pw.SizedBox(width: 2),
                      zText(
                        text: currencyCode, // Changed from record.ccySymbol to currencyCode
                        fontSize: 7,
                        color: pw.PdfColors.grey600,
                      ),
                    ],
                  ),
                ),

                // Opening Sys
                pw.Expanded(
                  flex: 1,
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.end,
                    children: [
                      zText(
                        text: openingSys.toAmount(),
                        fontSize: 8,
                      ),
                      pw.SizedBox(width: 2),
                      zText(
                        text: baseCcy,
                        fontSize: 7,
                        color: pw.PdfColors.grey600,
                      ),
                    ],
                  ),
                ),

                // Closing - Show currency code instead of symbol
                pw.Expanded(
                  flex: 1,
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.end,
                    children: [
                      zText(
                        text: closing.toAmount(),
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                      ),
                      pw.SizedBox(width: 2),
                      zText(
                        text: currencyCode, // Changed from record.ccySymbol to currencyCode
                        fontSize: 7,
                        color: pw.PdfColors.grey600,
                      ),
                    ],
                  ),
                ),

                // Closing Sys
                pw.Expanded(
                  flex: 1,
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.end,
                    children: [
                      zText(
                        text: closingSys.toAmount(),
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                      ),
                      pw.SizedBox(width: 2),
                      zText(
                        text: baseCcy,
                        fontSize: 7,
                        color: pw.PdfColors.grey600,
                      ),
                    ],
                  ),
                ),

                // Cash Flow - Show currency code instead of symbol
                pw.Expanded(
                  flex: 1,
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.end,
                    children: [
                      zText(
                        text: cashFlow.toAmount(),
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                        color: isPositive ? pw.PdfColors.green700 : pw.PdfColors.red700,
                      ),
                      pw.SizedBox(width: 2),
                      zText(
                        text: currencyCode, // Changed from record.ccySymbol to currencyCode
                        fontSize: 7,
                        color: isPositive ? pw.PdfColors.green700 : pw.PdfColors.red700,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),

        // Branch Total Row
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          decoration: pw.BoxDecoration(
            color: pw.PdfColors.purple50,
            border: pw.Border(
              top: pw.BorderSide(color: pw.PdfColors.purple200, width: 0.5),
            ),
          ),
          child: pw.Row(
            children: [
              pw.Expanded(
                flex: 1,
                child: zText(
                  text: tr(text: 'branchTotal', tr: language),
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: pw.PdfColors.purple700,
                ),
              ),
              pw.Expanded(
                flex: 1,
                child: pw.Container(),
              ),
              pw.Expanded(
                flex: 1,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    zText(
                      text: branchOpeningSys.toAmount(),
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                      color: pw.PdfColors.purple700,
                    ),
                    pw.SizedBox(width: 2),
                    zText(
                      text: baseCcy,
                      fontSize: 8,
                      color: pw.PdfColors.purple700,
                    ),
                  ],
                ),
              ),
              pw.Expanded(
                flex: 1,
                child: pw.Container(),
              ),
              pw.Expanded(
                flex: 1,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    zText(
                      text: branchClosingSys.toAmount(),
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                      color: pw.PdfColors.purple700,
                    ),
                    pw.SizedBox(width: 2),
                    zText(
                      text: baseCcy,
                      fontSize: 8,
                      color: pw.PdfColors.purple700,
                    ),
                  ],
                ),
              ),
              pw.Expanded(
                flex: 1,
                child: pw.Container(),
              ),
            ],
          ),
        ),
      ],
    );
  }



  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}';
  }
}