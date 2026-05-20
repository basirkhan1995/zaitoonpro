import 'dart:async';
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
    String? remark,
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
        remark: remark,
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
    String? remark,
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
        remark: remark,
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
    String? remark,
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
      remark: remark,
      totalLocalAmount: totalLocalAmount,
      localCurrency: localCurrency,
      exchangeRate: exchangeRate,
      subtotal: subtotal,
      totalItemDiscount: totalItemDiscount,
      generalDiscount: generalDiscount,
      extraCharges: extraCharges,
    );
  }
  bool _shouldShowLocalAmount({
    String? baseCurrency,
    String? localCurrency,
    double? exchangeRate,
  }) {
    return localCurrency != null &&
        baseCurrency != null &&
        baseCurrency != localCurrency &&
        exchangeRate != null;
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
    String? remark,
    double? totalLocalAmount,
    String? localCurrency,
    double? exchangeRate,
    double? subtotal,
    double? totalItemDiscount,
    double? generalDiscount,
    double? extraCharges,
  }) async {
    final document = pw.Document();
    final ByteData imageData = await rootBundle.load('assets/images/zaitoonLogo.png');
    final Uint8List imageBytes = imageData.buffer.asUint8List();
    final pw.MemoryImage logoImage = pw.MemoryImage(imageBytes);

    // Load the first page header (company info only)
    final firstPageHeader = await _firstPageHeader(
      language: language,
      com: company,
      customerSupplierName: customerSupplierName,
      isSale: isSale,
      invoiceType: invoiceType,
      invoiceNumber: invoiceNumber,
      invoiceDate: invoiceDate,
      reference: reference,
      account: account,
    );

    document.addPage(
      pw.MultiPage(
        maxPages: 1000,
        margin: pw.EdgeInsets.symmetric(horizontal: 25, vertical: 15),
        pageFormat: pageFormat,
        textDirection: documentLanguage(language: language),
        orientation: orientation,
        build: (pw.Context context) => [
          firstPageHeader,
          _itemsTableHeader(
            language: language,
            report: company,
            showLocalAmount: _shouldShowLocalAmount(
              baseCurrency: currency,
              localCurrency: localCurrency,
              exchangeRate: exchangeRate,
            ),
          ),
          pw.SizedBox(height: 5),
          ..._buildItemsTableContent(
            items: items,
            language: language,
            baseCurrency: currency,
            localCurrency: localCurrency,
            exchangeRate: exchangeRate,
            report: company,
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
            remark: remark,
            totalLocalAmount: totalLocalAmount,
            localCurrency: localCurrency,
            baseCurrency: currency,
            exchangeRate: exchangeRate,
            subtotal: subtotal,
            totalItemDiscount: totalItemDiscount,
            generalDiscount: generalDiscount,
            extraCharges: extraCharges,
          ),
          pw.Spacer(),
          if (remark != null && remark.isNotEmpty) ...[
            pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  zText(text: tr(text:"note",tr: language),fontSize: 8,color: pw.PdfColors.grey800),
                  pw.SizedBox(width: 5),
                  zText(
                      text: remark,
                      fontSize: 8
                  ),
                ]
            )
          ]
        ],
        header: (pw.Context context) => _pageHeader(
          language: language,
          report: company,
          context: context,
          baseCurrency: currency,
          localCurrency: localCurrency,
          exchangeRate: exchangeRate,
        ),
        footer: (pw.Context context) => footer(
          report: company,
          context: context,
          language: language,
          logoImage: logoImage,
        ),
      ),
    );
    return document;
  }

  Future<pw.Widget> _firstPageHeader({
    required String language,
    required ReportModel com,
    required String customerSupplierName,
    required bool isSale,
    required String invoiceType,
    required String invoiceNumber,
    required DateTime? invoiceDate,
    required String? reference,
    required AccountsModel? account,
  }) async {
    final companyHeader = await header(report: com);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        companyHeader,
        pw.SizedBox(height: 4),
        _invoiceHeaderWidget(
          language: language,
          com: com,
          customerSupplierName: customerSupplierName,
          isSale: isSale,
          invoiceType: invoiceType,
          invoiceNumber: invoiceNumber,
          invoiceDate: invoiceDate,
          reference: reference,
          account: account,
        ),
      ],
    );
  }

  pw.Widget _pageHeader({
    required pw.Context context,
    required String language,
    required ReportModel report,
    String? baseCurrency,
    String? localCurrency,
    double? exchangeRate,
  }) {
    final pageNumber = context.pageNumber;

    if (pageNumber > 1) {
      final needsConversion = localCurrency != null &&
          baseCurrency != null &&
          baseCurrency != localCurrency &&
          exchangeRate != null;
      final showLocalAmount = needsConversion;

      return pw.Column(
        children: [
          pw.SizedBox(height: 5),
          _itemsTableHeader(
            language: language,
            report: report,
            showLocalAmount: showLocalAmount,
          ),
        ],
      );
    }

    // Return empty SizedBox for first page
    return pw.SizedBox();
  }

  pw.Widget _itemsTableHeader({
    required String language,
    required ReportModel report,
    required bool showLocalAmount,
  }) {
    const numberWidth = 30.0;
    const descriptionWidth = 170.0;
    const qtyWidth = 40.0;
    const unitWidth = 30.0;
    const totalQtyWidth = 70.0;
    const priceWidth = 60.0;
    const totalWidth = 70.0;
    const batchWidth = 45.0;
    double headerFontSize = 11;

    final isRtl = language == 'fa' || language == 'ar';
    final isWholeSale = report.visible?.isWholeSale ?? false;

    final Map<int, pw.TableColumnWidth> columnWidths;
    final List<String> headers;

    if (isRtl) {
      if (showLocalAmount) {
        if (isWholeSale) {
          columnWidths = {
            0: pw.FixedColumnWidth(totalWidth),
            1: pw.FixedColumnWidth(priceWidth),
            2: pw.FixedColumnWidth(totalQtyWidth),
            3: pw.FixedColumnWidth(unitWidth),
            4: pw.FixedColumnWidth(batchWidth),
            5: pw.FixedColumnWidth(qtyWidth),
            6: pw.FixedColumnWidth(descriptionWidth),
            7: pw.FixedColumnWidth(numberWidth),
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
          columnWidths = {
            0: pw.FixedColumnWidth(totalWidth),
            1: pw.FixedColumnWidth(priceWidth),
            2: pw.FixedColumnWidth(unitWidth),
            3: pw.FixedColumnWidth(qtyWidth),
            4: pw.FixedColumnWidth(descriptionWidth),
            5: pw.FixedColumnWidth(numberWidth),
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
          columnWidths = {
            0: pw.FixedColumnWidth(totalWidth),
            1: pw.FixedColumnWidth(priceWidth),
            2: pw.FixedColumnWidth(totalQtyWidth),
            3: pw.FixedColumnWidth(unitWidth),
            4: pw.FixedColumnWidth(batchWidth),
            5: pw.FixedColumnWidth(qtyWidth),
            6: pw.FixedColumnWidth(descriptionWidth),
            7: pw.FixedColumnWidth(numberWidth),
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
          columnWidths = {
            0: pw.FixedColumnWidth(totalWidth),
            1: pw.FixedColumnWidth(priceWidth),
            2: pw.FixedColumnWidth(unitWidth),
            3: pw.FixedColumnWidth(qtyWidth),
            4: pw.FixedColumnWidth(descriptionWidth),
            5: pw.FixedColumnWidth(numberWidth),
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
      if (showLocalAmount) {
        if (isWholeSale) {
          columnWidths = {
            0: pw.FixedColumnWidth(numberWidth),
            1: pw.FixedColumnWidth(descriptionWidth),
            2: pw.FixedColumnWidth(qtyWidth),
            3: pw.FixedColumnWidth(batchWidth),
            4: pw.FixedColumnWidth(unitWidth),
            5: pw.FixedColumnWidth(totalQtyWidth),
            6: pw.FixedColumnWidth(priceWidth),
            7: pw.FixedColumnWidth(totalWidth),
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
          columnWidths = {
            0: pw.FixedColumnWidth(numberWidth),
            1: pw.FixedColumnWidth(descriptionWidth),
            2: pw.FixedColumnWidth(qtyWidth),
            3: pw.FixedColumnWidth(unitWidth),
            4: pw.FixedColumnWidth(priceWidth),
            5: pw.FixedColumnWidth(totalWidth),
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
          columnWidths = {
            0: pw.FixedColumnWidth(numberWidth),
            1: pw.FixedColumnWidth(descriptionWidth),
            2: pw.FixedColumnWidth(qtyWidth),
            3: pw.FixedColumnWidth(batchWidth),
            4: pw.FixedColumnWidth(unitWidth),
            5: pw.FixedColumnWidth(totalQtyWidth),
            6: pw.FixedColumnWidth(priceWidth),
            7: pw.FixedColumnWidth(totalWidth),
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
          columnWidths = {
            0: pw.FixedColumnWidth(numberWidth),
            1: pw.FixedColumnWidth(descriptionWidth),
            2: pw.FixedColumnWidth(qtyWidth),
            3: pw.FixedColumnWidth(unitWidth),
            4: pw.FixedColumnWidth(priceWidth),
            5: pw.FixedColumnWidth(totalWidth),
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
        pw.TableRow(
          verticalAlignment: pw.TableCellVerticalAlignment.middle,
          decoration: pw.BoxDecoration(color: pw.PdfColors.blue50),
          children: headers.map((header) {
            return pw.Padding(
              padding: pw.EdgeInsets.all(4),
              child: zText(
                text: header,
                fontSize: headerFontSize,
                fontWeight: pw.FontWeight.bold,
                textAlign: pw.TextAlign.center,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  List<pw.Widget> _buildItemsTableContent({
    required List<InvoiceItem> items,
    required String language,
    String? baseCurrency,
    String? localCurrency,
    double? exchangeRate,
    required ReportModel report,
  }) {
    const numberWidth = 30.0;
    const descriptionWidth = 170.0;
    const qtyWidth = 40.0;
    const unitWidth = 30.0;
    const totalQtyWidth = 70.0;
    const priceWidth = 60.0;
    const totalWidth = 70.0;
    const batchWidth = 45.0;

    final isRtl = language == 'fa' || language == 'ar';
    final safeLocalCurrency = localCurrency ?? '';
    final safeExchangeRate = exchangeRate ?? 1.0;
    final isWholeSale = report.visible?.isWholeSale ?? false;

    final needsConversion = localCurrency != null &&
        baseCurrency != null &&
        baseCurrency != localCurrency &&
        exchangeRate != null;

    final showLocalAmount = needsConversion;

    final Map<int, pw.TableColumnWidth> columnWidths;

    if (isRtl) {
      if (showLocalAmount) {
        if (isWholeSale) {
          columnWidths = {
            0: pw.FixedColumnWidth(totalWidth),
            1: pw.FixedColumnWidth(priceWidth),
            2: pw.FixedColumnWidth(totalQtyWidth),
            3: pw.FixedColumnWidth(unitWidth),
            4: pw.FixedColumnWidth(batchWidth),
            5: pw.FixedColumnWidth(qtyWidth),
            6: pw.FixedColumnWidth(descriptionWidth),
            7: pw.FixedColumnWidth(numberWidth),
          };
        } else {
          columnWidths = {
            0: pw.FixedColumnWidth(totalWidth),
            1: pw.FixedColumnWidth(priceWidth),
            2: pw.FixedColumnWidth(unitWidth),
            3: pw.FixedColumnWidth(qtyWidth),
            4: pw.FixedColumnWidth(descriptionWidth),
            5: pw.FixedColumnWidth(numberWidth),
          };
        }
      } else {
        if (isWholeSale) {
          columnWidths = {
            0: pw.FixedColumnWidth(totalWidth),
            1: pw.FixedColumnWidth(priceWidth),
            2: pw.FixedColumnWidth(totalQtyWidth),
            3: pw.FixedColumnWidth(unitWidth),
            4: pw.FixedColumnWidth(batchWidth),
            5: pw.FixedColumnWidth(qtyWidth),
            6: pw.FixedColumnWidth(descriptionWidth),
            7: pw.FixedColumnWidth(numberWidth),
          };
        } else {
          columnWidths = {
            0: pw.FixedColumnWidth(totalWidth),
            1: pw.FixedColumnWidth(priceWidth),
            2: pw.FixedColumnWidth(unitWidth),
            3: pw.FixedColumnWidth(qtyWidth),
            4: pw.FixedColumnWidth(descriptionWidth),
            5: pw.FixedColumnWidth(numberWidth),
          };
        }
      }
    } else {
      if (showLocalAmount) {
        if (isWholeSale) {
          columnWidths = {
            0: pw.FixedColumnWidth(numberWidth),
            1: pw.FixedColumnWidth(descriptionWidth),
            2: pw.FixedColumnWidth(qtyWidth),
            3: pw.FixedColumnWidth(batchWidth),
            4: pw.FixedColumnWidth(unitWidth),
            5: pw.FixedColumnWidth(totalQtyWidth),
            6: pw.FixedColumnWidth(priceWidth),
            7: pw.FixedColumnWidth(totalWidth),
          };
        } else {
          columnWidths = {
            0: pw.FixedColumnWidth(numberWidth),
            1: pw.FixedColumnWidth(descriptionWidth),
            2: pw.FixedColumnWidth(qtyWidth),
            3: pw.FixedColumnWidth(unitWidth),
            4: pw.FixedColumnWidth(priceWidth),
            5: pw.FixedColumnWidth(totalWidth),
          };
        }
      } else {
        if (isWholeSale) {
          columnWidths = {
            0: pw.FixedColumnWidth(numberWidth),
            1: pw.FixedColumnWidth(descriptionWidth),
            2: pw.FixedColumnWidth(qtyWidth),
            3: pw.FixedColumnWidth(batchWidth),
            4: pw.FixedColumnWidth(unitWidth),
            5: pw.FixedColumnWidth(totalQtyWidth),
            6: pw.FixedColumnWidth(priceWidth),
            7: pw.FixedColumnWidth(totalWidth),
          };
        } else {
          columnWidths = {
            0: pw.FixedColumnWidth(numberWidth),
            1: pw.FixedColumnWidth(descriptionWidth),
            2: pw.FixedColumnWidth(qtyWidth),
            3: pw.FixedColumnWidth(unitWidth),
            4: pw.FixedColumnWidth(priceWidth),
            5: pw.FixedColumnWidth(totalWidth),
          };
        }
      }
    }

    return [
      pw.Table(
        border: pw.TableBorder(
          bottom: pw.BorderSide(color: pw.PdfColors.grey400, width: 1),
          horizontalInside: pw.BorderSide(color: pw.PdfColors.grey400, width: 0.5),
        ),
        columnWidths: columnWidths,
        children: [
          // Data Rows only (no header row here)
          for (int i = 0; i < items.length; i++)
            pw.TableRow(
              decoration: i.isOdd ? pw.BoxDecoration(color: pw.PdfColors.grey50) : null,
              verticalAlignment: pw.TableCellVerticalAlignment.middle,
              children: isRtl
                  ? _buildRtlRow(items[i], i, showLocalAmount, safeLocalCurrency, safeExchangeRate, report)
                  : _buildLtrRow(items[i], i, showLocalAmount, safeLocalCurrency, safeExchangeRate, report),
            ),
          // Bottom Border Row
          pw.TableRow(
            children: List.generate(
              columnWidths.length,
                  (index) => pw.Container(height: 0),
            ),
          ),
        ],
      ),
    ];
  }
  List<pw.Widget> _buildAddressPhoneItems(ReportModel com) {
    final List<pw.Widget> items = [];

    if (com.partyPhone?.isNotEmpty == true) {
      items.add(verticalDivider(height: 10, width: 1));
      items.add(zText(text: com.partyPhone!, fontSize: 10));
    }

    if (com.partyAddress?.isNotEmpty == true) {
      items.add(verticalDivider(height: 10, width: 1));
      items.add(zText(text: com.partyAddress!, fontSize: 10));
    }

    if (com.partyCity?.isNotEmpty == true) {
      items.add(verticalDivider(height: 10, width: 1));
      items.add(zText(text: com.partyCity!, fontSize: 10));
    }

    if (com.partyProvince?.isNotEmpty == true) {
      items.add(verticalDivider(height: 10, width: 1));
      items.add(zText(text: com.partyProvince!, fontSize: 10));
    }

    return items;
  }

  bool _hasAnyAddressPhoneInfo(ReportModel com) {
    return (com.partyPhone?.isNotEmpty == true) ||
        (com.partyAddress?.isNotEmpty == true) ||
        (com.partyCity?.isNotEmpty == true) ||
        (com.partyProvince?.isNotEmpty == true);
  }

  pw.Widget _invoiceHeaderWidget({
    required String language,
    required String invoiceType,
    required String invoiceNumber,
    required DateTime? invoiceDate,
    required String customerSupplierName,
    required bool isSale,
    required ReportModel com,
    required String? reference,
    required AccountsModel? account,
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
                            text: invoiceNumber,
                            fontSize: 10,
                          ),
                        ]
                    )
                  ],
                ),
                pw.Spacer(),
                if (_hasAnyAddressPhoneInfo(com))
                  pw.Row(
                    children: [
                      zText(
                        text: tr(text: 'addressAndPhone', tr: language),
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                      ..._buildAddressPhoneItems(com),
                    ],
                  ),
              ]
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            children: [
              pw.Expanded(
                child: _customerSupplierInfo(
                  language: language,
                  customerSupplierName: customerSupplierName,
                  isSale: isSale,
                  account: account,
                ),
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

  pw.Widget _customerSupplierInfo({
    required String language,
    required String customerSupplierName,
    required bool isSale,
    required AccountsModel? account,
  }) {
    final title = isSale
        ? tr(text: 'customer', tr: language)
        : tr(text: 'supplier', tr: language);

    String accountInfo = '';
    if (account != null && account.accNumber != null && account.accName?.isNotEmpty == true) {
      accountInfo = "${account.accName}";
    }

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
          if (accountInfo.isNotEmpty) ...[
            verticalDivider(height: 8, width: 1),
            zText(
              text: accountInfo,
              fontSize: 10,
              color: pw.PdfColors.grey600,
            ),
          ],
        ],
      ),
    );
  }

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
    final localUnitPrice = (item.unitPrice * exchangeRate).toAmount(decimal: 4);
    final totalLocalAmount = (item.quantity * item.batch * item.unitPrice * exchangeRate).toAmount(decimal: 4);

    final widgets = <pw.Widget>[];

    widgets.add(pw.Padding(
      padding: pw.EdgeInsets.all(3),
      child: zText(
        text: (index + 1).toString(),
        fontSize: 10,
        textAlign: pw.TextAlign.center,
      ),
    ));

    widgets.add(pw.Padding(
      padding: pw.EdgeInsets.symmetric(horizontal: 5),
      child: zText(
        text: item.productName,
        textAlign: pw.TextAlign.left,
        fontSize: 12,
      ),
    ));

    widgets.add(pw.Padding(
      padding: pw.EdgeInsets.all(3),
      child: zText(
        text: item.quantity.toStringAsFixed(0),
        fontSize: 10,
        textAlign: pw.TextAlign.center,
      ),
    ));

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

    widgets.add(pw.Padding(
      padding: pw.EdgeInsets.all(3),
      child: zText(
        text: item.unit.isEmpty ? '-' : item.unit,
        fontSize: 10,
        textAlign: pw.TextAlign.center,
      ),
    ));

    if (isWholeSale) {
      widgets.add(pw.Padding(
        padding: pw.EdgeInsets.all(3),
        child: zText(
          text: totalQty,
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          textAlign: pw.TextAlign.center,
        ),
      ));
    }

    if (showLocalAmount) {
      widgets.add(pw.Padding(
        padding: pw.EdgeInsets.all(3),
        child: zText(
          text: localUnitPrice,
          fontSize: 10,
          textAlign: pw.TextAlign.center,
        ),
      ));

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
      widgets.add(pw.Padding(
        padding: pw.EdgeInsets.all(3),
        child: zText(
          text: item.unitPrice.toAmount(decimal: 4),
          fontSize: 10,
          textAlign: pw.TextAlign.center,
        ),
      ));

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
    final localUnitPrice = (item.unitPrice * exchangeRate).toAmount(decimal: 4);
    final totalLocalAmount = (item.quantity * item.batch * item.unitPrice * exchangeRate).toAmount(decimal: 4);

    final widgets = <pw.Widget>[];

    if (showLocalAmount) {
      widgets.add(pw.Padding(
        padding: pw.EdgeInsets.all(3),
        child: zText(
          text: totalLocalAmount,
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          textAlign: pw.TextAlign.center,
        ),
      ));

      widgets.add(pw.Padding(
        padding: pw.EdgeInsets.all(3),
        child: zText(
          text: localUnitPrice,
          fontSize: 10,
          textAlign: pw.TextAlign.center,
        ),
      ));
    } else {
      widgets.add(pw.Padding(
        padding: pw.EdgeInsets.all(3),
        child: zText(
          text: item.total.toAmount(),
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          textAlign: pw.TextAlign.center,
        ),
      ));

      widgets.add(pw.Padding(
        padding: pw.EdgeInsets.all(3),
        child: zText(
          text: item.unitPrice.toAmount(decimal: 4),
          fontSize: 10,
          textAlign: pw.TextAlign.center,
        ),
      ));
    }

    if (isWholeSale) {
      widgets.add(pw.Padding(
        padding: pw.EdgeInsets.all(3),
        child: zText(
          text: totalQty,
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          textAlign: pw.TextAlign.center,
        ),
      ));
    }

    widgets.add(pw.Padding(
      padding: pw.EdgeInsets.all(3),
      child: zText(
        text: item.unit.isEmpty ? '-' : item.unit,
        fontSize: 10,
        textAlign: pw.TextAlign.center,
      ),
    ));

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

    widgets.add(pw.Padding(
      padding: pw.EdgeInsets.all(3),
      child: zText(
        text: item.quantity.toStringAsFixed(0),
        fontSize: 10,
        textAlign: pw.TextAlign.center,
      ),
    ));

    widgets.add(pw.Padding(
      padding: pw.EdgeInsets.symmetric(horizontal: 5),
      child: zText(
        text: item.productName,
        fontSize: 12,
        textAlign: pw.TextAlign.right,
      ),
    ));

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

  pw.Widget _paymentSummary({
    required String language,
    required double grandTotal,
    required double cashPayment,
    required double creditAmount,
    required AccountsModel? account,
    required bool isSale,
    required List<InvoiceItem> items,
    String? remark,
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

    final double effectiveSubtotal = subtotal ?? items.fold(0.0, (sum, item) => sum + ((item.quantity * item.batch) * item.unitPrice));
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

    String accCcy;

    if (needsConversion && safeLocalCurrency.isNotEmpty) {
      accCcy = safeLocalCurrency;
    } else if (account != null &&
        account.actCurrency != null &&
        account.actCurrency!.isNotEmpty) {
      accCcy = account.actCurrency!;
    } else {
      accCcy = safeBaseCurrency;
    }

    final accountBalance = account != null
        ? double.tryParse(account.accAvailBalance ?? "0.0") ?? 0.0
        : 0.0;

    return pw.Container(
      width: 300,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          if(finalGrandTotal != effectiveSubtotal)...[
            _buildCompactRow(
                language: language,
                label: tr(text: 'subtotal', tr: language),
                value: needsConversion? effectiveLocalSubtotal : effectiveSubtotal,
                currency: needsConversion ? safeLocalCurrency : safeBaseCurrency,
                fontSize: 11
            ),
          ],
          if (totalDiscount > 0)
            _buildCompactRow(
                language: language,
                label: tr(text: 'totalDiscount', tr: language),
                value: needsConversion? -totalLocalDiscount : -totalDiscount,
                currency: needsConversion ? safeLocalCurrency : safeBaseCurrency,
                color: pw.PdfColors.red,
                fontSize: 11
            ),
          if (effectiveExtraCharges > 0)
            _buildCompactRow(
                language: language,
                label: tr(text: 'extraCharges', tr: language),
                value: needsConversion ? effectiveLocaleExtraCharges : effectiveExtraCharges,
                currency: needsConversion ? safeLocalCurrency : safeBaseCurrency,
                color: pw.PdfColors.orange,
                fontSize: 11
            ),
          if (cashPayment > 0)...[
            _buildCompactRow(
                language: language,
                label: tr(text: 'cashReceipt', tr: language),
                value: effectiveCashPayment,
                currency: needsConversion ? safeLocalCurrency : safeBaseCurrency,
                fontSize: 11
            ),
          ],
          _buildGrandTotalCompact(
            label: tr(text: 'grandTotal', tr: language),
            value: needsConversion ? grandTotalLocal : finalGrandTotal,
            currency: needsConversion ? safeLocalCurrency : safeBaseCurrency,
            language: language,
            color: pw.PdfColors.blue700,
          ),
          pw.SizedBox(height: 3),
          _buildCompactRow(
              language: language,
              label: tr(text: 'totalQty', tr: language),
              value: totalQty,
              decimalRange: 0,
              currency: '',
              fontSize: 11
          ),
          if (account != null && creditAmount > 0) ...[
            _buildCompactRow(
              language: language,
              label: tr(text: 'previousBalance', tr: language),
              value: accountBalance,
              fontSize: 11,
              currency: accCcy,
            ),
            if (needsConversion)
              pw.Padding(
                padding: pw.EdgeInsets.symmetric(horizontal: 5),
                child: pw.Row(
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
                        text: "1 ${_getLocalizedCurrency(safeBaseCurrency, language)} = ${safeExchangeRate.toStringAsFixed(4)} ${_getLocalizedCurrency(safeLocalCurrency, language)}",
                        fontSize: 10,
                      ),
                    ] else ...[
                      zText(
                        text: tr(text: 'exchangeRate', tr: language),
                        fontSize: 10,
                      ),
                      pw.Spacer(),
                      zText(
                        text: "1 ${_getLocalizedCurrency(safeBaseCurrency, language)} = ${safeExchangeRate.toStringAsFixed(4)} ${_getLocalizedCurrency(safeLocalCurrency, language)}",
                        fontSize: 10,
                      ),
                    ],
                  ],
                ),
              ),
            _buildCompactRow(
                language: language,
                label: tr(text: 'invoiceAmount', tr: language),
                value: effectiveCreditAmount,
                currency: accCcy,
                color: isSale ? pw.PdfColors.red : pw.PdfColors.orange,
                fontSize: 11
            ),
            _buildGrandTotalRow(
              label: tr(text: 'newBalance', tr: language),
              value: isSale
                  ? accountBalance - effectiveCreditAmount
                  : accountBalance + effectiveCreditAmount,
              currency: accCcy,
              language: language,
            ),
          ],
          pw.SizedBox(height: 3),

          pw.Row(
            mainAxisAlignment:
            pw.MainAxisAlignment.start,
            children: [
              zText(text: tr(text:"amountInWords",tr: language),fontSize: 8,color: pw.PdfColors.grey800),
              verticalDivider(height: 10, width: 1),
              zText(
                text: "$amountInWords ${accCcy == "USD"? tr(text: 'usd', tr: language) : accCcy == "AFN"? tr(text: "afn", tr: language) : accCcy == "CNY"? tr(text: "cny", tr: language) : accCcy}",
                fontSize: 8,
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildGrandTotalCompact({
    required String label,
    required double value,
    required String currency,
    required String language,
    int decimalRange = 2,
    pw.PdfColor color = pw.PdfColors.blue700,
  }) {
    final displayValue = value.toAmount(decimal: decimalRange);
    final localizedCurrency = _getLocalizedCurrency(currency, language);
    final displayCurrency = currency.isEmpty ? '' : ' $localizedCurrency';

    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 3),
      padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 5),
      decoration: pw.BoxDecoration(
        color: pw.PdfColor.fromInt(0xFFE3F2FD),
        borderRadius: pw.BorderRadius.circular(1),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: zText(
              text: label,
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          zText(
            text: "$displayValue$displayCurrency",
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            textAlign: language == "en"
                ? pw.TextAlign.right
                : pw.TextAlign.left,
            color: color,
          ),
        ],
      ),
    );
  }

  pw.Widget _buildGrandTotalRow({
    required String label,
    required double value,
    required String currency,
    required String language,
    int decimalRange = 2,
  }) {
    final displayValue = value.toAmount(decimal: decimalRange);
    final localizedCurrency = _getLocalizedCurrency(currency, language);
    final displayCurrency = currency.isEmpty ? '' : ' $localizedCurrency';

    final isNegative = value < 0;

    final bgColor = isNegative
        ? pw.PdfColor.fromInt(0xFFFFEBEE)
        : pw.PdfColor.fromInt(0xFFE8F5E9);

    final textColor = isNegative
        ? pw.PdfColors.red
        : pw.PdfColors.green;

    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 3),
      padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 5),
      decoration: pw.BoxDecoration(
        color: bgColor,
        borderRadius: pw.BorderRadius.circular(1),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: zText(
              text: label,
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          zText(
            text: "$displayValue$displayCurrency",
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            textAlign: language == "en"
                ? pw.TextAlign.right
                : pw.TextAlign.left,
            color: textColor,
          ),
        ],
      ),
    );
  }

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
    final localizedCurrency = _getLocalizedCurrency(currency, language);
    final displayCurrency = currency.isEmpty ? '' : ' $localizedCurrency';

    return pw.Padding(
      padding: pw.EdgeInsets.symmetric(vertical: 1, horizontal: 5),
      child: pw.Row(
        children: [
          pw.Container(
            width: 120,
            child: zText(
              text: label,
              fontSize: fontSize,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.SizedBox(width: 10),
          pw.Expanded(
            child: zText(
              text: "$displayValue$displayCurrency",
              fontSize: fontSize,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              textAlign: language == "en" ? pw.TextAlign.right : pw.TextAlign.left,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _getLocalizedCurrency(String currencyCode, String language) {
    if (language == 'en') {
      return currencyCode;
    }

    switch (currencyCode.toUpperCase()) {
      case 'USD':
        return 'دالر';
      case 'AFN':
        return 'افغانی';
      case 'EUR':
      case 'EURO':
        return 'یورو';
      default:
        return currencyCode;
    }
  }
}