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

      await Printing.sharePdf(
        bytes: bytes,
        filename: '${data.trnReference}.pdf',
      );

    } catch (e) {
      throw e.toString();
    }
  }

  bool _isRtl(String language) {
    final code = language.toLowerCase();
    return code.startsWith('fa') || code.startsWith('ar') || code.startsWith('ps');
  }

  Future<pw.Document> generateStatement({
    required String language,
    required ReportModel report,
    required TxnByReferenceModel data,
    required pw.PageOrientation orientation,
    required pw.PdfPageFormat pageFormat,
  }) async {
    final document = pw.Document();

    pw.ImageProvider? logoProvider;
    if (report.comLogo != null && report.comLogo is Uint8List && report.comLogo!.isNotEmpty) {
      logoProvider = pw.MemoryImage(report.comLogo!);
    }

    final isRtl = _isRtl(language);

    document.addPage(
      pw.MultiPage(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        mainAxisAlignment: pw.MainAxisAlignment.center,
        maxPages: 1000,
        margin: pw.EdgeInsets.all(20),
        pageFormat: pageFormat,
        textDirection: documentLanguage(language: language),
        orientation: orientation,
        build: (context) => [
          voucher(data: data, language: language, report: report, logoProvider: logoProvider, isRtl: isRtl),
        ],
      ),
    );
    return document;
  }

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

  pw.Widget voucher({
    required TxnByReferenceModel data,
    required String language,
    required ReportModel report,
    pw.ImageProvider? logoProvider,
    required bool isRtl,
  }) {
    final lang = NumberToWords.getLanguageFromLocale(Locale(language));

    final cleanAmount = data.amount?.replaceAll(',', '') ?? "0";
    final parsedAmount = int.tryParse(
      double.tryParse(cleanAmount)?.toStringAsFixed(0) ?? "0",
    ) ?? 0;

    final String voucherDate = data.trnEntryDate?.toFullDateTime ?? "";
    final String amountText = "${data.amount?.toAmount()} ${data.currency}";
    final String amountWords = "${NumberToWords.convert(parsedAmount, lang)} ${data.currency}";

    // Company info lines
    final List<String> companyLines = [];
    if (report.comName != null && report.comName!.isNotEmpty) {
      companyLines.add(report.comName!);
    }
    if (report.comAddress != null && report.comAddress!.isNotEmpty) {
      companyLines.add(report.comAddress!);
    }
    String contactLine = "";
    if (report.compPhone != null && report.compPhone!.isNotEmpty) {
      contactLine += "${isRtl ? 'تلفن' : 'Tel'}: ${report.compPhone!}";
    }
    if (report.comWhatsApp != null && report.comWhatsApp!.isNotEmpty) {
      if (contactLine.isNotEmpty) contactLine += " | ";
      contactLine += "WhatsApp: ${report.comWhatsApp!}";
    }
    if (report.comEmail != null && report.comEmail!.isNotEmpty) {
      if (contactLine.isNotEmpty) contactLine += " | ";
      contactLine += report.comEmail!;
    }
    if (contactLine.isNotEmpty) {
      companyLines.add(contactLine);
    }

    // Build account string: "AccountNumber - AccountName"
    final String accountValue = "${data.account} - ${data.accName ?? ""}";

    return pw.Column(
      children: [
        _buildSingleVoucher(data, language, voucherDate, amountText, amountWords, accountValue, false, companyLines, logoProvider, isRtl),
        pw.SizedBox(height: isRtl ? 10 : 16),
        // Cut line
        pw.Row(
          children: [
            pw.Expanded(child: pw.Container(height: 0.5, color: pw.PdfColors.grey400)),
            pw.SizedBox(width: 10),
            zText(text: "--- ${tr(text: 'cutHere', tr: language)} ---", fontSize: 8, color: pw.PdfColors.grey500),
            pw.SizedBox(width: 10),
            pw.Expanded(child: pw.Container(height: 0.5, color: pw.PdfColors.grey400)),
          ],
        ),
        pw.SizedBox(height: isRtl ? 10 : 16),
        _buildSingleVoucher(data, language, voucherDate, amountText, amountWords, accountValue, true, companyLines, logoProvider, isRtl),
      ],
    );
  }

  pw.Widget _buildSingleVoucher(
      TxnByReferenceModel data,
      String language,
      String voucherDate,
      String amountText,
      String amountWords,
      String accountValue,
      bool isCopy,
      List<String> companyLines,
      pw.ImageProvider? logoProvider,
      bool isRtl,
      ) {
    return pw.Container(
      padding: pw.EdgeInsets.all(isRtl ? 10 : 14),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(width: 1.5, color: pw.PdfColors.blueGrey800),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          // Company Header with Logo
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Company Info
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    for (int i = 0; i < companyLines.length; i++)
                      pw.Padding(
                        padding: pw.EdgeInsets.only(bottom: isRtl ? 1 : 2),
                        child: zText(
                          text: companyLines[i],
                          fontSize: i == 0 ? (isRtl ? 14 : 15) : (isRtl ? 9 : 9),
                          fontWeight: i == 0 ? pw.FontWeight.bold : pw.FontWeight.normal,
                          color: pw.PdfColors.blueGrey900,
                        ),
                      ),
                  ],
                ),
              ),

              // Logo
              if (logoProvider != null)
                pw.Container(
                  width: isRtl ? 90 : 85,
                  height: isRtl ? 90 : 85,
                  margin: pw.EdgeInsets.symmetric(horizontal: isRtl ? 8 : 10),
                  child: pw.Image(logoProvider, fit: pw.BoxFit.contain),
                ),
            ],
          ),

          pw.SizedBox(height: isRtl ? 5 : 8),
          pw.Container(height: 1, color: pw.PdfColors.grey300),
          pw.SizedBox(height: isRtl ? 5 : 8),

          // Title Row
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Row(
                children: [
                  zText(
                    text: tr(text: 'moneyReceipt', tr: language).toUpperCase(),
                    fontWeight: pw.FontWeight.bold,
                    fontSize: isRtl ? 16 : 17,
                    color: pw.PdfColors.blueGrey900,
                  ),
                  if (isCopy) ...[
                    pw.SizedBox(width: isRtl ? 8 : 10),
                    pw.Container(
                      padding: pw.EdgeInsets.symmetric(
                        horizontal: isRtl ? 8 : 10,
                      ),
                      color: pw.PdfColors.blueGrey50,
                      child: zText(
                        text: tr(text: 'copy', tr: language).toUpperCase(),
                        fontSize: isRtl ? 9 : 10,
                        fontWeight: pw.FontWeight.bold,
                        color: pw.PdfColors.blueGrey800,
                      ),
                    ),
                  ],
                ],
              ),
              zText(
                text: "${tr(text: 'date', tr: language)}: $voucherDate",
                fontSize: isRtl ? 10 : 11,
                color: pw.PdfColors.blueGrey700,
              ),
            ],
          ),

          pw.SizedBox(height: isRtl ? 6 : 10),

          // Details
          _voucherRow(tr(text: 'trnType', tr: language), tr(text: data.trnType ?? "", tr: language), isRtl),
          _voucherRow(tr(text: 'reference', tr: language), data.trnReference ?? "-", isRtl),
          _voucherRow(tr(text: 'branch', tr: language), data.branch.toString(), isRtl),
          _voucherRow(tr(text: 'accountNumber', tr: language), accountValue, isRtl),
          _voucherRow(tr(text: 'narration', tr: language), data.narration ?? "-", isRtl),

          pw.SizedBox(height: isRtl ? 6 : 7),

          // Amount
          pw.Container(
            width: double.infinity,
            padding: pw.EdgeInsets.symmetric(
              vertical: isRtl ? 8 : 6,
              horizontal: isRtl ? 12 : 14,
            ),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(width: 1, color: pw.PdfColors.blueGrey600),
              color: pw.PdfColors.blueGrey50,
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                zText(
                  text: "${tr(text: 'amount', tr: language)}:",
                  fontSize: isRtl ? 11 : 12,
                  fontWeight: pw.FontWeight.bold,
                ),
                zText(
                  text: amountText,
                  fontSize: isRtl ? 15 : 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ],
            ),
          ),

          pw.SizedBox(height: isRtl ? 5 : 8),

          // Amount in Words
          pw.Container(
            width: double.infinity,
            padding: pw.EdgeInsets.all(isRtl ? 7 : 3),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                zText(
                  text: tr(text: 'amountInWords', tr: language),
                  fontSize: isRtl ? 8 : 9,
                  color: pw.PdfColors.grey700,
                ),
                zText(
                  text: amountWords,
                  fontSize: isRtl ? 8 : 9,
                  color: pw.PdfColors.grey900,
                ),
              ],
            ),
          ),

          pw.SizedBox(height: isRtl ? 5 : 8),

          // Signatures
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [

              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    horizontalDivider(width: isRtl ? 120 : 130),
                    pw.SizedBox(height: isRtl ? 4 : 5),
                    zText(text: tr(text: 'createdBy', tr: language), fontSize: isRtl ? 8 : 9, color: pw.PdfColors.grey600),
                    pw.SizedBox(height: isRtl ? 1 : 2),
                    zText(text: data.maker ?? "___________", fontSize: isRtl ? 9 : 10, fontWeight: pw.FontWeight.bold),
                  ],
                ),
              ),
              pw.SizedBox(width: isRtl ? 15 : 20),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    horizontalDivider(width: isRtl ? 120 : 130),
                    pw.SizedBox(height: isRtl ? 2 : 3),
                    zText(text: tr(text: 'cashier', tr: language), fontSize: isRtl ? 8 : 9, color: pw.PdfColors.grey600),
                    pw.SizedBox(height: isRtl ? 1 : 2),
                    zText(text: data.checker ?? "___________", fontSize: isRtl ? 9 : 10, fontWeight: pw.FontWeight.bold),
                  ],
                ),
              ),
              pw.SizedBox(width: isRtl ? 15 : 20),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    horizontalDivider(width: isRtl ? 120 : 130),
                    pw.SizedBox(height: isRtl ? 4 : 5),
                    zText(text: tr(text: 'accountHolder', tr: language), fontSize: isRtl ? 8 : 9, color: pw.PdfColors.grey600),
                    pw.SizedBox(height: isRtl ? 1 : 2),
                    zText(text: data.accNameText, fontSize: isRtl ? 9 : 10, fontWeight: pw.FontWeight.bold),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _voucherRow(String label, String value, bool isRtl) {
    return pw.Padding(
      padding: pw.EdgeInsets.only(bottom: isRtl ? 0 : 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        mainAxisAlignment: pw.MainAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: isRtl ? 80 : 150,
            child: zText(
              text: "$label:",
              fontSize: isRtl ? 12 : 10,
              fontWeight: pw.FontWeight.bold,
              textAlign: pw.TextAlign.start,
              color: pw.PdfColors.grey700,
            ),
          ),
          pw.SizedBox(width: 30),
          zText(
            text: value,
            fontSize: isRtl ? 12 : 10,
            color: pw.PdfColors.grey900,
          ),
        ],
      ),
    );
  }
}