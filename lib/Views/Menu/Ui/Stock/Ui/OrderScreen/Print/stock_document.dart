import 'dart:async';
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

    document.addPage(
      pw.Page(
        margin: pw.EdgeInsets.all(25),
        pageFormat: pageFormat,
        textDirection: documentLanguage(language: language),
        orientation: orientation,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
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
      padding: pw.EdgeInsets.symmetric(horizontal: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Row(
            children: [
              zText(
                text: "$title:",
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: pw.PdfColors.grey800,
              ),
              pw.SizedBox(width: 8),
              zText(
                text: customerSupplierName,
                fontSize: 12,
                fontWeight: pw.FontWeight.normal,
              ),
            ],
          ),
          pw.Spacer(),
          pw.SizedBox(width: 5),
          // Total Quantity Row
          pw.Container(
            padding: pw.EdgeInsets.symmetric(horizontal: 5),
            child: pw.Row(
              mainAxisAlignment: isRtl ? pw.MainAxisAlignment.start : pw.MainAxisAlignment.end,
              children: [
                zText(
                  text: "${tr(text: 'totalBox', tr: language)}:",
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
                pw.SizedBox(width: 8),
                zText(
                  text: totalQuantity.toStringAsFixed(0),
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                ),
              ],
            ),
          ),
          pw.SizedBox(width: 5),
          zText(
            text: tr(text: "invoiceDate", tr: language),
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
          ),
          pw.SizedBox(width: 5),
          zText(
            text: com.statementDate.toFormattedDate(),
            fontSize: 9,
            fontWeight: pw.FontWeight.normal,
          ),
          pw.SizedBox(width: 10),
          zText(
            text: "${tr(text: 'documentNumber', tr: language)}: $documentNumber",
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
          ),
          pw.SizedBox(width: 20),
        ],
      ),
    );
  }

// ==================== STOCK ITEMS TABLE ====================
  pw.Widget _stockItemsTable({
    required List<StockDocumentItem> items,
    required String language,
  }) {
    final isRtl = language == 'fa' || language == 'ar';

    // Adjusted column widths for larger fonts
    const numberWidth = 20.0;
    const descriptionWidth = 130.0;
    const qtyWidth = 35.0;
    const batchWidth = 35.0;
    const totalWidth = 40.0;  // New column for total
    const unitWidth = 30.0;
    const storageWidth = 60.0;

    final Map<int, pw.TableColumnWidth> columnWidths;
    final List<String> headers;

    if (isRtl) {
      columnWidths = {
        0: pw.FixedColumnWidth(storageWidth),
        1: pw.FixedColumnWidth(unitWidth),
        2: pw.FixedColumnWidth(totalWidth),  // Total column
        3: pw.FixedColumnWidth(batchWidth),
        4: pw.FixedColumnWidth(qtyWidth),
        5: pw.FixedColumnWidth(descriptionWidth),
        6: pw.FixedColumnWidth(numberWidth),
      };
      headers = [
        tr(text: 'storage', tr: language),
        tr(text: 'unit', tr: language),
        tr(text: 'total', tr: language),  // Total header
        tr(text: 'packing', tr: language),
        tr(text: 'quantity', tr: language),
        tr(text: 'items', tr: language),
        '#',
      ];
    } else {
      columnWidths = {
        0: pw.FixedColumnWidth(numberWidth),
        1: pw.FixedColumnWidth(descriptionWidth),
        2: pw.FixedColumnWidth(qtyWidth),
        3: pw.FixedColumnWidth(batchWidth),
        4: pw.FixedColumnWidth(totalWidth),  // Total column
        5: pw.FixedColumnWidth(unitWidth),
        6: pw.FixedColumnWidth(storageWidth),
      };
      headers = [
        '#',
        tr(text: 'items', tr: language),
        tr(text: 'quantity', tr: language),
        tr(text: 'packing', tr: language),
        tr(text: 'total', tr: language),  // Total header
        tr(text: 'unit', tr: language),
        tr(text: 'storage', tr: language),
      ];
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
                ? _buildRtlStockRow(items[i], i)
                : _buildLtrStockRow(items[i], i),
          ),
      ],
    );
  }

