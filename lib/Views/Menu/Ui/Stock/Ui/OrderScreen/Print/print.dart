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
  int get batch;
  double get unitPrice;
  double get total;
  String get storageName;
  double? get localAmount;
  String? get localCurrency;
  double? get exchangeRate;
}

class SaleInvoiceItemForPrint implements InvoiceItem {
  @override
  final String productName;
  @override
  final double quantity;
  @override
  final int batch;
  @override
  final double unitPrice;
  @override
  final double total;
  @override
  final String storageName;
  final double? purchasePrice;
  final double? profit;
  @override
  final double? localAmount;
  @override
  final String? localCurrency;
  @override
  final double? exchangeRate;

  SaleInvoiceItemForPrint({
    required this.productName,
    required this.quantity,
    required this.batch,
    required this.unitPrice,
    required this.total,
    required this.storageName,
    this.purchasePrice,
    this.profit,
    this.localAmount,
    this.localCurrency,
    this.exchangeRate
  });
}

class PurchaseInvoiceItemForPrint implements InvoiceItem {
  @override
  final String productName;
  @override
  final double quantity;
  @override
  final int batch;
  @override
  final double unitPrice;
  @override
  final double total;
  @override
  final String storageName;
  @override
  final double? localAmount;
  @override
  final String? localCurrency;
  @override
  final double? exchangeRate;

