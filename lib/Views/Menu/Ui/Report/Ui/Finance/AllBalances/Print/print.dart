import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart' as pw;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:zaitoon_petroleum/Features/Other/extensions.dart';
import '../../../../../../../../Features/PrintSettings/PaperSize/paper_size.dart';
import '../../../../../../../../Features/PrintSettings/print_services.dart';
import '../../../../../../../../Features/PrintSettings/report_model.dart';
import '../model/all_balances_model.dart';

class AllBalancesPrintSettings extends PrintServices {

  // Create document (Save PDF)
  Future<void> createDocument({
    required List<AllBalancesModel> balances,
    required String language,
    required pw.PageOrientation orientation,
    required ReportModel company,
    required pw.PdfPageFormat pageFormat,
  }) async {
    try {
      final document = await generateReport(
        balances: balances,
        language: language,
        orientation: orientation,
        company: company,
        pageFormat: pageFormat,
      );

      await saveDocument(
        suggestedName: "all_balances_${DateTime.now().millisecondsSinceEpoch}.pdf",
        pdf: document,
      );
    } catch (e) {
      throw e.toString();
    }
  }

  // Print document (using Windows print dialog)
  Future<void> printDocument({
    required List<AllBalancesModel> balances,
    required String language,
    required pw.PageOrientation orientation,
    required ReportModel company,
    required Printer selectedPrinter,
    required pw.PdfPageFormat pageFormat,
    required int copies,
    required String pages,
  }) async {
    try {
      // Use clean format for PDF generation
      final cleanFormat = PdfFormatHelper.getPrinterFriendlyFormat(pageFormat);

      final document = await generateReport(
        balances: balances,
        language: language,
        orientation: orientation,
        company: company,
        pageFormat: cleanFormat,
      );

      final bytes = await document.save();

      // Open Windows print dialog
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'all_balances_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );

    } catch (e) {
      throw Exception('Failed to print: $e');
    }
  }

  // Print Preview (for dialog preview)
  Future<pw.Document> printPreview({
    required List<AllBalancesModel> balances,
    required String language,
    required pw.PageOrientation orientation,
    required ReportModel company,
    required pw.PdfPageFormat pageFormat,
  }) async {
    return generateReport(
      balances: balances,
      language: language,
      orientation: orientation,
      company: company,
      pageFormat: pageFormat,
    );
  }

