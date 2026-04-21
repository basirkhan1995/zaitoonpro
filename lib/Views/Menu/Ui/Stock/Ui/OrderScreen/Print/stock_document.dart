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
        margin: pw.EdgeInsets.all(15),
        pageFormat: pageFormat,
        textDirection: documentLanguage(language: language),
        orientation: orientation,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _stockDocumentHeader(
              language: language,
              title: tr(text: title, tr: language),
              documentDate: documentDate,
              reference: reference,
            ),
            _customerInfo(
              language: language,
              documentNumber: documentNumber,
              customerSupplierName: customerSupplierName,
              isSale: isSale,
            ),
            pw.SizedBox(height: 4),
            _stockItemsTable(
              items: items,
              language: language,
            ),
            pw.SizedBox(height: 15),
            _stockFooter(
              language: language,
              totalQuantity: totalQuantity,
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
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                zText(
                  text: title,
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                zText(
                  text: DateTime.now().toDateTime,
                  fontSize: 7,
                  fontWeight: pw.FontWeight.bold,
                ),
                zText(
                  text: DateTime.now().shamsiDateFormatted,
                  fontSize: 8,
                  color: pw.PdfColors.grey800,
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 5),
        if (reference != null && reference.isNotEmpty)
          zText(
            text: "${tr(text: 'referenceNumber', tr: language)}: $reference",
            fontSize: 7,
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
  }) {
    final title = isSale
        ? tr(text: 'customer', tr: language)
        : tr(text: 'supplier', tr: language);

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [

        pw.Row(
          children: [
            zText(
              text: "$title:",
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
              color: pw.PdfColors.grey800,
            ),
            pw.SizedBox(width: 5),
            zText(
              text: customerSupplierName,
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
            ),
          ]
        ),

        zText(
          text: "${tr(text: 'documentNumber', tr: language)}  | $documentNumber",
          fontSize: 7,
        ),
      ],
    );
  }

  // ==================== STOCK ITEMS TABLE ====================
  pw.Widget _stockItemsTable({
    required List<StockDocumentItem> items,
    required String language,
  }) {
    const numberWidth = 25.0;
    const descriptionWidth = 120.0;
    const qtyWidth = 40.0;
    const batchWidth = 45.0;
    const unitWidth = 35.0;
    const storageWidth = 60.0;

    final isRtl = language == 'fa' || language == 'ar';

    final Map<int, pw.TableColumnWidth> columnWidths;
    final List<String> headers;

    if (isRtl) {
      columnWidths = {
        0: pw.FixedColumnWidth(storageWidth),
        1: pw.FixedColumnWidth(unitWidth),
        2: pw.FixedColumnWidth(batchWidth),
        3: pw.FixedColumnWidth(qtyWidth),
        4: pw.FixedColumnWidth(descriptionWidth),
        5: pw.FixedColumnWidth(numberWidth),
      };
      headers = [
        tr(text: 'storage', tr: language),
        tr(text: 'unit', tr: language),
        tr(text: 'packing', tr: language),
        tr(text: 'quantity', tr: language),
        tr(text: 'description', tr: language),
        tr(text: 'number', tr: language),
      ];
    } else {
      columnWidths = {
        0: pw.FixedColumnWidth(numberWidth),
        1: pw.FixedColumnWidth(descriptionWidth),
        2: pw.FixedColumnWidth(qtyWidth),
        3: pw.FixedColumnWidth(batchWidth),
        4: pw.FixedColumnWidth(unitWidth),
        5: pw.FixedColumnWidth(storageWidth),
      };
      headers = [
        tr(text: 'number', tr: language),
        tr(text: 'description', tr: language),
        tr(text: 'quantity', tr: language),
        tr(text: 'packing', tr: language),
        tr(text: 'unit', tr: language),
        tr(text: 'storage', tr: language),
      ];
    }

    return pw.Table(
      border: pw.TableBorder.all(color: pw.PdfColors.grey300, width: 0.5),
      columnWidths: columnWidths,
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: pw.PdfColors.grey100),
          children: headers.map((header) {
            return pw.Padding(
              padding: pw.EdgeInsets.all(2),
              child: zText(
                text: header,
                fontSize: 7,
                fontWeight: pw.FontWeight.bold,
                textAlign: pw.TextAlign.center,
              ),
            );
          }).toList(),
        ),
        for (int i = 0; i < items.length; i++)
          pw.TableRow(
            decoration: i.isOdd ? pw.BoxDecoration(color: pw.PdfColors.grey50) : null,
            children: isRtl
                ? _buildRtlStockRow(items[i], i)
                : _buildLtrStockRow(items[i], i),
          ),
      ],
    );
  }

  // ==================== LTR STOCK ROW ====================
  List<pw.Widget> _buildLtrStockRow(StockDocumentItem item, int index) {
    return [
      pw.Padding(
        padding: pw.EdgeInsets.all(3),
        child: zText(
          text: (index + 1).toString(),
          fontSize: 7,
          textAlign: pw.TextAlign.center,
        ),
      ),
      pw.Padding(
        padding: pw.EdgeInsets.symmetric(horizontal: 3),
        child: zText(
          text: item.productName,
          textAlign: pw.TextAlign.left,
          fontSize: 7,
        ),
      ),
      pw.Padding(
        padding: pw.EdgeInsets.all(3),
        child: zText(
          text: item.quantity.toStringAsFixed(0),
          fontSize: 7,
          textAlign: pw.TextAlign.center,
        ),
      ),
      pw.Padding(
        padding: pw.EdgeInsets.all(3),
        child: zText(
          text: item.batch.toString(),
          fontSize: 7,
          textAlign: pw.TextAlign.center,
        ),
      ),
      pw.Padding(
        padding: pw.EdgeInsets.all(3),
        child: zText(
          text: item.unit,
          fontSize: 7,
          textAlign: pw.TextAlign.center,
        ),
      ),
      pw.Padding(
        padding: pw.EdgeInsets.all(3),
        child: zText(
          text: item.storageName,
          fontSize: 7,
          textAlign: pw.TextAlign.center,
        ),
      ),
    ];
  }

  // ==================== RTL STOCK ROW ====================
  List<pw.Widget> _buildRtlStockRow(StockDocumentItem item, int index) {
    return [
      pw.Padding(
        padding: pw.EdgeInsets.all(2),
        child: zText(
          text: item.storageName,
          fontSize: 7,
          textAlign: pw.TextAlign.center,
        ),
      ),
      pw.Padding(
        padding: pw.EdgeInsets.all(2),
        child: zText(
          text: item.unit,
          fontSize: 7,
          textAlign: pw.TextAlign.center,
        ),
      ),
      pw.Padding(
        padding: pw.EdgeInsets.all(2),
        child: zText(
          text: item.batch.toString(),
          fontSize: 7,
          textAlign: pw.TextAlign.center,
        ),
      ),
      pw.Padding(
        padding: pw.EdgeInsets.all(2),
        child: zText(
          text: item.quantity.toStringAsFixed(0),
          fontSize: 7,
          textAlign: pw.TextAlign.center,
        ),
      ),
      pw.Padding(
        padding: pw.EdgeInsets.symmetric(horizontal: 5),
        child: zText(
          text: item.productName,
          fontSize: 7,
          textAlign: pw.TextAlign.right,
        ),
      ),
      pw.Padding(
        padding: pw.EdgeInsets.all(2),
        child: zText(
          text: (index + 1).toString(),
          fontSize: 7,
          textAlign: pw.TextAlign.center,
        ),
      ),
    ];
  }

  // ==================== STOCK FOOTER WITH SIGNATURES ====================
  pw.Widget _stockFooter({
    required String language,
    required double totalQuantity,
    String? driverName,
    String? executedBy,
    String? authorizedBy,
    required bool isSale,
  }) {
    final isRtl = language == 'fa' || language == 'ar';

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Total Quantity Row
        pw.Row(
          mainAxisAlignment: isRtl ? pw.MainAxisAlignment.end : pw.MainAxisAlignment.start,
          children: [
            zText(
              text: "${tr(text: 'totalBox', tr: language)}:",
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
            ),
            pw.SizedBox(width: 4),
            zText(
              text: totalQuantity.toStringAsFixed(0),
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
              color: pw.PdfColors.blue700,
            ),
          ],
        ),

        pw.Divider(thickness: 0.1),

        // Signature Section - Reduced width for A5 paper
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            // Driver Name
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                zText(
                  text: tr(text: 'driverName', tr: language),
                  fontSize: 7,
                  fontWeight: pw.FontWeight.bold,
                ),
                pw.SizedBox(height: 3),
                pw.Container(
                  width: 70,
                  height: 25,
                  decoration: pw.BoxDecoration(
                    border: pw.Border(bottom: pw.BorderSide(color: pw.PdfColors.grey400, width: 0.5)),
                  ),
                  child: driverName != null && driverName.isNotEmpty
                      ? zText(
                    text: driverName,
                    fontSize: 7,
                  )
                      : null,
                ),
              ],
            ),

            // Executed By
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                zText(
                  text: tr(text: 'executedBy', tr: language),
                  fontSize: 7,
                  fontWeight: pw.FontWeight.bold,
                ),
                pw.SizedBox(height: 3),
                pw.Container(
                  width: 70,
                  height: 25,
                  decoration: pw.BoxDecoration(
                    border: pw.Border(bottom: pw.BorderSide(color: pw.PdfColors.grey400, width: 0.5)),
                  ),
                  child: executedBy != null && executedBy.isNotEmpty
                      ? zText(
                    text: executedBy,
                    fontSize: 7,
                  )
                      : null,
                ),
              ],
            ),

            // Authorized By
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                zText(
                  text: tr(text: 'authorizedBy', tr: language),
                  fontSize: 7,
                  fontWeight: pw.FontWeight.bold,
                ),
                pw.SizedBox(height: 3),
                pw.Container(
                  width: 70,
                  height: 25,
                  decoration: pw.BoxDecoration(
                    border: pw.Border(bottom: pw.BorderSide(color: pw.PdfColors.grey400, width: 0.5)),
                  ),
                  child: authorizedBy != null && authorizedBy.isNotEmpty
                      ? zText(
                    text: authorizedBy,
                    fontSize: 7,
                  )
                      : null,
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}