import 'dart:async';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
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
  String get unit;
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
  final String unit;
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
    required this.unit,
    required this.batch,
    required this.unitPrice,
    required this.total,
    required this.storageName,
    this.purchasePrice,
    this.profit,
    this.localAmount,
    this.localCurrency,
    this.exchangeRate,
  });
}

class PurchaseInvoiceItemForPrint implements InvoiceItem {
  @override
  final String productName;
  @override
  final double quantity;
  @override
  final String unit;
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
    required this.unit,
    required this.batch,
    required this.unitPrice,
    required this.total,
    required this.storageName,
    this.localAmount,
    this.localCurrency,
    this.exchangeRate,
  });
}

class InvoicePrintService extends PrintServices {
  // ==================== CREATE INVOICE ====================
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
    double? exchangeRate,
    double? subtotal,
    double? totalItemDiscount,
    double? generalDiscount,
    double? extraCharges,
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
        exchangeRate: exchangeRate,
        subtotal: subtotal,
        totalItemDiscount: totalItemDiscount,
        generalDiscount: generalDiscount,
        extraCharges: extraCharges,
      );
      await saveDocument(
        suggestedName: "${invoiceType}_$invoiceNumber.pdf",
        pdf: document,
      );
    } catch (e) {
      throw e.toString();
    }
  }

  // ==================== PRINT INVOICE ====================
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
    double? exchangeRate,
    double? subtotal,
    double? totalItemDiscount,
    double? generalDiscount,
    double? extraCharges,
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
        exchangeRate: exchangeRate,
        subtotal: subtotal,
        totalItemDiscount: totalItemDiscount,
        generalDiscount: generalDiscount,
        extraCharges: extraCharges,
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

  // ==================== PREVIEW INVOICE ====================
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
    double? totalLocalAmount,
    String? localCurrency,
    double? exchangeRate,
    double? subtotal,
    double? totalItemDiscount,
    double? generalDiscount,
    double? extraCharges,
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
      totalLocalAmount: totalLocalAmount,
      localCurrency: localCurrency,
      exchangeRate: exchangeRate,
      subtotal: subtotal,
      totalItemDiscount: totalItemDiscount,
      generalDiscount: generalDiscount,
      extraCharges: extraCharges,
    );
  }

  // ==================== GENERATE INVOICE ====================
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
    double? exchangeRate,
    double? subtotal,
    double? totalItemDiscount,
    double? generalDiscount,
    double? extraCharges,
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
            com: company,
            customerSupplierName: customerSupplierName,
            isSale: isSale,
            invoiceType: invoiceType,
            invoiceNumber: invoiceNumber,
            invoiceDate: invoiceDate,
            reference: reference,
          ),

          pw.SizedBox(height: 5),
          _itemsTable(
            items: items,
            language: language,
            baseCurrency: currency,
            localCurrency: localCurrency,
            exchangeRate: exchangeRate,
            report: company
          ),
          pw.SizedBox(height: 10),
          _paymentSummary(
            language: language,
            grandTotal: grandTotal,
            cashPayment: cashPayment,
            creditAmount: creditAmount,
            account: account,
            isSale: isSale,
            items: items,
            totalLocalAmount: totalLocalAmount,
            localCurrency: localCurrency,
            baseCurrency: currency,
            exchangeRate: exchangeRate,
            subtotal: subtotal,
            totalItemDiscount: totalItemDiscount,
            generalDiscount: generalDiscount,
            extraCharges: extraCharges,
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

  // ==================== HEADER WIDGET ====================
  pw.Widget _invoiceHeaderWidget({
    required String language,
    required String invoiceType,
    required String invoiceNumber,
    required DateTime? invoiceDate,
    required String customerSupplierName,
    required bool isSale,
    required ReportModel com,
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
          pw.SizedBox(height: 4),
          pw.Row(
              children: [
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    zText(
                      text: invoiceTitle,
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                    verticalDivider(height: 10, width: 1),
                    pw.Row(
                        children: [
                          zText(
                              text: tr(text: 'invoiceNumber', tr: language),
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold
                          ),
                          zText(
                            text: "$invoiceNumber :",
                            fontSize: 10,
                          ),
                        ]
                    )
                  ],
                ),
                pw.Spacer(),

                pw.Row(
                    children: [
                      zText(
                        text: tr(text: 'addressAndPhone', tr: language),
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                      zText(
                        text: com.partyPhone??"",
                        fontSize: 10,

                      ),
                      verticalDivider(height: 10, width: 1),
                      zText(
                        text: com.partyAddress??"",
                        fontSize: 10,

                      ),
                      verticalDivider(height: 10, width: 1),
                      zText(
                        text: com.partyCity??"",
                        fontSize: 10,

                      ),
                      verticalDivider(height: 10, width: 1),
                      zText(
                        text: com.partyProvince??"",
                        fontSize: 10,

                      ),
                    ]
                ),

              ]
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            children: [
              pw.Expanded(
                child: _customerSupplierInfo(language: language, customerSupplierName: customerSupplierName, isSale: isSale),
              ),

              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  zText(
                    text: DateTime.now().shamsiDateFormatted,
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  verticalDivider(height: 10, width: 1),
                  zText(
                    text: DateTime.now().toDateTime,
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                  ),

                ],
              ),
            ],
          ),

        ],
      ),
    );
  }

  // ==================== CUSTOMER/SUPPLIER INFO ====================
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
            text: "$title :",
            fontSize: 10,
            fontWeight: pw.FontWeight.bold
          ),
          pw.SizedBox(width: 4),
          zText(
            text: customerSupplierName,
            fontSize: 10,
          ),
        ],
      ),
    );
  }

  // ==================== ITEMS TABLE ====================
  pw.Widget _itemsTable({
    required List<InvoiceItem> items,
    required String language,
    String? baseCurrency,
    String? localCurrency,
    double? exchangeRate,
    required ReportModel report,
  }) {
    const numberWidth = 30.0;
    const descriptionWidth = 150.0;
    const qtyWidth = 45.0;
    const unitWidth = 45.0;      // New column for unit
    const totalQtyWidth = 70.0;
    const priceWidth = 60.0;
    const totalWidth = 70.0;
    const batchWidth = 45.0;

    final isRtl = language == 'fa' || language == 'ar';
    final safeLocalCurrency = localCurrency ?? '';
    final safeExchangeRate = exchangeRate ?? 1.0;
    final isWholeSale = report.visible?.isWholeSale ?? false;

    // Show local amount if currencies are different
    final needsConversion = localCurrency != null &&
        baseCurrency != null &&
        baseCurrency != localCurrency &&
        exchangeRate != null;

    final showLocalAmount = needsConversion;

    final Map<int, pw.TableColumnWidth> columnWidths;
    final List<String> headers;

    if (isRtl) {
      if (showLocalAmount) {
        if (isWholeSale) {
          // RTL with local amount + wholesale (show batch & total qty)
          columnWidths = {
            0: pw.FixedColumnWidth(totalWidth),        // Total Local Amount
            1: pw.FixedColumnWidth(priceWidth),        // Local Unit Price
            2: pw.FixedColumnWidth(totalQtyWidth),     // Total Qty
            3: pw.FixedColumnWidth(unitWidth),         // Unit
            4: pw.FixedColumnWidth(batchWidth),        // Packing
            5: pw.FixedColumnWidth(qtyWidth),          // Quantity
            6: pw.FixedColumnWidth(descriptionWidth),  // Description
            7: pw.FixedColumnWidth(numberWidth),       // Number
          };
          headers = [
            tr(text: 'total', tr: language),
            tr(text: 'unitPrice', tr: language),
            tr(text: 'totalQty', tr: language),
            tr(text: 'unit', tr: language),
            tr(text: 'packing', tr: language),
            tr(text: 'quantity', tr: language),
            tr(text: 'description', tr: language),
            tr(text: 'number', tr: language),
          ];
        } else {
          // RTL with local amount + non-wholesale (hide batch & total qty)
          columnWidths = {
            0: pw.FixedColumnWidth(totalWidth),        // Total Local Amount
            1: pw.FixedColumnWidth(priceWidth),        // Local Unit Price
            2: pw.FixedColumnWidth(unitWidth),         // Unit
            3: pw.FixedColumnWidth(qtyWidth),          // Quantity
            4: pw.FixedColumnWidth(descriptionWidth),  // Description
            5: pw.FixedColumnWidth(numberWidth),       // Number
          };
          headers = [
            tr(text: 'total', tr: language),
            tr(text: 'unitPrice', tr: language),
            tr(text: 'unit', tr: language),
            tr(text: 'quantity', tr: language),
            tr(text: 'description', tr: language),
            tr(text: 'number', tr: language),
          ];
        }
      } else {
        if (isWholeSale) {
          // RTL without local amount + wholesale (show batch & total qty)
          columnWidths = {
            0: pw.FixedColumnWidth(totalWidth),        // Total
            1: pw.FixedColumnWidth(priceWidth),        // Unit Price
            2: pw.FixedColumnWidth(totalQtyWidth),     // Total Qty
            3: pw.FixedColumnWidth(unitWidth),         // Unit
            4: pw.FixedColumnWidth(batchWidth),        // Packing
            5: pw.FixedColumnWidth(qtyWidth),          // Quantity
            6: pw.FixedColumnWidth(descriptionWidth),  // Description
            7: pw.FixedColumnWidth(numberWidth),       // Number
          };
          headers = [
            tr(text: 'total', tr: language),
            tr(text: 'unitPrice', tr: language),
            tr(text: 'totalQty', tr: language),
            tr(text: 'unit', tr: language),
            tr(text: 'packing', tr: language),
            tr(text: 'quantity', tr: language),
            tr(text: 'description', tr: language),
            tr(text: 'number', tr: language),
          ];
        } else {
          // RTL without local amount + non-wholesale (hide batch & total qty)
          columnWidths = {
            0: pw.FixedColumnWidth(totalWidth),        // Total
            1: pw.FixedColumnWidth(priceWidth),        // Unit Price
            2: pw.FixedColumnWidth(unitWidth),         // Unit
            3: pw.FixedColumnWidth(qtyWidth),          // Quantity
            4: pw.FixedColumnWidth(descriptionWidth),  // Description
            5: pw.FixedColumnWidth(numberWidth),       // Number
          };
          headers = [
            tr(text: 'total', tr: language),
            tr(text: 'unitPrice', tr: language),
            tr(text: 'unit', tr: language),
            tr(text: 'quantity', tr: language),
            tr(text: 'description', tr: language),
            tr(text: 'number', tr: language),
          ];
        }
      }
    } else {
      // LTR
      if (showLocalAmount) {
        if (isWholeSale) {
          // LTR with local amount + wholesale (show batch & total qty)
          columnWidths = {
            0: pw.FixedColumnWidth(numberWidth),       // Number
            1: pw.FixedColumnWidth(descriptionWidth),  // Description
            2: pw.FixedColumnWidth(qtyWidth),          // Quantity
            3: pw.FixedColumnWidth(batchWidth),        // Packing
            4: pw.FixedColumnWidth(unitWidth),         // Unit
            5: pw.FixedColumnWidth(totalQtyWidth),     // Total Qty
            6: pw.FixedColumnWidth(priceWidth),        // Local Unit Price
            7: pw.FixedColumnWidth(totalWidth),        // Total Local Amount
          };
          headers = [
            tr(text: 'number', tr: language),
            tr(text: 'description', tr: language),
            tr(text: 'quantity', tr: language),
            tr(text: 'packing', tr: language),
            tr(text: 'unit', tr: language),
            tr(text: 'totalQty', tr: language),
            tr(text: 'unitPrice', tr: language),
            tr(text: 'total', tr: language),
          ];
        } else {
          // LTR with local amount + non-wholesale (hide batch & total qty)
          columnWidths = {
            0: pw.FixedColumnWidth(numberWidth),       // Number
            1: pw.FixedColumnWidth(descriptionWidth),  // Description
            2: pw.FixedColumnWidth(qtyWidth),          // Quantity
            3: pw.FixedColumnWidth(unitWidth),         // Unit
            4: pw.FixedColumnWidth(priceWidth),        // Local Unit Price
            5: pw.FixedColumnWidth(totalWidth),        // Total Local Amount
          };
          headers = [
            tr(text: 'number', tr: language),
            tr(text: 'description', tr: language),
            tr(text: 'quantity', tr: language),
            tr(text: 'unit', tr: language),
            tr(text: 'unitPrice', tr: language),
            tr(text: 'total', tr: language),
          ];
        }
      } else {
        if (isWholeSale) {
          // LTR without local amount + wholesale (show batch & total qty)
          columnWidths = {
            0: pw.FixedColumnWidth(numberWidth),       // Number
            1: pw.FixedColumnWidth(descriptionWidth),  // Description
            2: pw.FixedColumnWidth(qtyWidth),          // Quantity
            3: pw.FixedColumnWidth(batchWidth),        // Packing
            4: pw.FixedColumnWidth(unitWidth),         // Unit
            5: pw.FixedColumnWidth(totalQtyWidth),     // Total Qty
            6: pw.FixedColumnWidth(priceWidth),        // Unit Price
            7: pw.FixedColumnWidth(totalWidth),        // Total
          };
          headers = [
            tr(text: 'number', tr: language),
            tr(text: 'description', tr: language),
            tr(text: 'quantity', tr: language),
            tr(text: 'packing', tr: language),
            tr(text: 'unit', tr: language),
            tr(text: 'totalQty', tr: language),
            tr(text: 'unitPrice', tr: language),
            tr(text: 'total', tr: language),
          ];
        } else {
          // LTR without local amount + non-wholesale (hide batch & total qty)
          columnWidths = {
            0: pw.FixedColumnWidth(numberWidth),       // Number
            1: pw.FixedColumnWidth(descriptionWidth),  // Description
            2: pw.FixedColumnWidth(qtyWidth),          // Quantity
            3: pw.FixedColumnWidth(unitWidth),         // Unit
            4: pw.FixedColumnWidth(priceWidth),        // Unit Price
            5: pw.FixedColumnWidth(totalWidth),        // Total
          };
          headers = [
            tr(text: 'number', tr: language),
            tr(text: 'description', tr: language),
            tr(text: 'quantity', tr: language),
            tr(text: 'unit', tr: language),
            tr(text: 'unitPrice', tr: language),
            tr(text: 'total', tr: language),
          ];
        }
      }
    }

    return pw.Table(
      border: pw.TableBorder(
        bottom: pw.BorderSide(color: pw.PdfColors.grey400, width: 1),
        horizontalInside: pw.BorderSide(color: pw.PdfColors.grey400, width: 0.5),
      ),
      columnWidths: columnWidths,
      children: [
        // Header Row
        pw.TableRow(
          verticalAlignment: pw.TableCellVerticalAlignment.middle,
          decoration: pw.BoxDecoration(color: pw.PdfColors.blue50),
          children: headers.map((header) {
            return pw.Padding(
              padding: pw.EdgeInsets.all(4),
              child: zText(
                text: header,
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                textAlign: pw.TextAlign.center,
              ),
            );
          }).toList(),
        ),
        // Data Rows
        for (int i = 0; i < items.length; i++)
          pw.TableRow(
            decoration: i.isOdd ? pw.BoxDecoration(color: pw.PdfColors.grey50) : null,
            verticalAlignment: pw.TableCellVerticalAlignment.middle,
            children: isRtl
                ? _buildRtlRow(items[i], i, showLocalAmount, safeLocalCurrency, safeExchangeRate, report)
                : _buildLtrRow(items[i], i, showLocalAmount, safeLocalCurrency, safeExchangeRate, report),
          ),
        // Bottom Border Row (adds border at bottom of table)
        pw.TableRow(
          children: List.generate(
            headers.length,
                (index) => pw.Container(height: 0),
          ),
        ),
      ],
    );
  }
  // ==================== LTR ROW ====================
  List<pw.Widget> _buildLtrRow(
      InvoiceItem item,
      int index,
      bool showLocalAmount,
      String localCurrency,
      double exchangeRate,
      ReportModel report
      ) {
    final isWholeSale = report.visible?.isWholeSale ?? false;
    final totalQty = (item.quantity * item.batch).toStringAsFixed(0);
    final localUnitPrice = (item.unitPrice * exchangeRate).toAmount();
    final totalLocalAmount = (item.quantity * item.batch * item.unitPrice * exchangeRate).toAmount();

    final widgets = <pw.Widget>[];

    // Number
    widgets.add(pw.Padding(
      padding: pw.EdgeInsets.all(3),
      child: zText(
        text: (index + 1).toString(),
        fontSize: 10,
        textAlign: pw.TextAlign.center,
      ),
    ));

    // Description
    widgets.add(pw.Padding(
      padding: pw.EdgeInsets.symmetric(horizontal: 5),
      child: zText(
        text: item.productName,
        textAlign: pw.TextAlign.left,
        fontSize: 10,
      ),
    ));

    // Quantity
    widgets.add(pw.Padding(
      padding: pw.EdgeInsets.all(3),
      child: zText(
        text: item.quantity.toStringAsFixed(0),
        fontSize: 10,
        textAlign: pw.TextAlign.center,
      ),
    ));

    // Batch (Packing) - Only show if wholesale is enabled
    if (isWholeSale) {
      widgets.add(pw.Padding(
        padding: pw.EdgeInsets.all(3),
        child: zText(
          text: item.batch.toString(),
          fontSize: 10,
          textAlign: pw.TextAlign.center,
        ),
      ));
    }

    // Unit column - shows only the unit (PCS, KG, etc.)
    widgets.add(pw.Padding(
      padding: pw.EdgeInsets.all(3),
      child: zText(
        text: item.unit.isEmpty ? '-' : item.unit,
        fontSize: 10,
        textAlign: pw.TextAlign.center,
      ),
    ));

    // Total Qty column - shows only the number (NO unit)
    if (isWholeSale) {
      widgets.add(pw.Padding(
        padding: pw.EdgeInsets.all(3),
        child: zText(
          text: totalQty,  // Just the number, no unit
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          textAlign: pw.TextAlign.center,
        ),
      ));
    }

    if (showLocalAmount) {
      // Local Unit Price
      widgets.add(pw.Padding(
        padding: pw.EdgeInsets.all(3),
        child: zText(
          text: localUnitPrice,
          fontSize: 10,
          textAlign: pw.TextAlign.center,
        ),
      ));

      // Total Local Amount
      widgets.add(pw.Padding(
        padding: pw.EdgeInsets.all(3),
        child: zText(
          text: totalLocalAmount,
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          textAlign: pw.TextAlign.center,
        ),
      ));
    } else {
      // Unit Price
      widgets.add(pw.Padding(
        padding: pw.EdgeInsets.all(3),
        child: zText(
          text: item.unitPrice.toAmount(),
          fontSize: 10,
          textAlign: pw.TextAlign.center,
        ),
      ));

      // Total
      widgets.add(pw.Padding(
        padding: pw.EdgeInsets.all(3),
        child: zText(
          text: item.total.toAmount(),
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          textAlign: pw.TextAlign.center,
        ),
      ));
    }

    return widgets;
  }

