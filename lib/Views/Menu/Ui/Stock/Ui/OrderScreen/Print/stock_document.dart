import 'dart:async';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart' as pw;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:zaitoonpro/Features/Date/shamsi_converter.dart';
import 'package:zaitoonpro/Features/PrintSettings/print_services.dart';
import 'package:zaitoonpro/Features/PrintSettings/report_model.dart';

abstract class StockDocumentItem {
  String get productName;
  double get quantity;
  int get batch;
  String get unit;
  String get storageName;
}

class SaleStockItem implements StockDocumentItem {
  @override
  final String productName;
  @override
  final String unit;
  @override
  final double quantity;
  @override
  final int batch;
  @override
  final String storageName;

  SaleStockItem({
    required this.productName,
    required this.unit,
    required this.quantity,
    required this.batch,
    required this.storageName,
  });
}

class StockDocumentPrintService extends PrintServices {

  // ==================== CREATE STOCK DOCUMENT ====================
  Future<void> createStockDocument({
    required String documentType,
    required String documentNumber,
    required String? reference,
    required DateTime? documentDate,
    required String customerSupplierName,
    required List<StockDocumentItem> items,
    required double totalQuantity,
    required String language,
    required pw.PageOrientation orientation,
    required ReportModel company,
    required pw.PdfPageFormat pageFormat,
    String? driverName,
    String? executedBy,
    String? authorizedBy,
  }) async {
    try {
      final document = await generateStockDocument(
        documentType: documentType,
        documentNumber: documentNumber,
        reference: reference,
        documentDate: documentDate,
        customerSupplierName: customerSupplierName,
        items: items,
        totalQuantity: totalQuantity,
        language: language,
        orientation: orientation,
        company: company,
        pageFormat: pageFormat,
        driverName: driverName,
        executedBy: executedBy,
        authorizedBy: authorizedBy,
      );
      await saveDocument(
        suggestedName: "Stock_${documentType}_$documentNumber.pdf",
        pdf: document,
      );
    } catch (e) {
      throw e.toString();
    }
  }

