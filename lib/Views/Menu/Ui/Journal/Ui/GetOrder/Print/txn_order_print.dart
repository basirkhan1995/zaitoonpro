import 'dart:async';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart' as pw;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:zaitoonpro/Features/Date/shamsi_converter.dart';
import 'package:zaitoonpro/Features/Other/amount_to_word.dart';
import 'package:zaitoonpro/Features/Other/extensions.dart';
import 'package:zaitoonpro/Features/PrintSettings/print_services.dart';
import 'package:zaitoonpro/Features/PrintSettings/report_model.dart';
import '../model/get_order_model.dart';

class OrderTxnPrintSettings extends PrintServices {

  Future<void> createDocument({
    required OrderTxnModel data,
    required ReportModel company,
    required String language,
    required pw.PageOrientation orientation,
    required pw.PdfPageFormat pageFormat,
  }) async {
    try {
      final document = await generateDocument(
        data: data,
        company: company,
        language: language,
        orientation: orientation,
        pageFormat: pageFormat,
      );

      await saveDocument(
        suggestedName: "${data.trnReference}_${DateTime.now().millisecondsSinceEpoch}.pdf",
        pdf: document,
      );
    } catch (e) {
      throw e.toString();
    }
  }

  Future<void> printDocument({
    required OrderTxnModel data,
    required ReportModel company,
    required String language,
    required pw.PageOrientation orientation,
    required pw.PdfPageFormat pageFormat,
    required Printer selectedPrinter,
    required int copies,
    required String pages,
  }) async {
    try {
      final document = await generateDocument(
        data: data,
        company: company,
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
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }
    } catch (e) {
      throw e.toString();
    }
  }

  Future<pw.Document> printPreview({
    required OrderTxnModel data,
    required ReportModel company,
    required String language,
    required pw.PageOrientation orientation,
    required pw.PdfPageFormat pageFormat,
  }) async {
    return generateDocument(
      data: data,
      company: company,
      language: language,
      orientation: orientation,
      pageFormat: pageFormat,
    );
  }

  Future<pw.Document> generateDocument({
    required OrderTxnModel data,
    required ReportModel company,
    required String language,
    required pw.PageOrientation orientation,
    required pw.PdfPageFormat pageFormat,
  }) async {
    final document = pw.Document();
    final prebuiltHeader = await header(report: company);

    final ByteData imageData = await rootBundle.load('assets/images/zaitoonLogo.png');
    final Uint8List imageBytes = imageData.buffer.asUint8List();
    final pw.MemoryImage logoImage = pw.MemoryImage(imageBytes);

    final isSale = data.trnType?.toLowerCase().contains('sale') ?? false;
    final isPurchase = data.trnType?.toLowerCase().contains('purchase') ?? false;
    final invoiceType = isSale ? 'SEL' : (isPurchase ? 'PUR' : 'TRN');

    final grandTotal = double.tryParse(data.totalBill ?? "0") ?? 0;
    final records = data.records ?? [];
    final billItems = data.bill ?? [];

    document.addPage(
      pw.MultiPage(
        maxPages: 1000,
        margin: const pw.EdgeInsets.symmetric(horizontal: 25, vertical: 15),
        pageFormat: pageFormat,
        textDirection: documentLanguage(language: language),
        orientation: orientation,
        build: (context) => [
          _invoiceHeaderWidget(
            language: language,
            invoiceType: invoiceType,
            invoiceNumber: data.trnReference ?? "",
            invoiceDate: data.trnEntryDate,
            reference: data.trnReference,
            status: data.trnStateText ?? "",
          ),
          _itemsTable(
            billItems: billItems,
            language: language,
          ),
          pw.SizedBox(height: 15),
          _paymentSummary(
            language: language,
            grandTotal: grandTotal,
            records: records,
            currency: data.ccy,
            trnReference: data.trnReference ?? "",
            maker: data.maker ?? "",
            checker: data.checker ?? "",
            remark: data.remark,
          ),
        ],
        header: (context) => prebuiltHeader,
        footer: (context) => footer(
          report: company,
          context: context,
          language: language,
          logoImage: logoImage,
        ),
      ),
    );
    return document;
  }