  PurchaseInvoiceItemForPrint({
    required this.productName,
    required this.quantity,
    required this.batch,
    required this.unitPrice,
    required this.total,
    required this.storageName,
    this.localAmount,
    this.localCurrency,
    this.exchangeRate
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
    double? totalLocalAmount,
    String? localCurrency,
    double? exchangeRate,  // Add this
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
        totalLocalAmount: totalLocalAmount,
        localCurrency: localCurrency,
        exchangeRate: exchangeRate,  // Pass through
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
    double? totalLocalAmount,
    String? localCurrency,
    double? exchangeRate,  // Add this
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
        totalLocalAmount: totalLocalAmount,
        localCurrency: localCurrency,
        exchangeRate: exchangeRate,  // Pass through
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
    double? totalLocalAmount,     // Add this
    String? localCurrency,        // Add this
    double? exchangeRate,  // Add this line
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
      isSale: isSale,
      totalLocalAmount: totalLocalAmount,    // Pass through
      localCurrency: localCurrency,          // Pass through
      exchangeRate: exchangeRate,  // Add this line
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
    double? totalLocalAmount,
    String? localCurrency,
    double? exchangeRate,  // Add this parameter
  }) async {
    final document = pw.Document();
    final prebuiltHeader = await header(report: company);
    final ByteData imageData = await rootBundle.load('assets/images/zaitoonLogo.png');
    final Uint8List imageBytes = imageData.buffer.asUint8List();
    final pw.MemoryImage logoImage = pw.MemoryImage(imageBytes);

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
            baseCurrency: currency,  // Pass baseCurrency
            localCurrency: localCurrency,
            exchangeRate: exchangeRate,  // Pass exchangeRate
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
            items: items,
            totalLocalAmount: totalLocalAmount,
            localCurrency: localCurrency,
            baseCurrency: currency,
            exchangeRate: exchangeRate,  // Pass exchangeRate
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
    String? baseCurrency,
    String? localCurrency,
    double? exchangeRate,
  }) {
    const numberWidth = 30.0;
    const descriptionWidth = 180.0;
    const qtyWidth = 50.0;
    const priceWidth = 70.0;
    const totalWidth = 80.0;
    const batchWidth = 50.0;
    const localAmountWidth = 80.0;

    final isRtl = language == 'fa' || language == 'ar';

    // Only show local amount column if:
    // 1. It's a purchase invoice
    // 2. Local currency is provided
    // 3. Base currency and local currency are different
    final needsConversion = !isSale &&
        localCurrency != null &&
        baseCurrency != null &&
        baseCurrency != localCurrency &&
        exchangeRate != null;

    final showLocalAmount = needsConversion;

    // Define column widths and headers based on whether we show local amount
    final Map<int, pw.TableColumnWidth> columnWidths;
    final List<String> headers;

    if (isRtl) {
      if (showLocalAmount) {
        columnWidths = {
          0: pw.FixedColumnWidth(batchWidth),
          1: pw.FixedColumnWidth(localAmountWidth),
          2: pw.FixedColumnWidth(totalWidth),
          3: pw.FixedColumnWidth(priceWidth),
          4: pw.FixedColumnWidth(qtyWidth),
          5: pw.FixedColumnWidth(descriptionWidth),
          6: pw.FixedColumnWidth(numberWidth),
        };
        headers = [
          tr(text: 'total', tr: language),
          '${tr(text: 'localAmount', tr: language)} ($localCurrency)',
          tr(text: 'unitPrice', tr: language),
          tr(text: 'batch', tr: language),
          tr(text: 'quantity', tr: language),
          tr(text: 'description', tr: language),
          tr(text: 'number', tr: language),
        ];
      } else {
        columnWidths = {
          0: pw.FixedColumnWidth(batchWidth),
          1: pw.FixedColumnWidth(totalWidth),
          2: pw.FixedColumnWidth(priceWidth),
          3: pw.FixedColumnWidth(qtyWidth),
          4: pw.FixedColumnWidth(descriptionWidth),
          5: pw.FixedColumnWidth(numberWidth),
        };
        headers = [
          tr(text: 'total', tr: language),
          tr(text: 'unitPrice', tr: language),
          tr(text: 'batch', tr: language),
          tr(text: 'quantity', tr: language),
          tr(text: 'description', tr: language),
          tr(text: 'number', tr: language),
        ];
      }
    } else {
      if (showLocalAmount) {
        columnWidths = {
          0: pw.FixedColumnWidth(numberWidth),
          1: pw.FixedColumnWidth(descriptionWidth),
          2: pw.FixedColumnWidth(qtyWidth),
          3: pw.FixedColumnWidth(batchWidth),
          4: pw.FixedColumnWidth(priceWidth),
          5: pw.FixedColumnWidth(localAmountWidth),
          6: pw.FixedColumnWidth(totalWidth),
        };
        headers = [
          tr(text: 'number', tr: language),
          tr(text: 'description', tr: language),
          tr(text: 'quantity', tr: language),
          tr(text: 'batch', tr: language),
          tr(text: 'unitPrice', tr: language),
          '${tr(text: 'localAmount', tr: language)} ($localCurrency)',
          tr(text: 'total', tr: language),
        ];
      } else {
        columnWidths = {
          0: pw.FixedColumnWidth(numberWidth),
          1: pw.FixedColumnWidth(descriptionWidth),
          2: pw.FixedColumnWidth(qtyWidth),
          3: pw.FixedColumnWidth(batchWidth),
          4: pw.FixedColumnWidth(priceWidth),
          5: pw.FixedColumnWidth(totalWidth),
        };
        headers = [
          tr(text: 'number', tr: language),
          tr(text: 'description', tr: language),
          tr(text: 'quantity', tr: language),
          tr(text: 'batch', tr: language),
          tr(text: 'unitPrice', tr: language),
          tr(text: 'total', tr: language),
        ];
      }
    }

    return pw.Table(
      border: pw.TableBorder.all(color: pw.PdfColors.grey300, width: 1),
      columnWidths: columnWidths,
      children: [
        // Header Row
        pw.TableRow(
          decoration: pw.BoxDecoration(color: pw.PdfColors.grey100),
          children: headers.map((header) {
            return pw.Padding(
              padding: pw.EdgeInsets.all(4),
              child: zText(
                text: header,
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                textAlign: pw.TextAlign.center,
              ),
            );
          }).toList(),
        ),

        // Data Rows - Pass exchangeRate to row builders
        for (int i = 0; i < items.length; i++)
          pw.TableRow(
            decoration: i.isOdd ? pw.BoxDecoration(color: pw.PdfColors.grey50) : null,
            children: isRtl
                ? _buildRtlRow(items[i], i, showLocalAmount, localCurrency, exchangeRate)  // Pass exchangeRate
                : _buildLtrRow(items[i], i, showLocalAmount, localCurrency, exchangeRate),  // Pass exchangeRate
          ),
      ],
    );
  }