  // ==================== PRINT STOCK DOCUMENT ====================
  Future<void> printStockDocument({
    required String documentType,
    required String documentNumber,
    required String? reference,
    required DateTime? documentDate,
    required String customerSupplierName,
    required List<StockDocumentItem> items,
    required double totalQuantity,
    required String language,
    required pw.PageOrientation orientation,
    required ReportModel company,
    required Printer selectedPrinter,
    required pw.PdfPageFormat pageFormat,
    required int copies,
    String? driverName,
    String? executedBy,
    String? authorizedBy,
  }) async {
    try {
      final document = await generateStockDocument(
        documentType: documentType,
        documentNumber: documentNumber,
        reference: reference,
        documentDate: documentDate,
        customerSupplierName: customerSupplierName,
        items: items,
        totalQuantity: totalQuantity,
        language: language,
        orientation: orientation,
        company: company,
        pageFormat: pageFormat,
        driverName: driverName,
        executedBy: executedBy,
        authorizedBy: authorizedBy,
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

  // ==================== PREVIEW STOCK DOCUMENT ====================
  Future<pw.Document> previewStockDocument({
    required String documentType,
    required String documentNumber,
    required String? reference,
    required DateTime? documentDate,
    required String customerSupplierName,
    required List<StockDocumentItem> items,
    required double totalQuantity,
    required String language,
    required pw.PageOrientation orientation,
    required ReportModel company,
    required pw.PdfPageFormat pageFormat,
    String? driverName,
    String? executedBy,
    String? authorizedBy,
  }) async {
    return generateStockDocument(
      documentType: documentType,
      documentNumber: documentNumber,
      reference: reference,
      documentDate: documentDate,
      customerSupplierName: customerSupplierName,
      items: items,
      totalQuantity: totalQuantity,
      language: language,
      orientation: orientation,
      company: company,
      pageFormat: pageFormat,
      driverName: driverName,
      executedBy: executedBy,
      authorizedBy: authorizedBy,
    );
  }

  // ==================== GENERATE STOCK DOCUMENT ====================

  Future<pw.Document> generateStockDocument({
    required String documentType,
    required String documentNumber,
    required String? reference,
    required DateTime? documentDate,
    required String customerSupplierName,
    required List<StockDocumentItem> items,
    required double totalQuantity,
    required String language,
    required pw.PageOrientation orientation,
    required ReportModel company,
    required pw.PdfPageFormat pageFormat,
    String? driverName,
    String? executedBy,
    String? authorizedBy,
  }) async {
    final document = pw.Document();

    final isSale = documentType.toLowerCase().contains('sale');
    final title = "stockPaper";


    final ByteData imageData = await rootBundle.load('assets/images/zaitoonLogo.png');
    final Uint8List imageBytes = imageData.buffer.asUint8List();
    final pw.MemoryImage logoImage = pw.MemoryImage(imageBytes);

    document.addPage(
      pw.MultiPage(
        maxPages: 1000,  // ✅ Same as invoice
        margin: pw.EdgeInsets.all(25),
        pageFormat: pageFormat,
        textDirection: documentLanguage(language: language),
        orientation: orientation,
        build: (context) => [
          _stockDocumentHeader(
            com: company,
            language: language,
            title: tr(text: title, tr: language),
            documentDate: documentDate,
            reference: reference,
          ),
          _customerInfo(
            com: company,
            language: language,
            totalQuantity: totalQuantity,
            documentNumber: documentNumber,
            customerSupplierName: customerSupplierName,
            isSale: isSale,
          ),
          pw.SizedBox(height: 4),
          _stockItemsTable(
            report: company,
            items: items,
            language: language,
          ),
          pw.SizedBox(height: 8),
          _stockFooter(
            language: language,
            driverName: driverName,
            executedBy: executedBy,
            authorizedBy: authorizedBy,
            isSale: isSale,
          ),
        ],

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
  pw.Widget _stockDocumentHeader({
    required String language,
    required String title,
    required DateTime? documentDate,
    required String? reference,
    required ReportModel com,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            zText(
              text: title,
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                zText(
                  text: DateTime.now().toDateTime,
                  fontSize: 9,
                  fontWeight: pw.FontWeight.normal,
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
      ],
    );
  }

  // ==================== CUSTOMER/SUPPLIER INFO ====================
  pw.Widget _customerInfo({
    required String language,
    required String customerSupplierName,
    required String documentNumber,
    required bool isSale,
    required double totalQuantity,
    required ReportModel com,
  }) {
    final title = isSale
        ? tr(text: 'customer', tr: language)
        : tr(text: 'supplier', tr: language);
    final isRtl = language == 'fa' || language == 'ar';
    return pw.Container(
      padding: pw.EdgeInsets.symmetric(horizontal: 0),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Row(
            children: [
              zText(
                text: "$title:",
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: pw.PdfColors.grey800,
              ),
              pw.SizedBox(width: 3),
              zText(
                text: customerSupplierName,
                fontSize: 9,
                fontWeight: pw.FontWeight.normal,
              ),
            ],
          ),
          pw.Spacer(),
          pw.SizedBox(width: 3),

          // Total Quantity Row
          pw.Container(
            padding: pw.EdgeInsets.symmetric(horizontal: 5),
            child: pw.Row(
              mainAxisAlignment: isRtl ? pw.MainAxisAlignment.start : pw.MainAxisAlignment.end,
              children: [
                zText(
                  text: "${tr(text: 'totalBox', tr: language)}:",
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                ),
                pw.SizedBox(width: 5),
                zText(
                  text: totalQuantity.toStringAsFixed(0),
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                ),
              ],
            ),
          ),
          pw.SizedBox(width: 10),
          zText(
            text: "${tr(text: 'documentNumber', tr: language)}: $documentNumber",
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
          ),
          pw.SizedBox(width: 15),
          zText(
            text: "${tr(text: "invoiceDate", tr: language)}:",
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
          ),
          pw.SizedBox(width: 5),
          zText(
            text: com.statementDate.toFormattedDate(),
            fontSize: 9,
            fontWeight: pw.FontWeight.normal,
          ),
        ],
      ),
    );
  }

  // ==================== STOCK ITEMS TABLE ====================
  pw.Widget _stockItemsTable({
    required List<StockDocumentItem> items,
    required ReportModel report,
    required String language,
  }) {
    final isRtl = language == 'fa' || language == 'ar';
    final isWholeSale = report.visible?.isWholeSale ?? false;

    // Column widths
    const numberWidth = 25.0;
    const descriptionWidth = 130.0;
    const qtyWidth = 40.0;
    const batchWidth = 45.0;
    const totalWidth = 50.0;
    const unitWidth = 35.0;
    const storageWidth = 60.0;

    final Map<int, pw.TableColumnWidth> columnWidths;
    final List<String> headers;

    if (isRtl) {
      if (isWholeSale) {
        // RTL with wholesale - Order: Storage, Unit, Total Qty, Packing, Quantity, Description, #
        columnWidths = {
          0: pw.FixedColumnWidth(storageWidth),      // Storage
          1: pw.FixedColumnWidth(unitWidth),         // Unit
          2: pw.FixedColumnWidth(totalWidth),        // Total Qty
          3: pw.FixedColumnWidth(batchWidth),        // Packing
          4: pw.FixedColumnWidth(qtyWidth),          // Quantity
          5: pw.FixedColumnWidth(descriptionWidth),  // Description
          6: pw.FixedColumnWidth(numberWidth),       // #
        };
        headers = [
          tr(text: 'storage', tr: language),
          tr(text: 'unit', tr: language),
          tr(text: 'totalQty', tr: language),
          tr(text: 'packing', tr: language),
          tr(text: 'quantity', tr: language),
          tr(text: 'items', tr: language),
          '#',
        ];
      } else {
        // RTL without wholesale - Order: Storage, Unit, Quantity, Description, #
        columnWidths = {
          0: pw.FixedColumnWidth(storageWidth),
          1: pw.FixedColumnWidth(unitWidth),
          2: pw.FixedColumnWidth(qtyWidth),
          3: pw.FixedColumnWidth(descriptionWidth),
          4: pw.FixedColumnWidth(numberWidth),
        };
        headers = [
          tr(text: 'storage', tr: language),
          tr(text: 'unit', tr: language),
          tr(text: 'quantity', tr: language),
          tr(text: 'items', tr: language),
          '#',
        ];
      }
    } else {
      if (isWholeSale) {
        // LTR with wholesale - Order: #, Description, Quantity, Packing, Unit, Total Qty, Storage
        columnWidths = {
          0: pw.FixedColumnWidth(numberWidth),       // #
          1: pw.FixedColumnWidth(descriptionWidth),  // Description
          2: pw.FixedColumnWidth(qtyWidth),          // Quantity
          3: pw.FixedColumnWidth(batchWidth),        // Packing
          4: pw.FixedColumnWidth(unitWidth),         // Unit
          5: pw.FixedColumnWidth(totalWidth),        // Total Qty
          6: pw.FixedColumnWidth(storageWidth),      // Storage
        };
        headers = [
          '#',
          tr(text: 'items', tr: language),
          tr(text: 'quantity', tr: language),
          tr(text: 'packing', tr: language),
          tr(text: 'unit', tr: language),
          tr(text: 'totalQty', tr: language),
          tr(text: 'storage', tr: language),
        ];
      } else {
        // LTR without wholesale - Order: #, Description, Quantity, Unit, Storage
        columnWidths = {
          0: pw.FixedColumnWidth(numberWidth),
          1: pw.FixedColumnWidth(descriptionWidth),
          2: pw.FixedColumnWidth(qtyWidth),
          3: pw.FixedColumnWidth(unitWidth),
          4: pw.FixedColumnWidth(storageWidth),
        };
        headers = [
          '#',
          tr(text: 'items', tr: language),
          tr(text: 'quantity', tr: language),
          tr(text: 'unit', tr: language),
          tr(text: 'storage', tr: language),
        ];
      }
    }

    return pw.Table(
      border: pw.TableBorder.all(
        color: pw.PdfColors.grey700,
        width: 0.8,
      ),
      columnWidths: columnWidths,
      children: [
        // Header Row
        pw.TableRow(
          decoration: pw.BoxDecoration(color: pw.PdfColors.grey100),
          children: headers.map((header) {
            return pw.Container(
              padding: pw.EdgeInsets.symmetric(vertical: 3, horizontal: 6),
              child: zText(
                text: header,
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                textAlign: pw.TextAlign.center,
              ),
            );
          }).toList(),
        ),
        // Data Rows
        for (int i = 0; i < items.length; i++)
          pw.TableRow(
            decoration: i.isOdd
                ? pw.BoxDecoration(color: pw.PdfColors.grey50)
                : null,
            children: isRtl
                ? _buildRtlStockRow(items[i], i, isWholeSale)
                : _buildLtrStockRow(items[i], i, isWholeSale),
          ),
      ],
    );
  }

// ==================== LTR STOCK ROW ====================
  List<pw.Widget> _buildLtrStockRow(StockDocumentItem item, int index, bool isWholeSale) {
    final total = (item.quantity * item.batch).toStringAsFixed(0);
    final widgets = <pw.Widget>[];

    // # (Number)
    widgets.add(pw.Container(
      padding: pw.EdgeInsets.symmetric(vertical: 3, horizontal: 4),
      child: zText(
        text: (index + 1).toString(),
        fontSize: 9,
        textAlign: pw.TextAlign.center,
      ),
    ));

    // Description
    widgets.add(pw.Container(
      padding: pw.EdgeInsets.symmetric(vertical: 3, horizontal: 6),
      child: zText(
        text: item.productName,
        textAlign: pw.TextAlign.left,
        fontSize: 12,
        fontWeight: pw.FontWeight.normal,
      ),
    ));

    // Quantity
    widgets.add(pw.Container(
      padding: pw.EdgeInsets.symmetric(vertical: 3, horizontal: 4),
      child: zText(
        text: item.quantity.toStringAsFixed(0),
        fontSize: 10,
        textAlign: pw.TextAlign.center,
      ),
    ));

    if (isWholeSale) {
      // Packing (Batch)
      widgets.add(pw.Container(
        padding: pw.EdgeInsets.symmetric(vertical: 3, horizontal: 4),
        child: zText(
          text: item.batch.toString(),
          fontSize: 10,
          textAlign: pw.TextAlign.center,
        ),
      ));
    }

    // Unit
    widgets.add(pw.Container(
      padding: pw.EdgeInsets.symmetric(vertical: 3, horizontal: 4),
      child: zText(
        text: item.unit,
        fontSize: 10,
        textAlign: pw.TextAlign.center,
      ),
    ));

    if (isWholeSale) {
      // Total Qty (quantity × batch)
      widgets.add(pw.Container(
        padding: pw.EdgeInsets.symmetric(vertical: 3, horizontal: 4),
        child: zText(
          text: total,
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          color: pw.PdfColors.blue700,
          textAlign: pw.TextAlign.center,
        ),
      ));
    }

    // Storage
    widgets.add(pw.Container(
      padding: pw.EdgeInsets.symmetric(vertical: 3, horizontal: 4),
      child: zText(
        text: item.storageName,
        fontSize: 8,
        textAlign: pw.TextAlign.center,
      ),
    ));

    return widgets;
  }

// ==================== RTL STOCK ROW ====================
  List<pw.Widget> _buildRtlStockRow(StockDocumentItem item, int index, bool isWholeSale) {
    final total = (item.quantity * item.batch).toStringAsFixed(0);
    final widgets = <pw.Widget>[];

    // Storage (appears first on right side)
    widgets.add(pw.Container(
      padding: pw.EdgeInsets.symmetric(vertical: 3, horizontal: 4),
      child: zText(
        text: item.storageName,
        fontSize: 8,
        textAlign: pw.TextAlign.center,
      ),
    ));

    // Unit
    widgets.add(pw.Container(
      padding: pw.EdgeInsets.symmetric(vertical: 3, horizontal: 4),
      child: zText(
        text: item.unit,
        fontSize: 10,
        textAlign: pw.TextAlign.center,
      ),
    ));

    if (isWholeSale) {
      // Total Qty (quantity × batch)
      widgets.add(pw.Container(
        padding: pw.EdgeInsets.symmetric(vertical: 3, horizontal: 4),
        child: zText(
          text: total,
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          color: pw.PdfColors.blue700,
          textAlign: pw.TextAlign.center,
        ),
      ));

      // Packing (Batch)
      widgets.add(pw.Container(
        padding: pw.EdgeInsets.symmetric(vertical: 3, horizontal: 4),
        child: zText(
          text: item.batch.toString(),
          fontSize: 10,
          textAlign: pw.TextAlign.center,
        ),
      ));
    }

    // Quantity
    widgets.add(pw.Container(
      padding: pw.EdgeInsets.symmetric(vertical: 3, horizontal: 4),
      child: zText(
        text: item.quantity.toStringAsFixed(0),
        fontSize: 10,
        textAlign: pw.TextAlign.center,
      ),
    ));

    // Description
    widgets.add(pw.Container(
      padding: pw.EdgeInsets.symmetric(vertical: 3, horizontal: 6),
      child: zText(
        text: item.productName,
        fontSize: 12,
        fontWeight: pw.FontWeight.normal,
        textAlign: pw.TextAlign.right,
      ),
    ));

    // # (Number - appears last on left side)
    widgets.add(pw.Container(
      padding: pw.EdgeInsets.symmetric(vertical: 3, horizontal: 4),
      child: zText(
        text: (index + 1).toString(),
        fontSize: 9,
        textAlign: pw.TextAlign.center,
      ),
    ));

    return widgets;
  }
  // ==================== SIMPLIFIED STOCK FOOTER WITH SIGNATURES ====================
  pw.Widget _stockFooter({
    required String language,
    String? driverName,
    String? executedBy,
    String? authorizedBy,
    required bool isSale,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [

        // Simplified Signature Section
        pw.Container(
          padding: pw.EdgeInsets.all(10),

          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [

              // Executed By
              _signatureField(
                label: tr(text: 'executedBy', tr: language),
                value: executedBy,
              ),

              // Authorized By
              _signatureField(
                label: tr(text: 'authorizedBy', tr: language),
                value: authorizedBy,
              ),

              // Driver Name
              _signatureField(
                label: tr(text: 'driverName', tr: language),
                value: driverName,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Helper widget for signature fields
  pw.Widget _signatureField({
    required String label,
    required String? value,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        zText(
          text: label,
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
        ),
        pw.SizedBox(height: 5),
        pw.Container(
          width: 100,
          height: 0,
          alignment: pw.Alignment.center,
          child: (value != null && value.isNotEmpty)
              ? zText(
            text: value,
            fontSize: 10,
            textAlign: pw.TextAlign.center,
          )
              : pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: pw.PdfColors.grey600, width: 0.8),
              ),
            ),
          ),
        ),
      ],
    );
  }
}