  pw.Widget _invoiceHeaderWidget({
    required String language,
    required String invoiceType,
    required String invoiceNumber,
    required DateTime? invoiceDate,
    required String? reference,
    required String status,
  }) {
    final invoiceTitle = invoiceType == 'SEL'
        ? tr(text: 'SEL', tr: language)
        : (invoiceType == 'PUR'
        ? tr(text: 'PUR', tr: language)
        : tr(text: 'transaction', tr: language));

    final isAuthorized = status.toLowerCase().contains('authorize');

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 0),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  zText(
                    text: invoiceTitle,
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  zText(
                    text: "${tr(text: 'invoiceNumber', tr: language)} | $invoiceNumber",
                    fontSize: 8,
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  zText(
                    text: DateTime.now().toDateTime,
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  zText(
                    text: DateTime.now().shamsiDateFormatted,
                    fontSize: 10,
                    color: pw.PdfColors.grey800,
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              if (reference != null && reference.isNotEmpty)
                zText(
                  text: "${tr(text: 'referenceNumber', tr: language)}: $reference",
                  fontSize: 11,
                ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: pw.BoxDecoration(
                  color: isAuthorized ? pw.PdfColors.green50 : pw.PdfColors.orange50,
                  border: pw.Border.all(
                    color: isAuthorized ? pw.PdfColors.green : pw.PdfColors.orange,
                    width: 1,
                  ),
                  borderRadius: pw.BorderRadius.circular(3),
                ),
                child: zText(
                  text: status,
                  fontSize: 8,
                  color: isAuthorized ? pw.PdfColors.green : pw.PdfColors.orange,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _itemsTable({
    required List<Bill> billItems,
    required String language,
  }) {
    const numberWidth = 30.0;
    const descriptionWidth = 200.0;
    const qtyWidth = 60.0;
    const priceWidth = 80.0;
    const totalWidth = 90.0;
    const storageWidth = 100.0;

    return pw.Table(
      border: pw.TableBorder.all(color: pw.PdfColors.grey300, width: 1),
      columnWidths: {
        0: pw.FixedColumnWidth(numberWidth),
        1: pw.FixedColumnWidth(descriptionWidth),
        2: pw.FixedColumnWidth(qtyWidth),
        3: pw.FixedColumnWidth(priceWidth),
        4: pw.FixedColumnWidth(totalWidth),
        5: pw.FixedColumnWidth(storageWidth),
      },
      children: [
        // Header Row
        pw.TableRow(
          decoration: pw.BoxDecoration(color: pw.PdfColors.grey50),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: zText(
                text: tr(text: 'number', tr: language),
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: zText(
                text: tr(text: 'description', tr: language),
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: zText(
                text: tr(text: 'qty', tr: language),
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: zText(
                text: tr(text: 'unitPrice', tr: language),
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: zText(
                text: tr(text: 'total', tr: language),
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: zText(
                text: tr(text: 'storage', tr: language),
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                textAlign: pw.TextAlign.center,
              ),
            ),
          ],
        ),

        // Data Rows
        for (int i = 0; i < billItems.length; i++)
          pw.TableRow(
            decoration: i.isOdd ? pw.BoxDecoration(color: pw.PdfColors.grey50) : null,
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(5),
                child: zText(
                  text: (i + 1).toString(),
                  fontSize: 9,
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(5),
                child: zText(
                  text: billItems[i].productName ?? "-",
                  fontSize: 9,
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(5),
                child: zText(
                  text: "${billItems[i].quantity ?? "0"} T",
                  fontSize: 9,
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(5),
                child: zText(
                  text: (double.tryParse(billItems[i].unitPrice ?? "0") ?? 0).toAmount(),
                  fontSize: 9,
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(5),
                child: zText(
                  text: (double.tryParse(billItems[i].totalPrice ?? "0") ?? 0).toAmount(),
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(5),
                child: zText(
                  text: billItems[i].storageName ?? "-",
                  fontSize: 9,
                  textAlign: pw.TextAlign.center,
                ),
              ),
            ],
          ),
      ],
    );
  }

  pw.Widget _paymentSummary({
    required String language,
    required double grandTotal,
    required List<Record> records,
    String? currency,
    required String trnReference,
    required String maker,
    required String checker,
    String? remark,
  }) {
    final lang = NumberToWords.getLanguageFromLocale(Locale(language));
    final cleanAmount = grandTotal.toString().replaceAll(',', '');
    final parsedAmount = int.tryParse(
      double.tryParse(cleanAmount)?.toStringAsFixed(0) ?? "0",
    ) ?? 0;
    final amountInWords = NumberToWords.convert(parsedAmount, lang);
    final ccy = currency ?? '';

    // Separate debit and credit records
    final debitRecords = records.where((r) => r.debitCredit?.toLowerCase() == "debit").toList();
    final creditRecords = records.where((r) => r.debitCredit?.toLowerCase() == "credit").toList();

    return pw.Container(
      width: 300,
      alignment: pw.Alignment.centerRight,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          // Grand Total
          pw.Container(
            padding: const pw.EdgeInsets.all(2),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    zText(
                      text: tr(text: 'grandTotal', tr: language),
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                    ),
                    zText(
                      text: "${grandTotal.toAmount()} $ccy",
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                      color: pw.PdfColors.blue700,
                    ),
                  ],
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 10),

          // Accounting Entries
          if (records.isNotEmpty) ...[
            pw.Container(
              padding: const pw.EdgeInsets.all(2),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: pw.PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(3),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  zText(
                    text: tr(text: 'accountingEntries', tr: language),
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: pw.PdfColors.blue700,
                  ),
                  pw.SizedBox(height: 5),

                  // Debit Entries
                  if (debitRecords.isNotEmpty) ...[
                    zText(
                      text: tr(text: 'debit', tr: language),
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                      color: pw.PdfColors.red,
                    ),
                    ...debitRecords.map((r) => _buildRecordRow(r, ccy, language)),
                    pw.SizedBox(height: 3),
                  ],

                  // Credit Entries
                  if (creditRecords.isNotEmpty) ...[
                    zText(
                      text: tr(text: 'credit', tr: language),
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                      color: pw.PdfColors.green,
                    ),
                    ...creditRecords.map((r) => _buildRecordRow(r, ccy, language)),
                  ],
                ],
              ),
            ),
            pw.SizedBox(height: 10),
          ],

          // Transaction Info
          pw.Container(
            padding: const pw.EdgeInsets.all(2),
            width: double.infinity,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildInfoRow(
                  label: tr(text: 'referenceNumber', tr: language),
                  value: trnReference,
                ),
                _buildInfoRow(
                  label: tr(text: 'maker', tr: language),
                  value: maker,
                ),
                _buildInfoRow(
                  label: tr(text: 'checker', tr: language),
                  value: checker,
                ),
                if (remark != null && remark.isNotEmpty) ...[
                  _buildInfoRow(
                    label: tr(text: 'remark', tr: language),
                    value: remark,
                  ),
                ],
              ],
            ),
          ),

          // Amount in words
          pw.SizedBox(height: 5),
          pw.Container(
            padding: const pw.EdgeInsets.all(2),
            width: double.infinity,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                zText(
                  text: tr(text: 'amountInWords', tr: language),
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                ),
                pw.SizedBox(height: 1),
                zText(
                  text: amountInWords.isNotEmpty ? "$amountInWords $ccy" : "",
                  fontSize: 8,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildRecordRow(Record record, String ccy, String language) {
    final isDebit = record.debitCredit?.toLowerCase() == "debit";
    final amount = double.tryParse(record.amount ?? "0") ?? 0;

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Expanded(
            flex: 3,
            child: zText(
              text: "${record.accountName ?? "-"} (${record.accountNumber ?? "-"})",
              fontSize: 8,
            ),
          ),
          pw.Expanded(
            flex: 1,
            child: zText(
              text: "${amount.toAmount()} $ccy",
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
              color: isDebit ? pw.PdfColors.red : pw.PdfColors.green,
              textAlign: pw.TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildInfoRow({
    required String label,
    required String value,
  }) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 70,
            child: zText(
              text: "$label:",
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.Expanded(
            child: zText(
              text: value,
              fontSize: 8,
            ),
          ),
        ],
      ),
    );
  }
}