// LTR Row builder
  List<pw.Widget> _buildLtrRow(
      InvoiceItem item,
      int index,
      bool showLocalAmount,
      String? localCurrency,
      double? exchangeRate,  // Add this parameter
      ) {
    final widgets = <pw.Widget>[];

    // Number
    widgets.add(pw.Padding(
      padding: pw.EdgeInsets.all(3),
      child: zText(
        text: (index + 1).toString(),
        fontSize: 9,
        textAlign: pw.TextAlign.center,
      ),
    ));

    // Description
    widgets.add(pw.Padding(
      padding: pw.EdgeInsets.symmetric(horizontal: 5),
      child: zText(
        text: item.productName,
        fontSize: 9,
      ),
    ));

    // Quantity
    widgets.add(pw.Padding(
      padding: pw.EdgeInsets.all(3),
      child: zText(
        text: item.quantity.toString(),
        fontSize: 9,
        textAlign: pw.TextAlign.center,
      ),
    ));

    // Batch
    widgets.add(pw.Padding(
      padding: pw.EdgeInsets.all(3),
      child: zText(
        text: item.batch.toString(),
        fontSize: 9,
        textAlign: pw.TextAlign.center,
      ),
    ));

    // Unit Price (in base currency)
    widgets.add(pw.Padding(
      padding: pw.EdgeInsets.all(3),
      child: zText(
        text: item.unitPrice.toAmount(),
        fontSize: 9,
        textAlign: pw.TextAlign.center,
      ),
    ));

    // Local Amount (single item) - only show if needed
    if (showLocalAmount) {
      // Use item's localAmount if available, otherwise calculate
      final localAmountValue = item.localAmount ??
          (item.unitPrice * (exchangeRate ?? item.exchangeRate ?? 1.0));
      widgets.add(pw.Padding(
        padding: pw.EdgeInsets.all(3),
        child: zText(
          text: localAmountValue.toAmount(),
          fontSize: 9,
          textAlign: pw.TextAlign.center,
          fontWeight: pw.FontWeight.bold,
          color: pw.PdfColors.blue700,
        ),
      ));
    }

    // Total
    widgets.add(pw.Padding(
      padding: pw.EdgeInsets.all(3),
      child: zText(
        text: item.total.toAmount(),
        fontSize: 9,
        fontWeight: pw.FontWeight.bold,
        textAlign: pw.TextAlign.center,
      ),
    ));

    return widgets;
  }

