import 'package:pdf/pdf.dart' as pw;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:zaitoonpro/Features/Other/extensions.dart';
import 'package:zaitoonpro/Features/PrintSettings/print_services.dart';
import 'package:zaitoonpro/Features/PrintSettings/report_model.dart';
import '../model/ar_ap_model.dart';

class ArApPdfServices extends PrintServices {
  // Clean color palette
  static const _primaryColor = pw.PdfColors.blue800;
  static const _secondaryColor = pw.PdfColors.blue50;
  static const _textPrimary = pw.PdfColors.grey900;
  static const _textSecondary = pw.PdfColors.grey700;
  static const _borderColor = pw.PdfColors.grey300;
  static const _headerBgColor = pw.PdfColors.grey50;

  Future<pw.Document> generateArReport({
    required ReportModel report,
    required List<ArApModel> arAccounts,
    required String language,
    required pw.PageOrientation orientation,
    required pw.PdfPageFormat pageFormat,
  }) async {
    return _generateReport(
      report: report,
      accounts: arAccounts.where((e) => e.isAR).toList(),
      language: language,
      orientation: orientation,
      pageFormat: pageFormat,
      reportType: 'debtor',
      isAR: true,
    );
  }

  Future<pw.Document> generateApReport({
    required ReportModel report,
    required List<ArApModel> apAccounts,
    required String language,
    required pw.PageOrientation orientation,
    required pw.PdfPageFormat pageFormat,
  }) async {
    return _generateReport(
      report: report,
      accounts: apAccounts.where((e) => e.isAP).toList(),
      language: language,
      orientation: orientation,
      pageFormat: pageFormat,
      reportType: 'creditor',
      isAR: false,
    );
  }

  Future<pw.Document> _generateReport({
    required ReportModel report,
    required List<ArApModel> accounts,
    required String language,
    required pw.PageOrientation orientation,
    required pw.PdfPageFormat pageFormat,
    required String reportType,
    required bool isAR,
  }) async {
    final document = pw.Document();
    final totalsByCurrency = _calculateTotalsByCurrency(accounts);
    final totalAccounts = accounts.length;
    final activeAccounts = accounts.where((acc) => acc.accStatus == 1).length;

    document.addPage(
      pw.MultiPage(
        maxPages: 1000,
        margin: const pw.EdgeInsets.all(30),
        pageFormat: pageFormat,
        textDirection: documentLanguage(language: language),
        orientation: orientation,
        build: (context) => [
          _buildReportHeader(language, reportType),
          pw.SizedBox(height: 15),
          _buildSimpleStats(totalAccounts, activeAccounts, language),
          pw.SizedBox(height: 15),
          _buildCurrencySummary(totalsByCurrency, language, isAR),
          pw.SizedBox(height: 20),
          _buildAccountsTable(accounts, language),
        ],
      ),
    );

    return document;
  }