  // Main report generator
  Future<pw.Document> generateReport({
    required List<AllBalancesModel> balances,
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

    // Calculate totals by currency
    final Map<String, double> currencyTotals = {};
    for (var balance in balances) {
      final currency = balance.trdCcy ?? 'USD';
      final balanceValue = double.tryParse(balance.balance ?? '0') ?? 0;
      currencyTotals[currency] = (currencyTotals[currency] ?? 0) + balanceValue;
    }

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
          _buildTitle(language),
          pw.SizedBox(height: 10),

          // Summary Section
          _buildSummarySection(currencyTotals, language),
          pw.SizedBox(height: 15),

          // Table Header
          _buildTableHeader(language),
          pw.SizedBox(height: 2),

          // Data Rows
          ..._buildBalanceRows(balances, language),
        ],
      ),
    );

    return document;
  }

  // Report Title
  pw.Widget _buildTitle(String language) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        zText(
          text: tr(text: 'allBalances', tr: language),
          fontSize: 16,
          fontWeight: pw.FontWeight.bold,
        ),
        zText(
          text: '${tr(text: 'asOf', tr: language)} ${_getCurrentDate()}',
          fontSize: 8,
          color: pw.PdfColors.grey600,
          textAlign: language == 'en' ? pw.TextAlign.right : pw.TextAlign.left,
        ),
      ],
    );
  }

  // Summary Section - Clean and Simple
  pw.Widget _buildSummarySection(Map<String, double> currencyTotals, String language) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: pw.PdfColors.grey300, width: 0.5),
        borderRadius: pw.BorderRadius.circular(2),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          zText(
            text: tr(text: 'summary', tr: language),
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
          ),
          pw.Divider(height: 8, thickness: 0.5),
          ...currencyTotals.entries.map((entry) {
            final isPositive = entry.value >= 0;
            return pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 2),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Row(
                    children: [
                      pw.Container(
                        width: 8,
                        height: 8,
                        decoration: pw.BoxDecoration(
                          color: isPositive ? pw.PdfColors.green700 : pw.PdfColors.red700,
                          shape: pw.BoxShape.circle,
                        ),
                      ),
                      pw.SizedBox(width: 6),
                      zText(
                        text: entry.key,
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ],
                  ),
                  zText(
                    text: entry.value.toStringAsFixed(2),
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: isPositive ? pw.PdfColors.green700 : pw.PdfColors.red700,
                    textAlign: language == 'en' ? pw.TextAlign.right : pw.TextAlign.left,
                  ),
                ],
              ),
            );
          }),
          pw.Divider(height: 8, thickness: 0.5),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              zText(
                text: tr(text: 'total', tr: language),
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
              ),
              zText(
                text: _formatGrandTotal(currencyTotals),
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                textAlign: language == 'en' ? pw.TextAlign.right : pw.TextAlign.left,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Table Header - Clean Design
  pw.Widget _buildTableHeader(String language) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 4),
      decoration: pw.BoxDecoration(
        color: pw.PdfColors.grey100,
        border: pw.Border(
          bottom: pw.BorderSide(color: pw.PdfColors.grey400, width: 0.5),
        ),
      ),
      child: pw.Row(
        children: [
          _buildHeaderCell(tr(text: 'account', tr: language), 80, language),
          _buildHeaderCell(tr(text: 'name', tr: language), 150, language, flex: 2),
          _buildHeaderCell(tr(text: 'ccy', tr: language), 40, language),
          _buildHeaderCell(tr(text: 'branch', tr: language), 40, language),
          _buildHeaderCell(tr(text: 'category', tr: language), 100, language),
          _buildHeaderCell(tr(text: 'balance', tr: language), 100, language, align: pw.TextAlign.right),
        ],
      ),
    );
  }

  pw.Widget _buildHeaderCell(String text, double width, String language, {int flex = 1, pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Expanded(
      flex: flex,
      child: pw.Container(
        width: width,
        child: zText(
          text: text,
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
          textAlign: language == 'en' ? align : (align == pw.TextAlign.right ? pw.TextAlign.left : pw.TextAlign.right),
        ),
      ),
    );
  }

  // Balance Rows - Clean Alternating Rows
  List<pw.Widget> _buildBalanceRows(List<AllBalancesModel> balances, String language) {
    final rows = <pw.Widget>[];

    for (int i = 0; i < balances.length; i++) {
      final balance = balances[i];
      final isEven = i % 2 == 0;
      final balanceValue = double.tryParse(balance.balance ?? '0') ?? 0;
      final isPositive = balanceValue >= 0;

      rows.add(
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 4),
          decoration: pw.BoxDecoration(
            color: isEven ? pw.PdfColors.grey50 : pw.PdfColors.white,
            border: pw.Border(
              bottom: pw.BorderSide(color: pw.PdfColors.grey200, width: 0.3),
            ),
          ),
          child: pw.Row(
            children: [
              _buildCell(balance.trdAccount?.toString() ?? '', 80, language),
              _buildCell(balance.accName ?? '', 150, language, flex: 2),
              _buildCell(balance.trdCcy ?? '', 40, language),
              _buildCell(balance.trdBranch?.toString() ?? '', 40, language),
              _buildCell(balance.acgName ?? '', 100, language),
              _buildBalanceCell(
                balance.balance ?? '0',
                balance.trdCcy ?? '',
                100,
                isPositive,
                language,
              ),
            ],
          ),
        ),
      );
    }

    return rows;
  }

  pw.Widget _buildCell(String text, double width, String language, {int flex = 1}) {
    return pw.Expanded(
      flex: flex,
      child: pw.Container(
        width: width,
        child: zText(
          text: text,
          fontSize: 8,
          textAlign: language == 'en' ? pw.TextAlign.left : pw.TextAlign.right,
        ),
      ),
    );
  }

  pw.Widget _buildBalanceCell(String amount, String currency, double width, bool isPositive, String language) {
    return pw.Expanded(
      child: pw.Container(
        width: width,
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.end,
          children: [
            pw.Text(
              amount.toAmount(),
              style: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: isPositive ? pw.PdfColors.green700 : pw.PdfColors.red700,
              ),
              textAlign: language == 'en' ? pw.TextAlign.right : pw.TextAlign.left,
            ),
            pw.SizedBox(width: 4),
            zText(
              text: currency,
              fontSize: 7,
              color: pw.PdfColors.grey600,
              textAlign: language == 'en' ? pw.TextAlign.right : pw.TextAlign.left,
            ),
          ],
        ),
      ),
    );
  }

  // Helper to format grand total
  String _formatGrandTotal(Map<String, double> currencyTotals) {
    if (currencyTotals.isEmpty) return '0.00';
    if (currencyTotals.length == 1) {
      return currencyTotals.values.first.toStringAsFixed(2);
    }
    return 'Multiple Currencies';
  }

  String _getCurrentDate() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
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
            pw.Expanded(
              flex: 3,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  zText(
                    text: report.comName ?? "",
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    tightBounds: true,
                  ),
                  pw.SizedBox(height: 3),
                  zText(
                    text: report.comAddress ?? "",
                    fontSize: 8,
                    color: pw.PdfColors.grey600,
                  ),
                ],
              ),
            ),
            if (image != null)
              pw.Container(
                width: 40,
                height: 40,
                child: pw.Image(image, fit: pw.BoxFit.contain),
              ),
          ],
        ),
        pw.SizedBox(height: 5),
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
        pw.Divider(thickness: 0.5),
        pw.SizedBox(height: 3),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Row(
              children: [
                pw.Container(
                  height: 15,
                  child: pw.Image(logoImage),
                ),
                pw.SizedBox(width: 5),
                zText(
                  text: tr(text: 'producedBy', tr: language),
                  fontSize: 7,
                  color: pw.PdfColors.grey600,
                ),
              ],
            ),
            pw.Row(
              children: [
                zText(
                  text: report.compPhone ?? "",
                  fontSize: 7,
                  color: pw.PdfColors.grey600,
                ),
                if (report.comEmail != null && report.comEmail!.isNotEmpty) ...[
                  pw.SizedBox(width: 8),
                  zText(
                    text: report.comEmail!,
                    fontSize: 7,
                    color: pw.PdfColors.grey600,
                  ),
                ],
              ],
            ),
            buildPage(context.pageNumber, context.pagesCount, language),
          ],
        ),
      ],
    );
  }
}