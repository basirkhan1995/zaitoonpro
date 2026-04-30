import 'dart:ui';

import 'package:zaitoonpro/Features/Date/shamsi_converter.dart';
import 'package:zaitoonpro/Features/Other/extensions.dart';
import 'package:zaitoonpro/Features/PrintSettings/print_services.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart' as pw;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Journal/Ui/model/transaction_model.dart';
import '../../../../../../../Features/PrintSettings/report_model.dart';
import '../../../../../Features/Other/amount_to_word.dart';

class CashFlowTransactionPrint extends PrintServices{

  Future<void> createDocument({
    required TransactionsModel data,
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

      // Save the document
      await saveDocument(
        suggestedName: "transaction.pdf",
        pdf: document,
      );
    } catch (e) {
      throw e.toString();
    }
  }
// Add this method to your PrintServices class (around line 300)
  pw.PdfPageFormat _getPrinterFriendlyFormat(pw.PdfPageFormat format) {
    // Round to nearest integer to match printer expectations
    return pw.PdfPageFormat(
      format.width.roundToDouble(),
      format.height.roundToDouble(),
    );
  }
  // In CashFlowTransactionPrint.printDocument method
  Future<void> printDocument({
    required TransactionsModel data,
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


      // Create printer-friendly format
      final printerFormat = _getPrinterFriendlyFormat(pageFormat);

      for (int i = 0; i < copies; i++) {

        await Printing.directPrintPdf(
          printer: selectedPrinter,
          onLayout: (pw.PdfPageFormat format) async {
            return document.save();
          },
          format: printerFormat,
          usePrinterSettings: false,
        );

        if (i < copies - 1) {
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }

    } catch (e) {
      rethrow;
    }
  }
  Future<pw.Document> generateStatement({
    required String language,
    required ReportModel report,
    required TransactionsModel data,
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
          voucher(data: data,language: language),
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


  //Real Time document show
  Future<pw.Document> printPreview({
    required String language,
    required ReportModel company,
    required pw.PageOrientation orientation,
    required TransactionsModel data,
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


  pw.Widget voucher({
    required TransactionsModel data,
    required String language,
  }) {
    final lang = NumberToWords.getLanguageFromLocale(Locale(language));

    final cleanAmount = data.trdAmount?.replaceAll(',', '') ?? "0";
    final parsedAmount = int.tryParse(
      double.tryParse(cleanAmount)?.toStringAsFixed(0) ?? "0",
    ) ?? 0;

    final rows = <Map<String, String>>[
      {"title": "date", "value": data.trnEntryDate?.toFullDateTime ?? ""},
      {"title": "reference", "value": data.trnReference ?? ""},
      {"title": "branch", "value": data.trdBranch.toString()},
      {"title": "trnType", "value": data.trnType.toString()},
      {"title": "accountNumber", "value": data.trdAccount.toString()},
      {"title": "amount", "value": "${data.trdAmount?.toAmount()} ${data.trdCcy}"},
      {"title": "narration", "value": data.trdNarration ?? ""},
    ];

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      mainAxisAlignment: pw.MainAxisAlignment.start,
      children: [
        pw.SizedBox(height: 5),
        pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              zText(text: tr(text: 'moneyReceipt', tr: language),fontWeight: pw.FontWeight.bold),
              zText(text: tr(text: data.trnType??"", tr: language),fontWeight: pw.FontWeight.bold),
            ]
        ),
        pw.SizedBox(height: 5),
        pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border.all(width: 0.1),
          ),
          child: pw.Column(
            children: rows.map((r) => pw.Container(padding: const pw.EdgeInsets.symmetric(
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
            )
                .toList(),
          ),
        ),

        pw.SizedBox(height: 5),

        zText(
          text: tr(text: 'amountInWords', tr: language),
          fontSize:8,
        ),
        horizontalDivider(),

        zText(
          text: "${NumberToWords.convert(parsedAmount, lang)} ${data.trdCcy}",
          fontSize: 7,
        ),
        pw.SizedBox(height: 5),
       signatory(language: language, data: data)

      ],
    );
  }


  //Signature
  pw.Padding signatory({required String language, required TransactionsModel data}) {
    return pw.Padding(
      padding: pw.EdgeInsets.symmetric(horizontal: 0, vertical: 10),
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
                  zText(text: data.checker??"", fontSize: 7),
                ],
              ),

            ],
          ),
        ],
      ),
    );
  }
}