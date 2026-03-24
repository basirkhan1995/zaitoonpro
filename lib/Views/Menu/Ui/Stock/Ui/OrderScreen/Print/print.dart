import 'dart:async';
import 'dart:ui';
import 'package:pdf/pdf.dart' as pw;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';
import 'package:zaitoonpro/Features/Date/shamsi_converter.dart';
import 'package:zaitoonpro/Features/Other/amount_to_word.dart';
import 'package:zaitoonpro/Features/Other/extensions.dart';
import 'package:zaitoonpro/Features/PrintSettings/print_services.dart';
import 'package:zaitoonpro/Features/PrintSettings/report_model.dart';
import '../../../../Stakeholders/Ui/Accounts/model/acc_model.dart';

abstract class InvoiceItem {
  String get productName;
  double get quantity;
  double get unitPrice;
  double get total;
  String get storageName;
}

class SaleInvoiceItemForPrint implements InvoiceItem {
  @override
  final String productName;
  @override
  final double quantity;
  @override
  final double unitPrice;
  @override
  final double total;
  @override
  final String storageName;
  final double? purchasePrice;
  final double? profit;

  SaleInvoiceItemForPrint({
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.total,
    required this.storageName,
    this.purchasePrice,
    this.profit,
  });
}

class PurchaseInvoiceItemForPrint implements InvoiceItem {
  @override
  final String productName;
  @override
  final double quantity;
  @override
  final double unitPrice;
  @override
  final double total;
  @override
  final String storageName;

  PurchaseInvoiceItemForPrint({
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.total,
    required this.storageName,
  });
}

class InvoicePrintService extends PrintServices {

  Future<void> createInvoiceDocument({
    required String invoiceType,
    required String invoiceNumber,
    required String? reference,
    required DateTime? invoiceDate,
    required String customerSupplierName,
    required List<InvoiceItem> items,
    required double grandTotal,
    required double cashPayment,
    required double creditAmount,
    required AccountsModel? account,
    required String language,
    required pw.PageOrientation orientation,
    required ReportModel company,
    required pw.PdfPageFormat pageFormat,
    required bool isSale,
    String? currency,
  }) async {
    try {
      final document = await generateInvoiceDocument(
        invoiceType: invoiceType,
        invoiceNumber: invoiceNumber,
        reference: reference,
        invoiceDate: invoiceDate,
        customerSupplierName: customerSupplierName,
        items: items,
        grandTotal: grandTotal,
        cashPayment: cashPayment,
        creditAmount: creditAmount,
        account: account,
        language: language,
        orientation: orientation,
        company: company,
        pageFormat: pageFormat,
        isSale: isSale,
        currency: currency,
      );

      await saveDocument(
        suggestedName: "${invoiceType}_$invoiceNumber.pdf",
        pdf: document,
      );
    } catch (e) {
      throw e.toString();
    }
  }