// RTL Row builder
  List<pw.Widget> _buildRtlRow(
      InvoiceItem item,
      int index,
      bool showLocalAmount,
      String? localCurrency,
      double? exchangeRate,  // Add this parameter
      ) {
    final widgets = <pw.Widget>[];

    // Total
    widgets.add(pw.Padding(
      padding: pw.EdgeInsets.all(3),
      child: zText(
        text: item.total.toAmount(),
        fontSize: 9,
        fontWeight: pw.FontWeight.bold,
        textAlign: pw.TextAlign.center,
      ),
    ));

    // Local Amount - only show if needed
    if (showLocalAmount) {
      // Use item's localAmount if available, otherwise calculate
      final localAmountValue = item.localAmount ??
          (item.unitPrice * (exchangeRate ?? item.exchangeRate ?? 1.0));
      widgets.add(pw.Padding(
        padding: pw.EdgeInsets.all(3),
        child: zText(
          text: localAmountValue.toAmount(),
          fontSize: 9,
          textAlign: pw.TextAlign.center,
          fontWeight: pw.FontWeight.bold,
          color: pw.PdfColors.blue700,
        ),
      ));
    }

    // Unit Price
    widgets.add(pw.Padding(
      padding: pw.EdgeInsets.all(3),
      child: zText(
        text: item.unitPrice.toAmount(),
        fontSize: 9,
        textAlign: pw.TextAlign.center,
      ),
    ));

    // Batch
    widgets.add(pw.Padding(
      padding: pw.EdgeInsets.all(3),
      child: zText(
        text: item.batch.toString(),
        fontSize: 9,
        textAlign: pw.TextAlign.center,
      ),
    ));

    // Quantity
    widgets.add(pw.Padding(
      padding: pw.EdgeInsets.all(3),
      child: zText(
        text: item.quantity.toString(),
        fontSize: 9,
        textAlign: pw.TextAlign.center,
      ),
    ));

    // Description
    widgets.add(pw.Padding(
      padding: pw.EdgeInsets.symmetric(horizontal: 5),
      child: zText(
        text: item.productName,
        fontSize: 9,
        textAlign: pw.TextAlign.right,
      ),
    ));

    // Number
    widgets.add(pw.Padding(
      padding: pw.EdgeInsets.all(3),
      child: zText(
        text: (index + 1).toString(),
        fontSize: 9,
        textAlign: pw.TextAlign.center,
      ),
    ));

    return widgets;
  }

  pw.Widget _paymentSummary({
    required String language,
    required double grandTotal,
    required double cashPayment,
    required double creditAmount,
    required AccountsModel? account,
    String? currency,  // This is the account/supplier currency
    required bool isSale,
    required List<InvoiceItem> items,
    double? totalLocalAmount,
    String? localCurrency,
    String? baseCurrency,  // Add this parameter for the company base currency
    double? exchangeRate,  // Add this to show exchange rate
  }) {
    final totalQty = items.fold<double>(0, (sum, item) => sum + item.quantity);
    final lang = NumberToWords.getLanguageFromLocale(Locale(language));

    final cleanAmount = grandTotal.toString().replaceAll(',', '');
    final parsedAmount = int.tryParse(
      double.tryParse(cleanAmount)?.toStringAsFixed(0) ?? "0",
    ) ?? 0;
    final amountInWords = NumberToWords.convert(parsedAmount, lang);

    // Check if we need to show local amount (different currencies)
    final needsConversion = !isSale &&
        localCurrency != null &&
        baseCurrency != null &&
        baseCurrency != localCurrency &&
        exchangeRate != null;

    final showLocalSummary = needsConversion;

    return pw.Container(
      width: 350,
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

                // Grand Total (in base currency)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    zText(
                      text: tr(text: 'grandTotal', tr: language),
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                    ),
                    zText(
                      text: "${grandTotal.toAmount()} $baseCurrency",
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                      color: pw.PdfColors.blue700,
                    ),
                  ],
                ),

                // Exchange Rate Info (if currencies are different)
                if (needsConversion) ...[
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      zText(
                        text: tr(text: 'exchangeRate', tr: language),
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                      ),
                      zText(
                        text: "1 $baseCurrency = ${exchangeRate.toStringAsFixed(4)} $localCurrency",
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        color: pw.PdfColors.orange700,
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 5),
                ],

                // Total Local Amount (in supplier's currency)
                if (showLocalSummary) ...[
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      zText(
                        text: tr(text: 'total', tr: language),
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                      zText(
                        text: "${totalLocalAmount?.toAmount() ?? '0.00'} $localCurrency",
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: pw.PdfColors.purple700,
                      ),
                    ],
                  ),
                ],

                pw.SizedBox(height: 3),

                // Total Quantity
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    zText(
                      text: tr(text: 'totalQty', tr: language),
                      fontSize: 10,
                    ),
                    zText(
                      text: totalQty.toStringAsFixed(0),
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ],
                ),

                pw.SizedBox(height: 3),

                // Cash Payment (if any) - in base currency
                if (cashPayment > 0)
                  _buildPaymentRow(
                    label: tr(text: 'cashPayment', tr: language),
                    value: cashPayment,
                    ccy: baseCurrency ?? '',
                  ),

                // Account Balance Information - ONLY show when credit is used AND account exists
                if (account != null && creditAmount > 0) ...[
                  pw.SizedBox(height: 3),

                  // Account Info
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      zText(
                          text: "${account.accNumber} | ${account.accName}",
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 3),

                  // Previous Balance (in account currency)
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      zText(
                        text: tr(text: 'previousAccBalance', tr: language),
                        fontSize: 10,
                      ),
                      zText(
                        text: "${_getAccountBalance(account).toAmount()} ${account.actCurrency ?? localCurrency ?? baseCurrency}",
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: _getBalanceColor(_getAccountBalance(account)),
                      ),
                    ],
                  ),

                  // Current Transaction (in account currency)
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      zText(
                        text: isSale
                            ? tr(text: 'saleAmount', tr: language)
                            : tr(text: 'dueAmount', tr: language),
                        fontSize: 10,
                      ),
                      zText(
                        text: "${creditAmount.toAmount()} ${account.actCurrency ?? localCurrency ?? baseCurrency}",
                        fontSize: 10,
                        color: isSale ? pw.PdfColors.red : pw.PdfColors.green,
                      ),
                    ],
                  ),

                  // New Balance Calculation (in account currency)
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      zText(
                        text: tr(text: 'newBalance', tr: language),
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                      zText(
                        text: isSale
                            ? "${(_getAccountBalance(account) - creditAmount).toAmount()} ${account.actCurrency ?? localCurrency ?? baseCurrency}"
                            : "${(_getAccountBalance(account) + creditAmount).toAmount()} ${account.actCurrency ?? localCurrency ?? baseCurrency}",
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: isSale
                            ? _getBalanceColor(_getAccountBalance(account) - creditAmount)
                            : _getBalanceColor(_getAccountBalance(account) + creditAmount),
                      ),
                    ],
                  ),

                  // Status
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      zText(
                        text: tr(text: 'status', tr: language),
                        fontSize: 9,
                      ),
                      zText(
                        text: isSale
                            ? _getBalanceStatus(_getAccountBalance(account) - creditAmount, language)
                            : _getBalanceStatus(_getAccountBalance(account) + creditAmount, language),
                        fontSize: 9,
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

          // Amount in words (in base currency)
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
                  text: amountInWords.isNotEmpty ? "$amountInWords $baseCurrency" : "",
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