// ==================== LTR STOCK ROW ====================
  List<pw.Widget> _buildLtrStockRow(StockDocumentItem item, int index) {
    final total = (item.quantity * item.batch).toStringAsFixed(0);

    return [
      // Number
      pw.Container(
        padding: pw.EdgeInsets.symmetric(vertical: 3, horizontal: 4),
        child: zText(
          text: (index + 1).toString(),
          fontSize: 9,
          textAlign: pw.TextAlign.center,
        ),
      ),
      // Description
      pw.Container(
        padding: pw.EdgeInsets.symmetric(vertical: 3, horizontal: 6),
        child: zText(
          text: item.productName,
          textAlign: pw.TextAlign.left,
          fontSize: 9,
          fontWeight: pw.FontWeight.normal,
        ),
      ),
      // Quantity
      pw.Container(
        padding: pw.EdgeInsets.symmetric(vertical: 3, horizontal: 4),
        child: zText(
          text: item.quantity.toStringAsFixed(0),
          fontSize: 9,
          textAlign: pw.TextAlign.center,
        ),
      ),
      // Batch
      pw.Container(
        padding: pw.EdgeInsets.symmetric(vertical: 3, horizontal: 4),
        child: zText(
          text: item.batch.toString(),
          fontSize: 9,
          textAlign: pw.TextAlign.center,
        ),
      ),
      // Total (Qty × Batch)
      pw.Container(
        padding: pw.EdgeInsets.symmetric(vertical: 3, horizontal: 4),
        child: zText(
          text: total,
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
          color: pw.PdfColors.blue700,
          textAlign: pw.TextAlign.center,
        ),
      ),
      // Unit
      pw.Container(
        padding: pw.EdgeInsets.symmetric(vertical: 3, horizontal: 4),
        child: zText(
          text: item.unit,
          fontSize: 9,
          textAlign: pw.TextAlign.center,
        ),
      ),
      // Storage
      pw.Container(
        padding: pw.EdgeInsets.symmetric(vertical: 3, horizontal: 4),
        child: zText(
          text: item.storageName,
          fontSize: 8,
          textAlign: pw.TextAlign.center,
        ),
      ),
    ];
  }

// ==================== RTL STOCK ROW ====================
  List<pw.Widget> _buildRtlStockRow(StockDocumentItem item, int index) {
    final total = (item.quantity * item.batch).toStringAsFixed(0);

    return [
      // Storage
      pw.Container(
        padding: pw.EdgeInsets.symmetric(vertical: 3, horizontal: 4),
        child: zText(
          text: item.storageName,
          fontSize: 8,
          textAlign: pw.TextAlign.center,
        ),
      ),
      // Unit
      pw.Container(
        padding: pw.EdgeInsets.symmetric(vertical: 3, horizontal: 4),
        child: zText(
          text: item.unit,
          fontSize: 9,
          textAlign: pw.TextAlign.center,
        ),
      ),
      // Total (Qty × Batch)
      pw.Container(
        padding: pw.EdgeInsets.symmetric(vertical: 3, horizontal: 4),
        child: zText(
          text: total,
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
          color: pw.PdfColors.blue700,
          textAlign: pw.TextAlign.center,
        ),
      ),
      // Batch
      pw.Container(
        padding: pw.EdgeInsets.symmetric(vertical: 3, horizontal: 4),
        child: zText(
          text: item.batch.toString(),
          fontSize: 9,
          textAlign: pw.TextAlign.center,
        ),
      ),
      // Quantity
      pw.Container(
        padding: pw.EdgeInsets.symmetric(vertical: 3, horizontal: 4),
        child: zText(
          text: item.quantity.toStringAsFixed(0),
          fontSize: 9,
          textAlign: pw.TextAlign.center,
        ),
      ),
      // Description
      pw.Container(
        padding: pw.EdgeInsets.symmetric(vertical: 3, horizontal: 6),
        child: zText(
          text: item.productName,
          fontSize: 9,
          fontWeight: pw.FontWeight.normal,
          textAlign: pw.TextAlign.right,
        ),
      ),
      // Number
      pw.Container(
        padding: pw.EdgeInsets.symmetric(vertical: 3, horizontal: 4),
        child: zText(
          text: (index + 1).toString(),
          fontSize: 9,
          textAlign: pw.TextAlign.center,
        ),
      ),
    ];
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