import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart' as pw;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:zaitoonpro/Features/Date/shamsi_converter.dart';
import 'package:zaitoonpro/Features/Other/extensions.dart';
import '../../../../../../../../Features/PrintSettings/PaperSize/paper_size.dart';
import '../../../../../../../../Features/PrintSettings/print_services.dart';
import '../../../../../../../../Features/PrintSettings/report_model.dart';
import '../model/stmt_model.dart';


class AccountStatementPrintSettings extends PrintServices {
  final pdf = pw.Document();

  Future<void> createDocument({
    required AccountStatementModel info,
    required List<AccountStatementModel> statement,
    required String language,
    required pw.PageOrientation orientation,
    required ReportModel company,
    required pw.PdfPageFormat pageFormat,
  }) async {
    try {
      final document = await generateStatement(
          report: company,
          stmtInfo: info,
          language: language,
          orientation: orientation,
          pageFormat: pageFormat
      );

      // Save the document
      await saveDocument(
        suggestedName: "${info.accName}_${info.accNumber}.pdf",
        pdf: document,
      );
    } catch (e) {
      throw e.toString();
    }
  }

  Future<void> printDocument({
    required AccountStatementModel info,
    required List<AccountStatementModel> statement,
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

      final document = await generateStatement(
        report: company,
        stmtInfo: info,
        language: language,
        orientation: orientation,
        pageFormat: cleanFormat,
      );

      final bytes = await document.save();

      await Printing.sharePdf(
        bytes: bytes,
        filename: 'account_statement_${info.signatory}.pdf',
      );

    } catch (e) {

      throw Exception('Failed to print: $e');
    }
  }

  Future<pw.Document> printPreview({
    required String language,
    required ReportModel company,
    required pw.PageOrientation orientation,
    required AccountStatementModel info,
    required pw.PdfPageFormat pageFormat,
  }) async {
    return generateStatement(
      report: company,
      language: language,
      orientation: orientation,
      stmtInfo: info,
      pageFormat: pageFormat,
    );
  }

