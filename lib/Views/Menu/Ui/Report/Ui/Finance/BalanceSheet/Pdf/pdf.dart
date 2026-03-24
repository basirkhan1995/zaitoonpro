import 'package:pdf/pdf.dart' as pw;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:zaitoonpro/Features/Other/extensions.dart';
import '../../../../../../../../Features/PrintSettings/print_services.dart';
import '../../../../../../../../Features/PrintSettings/report_model.dart';
import '../model/bs_model.dart';

class BalanceSheetPrintSettings extends PrintServices {
  Future<pw.Document> printPreview({
    required BalanceSheetModel data,
    required String language,
    required pw.PageOrientation orientation,
    required ReportModel company,
    required pw.PdfPageFormat pageFormat,
  }) {
    return _generate(
      data: data,
      company: company,
      language: language,
      orientation: orientation,
      pageFormat: pageFormat,
    );
  }

  Future<void> createDocument({
    required BalanceSheetModel data,
    required String language,
    required pw.PageOrientation orientation,
    required ReportModel company,
    required pw.PdfPageFormat pageFormat,
  }) async {
    final doc = await printPreview(
      data: data,
      language: language,
      orientation: orientation,
      company: company,
      pageFormat: pageFormat,
    );

    await saveDocument(
      suggestedName: "BalanceSheet_${DateTime.now().millisecondsSinceEpoch}.pdf",
      pdf: doc,
    );
  }

  Future<void> printDocument({
    required BalanceSheetModel data,
    required String language,
    required pw.PageOrientation orientation,
    required ReportModel company,
    required Printer selectedPrinter,
    required pw.PdfPageFormat pageFormat,
    required int copies,
    required String pages,
  }) async {
    final doc = await printPreview(
      data: data,
      language: language,
      orientation: orientation,
      company: company,
      pageFormat: pageFormat,
    );

    for (int i = 0; i < copies; i++) {
      await Printing.directPrintPdf(
        printer: selectedPrinter,
        onLayout: (_) async => doc.save(),
      );
    }
  }

  // =========================
  // DOCUMENT GENERATOR
  // =========================

