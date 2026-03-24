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
import '../../../../Settings/Ui/Company/Storage/model/storage_model.dart';
import '../../../../Stakeholders/Ui/Accounts/model/acc_model.dart';
import '../../../../Stakeholders/Ui/Individuals/model/individual_model.dart';
import '../GetOrderById/model/ord_by_id_model.dart';

class OrderPrintService extends PrintServices {
  Future<void> createDocument({
    required OrderByIdModel order,
    required String language,
    required pw.PageOrientation orientation,
    required ReportModel company,
    required pw.PdfPageFormat pageFormat,
    required List<StorageModel> storages,
    required Map<int, String> productNames,
    required Map<int, String> storageNames,
    required double cashPayment,
    required double creditAmount,
    required AccountsModel? selectedAccount,
    required IndividualsModel? selectedSupplier,
  }) async {
    try {
      final document = await generateOrderDocument(
        order: order,
        company: company,
        language: language,
        orientation: orientation,
        pageFormat: pageFormat,
        storages: storages,
        productNames: productNames,
        storageNames: storageNames,
        cashPayment: cashPayment,
        creditAmount: creditAmount,
        selectedAccount: selectedAccount,
        selectedSupplier: selectedSupplier,
      );

      await saveDocument(
        suggestedName: "${order.ordName}_${order.ordId}.pdf",
        pdf: document,
      );
    } catch (e) {
      throw e.toString();
    }
  }