  pw.Widget _buildReportHeader(String language, String reportType) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 15),
      decoration: pw.BoxDecoration(
        color: _secondaryColor,
        borderRadius: pw.BorderRadius.circular(3),
        border: pw.Border.all(color: _borderColor),
      ),
      child: pw.Row(
        children: [
          pw.Container(
            width: 4,
            height: 50,
            color: _primaryColor,
            margin: const pw.EdgeInsets.symmetric(horizontal: 12),
          ),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                zText(
                 text: tr(text: 'accountStatement', tr: language).toUpperCase(),
                    fontSize: 14,
                    color: _textSecondary,
                ),
                zText(
                 text: tr(text: reportType, tr: language),
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: _primaryColor,
                ),
              ],
            ),
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: pw.BoxDecoration(
              color: pw.PdfColors.white,
              borderRadius: pw.BorderRadius.circular(4),
              border: pw.Border.all(color: _borderColor),
            ),
            child: pw.Text(
              DateTime.now().toIso8601String().substring(0, 10),
              style: pw.TextStyle(
                fontSize: 12,
                color: _textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSimpleStats(int total, int active, String language) {
    return pw.Row(
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: pw.BoxDecoration(
            color: pw.PdfColors.grey100,
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Row(
            children: [
              zText(
               text: '${tr(text: 'total', tr: language)}: ',
                fontSize: 10, color: _textSecondary,
              ),
              pw.Text(
                total.toString(),
                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: _primaryColor),
              ),
            ],
          ),
        ),
        pw.SizedBox(width: 10),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: pw.BoxDecoration(
            color: pw.PdfColors.grey100,
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Row(
            children: [
              zText(
              text: '${tr(text: 'active', tr: language)}: ',
                fontSize: 10, color: _textSecondary,
              ),
              pw.Text(
                active.toString(),
                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: pw.PdfColors.green700),
              ),
            ],
          ),
        ),
        pw.SizedBox(width: 10),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: pw.BoxDecoration(
            color: pw.PdfColors.grey100,
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Row(
            children: [
              zText(
               text: '${tr(text: 'inactive', tr: language)}: ',
                fontSize: 10, color: _textSecondary,
              ),
              zText(
               text: (total - active).toString(),
                fontSize: 12, fontWeight: pw.FontWeight.bold, color: pw.PdfColors.grey700,
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildCurrencySummary(Map<String, double> totalsByCurrency, String language, bool isAR) {
    final balanceColor = isAR ? pw.PdfColors.red700 : pw.PdfColors.green700;

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: pw.PdfColors.white,
        borderRadius: pw.BorderRadius.circular(4),
        border: pw.Border.all(color: _borderColor),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          zText(
           text: tr(text: 'currencyBreakdown', tr: language),
            fontSize: 11, fontWeight: pw.FontWeight.bold, color: _textPrimary,
          ),
          pw.SizedBox(height: 4),
          pw.Divider(color: _borderColor, height: 1),
          pw.SizedBox(height: 4),
          ...totalsByCurrency.entries.map((entry) => pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 2),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Row(
                  children: [
                    pw.Container(
                      width: 3,
                      height: 3,
                      color: balanceColor,
                      margin: pw.EdgeInsets.symmetric(horizontal: 6),
                    ),
                    pw.Text(
                      entry.key,
                      style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _textPrimary),
                    ),
                  ],
                ),
                pw.Text(
                  entry.value.toAmount(),
                  style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: balanceColor),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  pw.Widget _buildAccountsTable(
      List<ArApModel> accounts,
      String language,
      ) {
    // Define fixed column widths
    const colSNo = 0.4;
    const colAccount = 2.5;
    const colSignatory = 2.0;
    const colBalance = 1.2;
    const colStatus = 0.7;

    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _borderColor),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        children: [
          // Table Header
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: pw.BoxDecoration(
              color: pw.PdfColors.blue50,
              borderRadius: const pw.BorderRadius.only(
                topLeft: pw.Radius.circular(4),
                topRight: pw.Radius.circular(4),
              ),
            ),
            child: pw.Row(
              children: [
                pw.Expanded(flex: (colSNo * 10).toInt(), child: pw.Text('#', style: _headerStyle())),
                pw.Expanded(flex: (colAccount * 10).toInt(), child: zText(text: tr(text: 'accounts', tr: language), fontWeight: pw.FontWeight.bold,color: _textPrimary, fontSize: 9)),
                pw.Expanded(flex: (colSignatory * 10).toInt(), child: zText(text: tr(text: 'signatory', tr: language), fontWeight: pw.FontWeight.bold,color: _textPrimary, fontSize: 9)),
                pw.Expanded(flex: (colBalance * 10).toInt(), child: zText(text: tr(text: 'balance', tr: language), textAlign: language == "en"? pw.TextAlign.right : pw.TextAlign.left, fontWeight: pw.FontWeight.bold,color: _textPrimary, fontSize: 9)),
                pw.Expanded(flex: (colStatus * 10).toInt(), child: zText(text: tr(text: 'status', tr: language),textAlign: language == "en"? pw.TextAlign.right : pw.TextAlign.left, fontWeight: pw.FontWeight.bold,color: _textPrimary, fontSize: 9)),
              ],
            ),
          ),

          // Table Rows
          for (var i = 0; i < accounts.length; i++)
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              decoration: pw.BoxDecoration(
                color: i.isEven ? _headerBgColor : pw.PdfColors.white,
                border: i < accounts.length - 1
                    ? pw.Border(bottom: pw.BorderSide(color: _borderColor))
                    : null,
              ),
              child: pw.Row(
                children: [
                  // Serial No
                  pw.Expanded(
                    flex: (colSNo * 10).toInt(),
                    child: pw.Text(
                      (i + 1).toString(),
                      style: _cellStyle(),
                    ),
                  ),

                  // Account Details (Name + Number)
                  pw.Expanded(
                    flex: (colAccount * 10).toInt(),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        zText(
                         text: accounts[i].accName ?? '-',
                          fontSize: 9, fontWeight: pw.FontWeight.bold,
                        ),
                        zText(
                          text: accounts[i].accNumber?.toString() ?? '-',
                          fontSize: 7, color: _textSecondary,
                        ),
                        zText(
                          text: accounts[i].accCurrency?.toString() ?? '-',
                          fontSize: 7, fontWeight: pw.FontWeight.bold, color: _textSecondary,
                        ),
                      ],
                    ),
                  ),

                  // Signatory
                  pw.Expanded(
                    flex: (colSignatory * 10).toInt(),
                    child: zText(
                     text: accounts[i].fullName ?? '-',
                      fontSize: 9,
                      textAlign: language == "en"? pw.TextAlign.left : pw.TextAlign.right,
                    ),
                  ),

                  // Balance (without currency header)
                  pw.Expanded(
                    flex: (colBalance * 10).toInt(),
                    child: pw.Text(
                      accounts[i].balance.abs().toAmount(),
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        color: accounts[i].balance < 0 ? pw.PdfColors.red700 : pw.PdfColors.green700,
                      ),
                      textAlign: language == "en"? pw.TextAlign.right : pw.TextAlign.left,
                    ),
                  ),

                  // Status
                  pw.Expanded(
                    flex: (colStatus * 10).toInt(),
                    child: _buildStatusText(accounts[i].accStatus == 1, language),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  pw.TextStyle _headerStyle() {
    return pw.TextStyle(
      fontSize: 9,
      fontWeight: pw.FontWeight.bold,
      color: _textPrimary,
    );
  }

  pw.TextStyle _cellStyle() {
    return const pw.TextStyle(fontSize: 9);
  }

  pw.Widget _buildStatusText(bool isActive, String language) {
    final statusText = isActive
        ? tr(text: 'active', tr: language)
        : tr(text: 'blocked', tr: language);

    final color = isActive ? pw.PdfColors.green700 : pw.PdfColors.red700;

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: zText(
        text: statusText,
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
          color: color,
        textAlign: language == "en"? pw.TextAlign.right : pw.TextAlign.left,
      ),
    );
  }

  Map<String, double> _calculateTotalsByCurrency(List<ArApModel> accounts) {
    final Map<String, double> totals = {};
    for (var account in accounts) {
      final currency = account.accCurrency ?? 'N/A';
      totals[currency] = (totals[currency] ?? 0.0) + account.absBalance;
    }
    return totals;
  }

  // Create document for saving
  Future<void> createDocument({
    required ReportModel company,
    required List<ArApModel> accounts,
    required String language,
    required pw.PageOrientation orientation,
    required pw.PdfPageFormat pageFormat,
    required bool isAR,
  }) async {
    try {
      final document = isAR
          ? await generateArReport(
        report: company,
        arAccounts: accounts,
        language: language,
        orientation: orientation,
        pageFormat: pageFormat,
      )
          : await generateApReport(
        report: company,
        apAccounts: accounts,
        language: language,
        orientation: orientation,
        pageFormat: pageFormat,
      );

      await saveDocument(
        suggestedName: "${isAR ? 'Receivables' : 'Payables'}_Report_${DateTime.now().toIso8601String()}.pdf",
        pdf: document,
      );
    } catch (e) {
      throw e.toString();
    }
  }

  // Print document
  Future<void> printDocument({
    required ReportModel company,
    required List<ArApModel> accounts,
    required String language,
    required pw.PageOrientation orientation,
    required pw.PdfPageFormat pageFormat,
    required Printer selectedPrinter,
    required int copies,
    required String pages,
    required bool isAR,
  }) async {
    try {
      final document = isAR
          ? await generateArReport(
        report: company,
        arAccounts: accounts,
        language: language,
        orientation: orientation,
        pageFormat: pageFormat,
      )
          : await generateApReport(
        report: company,
        apAccounts: accounts,
        language: language,
        orientation: orientation,
        pageFormat: pageFormat,
      );

      for (int i = 0; i < copies; i++) {
        await Printing.directPrintPdf(
          printer: selectedPrinter,
          onLayout: (pw.PdfPageFormat format) async => document.save(),
        );

        if (i < copies - 1) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }
    } catch (e) {
      throw e.toString();
    }
  }
}