  Future<pw.Document> _generate({
    required BalanceSheetModel data,
    required ReportModel company,
    required String language,
    required pw.PageOrientation orientation,
    required pw.PdfPageFormat pageFormat,
  }) async {
    final doc = pw.Document();


    final prebuiltHeader = await header(report: company);

    doc.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        orientation: orientation,
        margin: const pw.EdgeInsets.symmetric(horizontal: 30, vertical: 20),
        textDirection: documentLanguage(language: language),
        build: (context) => [
          balanceSheetHeader(data: data, company: company, language: language),
          _yearHeader(language: language),
          _mainTitle(tr(text: 'assets', tr: language)),
          ..._assetSection(data.assets, company, language),
          pw.SizedBox(height: 15),
          _mainTitle(tr(text: 'liabilitiesEquity', tr: language)),
          pw.SizedBox(height: 8),
          ..._liabilitySection(data.liability, company, language),
        ],
        header: (context) => prebuiltHeader,
        // footer: (context) => footer(
        //   report: company,
        //   context: context,
        //   language: language,
        //   logoImage: logoImage,
        // ),
      ),
    );

    return doc;
  }

  // =========================
  // HEADER SECTION
  // =========================

  pw.Widget balanceSheetHeader({
    required BalanceSheetModel data,
    required ReportModel company,
    required String language,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(height: 4),
        zText(
          text: tr(text: 'balanceSheet', tr: language),
          fontSize: 20,
          tightBounds: true,
          fontWeight: pw.FontWeight.bold,
        ),
        pw.SizedBox(height: 4),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            zText(
              text: company.statementDate ?? '',
              fontSize: 9,
              color: pw.PdfColors.grey600,
            ),
          ],
        ),
      ],
    );
  }

  // =========================
  // MAIN TITLE
  // =========================

  pw.Widget _mainTitle(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: zText(
        text: text,
          fontSize: 15,
          fontWeight: pw.FontWeight.bold,
          color: pw.PdfColors.grey800,
      ),
    );
  }

  pw.Widget _yearHeader({required String language}) {
    final currentYear = DateTime.now().year;
    final lastYear = currentYear - 1;

    return pw.Column(
      children: [
        // Title labels row
        pw.Row(
          children: [
            pw.Expanded(flex: 4, child: pw.SizedBox()),
            pw.Expanded(
              flex: 3,
              child: zText(
                text: tr(text: 'currentYear', tr: language),
                fontSize: 8,
                textAlign: pw.TextAlign.right,
                color: pw.PdfColors.grey600,
              ),
            ),
            pw.Expanded(
              flex: 3,
              child: zText(
                text: tr(text: 'lastYear', tr: language),
                fontSize: 8,
                textAlign: pw.TextAlign.right,
                color: pw.PdfColors.grey600,
              ),
            ),
          ],
        ),
        // Year numbers row
        pw.Row(
          children: [
            pw.Expanded(flex: 4, child: pw.SizedBox()),
            pw.Expanded(
              flex: 3,
              child: zText(
                text: currentYear.toString(),
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                textAlign: pw.TextAlign.right,
              ),
            ),
            pw.Expanded(
              flex: 3,
              child: zText(
                text: lastYear.toString(),
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                textAlign: pw.TextAlign.right,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // =========================
  // ASSETS SECTION
  // =========================

  List<pw.Widget> _assetSection(Assets? assets, ReportModel company, String language) {
    if (assets == null) return [];

    return [
      ..._subSection(
        tr(text: 'currentAssets', tr: language),
        assets.currentAsset,
        language,
      ),
      pw.SizedBox(height: 5),
      ..._subSection(
        tr(text: 'fixedAssets', tr: language),
        assets.fixedAsset,
        language,
      ),
      pw.SizedBox(height: 5),
      ..._subSection(
        tr(text: 'intangibleAssets', tr: language),
        assets.intangibleAsset,
        language,
      ),
      pw.SizedBox(height: 3),
      _grandTotal(
        tr(text: 'totalAssets', tr: language),
        _sumCurrent(assets),
        _sumLast(assets),
        company,
      ),
    ];
  }

  // =========================
  // LIABILITIES SECTION
  // =========================

  List<pw.Widget> _liabilitySection(Liability? liab, ReportModel company, String language) {
    if (liab == null) return [];

    final cy = _sumLiabilityCurrent(liab);
    final ly = _sumLiabilityLast(liab);

    return [
      ..._subSection(
        tr(text: 'currentLiabilities', tr: language),
        liab.currentLiability,
        language,
      ),
      pw.SizedBox(height: 5),
      ..._subSection(
        tr(text: 'ownerEquity', tr: language),
        liab.ownersEquity,
        language,
      ),
      pw.SizedBox(height: 5),
      ..._subSection(
        tr(text: 'stakeholders', tr: language),
        liab.stakeholders,
        language,
      ),
      pw.SizedBox(height: 5),
      ..._subSection(
        tr(text: 'netProfit', tr: language),
        liab.netProfit,
        language,
      ),
      pw.SizedBox(height: 3),
      _grandTotal(
        tr(text: 'totalLiabilitiesEquity', tr: language),
        cy,
        ly,
        company,
      ),
    ];
  }

  // =========================
  // SUB-SECTIONS
  // =========================

  List<pw.Widget> _subSection(String title, List<AssetItem>? items, String language) {
    if (items == null || items.isEmpty) return [];

    double cy = 0, ly = 0;

    final rows = items.map((e) {
      final c = double.tryParse(e.currentYear ?? "0") ?? 0;
      final l = double.tryParse(e.lastYear ?? "0") ?? 0;
      cy += c;
      ly += l;
      return _row(e.accName ?? "", c, l);
    }).toList();

    return [
      zText(
        text: title,
        fontSize: 9,
        fontWeight: pw.FontWeight.bold,
        color: pw.PdfColors.grey700,
      ),
      pw.SizedBox(height: 2),
      ...rows,
      _total("${tr(text: 'totalTitle', tr: language)} $title", cy, ly),
    ];
  }

  // =========================
  // ROWS
  // =========================

  pw.Widget _row(String name, double cy, double ly) {
    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Row(
        children: [
          pw.Expanded(
            flex: 4,
            child: zText(text: name, fontSize: 8),
          ),
          pw.Expanded(
            flex: 3,
            child: zText(
              text: cy.toAmount(),
              textAlign: pw.TextAlign.right,
              fontSize: 8
            ),
          ),
          pw.Expanded(
            flex: 3,
            child: zText(
              text: ly.toAmount(),
              textAlign: pw.TextAlign.right,
              fontSize: 8
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _total(String label, double cy, double ly) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 3, top: 3),
      padding: const pw.EdgeInsets.symmetric(vertical: 2,horizontal: 1),
      decoration: const pw.BoxDecoration(
        color: pw.PdfColors.grey100,
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            flex: 4,
            child: zText(
              text: label,
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.Expanded(
            flex: 3,
            child: zText(
              text:  cy.toAmount(),
              textAlign: pw.TextAlign.right,
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.Expanded(
            flex: 3,
            child: zText(
              text: ly.toAmount(),
              textAlign: pw.TextAlign.right,
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _grandTotal(String label, double cy, double ly, ReportModel company) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 3),
      padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 1),
      decoration: pw.BoxDecoration(
        color: pw.PdfColors.blue50,
        borderRadius: pw.BorderRadius.circular(2),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            flex: 4,
            child: zText(
             text:  label,
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.Expanded(
            flex: 3,
            child: zText(
              text:  "${cy.toAmount()} ${company.baseCurrency ?? 'USD'}",
              textAlign: pw.TextAlign.right,
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.Expanded(
            flex: 3,
            child: zText(
              text:  "${ly.toAmount()} ${company.baseCurrency ?? 'USD'}",
              textAlign: pw.TextAlign.right,
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // =========================
  // TOTAL HELPERS
  // =========================

  double _sumCurrent(Assets a) =>
      [...?a.currentAsset, ...?a.fixedAsset, ...?a.intangibleAsset]
          .fold(0, (p, e) => p + (double.tryParse(e.currentYear ?? "0") ?? 0));

  double _sumLast(Assets a) =>
      [...?a.currentAsset, ...?a.fixedAsset, ...?a.intangibleAsset]
          .fold(0, (p, e) => p + (double.tryParse(e.lastYear ?? "0") ?? 0));

  double _sumLiabilityCurrent(Liability l) =>
      [...?l.currentLiability, ...?l.ownersEquity, ...?l.stakeholders, ...?l.netProfit]
          .fold(0, (p, e) => p + (double.tryParse(e.currentYear ?? "0") ?? 0));

  double _sumLiabilityLast(Liability l) =>
      [...?l.currentLiability, ...?l.ownersEquity, ...?l.stakeholders, ...?l.netProfit]
          .fold(0, (p, e) => p + (double.tryParse(e.lastYear ?? "0") ?? 0));
}