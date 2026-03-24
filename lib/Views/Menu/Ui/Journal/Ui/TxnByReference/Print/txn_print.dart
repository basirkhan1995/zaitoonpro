import 'dart:ui';
import 'package:zaitoonpro/Features/Date/shamsi_converter.dart';
import 'package:zaitoonpro/Features/Other/extensions.dart';
import 'package:zaitoonpro/Features/PrintSettings/print_services.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart' as pw;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Journal/Ui/TxnByReference/model/txn_ref_model.dart';
import '../../../../../../../Features/Other/amount_to_word.dart';
import '../../../../../../../Features/PrintSettings/report_model.dart';

class TransactionReferencePrintSettings extends PrintServices {

  Future<void> createDocument({
    required TxnByReferenceModel data,
    required String language,
    required pw.PageOrientation orientation,
    required ReportModel company,
    required pw.PdfPageFormat pageFormat,
  }) async {
    try {
      final document = await generateStatement(
          report: company,
          data: data,
          language: language,
          orientation: orientation,
          pageFormat: pageFormat
      );

      await saveDocument(
        suggestedName: "transaction.pdf",
        pdf: document,
      );
    } catch (e) {
      throw e.toString();
    }
  }

  Future<void> printDocument({
    required TxnByReferenceModel data,
    required String language,
    required pw.PageOrientation orientation,
    required ReportModel company,
    required Printer selectedPrinter,
    required pw.PdfPageFormat pageFormat,
    required int copies,
    required String pages,
  }) async {
    try {
      final document = await generateStatement(
        report: company,
        data: data,
        language: language,
        orientation: orientation,
        pageFormat: pageFormat,
      );

      final bytes = await document.save();

      // This opens the Windows print dialog
      await Printing.sharePdf(
        bytes: bytes,
        filename: '${data.trnReference}.pdf',
      );

    } catch (e) {
      throw e.toString();
    }
  }

  Future<pw.Document> generateStatement({
    required String language,
    required ReportModel report,
    required TxnByReferenceModel data,
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
          pw.SizedBox(height: 5),
          voucher(data: data, language: language),
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

  // Real Time document show
  Future<pw.Document> printPreview({
    required String language,
    required ReportModel company,
    required pw.PageOrientation orientation,
    required TxnByReferenceModel data,
    required pw.PdfPageFormat pageFormat,
  }) async {
    return generateStatement(
      report: company,
      language: language,
      orientation: orientation,
      data: data,
      pageFormat: pageFormat,
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
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            // Company info (left side)
            pw.Expanded(
              flex: 3,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  zText(text: report.comName ?? "", fontSize: 20, tightBounds: true),
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
    required pw.MemoryImage logoImage
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

  pw.Widget voucher({
    required TxnByReferenceModel data,
    required String language,
  }) {
    final lang = NumberToWords.getLanguageFromLocale(Locale(language));

    final cleanAmount = data.amount?.replaceAll(',', '') ?? "0";
    final parsedAmount = int.tryParse(
      double.tryParse(cleanAmount)?.toStringAsFixed(0) ?? "0",
    ) ?? 0;

    final rows = <Map<String, String>>[
      {"title": "date", "value": data.trnEntryDate?.toFullDateTime ?? ""},
      {"title": "reference", "value": data.trnReference ?? ""},
      {"title": "branch", "value": data.branch.toString()},
      {"title": "trnType", "value": data.trnType.toString()},
      {"title": "accountNumber", "value": data.account.toString()},
      {"title": "accountName", "value": data.accName.toString()},
      {"title": "amount", "value": "${data.amount?.toAmount()} ${data.currency}"},
      {"title": "narration", "value": data.narration ?? ""},
    ];

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      mainAxisAlignment: pw.MainAxisAlignment.start,
      children: [
        pw.SizedBox(height: 5),
        pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              zText(
                  text: tr(text: 'moneyReceipt', tr: language),
                  fontWeight: pw.FontWeight.bold
              ),
              zText(
                  text: tr(text: data.trnType ?? "", tr: language),
                  fontWeight: pw.FontWeight.bold
              ),
            ]
        ),
        pw.SizedBox(height: 5),
        pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border.all(width: 0.1),
          ),
          child: pw.Column(
            children: rows.map((r) => pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 5,
                vertical: 3,
              ),
              decoration: pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(width: 0.1),
                ),
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.start,
                children: [
                  pw.Container(
                    width: 90,
                    child: zText(
                        text: "${tr(text: r["title"]!, tr: language)}:",
                        fontSize: 8
                    ),
                  ),
                  pw.SizedBox(width: 5),
                  zText(
                    text: r["value"]!,
                    fontSize: 8,
                  ),
                ],
              ),
            ),
            ).toList(),
          ),
        ),
        pw.SizedBox(height: 5),
        zText(
          text: tr(text: 'amountInWords', tr: language),
          fontSize: 8,
        ),
        horizontalDivider(),
        zText(
          text: "${NumberToWords.convert(parsedAmount, lang)} ${data.currency}",
          fontSize: 7,
        ),
        pw.SizedBox(height: 5),
        signatory(language: language, data: data)
      ],
    );
  }

  // Signature
  pw.Padding signatory({
    required String language,
    required TxnByReferenceModel data
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 0, vertical: 10),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.start,
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              horizontalDivider(width: 120),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.start,
                children: [
                  zText(text: tr(text: 'createdBy', tr: language), fontSize: 7),
                  zText(text: " ${data.maker} ", fontSize: 7),
                ],
              ),
            ],
          ),
          pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.start,
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              horizontalDivider(width: 120),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.start,
                children: [
                  zText(text: tr(text: 'authorizedBy', tr: language), fontSize: 7),
                  zText(text: data.checker ?? "", fontSize: 7),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}