  Future<pw.Document> generateStatement({
    required String language,
    required ReportModel report,
    required AccountStatementModel stmtInfo,
    required pw.PageOrientation orientation,
    required pw.PdfPageFormat pageFormat,
  }) async {
    final document = pw.Document();
    final prebuiltHeader = await header(report: report);

    // Load your image asset
    final ByteData imageData = await rootBundle.load('assets/images/zaitoonLogo.png');
    final Uint8List imageBytes = imageData.buffer.asUint8List();
    final pw.MemoryImage logoImage = pw.MemoryImage(imageBytes);

    document.addPage(
      pw.MultiPage(
        maxPages: 1000,
        margin: pw.EdgeInsets.symmetric(horizontal: 25, vertical: 10),
        pageFormat: pageFormat,
        textDirection: documentLanguage(language: language),
        orientation: orientation,
        build: (context) => [
          horizontalDivider(),
          statementHeaderWidget(language: language, reportInfo: report, statement: stmtInfo),
          pw.SizedBox(height: 5),
          items(items: stmtInfo, language: language),
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
                  zText(text: report.comName ?? "", fontSize: 25,fontWeight: pw.FontWeight.bold, tightBounds: true),
                  pw.SizedBox(height: 3),
                  zText(text: report.statementDate ?? "", fontSize: 10),
                ],
              ),
            ),
            // Logo (right side)
            if (image != null)
              pw.Container(
                width: 40,
                height: 40,
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

  pw.Widget totalSummary({
    required String language,
    required ReportModel reportInfo,
    required AccountStatementModel info,

  }) {
    double parseAmount(String amountStr) {
      try {
        return double.tryParse(amountStr.replaceAll(',', '')) ?? 0.0;
      } catch (e) {
        return 0.0;
      }
    }

      // Calculate totals
      double totalCredit = 0;
      double totalDebit = 0;
      String openingBalance = '0.0';
      String availableBalance = '0.0';
      String currentBalance = '0.0';


      // Get opening balance from first record
      openingBalance = info.records?.first.total?.toAmount() ?? '0.0';

      for (var item in info.records ?? []) {
        totalCredit += parseAmount(item.credit);
        totalDebit += parseAmount(item.debit);
        availableBalance = info.avilBalance??"";
        currentBalance = info.curBalance??"";
      }


    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.start,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              buildSummary(
                distance: 120,
                label: tr(
                  text: 'accountSummary',
                  tr: language,
                ),
                fontSize: 11,
                value: "",
                isEmphasized: true,
              ),
              pw.SizedBox(height: 1),
              pw.Row(
                  children: [
                    zText(
                        color: pw.PdfColors.grey800,
                        text: "${reportInfo.startDate} to ${reportInfo.endDate}",fontSize: 8)
                  ]
              ),
              pw.SizedBox(height: 1),
              horizontalDivider(width: 190),
              pw.SizedBox(height: 1),

              buildTotalSummary(
                color: pw.PdfColors.grey800,
                label: tr(
                  text: 'openingBalance',
                  tr: language,
                ),
                value: openingBalance.toAmount(),
              ),
              pw.SizedBox(height: 1),
              buildTotalSummary(
                color: pw.PdfColors.grey800,
                label: tr(text: 'totalDebits', tr: language),
                value: totalDebit.toAmount(),
              ),
              pw.SizedBox(height: 1),
              buildTotalSummary(
                color: pw.PdfColors.grey800,
                label: tr(
                  text: 'totalCredits',
                  tr: language,
                ),
                value: totalCredit.toAmount(),
              ),

              pw.SizedBox(height: 1),
              horizontalDivider(width: 190),
              pw.SizedBox(height: 1),
              buildTotalSummary(
                label: tr(
                  text: 'currentBalance',
                  tr: language,
                ),
                ccySymbol: info.actCurrency,
                value: currentBalance.toAmount(),
                isEmphasized: true,
              ),
              pw.SizedBox(height: 1),
              buildTotalSummary(
                label: tr(
                  text: 'availableBalance',
                  tr: language,
                ),
                ccySymbol: info.actCurrency,
                value: availableBalance.toAmount(),
                isEmphasized: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget statementDescription({
    required String language,
    required ReportModel reportInfo,
    required AccountStatementModel statement,
  }) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.start,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              buildSummary(
                distance: 150,
                label: tr(
                  text: 'statementAccount',
                  tr: language,
                ),
                value: "",
                fontSize: 12,
                isEmphasized: true,
              ),
              pw.SizedBox(height: 1),
              horizontalDivider(width: 200),
              pw.SizedBox(height: 1),
              buildSummary(
                color: pw.PdfColors.grey800,
                distance: 75,
                label: tr(
                  text: 'accountName',
                  tr: language,
                ),
                value: statement.accName??"",
              ),
              pw.SizedBox(height: 1),
              buildSummary(
                distance: 75,
                color: pw.PdfColors.grey800,
                label: tr(
                  text: 'accountNumber',
                  tr: language,
                ),
                value: statement.accNumber.toString(),
              ),

              pw.SizedBox(height: 1),
              buildSummary(
                color: pw.PdfColors.grey800,
                distance: 75,
                label: tr(text: 'signatory', tr: language),
                value: "${statement.signatory}",
              ),
              pw.SizedBox(height: 1),
              buildSummary(
                color: pw.PdfColors.grey800,
                distance: 75,
                label: tr(text: 'currency', tr: language),
                value: "${statement.actCurrency}",
              ),
              pw.SizedBox(height: 1),
              buildSummary(
                color: pw.PdfColors.grey800,
                distance: 75,
                label: tr(text: 'mobile', tr: language),
                value: "${statement.perPhone}",
              ),
              pw.SizedBox(height: 1),
              buildSummary(
                color: pw.PdfColors.grey800,
                distance: 75,
                label: tr(text: 'email', tr: language),
                value: statement.perEmail??"",
              ),
              pw.SizedBox(height: 1),
              buildSummary(
                color: pw.PdfColors.grey800,
                distance: 75,
                label: tr(text: 'address', tr: language),
                value: "${statement.address}",
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Container statementHeaderWidget({
    required String language,
    required AccountStatementModel statement,
    required ReportModel reportInfo,

  }) {
    return pw.Container(
      padding: pw.EdgeInsets.symmetric(vertical: 5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          statementDescription(language: language, statement: statement,reportInfo: reportInfo),
          totalSummary(language: language, info: statement,reportInfo: reportInfo),
        ],
      ),
    );
  }

  pw.Widget items({
    required AccountStatementModel items,
    required String language,
  }) {
    const dateWidth = 50.0;
    const trnWidth = 90.0;
    const amountWidth = 60.0;
    const balanceWidth = 70.0;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(vertical: 4),
          decoration: pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(width: 1, color: pw.PdfColors.grey300),
            ),
          ),
          child: pw.Row(
            children: [
              pw.SizedBox(
                width: dateWidth,
                child: zText(
                  text: tr(text: "date", tr: language),
                  textAlign:
                  language == "en" ? pw.TextAlign.left : pw.TextAlign.right,
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(
                width: trnWidth,
                child: zText(
                  textAlign: language == "en" ? pw.TextAlign.left : pw.TextAlign.right,
                  text: tr(text: "reference", tr: language),
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Expanded(child: pw.SizedBox(
                child: zText(
                  textAlign:
                  language == "en" ? pw.TextAlign.left : pw.TextAlign.right,
                  text: tr(text: "narration", tr: language),
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),),

              pw.SizedBox(
                width: amountWidth,
                child: zText(
                  textAlign: language == "en" ? pw.TextAlign.right : pw.TextAlign.left,
                  text: tr(text: "debit", tr: language),
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(
                width: amountWidth,
                child: zText(
                  textAlign: language == "en" ? pw.TextAlign.right : pw.TextAlign.left,
                  text: tr(text: "credit", tr: language),
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(
                width: balanceWidth,
                child: zText(
                  text:
                  tr(text: "balance", tr: language),
                  fontSize: 8,
                  textAlign: language == "en" ? pw.TextAlign.right : pw.TextAlign.left,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(width: 10),
            ],
          ),
        ),

        // Data Rows
        for (var i = 0; i < (items.records?.length ?? 0); i++)
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(vertical: 6),
            decoration: pw.BoxDecoration(
             // color: i.isOdd ? pw.PdfColors.grey100 : null,
              border: pw.Border(
               bottom: pw.BorderSide(width: 0.6, color: pw.PdfColors.grey300),
              ),
            ),
            child: pw.Row(
              children: [
                pw.SizedBox(
                  width: dateWidth,
                  child: zText(
                    textAlign: language == "en"
                        ? pw.TextAlign.left
                        : pw.TextAlign.right,
                    text: items.records![i].trnEntryDate!.toFormattedDate(),
                    fontSize: language == "en"? 7 : 8,
                  ),
                ),
                pw.SizedBox(
                  width: trnWidth,
                  child: zText(
                    textAlign:
                    language == "en"
                        ? pw.TextAlign.left
                        : pw.TextAlign.right,
                    text: items.records![i].trnReference ?? "",
                    fontSize: 7,
                  ),
                ),
                pw.Expanded(
                  child:   pw.SizedBox(
                    child: zText(
                      textAlign:
                      language == "en"
                          ? pw.TextAlign.left
                          : pw.TextAlign.right,
                      text:
                      items.records![i].trdNarration == "Opening Balance"
                          ? tr(
                        text: 'openingBalance',
                        tr: language,
                      ) : items.records![i].trdNarration ?? "",
                      fontSize: 7,
                    ),
                  ),
                ),

                pw.SizedBox(
                  width: amountWidth,
                  child: zText(
                    textAlign: language == "en" ? pw.TextAlign.right : pw.TextAlign.left,
                    text: items.records![i].debit?.toAmount()??"",
                    fontSize: 7,
                  ),
                ),
                pw.SizedBox(
                  width: amountWidth,
                  child: zText(
                    textAlign: language == "en" ? pw.TextAlign.right : pw.TextAlign.left,
                    text: items.records![i].credit?.toAmount() ??"",
                    fontSize: 7,
                  ),
                ),
                pw.SizedBox(
                  width: balanceWidth,
                  child: zText(
                    textAlign: language == "en" ? pw.TextAlign.right : pw.TextAlign.left,
                    fontWeight: pw.FontWeight.bold,
                    text: items.records![i].total?.toAmount() ??"",
                    color: items.records![i].trdNarration == "Opening Balance" || items.records![i].trdNarration == "Closing Balance"? pw.PdfColors.blue : null,
                    fontSize: 7,
                  ),
                ),
                pw.SizedBox(
                  width: 10,
                  child: zText(
                    textAlign: language == "en" ? pw.TextAlign.right : pw.TextAlign.left,
                    text: items.records![i].status??"",
                    color: pw.PdfColors.red,
                    fontSize: 7,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