  Future<void> printDocument({
    required OrderByIdModel order,
    required String language,
    required pw.PageOrientation orientation,
    required ReportModel company,
    required Printer selectedPrinter,
    required pw.PdfPageFormat pageFormat,
    required int copies,
    required List<StorageModel> storages,
    required Map<int, String> productNames,
    required Map<int, String> storageNames,
    required double cashPayment,
    required double creditAmount,
    required AccountsModel? selectedAccount,
    required IndividualsModel? selectedSupplier,
  }) async {
    try {
      final document = await generateOrderDocument(
        order: order,
        company: company,
        language: language,
        orientation: orientation,
        pageFormat: pageFormat,
        storages: storages,
        productNames: productNames,
        storageNames: storageNames,
        cashPayment: cashPayment,
        creditAmount: creditAmount,
        selectedAccount: selectedAccount,
        selectedSupplier: selectedSupplier,
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
    required OrderByIdModel order,
    required String language,
    required ReportModel company,
    required pw.PageOrientation orientation,
    required pw.PdfPageFormat pageFormat,
    required List<StorageModel> storages,
    required Map<int, String> productNames,
    required Map<int, String> storageNames,
    required double cashPayment,
    required double creditAmount,
    required AccountsModel? selectedAccount,
    required IndividualsModel? selectedSupplier,
  }) async {
    return generateOrderDocument(
      order: order,
      company: company,
      language: language,
      orientation: orientation,
      pageFormat: pageFormat,
      storages: storages,
      productNames: productNames,
      storageNames: storageNames,
      cashPayment: cashPayment,
      creditAmount: creditAmount,
      selectedAccount: selectedAccount,
      selectedSupplier: selectedSupplier,
    );
  }

  Future<pw.Document> generateOrderDocument({
    required OrderByIdModel order,
    required String language,
    required ReportModel company,
    required pw.PageOrientation orientation,
    required pw.PdfPageFormat pageFormat,
    required List<StorageModel> storages,
    required Map<int, String> productNames,
    required Map<int, String> storageNames,
    required double cashPayment,
    required double creditAmount,
    required AccountsModel? selectedAccount,
    required IndividualsModel? selectedSupplier,
  }) async {
    final document = pw.Document();
    final prebuiltHeader = await header(report: company);

    final ByteData imageData = await rootBundle.load('assets/images/zaitoonLogo.png');
    final Uint8List imageBytes = imageData.buffer.asUint8List();
    final pw.MemoryImage logoImage = pw.MemoryImage(imageBytes);

    final isPurchase = order.ordName?.toLowerCase().contains('purchase') ?? true;
    final grandTotal = _calculateOrderTotal(order, isPurchase);

    document.addPage(
      pw.MultiPage(
        maxPages: 1000,
        margin: pw.EdgeInsets.symmetric(horizontal: 25, vertical: 10),
        pageFormat: pageFormat,
        textDirection: documentLanguage(language: language),
        orientation: orientation,
        build: (context) => [
          horizontalDivider(),
          invoiceHeaderWidget(
            language: language,
            order: order,
            company: company,
            isPurchase: isPurchase,
          ),
          customerSupplierInfo(
            order: order,
            language: language,
            isPurchase: isPurchase,
            selectedSupplier: selectedSupplier,
          ),
          pw.SizedBox(height: 10),
          itemsTable(
            order: order,
            language: language,
            productNames: productNames,
            storageNames: storageNames,
            isPurchase: isPurchase,
          ),
          pw.SizedBox(height: 15),
          paymentSummary(
            language: language,
            grandTotal: grandTotal,
            cashPayment: cashPayment,
            creditAmount: creditAmount,
            account: selectedAccount,
            currency: "", // Add currency if needed
            isPurchase: isPurchase,
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
                  zText(text: report.comName ?? "",fontWeight: pw.FontWeight.bold, fontSize: 25, tightBounds: true),
                  pw.SizedBox(height: 3),
                  zText(text: report.comAddress ?? "", fontSize: 10),
                  zText(text: "${report.compPhone ?? ""} | ${report.comEmail ?? ""}", fontSize: 9),
                ],
              ),
            ),
            if (image != null)
              pw.Container(
                width: 50,
                height: 50,
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
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            zText(text: report.comAddress ?? "", fontSize: 9),
            buildPage(context.pageNumber, context.pagesCount, language),
          ],
        ),
      ],
    );
  }

  pw.Widget invoiceHeaderWidget({
    required String language,
    required OrderByIdModel order,
    required ReportModel company,
    required bool isPurchase,
  }) {
    final invoiceType = isPurchase
        ? tr(text: 'PUR', tr: language)
        : tr(text: 'SEL', tr: language);

    return pw.Container(
      padding: pw.EdgeInsets.symmetric(vertical: 5),
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
                    text: invoiceType,
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  zText(
                    text: "${tr(text: 'invoiceNumber', tr: language)}: ${order.ordId}",
                    fontSize: 10,
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  zText(
                    text: order.ordEntryDate?.toDateTime ?? DateTime.now().toFormattedDate(),
                    fontSize: 10,
                  ),
                  zText(
                    text: order.ordEntryDate?.shamsiDateFormatted ?? DateTime.now().toFormattedDate(),
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),

                ],
              ),
            ],
          ),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              zText(
                text: order.ordTrnRef ?? "",
                fontSize: 11,
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget customerSupplierInfo({
    required OrderByIdModel order,
    required String language,
    required bool isPurchase,
    required IndividualsModel? selectedSupplier,
  }) {
    final title = isPurchase
        ? tr(text: 'supplier', tr: language)
        : tr(text: 'customer', tr: language);

    final name = selectedSupplier?.perName ?? order.personal ?? "";

    return pw.Container(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          zText(
            text: title,
            fontSize: 9,
            color: pw.PdfColors.grey500,
          ),
          zText(
            text: name,
            fontSize: 12,
          ),
        ],
      ),
    );
  }

  pw.Widget itemsTable({
    required OrderByIdModel order,
    required String language,
    required Map<int, String> productNames,
    required Map<int, String> storageNames,
    required bool isPurchase,
  }) {
    const numberWidth = 30.0;
    const descriptionWidth = 200.0;
    const qtyWidth = 60.0;
    const priceWidth = 80.0;
    const totalWidth = 90.0;
    const storageWidth = 100.0;

    final records = order.records ?? [];

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
        pw.TableRow(
          decoration: pw.BoxDecoration(color: pw.PdfColors.grey200),
          children: [
            pw.Padding(
              padding: pw.EdgeInsets.all(8),
              child: zText(
                text: tr(text: 'number', tr: language),
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.Padding(
              padding: pw.EdgeInsets.all(8),
              child: zText(
                text: tr(text: 'productName', tr: language),
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.Padding(
              padding: pw.EdgeInsets.all(8),
              child: zText(
                text: tr(text: 'qty', tr: language),
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.Padding(
              padding: pw.EdgeInsets.all(8),
              child: zText(
                text: tr(text: 'unitPrice', tr: language),
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.Padding(
              padding: pw.EdgeInsets.all(8),
              child: zText(
                text: tr(text: 'total', tr: language),
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.Padding(
              padding: pw.EdgeInsets.all(8),
              child: zText(
                text: tr(text: 'storage', tr: language),
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                textAlign: pw.TextAlign.center,
              ),
            ),
          ],
        ),

        for (int i = 0; i < records.length; i++)
          pw.TableRow(
            decoration: i.isOdd ? pw.BoxDecoration(color: pw.PdfColors.grey50) : null,
            children: [
              pw.Padding(
                padding: pw.EdgeInsets.all(8),
                child: zText(
                  text: (i + 1).toString(),
                  fontSize: 9,
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.Padding(
                padding: pw.EdgeInsets.all(8),
                child: zText(
                  text: productNames[records[i].stkProduct] ?? "Unknown",
                  fontSize: 9,
                ),
              ),
              pw.Padding(
                padding: pw.EdgeInsets.all(8),
                child: zText(
                  text: records[i].stkQuantity?.toString() ?? "0",
                  fontSize: 9,
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.Padding(
                padding: pw.EdgeInsets.all(8),
                child: zText(
                  text: isPurchase
                      ? (double.tryParse(records[i].stkPurPrice ?? "0") ?? 0).toAmount()
                      : (double.tryParse(records[i].stkSalePrice ?? "0") ?? 0).toAmount(),
                  fontSize: 9,
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.Padding(
                padding: pw.EdgeInsets.all(8),
                child: zText(
                  text: _calculateItemTotal(records[i], isPurchase).toAmount(),
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.Padding(
                padding: pw.EdgeInsets.all(8),
                child: zText(
                  text: storageNames[records[i].stkStorage] ?? "Unknown",
                  fontSize: 9,
                  textAlign: pw.TextAlign.center,
                ),
              ),
            ],
          ),
      ],
    );
  }

  // NEW: Updated paymentSummary method exactly matching InvoicePrintService style
  pw.Widget paymentSummary({
    required String language,
    required double grandTotal,
    required double cashPayment,
    required double creditAmount,
    required AccountsModel? account,
    String? currency,
    required bool isPurchase,
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

                // Cash Payment (if any)
                if (cashPayment > 0)
                  _buildPaymentRow(
                    label: tr(text: 'cashPayment', tr: language),
                    value: cashPayment,
                    ccy: ccy,
                  ),

                // Credit/Account Payment (if any)
                if (creditAmount > 0 && account != null)
                  _buildPaymentRow(
                    label: "${tr(text: 'accountPayment', tr: language)} (${account.accNumber})",
                    value: creditAmount,
                    ccy: ccy,
                  ),

                // Total Payment
                _buildPaymentRow(
                  label: tr(text: 'totalPayment', tr: language),
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

                  // Current Transaction - Show based on order type
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      zText(
                        text: isPurchase
                            ? tr(text: 'purchaseAmount', tr: language)
                            : tr(text: 'saleAmount', tr: language),
                        fontSize: 10,
                      ),
                      zText(
                        text: "${creditAmount.toAmount()} $ccy",
                        fontSize: 10,
                        color: isPurchase ? pw.PdfColors.green : pw.PdfColors.red,
                      ),
                    ],
                  ),

                  // New Balance Calculation
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      zText(
                        text: tr(text: 'newBalance', tr: language),
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                      zText(
                        text: isPurchase
                            ? "${(_getAccountBalance(account) + creditAmount).toAmount()} $ccy"
                            : "${(_getAccountBalance(account) - creditAmount).toAmount()} $ccy",
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: isPurchase
                            ? _getBalanceColor(_getAccountBalance(account) + creditAmount)
                            : _getBalanceColor(_getAccountBalance(account) - creditAmount),
                      ),
                    ],
                  ),

                  // Status (Debtor/Creditor)
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      zText(
                        text: tr(text: 'status', tr: language),
                        fontSize: 10,
                      ),
                      zText(
                        text: isPurchase
                            ? _getBalanceStatus(_getAccountBalance(account) + creditAmount, language)
                            : _getBalanceStatus(_getAccountBalance(account) - creditAmount, language),
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: isPurchase
                            ? _getBalanceColor(_getAccountBalance(account) + creditAmount)
                            : _getBalanceColor(_getAccountBalance(account) - creditAmount),
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

  // Helper methods for account balance
  double _getAccountBalance(AccountsModel account) {
    return double.tryParse(account.accAvailBalance ?? "0.0") ?? 0.0;
  }

  pw.PdfColor _getBalanceColor(double balance) {
    if (balance < 0) {
      return pw.PdfColors.red;
    } else if (balance > 0) {
      return pw.PdfColors.green;
    } else {
      return pw.PdfColors.grey700;
    }
  }

  String _getBalanceStatus(double balance, String language) {
    if (balance < 0) {
      return tr(text: 'debtor', tr: language);
    } else if (balance > 0) {
      return tr(text: 'creditor', tr: language);
    } else {
      return tr(text: 'settled', tr: language);
    }
  }

  double _calculateOrderTotal(OrderByIdModel order, bool isPurchase) {
    if (order.records == null || order.records!.isEmpty) return 0.0;
    double total = 0.0;
    for (final record in order.records!) {
      total += _calculateItemTotal(record, isPurchase);
    }
    return total;
  }

  double _calculateItemTotal(OrderRecords record, bool isPurchase) {
    try {
      final quantity = double.tryParse(record.stkQuantity ?? "0") ?? 0.0;
      double price;
      if (isPurchase) {
        price = double.tryParse(record.stkPurPrice ?? "0") ?? 0.0;
      } else {
        price = double.tryParse(record.stkSalePrice ?? "0") ?? 0.0;
      }
      return quantity * price;
    } catch (e) {
      return 0.0;
    }
  }
}