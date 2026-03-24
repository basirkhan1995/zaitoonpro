
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart' as pw;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:zaitoonpro/Features/Other/extensions.dart';
import '../../../../../../../../Features/PrintSettings/print_services.dart';
import '../../../../../../../../Features/PrintSettings/report_model.dart';
import '../model/trial_balance_model.dart';

class TrialBalancePrintSettings extends PrintServices {
  final pdf = pw.Document();

  Future<void> createDocument({
    required List<TrialBalanceModel> trialBalance,
    required String date,
    required String language,
    required pw.PageOrientation orientation,
    required ReportModel company,
    required pw.PdfPageFormat pageFormat,
  }) async {
    try {
      final document = await generateTrialBalance(
        report: company,
        trialBalance: trialBalance,
        date: date,
        language: language,
        orientation: orientation,
        pageFormat: pageFormat,
      );

      await saveDocument(
        suggestedName: "Trial_Balance_$date.pdf",
        pdf: document,
      );
    } catch (e) {
      throw e.toString();
    }
  }

  Future<void> printDocument({
    required List<TrialBalanceModel> trialBalance,
    required String date,
    required String language,
    required pw.PageOrientation orientation,
    required ReportModel company,
    required Printer selectedPrinter,
    required pw.PdfPageFormat pageFormat,
    required int copies,
    required String pages,
  }) async {
    try {
      final document = await generateTrialBalance(
        report: company,
        trialBalance: trialBalance,
        date: date,
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
          await Future.delayed(Duration(milliseconds: 100));
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
    required List<TrialBalanceModel> trialBalance,
    required String date,
    required pw.PdfPageFormat pageFormat,
  }) async {
    return generateTrialBalance(
      report: company,
      trialBalance: trialBalance,
      date: date,
      language: language,
      orientation: orientation,
      pageFormat: pageFormat,
    );
  }

  Future<pw.Document> generateTrialBalance({
    required String language,
    required ReportModel report,
    required List<TrialBalanceModel> trialBalance,
    required String date,
    required pw.PageOrientation orientation,
    required pw.PdfPageFormat pageFormat,
  }) async {
    final document = pw.Document();
    final prebuiltHeader = await header(report: report);

    // Load your image asset
    final ByteData imageData = await rootBundle.load('assets/images/zaitoonLogo.png');
    final Uint8List imageBytes = imageData.buffer.asUint8List();
    final pw.MemoryImage logoImage = pw.MemoryImage(imageBytes);

    // Calculate totals
    final totals = _calculateTotals(trialBalance);

    document.addPage(
      pw.MultiPage(
        maxPages: 1000,
        margin: pw.EdgeInsets.symmetric(horizontal: 25, vertical: 10),
        pageFormat: pageFormat,
        textDirection: documentLanguage(language: language),
        orientation: orientation,
        build: (context) => [
          trialBalanceHeader(date: date, language: language, reportInfo: report),
          pw.SizedBox(height: 3),
          items(trialBalance: trialBalance, language: language),
          pw.SizedBox(height: 20),
          totalRow(
            totalDebit: totals['totalDebit'] ?? 0,
            totalCredit: totals['totalCredit'] ?? 0,
            difference: totals['difference'] ?? 0,
            language: language,
            currency: trialBalance.isNotEmpty ? trialBalance.first.currency : "USD",
          ),
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

  Map<String, double> _calculateTotals(List<TrialBalanceModel> trialBalance) {
    double totalDebit = 0;
    double totalCredit = 0;

    for (var item in trialBalance) {
      totalDebit += item.debit;
      totalCredit += item.credit;
    }

    final difference = totalDebit - totalCredit;

    return {
      'totalDebit': totalDebit,
      'totalCredit': totalCredit,
      'difference': difference,
    };
  }

  pw.Widget trialBalanceHeader({
    required String date,
    required String language,
    required ReportModel reportInfo,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(height: 5),
        zText(
          text: tr(text: 'trialBalance', tr: language),
          tightBounds: true,
          fontSize: 22,
          fontWeight: pw.FontWeight.bold,
        ),
        pw.SizedBox(height: 5),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            zText(
              text: date,
              fontSize: 10,
            ),
            if (reportInfo.startDate != null && reportInfo.endDate != null)
              zText(
                text: "${reportInfo.startDate!} ${tr(text: 'of', tr: language)} ${reportInfo.endDate!}",
                fontSize: 10,
              ),
          ],
        ),
      ],
    );
  }

  pw.Widget items({required List<TrialBalanceModel> trialBalance, required String language}) {
    const accountNumberWidth = 60.0;
    const categoryWidth = 80.0;
    const debitWidth = 80.0;
    const creditWidth = 80.0;
    const balanceWidth = 100.0;

    trialBalance.sort((a, b) => a.accountNumber.compareTo(b.accountNumber));

    return pw.Column(
      children: [
        // Header Row
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 5),
          decoration: pw.BoxDecoration(
            color: pw.PdfColors.blue50,
          ),
          child: pw.Row(
            children: [
              // Account Number
              pw.SizedBox(
                width: accountNumberWidth,
                child: zText(
                  text: tr(text: 'accountNumber', tr: language),
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              // Account Name
              pw.Expanded(
                child: zText(
                  text: tr(text: 'accountName', tr: language),
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              // Category
              pw.SizedBox(
                width: categoryWidth,
                child: zText(
                  text: tr(text: 'category', tr: language),
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              // Debit
              pw.SizedBox(
                width: debitWidth,
                child: zText(
                  text: tr(text: 'debit', tr: language),
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                  textAlign: pw.TextAlign.right,
                ),
              ),
              // Credit
              pw.SizedBox(
                width: creditWidth,
                child: zText(
                  text: tr(text: 'credit', tr: language),
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                  textAlign: pw.TextAlign.right,
                ),
              ),
              // Balance
              pw.SizedBox(
                width: balanceWidth,
                child: zText(
                  text: tr(text: 'actualBalance', tr: language),
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                  textAlign: pw.TextAlign.right,
                ),
              ),
            ],
          ),
        ),
        // Data Rows
        ...trialBalance.map((item) {
          return pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 5),
            decoration: pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(width: 0.5, color: pw.PdfColors.grey300),
              ),
            ),
            child: pw.Row(
              children: [
                // Account Number
                pw.SizedBox(
                  width: accountNumberWidth,
                  child: zText(
                    text: item.accountNumber,
                    fontSize: 8,
                  ),
                ),
                // Account Name
                pw.Expanded(
                  child: zText(
                    text: item.accountName,
                    fontSize: 8,
                  ),
                ),
                // Category
                pw.SizedBox(
                  width: categoryWidth,
                  child: zText(
                    text: _translateCategory(item.category, language),
                    fontSize: 8,
                  ),
                ),
                // Debit
                pw.SizedBox(
                  width: debitWidth,
                  child: zText(
                    text: item.debit > 0 ? item.debit.toAmount() : "-",
                    fontSize: 8,
                    textAlign: pw.TextAlign.right,
                    color: item.debit > 0 ? pw.PdfColors.black : pw.PdfColors.grey600,
                  ),
                ),
                // Credit
                pw.SizedBox(
                  width: creditWidth,
                  child: zText(
                    text: item.credit > 0 ? item.credit.toAmount() : "-",
                    fontSize: 8,
                    textAlign: pw.TextAlign.right,
                    color: item.credit > 0 ? pw.PdfColors.black : pw.PdfColors.grey600,
                  ),
                ),
                // Balance
                pw.SizedBox(
                  width: balanceWidth,
                  child: zText(
                    text: "${item.actualBalance.toAmount()} ${item.currency}",
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                    textAlign: pw.TextAlign.right,
                    color: item.actualBalance < 0
                        ? pw.PdfColors.red
                        : item.actualBalance > 0
                        ? pw.PdfColors.green
                        : pw.PdfColors.black,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  String _translateCategory(String category, String language) {
    final categories = {
      'Asset': {
        'en': 'Asset',
        'fa': 'دارایی',
        'ar': 'دارایی',
      },
      'Liability': {
        'en': 'Liability',
        'fa': 'بدهی',
        'ar': 'بدهی',
      },
      'Income': {
        'en': 'Income',
        'fa': 'درآمد',
        'ar': 'درآمد',
      },
      'Expense': {
        'en': 'Expense',
        'fa': 'مخارج',
        'ar': 'مخارج',
      },
      'Equity': {
        'en': 'Equity',
        'fa': 'حقوق صاحبان سهام',
        'ar': 'حقوق صاحبان سهام',
      },
    };

    if (categories.containsKey(category)) {
      return categories[category]![language] ?? category;
    }
    return category;
  }

  pw.Widget totalRow({
    required double totalDebit,
    required double totalCredit,
    required double difference,
    required String language,
    required String currency,
  }) {
    final isBalanced = difference == 0;
    final differencePercentage = totalDebit > 0 ? (difference.abs() / totalDebit * 100) : 0;
    final isPositiveDifference = difference > 0;

    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 10),
      padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      decoration: pw.BoxDecoration(
        color: pw.PdfColors.grey50,
        borderRadius: pw.BorderRadius.circular(5),
        border: pw.Border.all(
          width: 0.5,
          color: isBalanced ? pw.PdfColors.green : pw.PdfColors.grey200,
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          // Left side - Total label and status
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Row(
                  children: [
                    zText(
                      text: tr(text: 'total', tr: language),
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: pw.PdfColors.grey800,
                    ),
                  ],
                ),
                pw.SizedBox(height: 6),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: pw.BoxDecoration(
                    color: pw.PdfColors.white,
                    borderRadius: pw.BorderRadius.circular(2),
                    border: pw.Border.all(
                      width: 0.8,
                      color: isBalanced ? pw.PdfColors.green : pw.PdfColors.red,
                    ),
                  ),
                  child: pw.Row(
                    mainAxisSize: pw.MainAxisSize.min,
                    children: [
                      pw.Container(
                        width: 8,
                        height: 8,
                        decoration: pw.BoxDecoration(
                          shape: pw.BoxShape.circle,
                          color: isBalanced ? pw.PdfColors.green : pw.PdfColors.red,
                        ),
                      ),
                      pw.SizedBox(width: 6),
                      zText(
                        text: isBalanced
                            ? tr(text: 'balanced', tr: language)
                            : tr(text: 'outOfBalance', tr: language),
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        color: isBalanced ? pw.PdfColors.green : pw.PdfColors.red,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Vertical divider
          pw.Container(
            width: 1,
            height: 60,
            color: pw.PdfColors.grey300,
            margin: const pw.EdgeInsets.symmetric(horizontal: 20),
          ),

          // Middle - Totals section
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                // Debit Total
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    zText(
                      text: tr(text: 'totalDebit', tr: language),
                      fontSize: 9,
                      color: pw.PdfColors.grey600,
                    ),
                    pw.SizedBox(width: 12),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        zText(
                          text: totalDebit.toAmount(),
                          fontSize: 15,
                          fontWeight: pw.FontWeight.bold,
                          color: pw.PdfColors.blue800,
                        ),
                        zText(
                          text: currency,
                          fontSize: 9,
                          color: pw.PdfColors.blue600,
                        ),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 8),

                // Credit Total
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    zText(
                      text: tr(text: 'totalCredit', tr: language),
                      fontSize: 9,
                      color: pw.PdfColors.grey600,
                    ),
                    pw.SizedBox(width: 12),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        zText(
                          text: totalCredit.toAmount(),
                          fontSize: 15,
                          fontWeight: pw.FontWeight.bold,
                          color: pw.PdfColors.green800,
                        ),
                        zText(
                          text: currency,
                          fontSize: 9,
                          color: pw.PdfColors.green600,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Vertical divider
          pw.Container(
            width: 1,
            height: 60,
            color: pw.PdfColors.grey300,
            margin: const pw.EdgeInsets.symmetric(horizontal: 20),
          ),

          // Right side - Difference
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                zText(
                  text: tr(text: 'difference', tr: language),
                  fontSize: 10,
                  color: pw.PdfColors.grey600,
                ),
                pw.SizedBox(height: 5),

                // Difference amount
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                  decoration: pw.BoxDecoration(
                    color: pw.PdfColors.white,
                    borderRadius: pw.BorderRadius.circular(4),
                    border: pw.Border.all(
                      width: 0.5,
                      color: isBalanced
                          ? pw.PdfColors.green
                          : isPositiveDifference
                          ? pw.PdfColors.blue
                          : pw.PdfColors.red,
                    ),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Row(
                        mainAxisSize: pw.MainAxisSize.min,
                        children: [
                          zText(
                            text: difference.abs().toAmount(),
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                            color: isBalanced
                                ? pw.PdfColors.green
                                : isPositiveDifference
                                ? pw.PdfColors.blue
                                : pw.PdfColors.red,
                          ),
                          pw.SizedBox(width: 4),
                          zText(
                            text: currency,
                            fontSize: 10,
                            color: isBalanced
                                ? pw.PdfColors.green
                                : isPositiveDifference
                                ? pw.PdfColors.blue
                                : pw.PdfColors.red,
                          ),
                        ],
                      ),

                      if (!isBalanced) ...[
                        pw.SizedBox(height: 4),
                        pw.Row(
                          mainAxisSize: pw.MainAxisSize.min,
                          children: [
                            zText(
                              text: "${differencePercentage.toStringAsFixed(2)}%",
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                              color: pw.PdfColors.grey600,
                            ),
                            pw.SizedBox(width: 6),
                            zText(
                              text: isPositiveDifference
                                  ? tr(text: 'debit', tr: language)
                                  : tr(text: 'credit', tr: language),
                              fontSize: 9,
                              color: pw.PdfColors.grey600,
                              fontStyle: pw.FontStyle.italic,
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Future<pw.Widget> header({required ReportModel report}) async {
    final image = (report.comLogo != null && report.comLogo is Uint8List && report.comLogo!.isNotEmpty)
        ? pw.MemoryImage(report.comLogo!)
        : null;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Company info (left side)
            pw.Expanded(
              flex: 3,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  zText(text: report.comName ?? "", fontSize: 25, fontWeight: pw.FontWeight.bold, tightBounds: true),
                  pw.SizedBox(height: 3),
                  zText(text: report.statementDate ?? "", fontSize: 10),
                ],
              ),
            ),
            // Logo (right side)
            if (image != null)
              pw.Container(
                width: 45,
                height: 45,
                child: pw.Image(image, fit: pw.BoxFit.contain),
              ),
          ],
        ),
        pw.SizedBox(height: 5)
      ],
    );
  }

  @override
  pw.Widget footer({
    required ReportModel report,
    required pw.Context context,
    required String language,
    required pw.MemoryImage logoImage,
  }) {
    return pw.Column(
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.start,
          children: [
            pw.Container(
              height: 20,
              child: pw.Image(logoImage),
            ),
            verticalDivider(height: 15, width: 0.6),
            zText(
              text: tr(text: 'producedBy', tr: language),
              fontWeight: pw.FontWeight.normal,
              fontSize: 8,
            ),
          ],
        ),
        pw.SizedBox(height: 3),
        horizontalDivider(),
        pw.SizedBox(height: 3),
        pw.Row(
          children: [
            zText(text: report.comAddress ?? "", fontSize: 9),
          ],
        ),
        pw.SizedBox(height: 3),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Row(
              children: [
                zText(text: report.compPhone ?? "", fontSize: 9),
                verticalDivider(height: 10, width: 1),
                zText(text: report.comEmail ?? "", fontSize: 9),
              ],
            ),
            pw.Row(
              children: [
                buildPage(context.pageNumber, context.pagesCount, language),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

// Add this extension method if not already present
extension TrialBalanceHelper on List<TrialBalanceModel> {
  static double getTotalDebit(List<TrialBalanceModel> data) {
    return data.fold(0.0, (sum, item) => sum + item.debit);
  }

  static double getTotalCredit(List<TrialBalanceModel> data) {
    return data.fold(0.0, (sum, item) => sum + item.credit);
  }

  static double getDifference(List<TrialBalanceModel> data) {
    return getTotalDebit(data) - getTotalCredit(data);
  }

  static double getDifferencePercentage(List<TrialBalanceModel> data) {
    final totalDebit = getTotalDebit(data);
    final difference = getDifference(data);
    return totalDebit > 0 ? (difference.abs() / totalDebit * 100) : 0;
  }
}