  Future<void> printInvoiceDocument({
    required String invoiceType,
    required String invoiceNumber,
    required String? reference,
    required DateTime? invoiceDate,
    required String customerSupplierName,
    required List<InvoiceItem> items,
    required double grandTotal,
    required double cashPayment,
    required double creditAmount,
    required AccountsModel? account,
    required String language,
    required pw.PageOrientation orientation,
    required ReportModel company,
    required Printer selectedPrinter,
    required pw.PdfPageFormat pageFormat,
    required int copies,
    required bool isSale,
    String? currency,
  }) async {
    try {
      final document = await generateInvoiceDocument(
        invoiceType: invoiceType,
        invoiceNumber: invoiceNumber,
        reference: reference,
        invoiceDate: invoiceDate,
        customerSupplierName: customerSupplierName,
        items: items,
        grandTotal: grandTotal,
        cashPayment: cashPayment,
        creditAmount: creditAmount,
        account: account,
        language: language,
        orientation: orientation,
        company: company,
        pageFormat: pageFormat,
        currency: currency,
        isSale: isSale,
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

  Future<pw.Document> printInvoicePreview({
    required String invoiceType,
    required String invoiceNumber,
    required String? reference,
    required DateTime? invoiceDate,
    required String customerSupplierName,
    required List<InvoiceItem> items,
    required double grandTotal,
    required double cashPayment,
    required double creditAmount,
    required AccountsModel? account,
    required String language,
    required pw.PageOrientation orientation,
    required ReportModel company,
    required pw.PdfPageFormat pageFormat,
    required bool isSale,
    String? currency,
  }) async {
    return generateInvoiceDocument(
      invoiceType: invoiceType,
      invoiceNumber: invoiceNumber,
      reference: reference,
      invoiceDate: invoiceDate,
      customerSupplierName: customerSupplierName,
      items: items,
      grandTotal: grandTotal,
      cashPayment: cashPayment,
      creditAmount: creditAmount,
      account: account,
      language: language,
      orientation: orientation,
      company: company,
      pageFormat: pageFormat,
      currency: currency,
      isSale: isSale
    );
  }

  Future<pw.Document> generateInvoiceDocument({
    required String invoiceType,
    required String invoiceNumber,
    required String? reference,
    required DateTime? invoiceDate,
    required String customerSupplierName,
    required List<InvoiceItem> items,
    required double grandTotal,
    required double cashPayment,
    required double creditAmount,
    required AccountsModel? account,
    required String language,
    required pw.PageOrientation orientation,
    required ReportModel company,
    required pw.PdfPageFormat pageFormat,
    required bool isSale,
    String? currency,
  }) async {
    final document = pw.Document();
    final prebuiltHeader = await header(report: company);
    final ByteData imageData = await rootBundle.load('assets/images/zaitoonLogo.png');
    final Uint8List imageBytes = imageData.buffer.asUint8List();
    final pw.MemoryImage logoImage = pw.MemoryImage(imageBytes);

   // final isSale = invoiceType.toLowerCase().contains('sale');

    document.addPage(
      pw.MultiPage(
        maxPages: 1000,
        margin: pw.EdgeInsets.symmetric(horizontal: 25, vertical: 15),
        pageFormat: pageFormat,
        textDirection: documentLanguage(language: language),
        orientation: orientation,
        build: (context) => [
          _invoiceHeaderWidget(
            language: language,
            invoiceType: invoiceType,
            invoiceNumber: invoiceNumber,
            invoiceDate: invoiceDate,
            reference: reference,
          ),
          _customerSupplierInfo(
            language: language,
            customerSupplierName: customerSupplierName,
            isSale: isSale,
          ),
          pw.SizedBox(height: 5),
          _itemsTable(
            items: items,
            language: language,
            isSale: isSale,
          ),
          pw.SizedBox(height: 15),
          _paymentSummary(
            language: language,
            grandTotal: grandTotal,
            cashPayment: cashPayment,
            creditAmount: creditAmount,
            account: account,
            currency: currency,
            isSale: isSale,
          ),
        ],
        header: (context) => prebuiltHeader,
        footer: (context) => footer(
            report: company,
            context: context,
            language: language,
            logoImage: logoImage
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
  }) {
    final invoiceTitle = invoiceType.toLowerCase().contains('sale')
        ? tr(text: 'SEL', tr: language)
        : tr(text: 'PUR', tr: language);

    return pw.Container(
      padding: pw.EdgeInsets.symmetric(vertical: 0),
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
                    text:
                    "${tr(text: 'invoiceNumber', tr: language)} | $invoiceNumber",
                    fontSize: 8,
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
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
          if (reference != null && reference.isNotEmpty)
            zText(
              text:
              "${tr(text: 'referenceNumber', tr: language)}: $reference",
              fontSize: 11,
            ),
        ],
      ),
    );
  }

  pw.Widget _customerSupplierInfo({
    required String language,
    required String customerSupplierName,
    required bool isSale,
  }) {
    final title = isSale
        ? tr(text: 'customer', tr: language)
        : tr(text: 'supplier', tr: language);

    return pw.Container(
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          zText(
            text: "$title |",
            fontSize: 8,
            color: pw.PdfColors.grey600,

          ),
          pw.SizedBox(width: 4),
          zText(
            text: customerSupplierName,
            fontSize: 8,
          ),
        ],
      ),
    );
  }

  pw.Widget _itemsTable({
    required List<InvoiceItem> items,
    required String language,
    required bool isSale,
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
              padding: pw.EdgeInsets.all(4),
              child: zText(
                text: tr(text: 'number', tr: language),
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.Padding(
              padding: pw.EdgeInsets.all(4),
              child: zText(
                text: tr(text: 'description', tr: language),
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.Padding(
              padding: pw.EdgeInsets.all(4),
              child: zText(
                text: tr(text: 'qty', tr: language),
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.Padding(
              padding: pw.EdgeInsets.all(4),
              child: zText(
                text: tr(text: 'unitPrice', tr: language),
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.Padding(
              padding: pw.EdgeInsets.all(4),
              child: zText(
                text: tr(text: 'total', tr: language),
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.Padding(
              padding: pw.EdgeInsets.all(4),
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
        for (int i = 0; i < items.length; i++)
          pw.TableRow(
            decoration:
            i.isOdd ? pw.BoxDecoration(color: pw.PdfColors.grey50) : null,
            children: [
              pw.Padding(
                padding: pw.EdgeInsets.all(5),
                child: zText(
                  text: (i + 1).toString(),
                  fontSize: 9,
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.Padding(
                padding: pw.EdgeInsets.all(5),
                child: zText(
                  text: items[i].productName,
                  fontSize: 9,
                ),
              ),
              pw.Padding(
                padding: pw.EdgeInsets.all(5),
                child: zText(
                  text: items[i].quantity.toString(),
                  fontSize: 9,
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.Padding(
                padding: pw.EdgeInsets.all(5),
                child: zText(
                  text: items[i].unitPrice.toAmount(),
                  fontSize: 9,
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.Padding(
                padding: pw.EdgeInsets.all(5),
                child: zText(
                  text: items[i].total.toAmount(),
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.Padding(
                padding: pw.EdgeInsets.all(5),
                child: zText(
                  text: items[i].storageName,
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
    required double cashPayment,
    required double creditAmount,
    required AccountsModel? account,
    String? currency,
    required bool isSale,
  }) {
    final lang = NumberToWords.getLanguageFromLocale(Locale(language));
    final cleanAmount = grandTotal.toString().replaceAll(',', '');
    final parsedAmount = int.tryParse(
      double.tryParse(cleanAmount)?.toStringAsFixed(0) ?? "0",
    ) ?? 0;
    final amountInWords = NumberToWords.convert(parsedAmount, lang);
    final ccy = currency ?? '';

    return pw.Container(
      width: 300,
      alignment: pw.Alignment.centerRight,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          // Payment Breakdown
          pw.Container(
            padding: pw.EdgeInsets.all(2),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Grand Total
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    zText(
                      text: tr(
                          text: 'grandTotal', tr: language),
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

                // Cash Payment (if any)
                if (cashPayment > 0)
                  _buildPaymentRow(
                    label: tr(
                        text: 'cashPayment', tr: language),
                    value: cashPayment,
                    ccy: ccy,
                  ),

                // Credit/Account Payment (if any)
                if (creditAmount > 0 && account != null)
                  _buildPaymentRow(
                    label:
                    "${tr(text: 'accountPayment', tr: language)} (${account.accNumber})",
                    value: creditAmount,
                    ccy: ccy,
                  ),

                // Total Payment
                _buildPaymentRow(
                  label: tr(
                      text: 'totalPayment', tr: language),
                  value: cashPayment + creditAmount,
                  ccy: ccy,
                  isBold: true,
                ),

                // Account Balance Information - ONLY show when credit is used AND account exists
                if (account != null && creditAmount > 0) ...[
                  pw.Divider(color: pw.PdfColors.grey300),

                  // Account Info
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      zText(
                          text: "${account.accNumber} | ${account.accName}",
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold
                      ),
                    ],
                  ),

                  // Previous Balance
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      zText(
                        text: tr(text: 'previousAccBalance', tr: language),
                        fontSize: 10,
                      ),
                      zText(
                        text: "${_getAccountBalance(account).toAmount()} $ccy",
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: _getBalanceColor(_getAccountBalance(account)),
                      ),
                    ],
                  ),

                  // Current Transaction - Show based on invoice type
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      zText(
                        text: isSale
                            ? tr(text: 'saleAmount', tr: language)
                            : tr(text: 'purchaseAmount', tr: language),
                        fontSize: 10,
                      ),
                      zText(
                        text: "${creditAmount.toAmount()} $ccy",
                        fontSize: 10,
                        color: isSale ? pw.PdfColors.red : pw.PdfColors.green,
                      ),
                    ],
                  ),

                  // New Balance Calculation
                  // SALE: Previous Balance - Credit Amount (customer owes me, reduces what I owe)
                  // PURCHASE: Previous Balance + Credit Amount (I owe more to supplier)
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      zText(
                        text: tr(
                            text: 'newBalance', tr: language),
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                      zText(
                        text: isSale
                            ? "${(_getAccountBalance(account) - creditAmount).toAmount()} $ccy"
                            : "${(_getAccountBalance(account) + creditAmount).toAmount()} $ccy",
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: isSale
                            ? _getBalanceColor(_getAccountBalance(account) - creditAmount)
                            : _getBalanceColor(_getAccountBalance(account) + creditAmount),
                      ),
                    ],
                  ),

                  // Status (Debtor/Creditor)
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      zText(
                        text: tr(
                            text: 'status', tr: language),
                        fontSize: 10,
                      ),
                      zText(
                        text: isSale
                            ? _getBalanceStatus(_getAccountBalance(account) - creditAmount, language)
                            : _getBalanceStatus(_getAccountBalance(account) + creditAmount, language),
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: isSale
                            ? _getBalanceColor(_getAccountBalance(account) - creditAmount)
                            : _getBalanceColor(_getAccountBalance(account) + creditAmount),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Amount in words
          pw.SizedBox(height: 5),
          pw.Container(
            padding: pw.EdgeInsets.all(2),
            width: double.infinity,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                zText(
                  text: tr(
                      text: 'amountInWords', tr: language),
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

// Helper methods remain the same
  double _getAccountBalance(AccountsModel account) {
    return double.tryParse(account.accAvailBalance ?? "0.0") ?? 0.0;
  }

  pw.PdfColor _getBalanceColor(double balance) {
    if (balance < 0) {
      return pw.PdfColors.red; // Negative = Debtor (customer owes me) - RED
    } else if (balance > 0) {
      return pw.PdfColors.green; // Positive = Creditor (I owe them) - GREEN
    } else {
      return pw.PdfColors.grey700; // Zero balance - GREY
    }
  }

  String _getBalanceStatus(double balance, String language) {
    if (balance < 0) {
      return tr(text: 'debtor', tr: language); // Negative = Debtor
    } else if (balance > 0) {
      return tr(text: 'creditor', tr: language); // Positive = Creditor
    } else {
      return tr(text: 'settled', tr: language);
    }
  }

  pw.Widget _buildPaymentRow({
    required String label,
    required double value,
    String ccy = "",
    bool isBold = false,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        zText(
          text: label,
          fontSize: 11,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        zText(
          text: "${value.toAmount()} $ccy",
          fontSize: 11,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isBold ? pw.PdfColors.blue700 : null,
        ),
      ],
    );
  }
}