// ==================== RTL ROW ====================
  List<pw.Widget> _buildRtlRow(
      InvoiceItem item,
      int index,
      bool showLocalAmount,
      String localCurrency,
      double exchangeRate,
      ReportModel report,
      ) {
    final isWholeSale = report.visible?.isWholeSale ?? false;
    final totalQty = (item.quantity * item.batch).toStringAsFixed(0);
    final localUnitPrice = (item.unitPrice * exchangeRate).toAmount();
    final totalLocalAmount = (item.quantity * item.batch * item.unitPrice * exchangeRate).toAmount();

    final widgets = <pw.Widget>[];

    if (showLocalAmount) {
      // Total Local Amount (First in RTL)
      widgets.add(pw.Padding(
        padding: pw.EdgeInsets.all(3),
        child: zText(
          text: totalLocalAmount,
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          textAlign: pw.TextAlign.center,
        ),
      ));

      // Local Unit Price
      widgets.add(pw.Padding(
        padding: pw.EdgeInsets.all(3),
        child: zText(
          text: localUnitPrice,
          fontSize: 10,
          textAlign: pw.TextAlign.center,
        ),
      ));
    } else {
      // Total (First in RTL)
      widgets.add(pw.Padding(
        padding: pw.EdgeInsets.all(3),
        child: zText(
          text: item.total.toAmount(),
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          textAlign: pw.TextAlign.center,
        ),
      ));

      // Unit Price
      widgets.add(pw.Padding(
        padding: pw.EdgeInsets.all(3),
        child: zText(
          text: item.unitPrice.toAmount(),
          fontSize: 10,
          textAlign: pw.TextAlign.center,
        ),
      ));
    }

    // Total Qty column - shows only the number (NO unit) - Only show if wholesale is enabled
    if (isWholeSale) {
      widgets.add(pw.Padding(
        padding: pw.EdgeInsets.all(3),
        child: zText(
          text: totalQty,  // Just the number, no unit
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          textAlign: pw.TextAlign.center,
        ),
      ));
    }

    // Unit column - shows only the unit (PCS, KG, etc.)
    widgets.add(pw.Padding(
      padding: pw.EdgeInsets.all(3),
      child: zText(
        text: item.unit.isEmpty ? '-' : item.unit,
        fontSize: 10,
        textAlign: pw.TextAlign.center,
      ),
    ));

    // Batch (Packing) - Only show if wholesale is enabled
    if (isWholeSale) {
      widgets.add(pw.Padding(
        padding: pw.EdgeInsets.all(3),
        child: zText(
          text: item.batch.toString(),
          fontSize: 10,
          textAlign: pw.TextAlign.center,
        ),
      ));
    }

    // Quantity
    widgets.add(pw.Padding(
      padding: pw.EdgeInsets.all(3),
      child: zText(
        text: item.quantity.toStringAsFixed(0),
        fontSize: 10,
        textAlign: pw.TextAlign.center,
      ),
    ));

    // Description
    widgets.add(pw.Padding(
      padding: pw.EdgeInsets.symmetric(horizontal: 5),
      child: zText(
        text: item.productName,
        fontSize: 10,
        textAlign: pw.TextAlign.right,
      ),
    ));

    // Number
    widgets.add(pw.Padding(
      padding: pw.EdgeInsets.all(3),
      child: zText(
        text: (index + 1).toString(),
        fontSize: 10,
        textAlign: pw.TextAlign.center,
      ),
    ));

    return widgets;
  }

  // ==================== PAYMENT SUMMARY ====================
  pw.Widget _paymentSummary({
    required String language,
    required double grandTotal,
    required double cashPayment,
    required double creditAmount,
    required AccountsModel? account,
    required bool isSale,
    required List<InvoiceItem> items,
    double? totalLocalAmount,
    String? localCurrency,
    String? baseCurrency,
    double? exchangeRate,
    double? subtotal,
    double? totalItemDiscount,
    double? generalDiscount,
    double? extraCharges,
  }) {
    bool isRTL(String lang) {
      final code = lang.toLowerCase();
      return code.startsWith('fa') ||
          code.startsWith('ar') ||
          code.startsWith('ps');
    }

    final totalQty = items.fold<double>(0, (sum, item) => sum + item.quantity);

    final lang = NumberToWords.getLanguageFromLocale(Locale(language));

    final safeBaseCurrency = baseCurrency ?? '';
    final safeLocalCurrency = localCurrency ?? '';
    final safeExchangeRate = exchangeRate ?? 1.0;

    final needsConversion = localCurrency != null &&
        baseCurrency != null &&
        baseCurrency != localCurrency &&
        exchangeRate != null &&
        exchangeRate != 1.0;

    final double effectiveSubtotal = subtotal ?? items.fold(0.0, (sum, item) => sum + (item.quantity * item.unitPrice));
    final double effectiveLocalSubtotal = effectiveSubtotal * safeExchangeRate;

    final double totalDiscount = (totalItemDiscount ?? 0.0) + (generalDiscount ?? 0.0);
    final double totalLocalDiscount = totalDiscount * safeExchangeRate;

    final double effectiveExtraCharges = extraCharges ?? 0.0;
    final double effectiveLocaleExtraCharges = effectiveExtraCharges * safeExchangeRate;

    final double finalGrandTotal = effectiveSubtotal - totalDiscount + effectiveExtraCharges;
    final double grandTotalLocal = finalGrandTotal * safeExchangeRate;

    final effectiveCashPayment = (needsConversion && cashPayment > 0) ? cashPayment * safeExchangeRate : cashPayment;
    final effectiveCreditAmount = (needsConversion && creditAmount > 0) ? creditAmount * safeExchangeRate : creditAmount;

    final amountForWords = needsConversion ? (totalLocalAmount ?? finalGrandTotal * safeExchangeRate) : finalGrandTotal;
    final parsedAmount = int.tryParse(double.tryParse(amountForWords.toString())?.toStringAsFixed(0) ?? "0") ?? 0;
    final amountInWords = NumberToWords.convert(parsedAmount, lang);

    String accountCurrency;

    if (needsConversion && safeLocalCurrency.isNotEmpty) {
      accountCurrency = safeLocalCurrency;
    } else if (account != null &&
        account.actCurrency != null &&
        account.actCurrency!.isNotEmpty) {
      accountCurrency = account.actCurrency!;
    } else {
      accountCurrency = safeBaseCurrency;
    }

    final accountBalance = account != null
        ? double.tryParse(account.accAvailBalance ?? "0.0") ?? 0.0
        : 0.0;

    return pw.Container(
      width: 300,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // ===== SUBTOTAL =====
          _buildCompactRow(
            language: language,
            label: tr(text: 'subtotal', tr: language),
            value: needsConversion? effectiveLocalSubtotal : effectiveSubtotal,
            currency: needsConversion ? safeLocalCurrency : safeBaseCurrency,
            fontSize: 11
          ),

          // ===== COMBINED DISCOUNT =====
          if (totalDiscount > 0)
            _buildCompactRow(
              language: language,
              label: tr(text: 'totalDiscount', tr: language),
              value: needsConversion? -totalLocalDiscount : -totalDiscount,
              currency: needsConversion ? safeLocalCurrency : safeBaseCurrency,
              color: pw.PdfColors.red,
              fontSize: 11
            ),

          // ===== EXTRA =====
          if (effectiveExtraCharges > 0)
            _buildCompactRow(
              language: language,
              label: tr(text: 'extraCharges', tr: language),
              value: needsConversion ? effectiveLocaleExtraCharges : effectiveExtraCharges,
              currency: needsConversion ? safeLocalCurrency : safeBaseCurrency,
              color: pw.PdfColors.orange,
              fontSize: 11
            ),

          // ===== GRAND TOTAL =====
          _buildCompactRow(
            language: language,
            label: tr(text: 'grandTotal', tr: language),
            value: needsConversion ? grandTotalLocal : finalGrandTotal,
            currency: needsConversion ? safeLocalCurrency : safeBaseCurrency,
            isBold: true,
            fontSize: 12,
            color: pw.PdfColors.blue700,
          ),


          // ===== PAYMENTS =====
          _buildCompactRow(
            language: language,
            label: tr(text: 'totalQty', tr: language),
            value: totalQty,
            decimalRange: 0,
            currency: '',
            fontSize: 11
          ),

          if (cashPayment > 0)...[
            pw.Divider(color: pw.PdfColors.grey300,height: 9),
            _buildCompactRow(
              language: language,
              label: tr(text: 'cashPayment', tr: language),
              value: effectiveCashPayment,
              currency: needsConversion ? safeLocalCurrency : safeBaseCurrency,
              fontSize: 11
            ),
          ],

          // ===== ACCOUNT =====
          if (account != null && creditAmount > 0) ...[
            pw.Divider(color: pw.PdfColors.grey300,height: 9),
            pw.Row(
              mainAxisAlignment:
              isRTL(language) ? pw.MainAxisAlignment.end : pw.MainAxisAlignment.start,
              children: [
                if (!isRTL(language)) ...[
                  zText(
                    text: tr(text: 'account', tr: language),
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  pw.Spacer(),
                  zText(
                    text: "${account.accNumber} | ${account.accName}",
                    fontSize: 11,
                  ),
                ] else ...[
                  zText(
                    text: tr(text: 'account', tr: language),
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  pw.Spacer(),
                  zText(
                    text: "${account.accNumber} | ${account.accName}",
                    fontSize: 11,
                  ),
                ],
              ],
            ),

            _buildCompactRow(
              language: language,
              label: tr(text: 'previousBalance', tr: language),
              value: accountBalance,
              fontSize: 11,
              currency: accountCurrency,
            ),
            // ===== EXCHANGE =====
            if (needsConversion)
              pw.Row(
                mainAxisAlignment:
                isRTL(language) ? pw.MainAxisAlignment.end : pw.MainAxisAlignment.start,
                children: [
                  if (!isRTL(language)) ...[
                    zText(
                      text: tr(text: 'exchangeRate', tr: language),
                      fontSize: 10,
                    ),
                    pw.Spacer(),
                    zText(
                      text:
                      "1 $safeBaseCurrency = ${safeExchangeRate.toStringAsFixed(4)} $safeLocalCurrency",
                      fontSize: 10,
                    ),
                  ] else ...[
                    zText(
                      text: tr(text: 'exchangeRate', tr: language),
                      fontSize: 10,
                    ),
                    pw.Spacer(),
                    zText(
                      text:
                      "1 $safeBaseCurrency = ${safeExchangeRate.toStringAsFixed(4)} $safeLocalCurrency",
                      fontSize: 10,
                    ),
                  ],
                ],
              ),

            _buildCompactRow(
              language: language,
              label: tr(text: 'invoiceAmount', tr: language),
              value: effectiveCreditAmount,
              currency: accountCurrency,
              color: isSale ? pw.PdfColors.red : pw.PdfColors.orange,
              fontSize: 11
            ),

            _buildCompactRow(
              language: language,
              label: tr(text: 'newBalance', tr: language),
              fontSize: 11,
              value: isSale
                  ? accountBalance - effectiveCreditAmount
                  : accountBalance + effectiveCreditAmount,
              currency: accountCurrency,
              isBold: true,
              color: (isSale
                  ? accountBalance - effectiveCreditAmount
                  : accountBalance + effectiveCreditAmount) <
                  0
                  ? pw.PdfColors.red
                  : pw.PdfColors.green,
            ),
          ],

          pw.Divider(color: pw.PdfColors.grey300,height: 9),

          // ===== AMOUNT IN WORDS =====
          pw.Row(
            mainAxisAlignment:
            isRTL(language) ? pw.MainAxisAlignment.end : pw.MainAxisAlignment.start,
            children: [
              if (!isRTL(language)) ...[
                zText(
                  text: "$amountInWords ${accountCurrency == "USD"? tr(text: 'usd', tr: language) : accountCurrency == "AFN"? tr(text: "afn", tr: language) : accountCurrency}",
                  fontSize: 8,
                  textAlign: pw.TextAlign.right,
                ),
              ] else ...[
                zText(
                  text: "$amountInWords ${accountCurrency == "USD"? tr(text: 'usd', tr: language) : accountCurrency == "AFN"? tr(text: "afn", tr: language) : accountCurrency}",
                  fontSize: 8,
                  textAlign: pw.TextAlign.left,
                )
              ],
            ],
          ),
        ],
      ),
    );
  }

// ==================== COMPACT ROW HELPER ====================
  pw.Widget _buildCompactRow({
    required String label,
    required double value,
    int? decimalRange,
    required String currency,
    required String language,
    bool isBold = false,
    pw.PdfColor? color,
    double fontSize = 9,
  }) {
    final displayValue = value.toAmount(decimal: decimalRange ?? 2);
    final displayCurrency = currency.isEmpty ? '' : ' $currency';

    return pw.Padding(
      padding: pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Row(
        children: [
          // Label - fixed width, left aligned
          pw.Container(
            width: 120,
            child: zText(
              text: label,
              fontSize: fontSize,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          // Space between label and value
          pw.SizedBox(width: 10),
          // Value - right aligned, takes remaining space
          pw.Expanded(
            child: zText(
              text: "$displayValue$displayCurrency",
              fontSize: fontSize,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              textAlign: language == "en"? pw.TextAlign.right : pw.TextAlign. left,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}