import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart' as pw;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:zaitoonpro/Features/Date/shamsi_converter.dart';
import 'package:zaitoonpro/Features/Other/extensions.dart';
import '../../../../../../../../Features/PrintSettings/PaperSize/paper_size.dart';
import '../../../../../../../../Features/PrintSettings/print_services.dart';
import '../../../../../../../../Features/PrintSettings/report_model.dart';
import 'model/product_report_model.dart';

class ProductReportPrintSettings extends PrintServices {

  // Create document (Save PDF)
  Future<void> createDocument({
    required List<ProductReportModel> products,
    required String language,
    required pw.PageOrientation orientation,
    required ReportModel company,
    required pw.PdfPageFormat pageFormat,
    String? baseCurrency,
    int? storageId,
    String? storageName,
    int? productId,
    String? productName,
    int? stockStatus,
    String? statusName,
  }) async {
    try {
      final document = await generateReport(
        products: products,
        language: language,
        orientation: orientation,
        company: company,
        pageFormat: pageFormat,
        baseCurrency: baseCurrency,
        storageId: storageId,
        storageName: storageName,
        productId: productId,
        productName: productName,
        stockStatus: stockStatus,
        statusName: statusName,
      );

      await saveDocument(
        suggestedName: "product_report_${DateTime.now().millisecondsSinceEpoch}.pdf",
        pdf: document,
      );
    } catch (e) {
      throw e.toString();
    }
  }

  // Print document (using Windows print dialog)
  Future<void> printDocument({
    required List<ProductReportModel> products,
    required String language,
    required pw.PageOrientation orientation,
    required ReportModel company,
    required Printer selectedPrinter,
    required pw.PdfPageFormat pageFormat,
    required int copies,
    required String pages,
    String? baseCurrency,
    int? storageId,
    String? storageName,
    int? productId,
    String? productName,
    int? stockStatus,
    String? statusName,
  }) async {
    try {
      // Use clean format for PDF generation
      final cleanFormat = PdfFormatHelper.getPrinterFriendlyFormat(pageFormat);

      final document = await generateReport(
        products: products,
        language: language,
        orientation: orientation,
        company: company,
        pageFormat: cleanFormat,
        baseCurrency: baseCurrency,
        storageId: storageId,
        storageName: storageName,
        productId: productId,
        productName: productName,
        stockStatus: stockStatus,
        statusName: statusName,
      );

      final bytes = await document.save();

      // Open Windows print dialog
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'product_report_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );

    } catch (e) {
      throw Exception('Failed to print: $e');
    }
  }

  // Print Preview (for dialog preview)
  Future<pw.Document> printPreview({
    required List<ProductReportModel> products,
    required String language,
    required pw.PageOrientation orientation,
    required ReportModel company,
    required pw.PdfPageFormat pageFormat,
    String? baseCurrency,
    int? storageId,
    String? storageName,
    int? productId,
    String? productName,
    int? stockStatus,
    String? statusName,
  }) async {
    return generateReport(
      products: products,
      language: language,
      orientation: orientation,
      company: company,
      pageFormat: pageFormat,
      baseCurrency: baseCurrency,
      storageId: storageId,
      storageName: storageName,
      productId: productId,
      productName: productName,
      stockStatus: stockStatus,
      statusName: statusName,
    );
  }

  // Main report generator
  Future<pw.Document> generateReport({
    required List<ProductReportModel> products,
    required String language,
    required pw.PageOrientation orientation,
    required ReportModel company,
    required pw.PdfPageFormat pageFormat,
    String? baseCurrency,
    int? storageId,
    String? storageName,
    int? productId,
    String? productName,
    int? stockStatus,
    String? statusName,
  }) async {
    final document = pw.Document();
    final prebuiltHeader = await header(report: company);

    // Load logo
    final ByteData imageData = await rootBundle.load('assets/images/zaitoonLogo.png');
    final Uint8List imageBytes = imageData.buffer.asUint8List();
    final pw.MemoryImage logoImage = pw.MemoryImage(imageBytes);

    // Calculate totals
    double totalQuantity = 0;
    double totalValue = 0;

    for (var product in products) {
      totalQuantity += double.tryParse(product.availableQuantity ?? '0') ?? 0;
      totalValue += double.tryParse(product.total ?? '0') ?? 0;
    }

    document.addPage(
      pw.MultiPage(
        maxPages: 1000,
        margin: const pw.EdgeInsets.symmetric(horizontal: 25, vertical: 10),
        pageFormat: pageFormat,
        textDirection: documentLanguage(language: language),
        orientation: orientation,
        header: (context) => prebuiltHeader,
        footer: (context) => footer(
          report: company,
          context: context,
          language: language,
          logoImage: logoImage,
        ),
        build: (context) => [
          // Report Title
          _buildTitle(language, baseCurrency, storageName, productName, statusName),
          pw.SizedBox(height: 10),

          // Summary Stats
          _buildSummaryStats(products.length, totalQuantity, totalValue, baseCurrency, language),
          pw.SizedBox(height: 15),

          // Table Header
          _buildTableHeader(language, baseCurrency),
          pw.SizedBox(height: 2),

          // Data Rows
          ..._buildProductRows(products, language, baseCurrency),

          pw.SizedBox(height: 15),

          // Grand Total
          _buildGrandTotal(totalQuantity, totalValue, baseCurrency, language),
        ],
      ),
    );

    return document;
  }

  // Report Title with Filters
  pw.Widget _buildTitle(String language, String? baseCurrency, String? storageName, String? productName, String? statusName) {
    List<String> filters = [];
    if (storageName != null && storageName.isNotEmpty) filters.add(storageName);
    if (productName != null && productName.isNotEmpty) filters.add(productName);
    if (statusName != null && statusName.isNotEmpty) filters.add(statusName);

    String filterText = filters.isNotEmpty ? ' (${filters.join(' • ')})' : '';

    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            zText(
              text: '${tr(text: 'stockReport', tr: language)}$filterText',
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ],
        ),
        zText(
          text: _getCurrentDate(),
          fontSize: 8,
          color: pw.PdfColors.grey600,
          textAlign: language == 'en' ? pw.TextAlign.right : pw.TextAlign.left,
        ),
      ],
    );
  }

  // Summary Stats
  pw.Widget _buildSummaryStats(int itemCount, double totalQty, double totalVal, String? baseCurrency, String language) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: pw.PdfColors.grey50,
        border: pw.Border.all(color: pw.PdfColors.grey300, width: 0.5),
        borderRadius: pw.BorderRadius.circular(2),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            tr(text: 'totalItems', tr: language),
            itemCount.toString(),
            pw.PdfColors.blue700,
          ),
          _buildStatItem(
            tr(text: 'totalQuantity', tr: language),
            totalQty.toAmount(decimal: 4),
            pw.PdfColors.green700,
          ),
          _buildStatItem(
            tr(text: 'totalValue', tr: language),
            '${totalVal.toAmount(decimal: 2)} $baseCurrency',
            pw.PdfColors.purple700,
          ),
        ],
      ),
    );
  }

  pw.Widget _buildStatItem(String label, String value, pw.PdfColor color) {
    return pw.Column(
      children: [
        zText(
          text: label,
          fontSize: 8,
          color: pw.PdfColors.grey600,
        ),
        pw.SizedBox(height: 2),
        zText(
          text: value,
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          color: color,
        ),
      ],
    );
  }

  // Table Header - FIXED with proper flex ratios
  pw.Widget _buildTableHeader(String language, String? baseCurrency) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 4),
      decoration: pw.BoxDecoration(
        color: pw.PdfColors.grey100,
        border: pw.Border(
          bottom: pw.BorderSide(color: pw.PdfColors.grey400, width: 0.5),
        ),
      ),
      child: pw.Row(
        children: [
          // Serial No - small flex
          pw.SizedBox(
            width: 20,
            child: _buildHeaderCell(tr(text: 'no', tr: language), language),
          ),
          // Product Name with ID - larger flex
          pw.Expanded(
            flex: 5,
            child: _buildHeaderCell(tr(text: 'productName', tr: language), language),
          ),
          // Storage - medium flex
          pw.Expanded(
            flex: 2,
            child: _buildHeaderCell(tr(text: 'storage', tr: language), language),
          ),
          // Unit Price - small flex
          pw.Expanded(
            flex: 2,
            child: _buildHeaderCell(tr(text: 'unitPrice', tr: language), language, align: pw.TextAlign.right),
          ),
          // Quantity - small flex
          pw.Expanded(
            flex: 2,
            child: _buildHeaderCell(tr(text: 'quantity', tr: language), language, align: pw.TextAlign.right),
          ),
          // Total - medium flex (to accommodate currency symbol)
          pw.Expanded(
            flex: 3,
            child: _buildHeaderCell(tr(text: 'total', tr: language), language, align: pw.TextAlign.right),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildHeaderCell(String text, String language, {pw.TextAlign align = pw.TextAlign.left}) {
    return zText(
      text: text,
      fontSize: 8,
      fontWeight: pw.FontWeight.bold,
      textAlign: language == 'en' ? align : (align == pw.TextAlign.right ? pw.TextAlign.left : pw.TextAlign.right),
    );
  }

  // Product Rows - FIXED with proper flex ratios and product ID + name combined
  List<pw.Widget> _buildProductRows(List<ProductReportModel> products, String language, String? baseCurrency) {
    final rows = <pw.Widget>[];

    for (int i = 0; i < products.length; i++) {
      final product = products[i];
      final isEven = i % 2 == 0;
      final qty = double.tryParse(product.availableQuantity ?? '0') ?? 0;
      final price = double.tryParse(product.pricePerUnit ?? '0') ?? 0;
      final total = double.tryParse(product.total ?? '0') ?? 0;

      // Combine product ID and name
      String productDisplay = '';

      productDisplay = product.proName ?? '';

      rows.add(
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          decoration: pw.BoxDecoration(
            color: isEven ? pw.PdfColors.grey50 : pw.PdfColors.white,
            border: pw.Border(
              bottom: pw.BorderSide(color: pw.PdfColors.grey200, width: 0.3),
            ),
          ),
          child: pw.Row(
            children: [
              // Serial No
              pw.SizedBox(
                width: 20,
                child: _buildCell(product.proId.toString(), language),
              ),
              // Product Name with ID (combined)
              pw.Expanded(
                flex: 5,
                child: _buildCell(productDisplay, language),
              ),
              // Storage
              pw.Expanded(
                flex: 2,
                child: _buildCell(product.stgName ?? '', language),
              ),
              // Unit Price
              pw.Expanded(
                flex: 2,
                child: _buildNumberCell(price.toAmount(), language, align: pw.TextAlign.right),
              ),
              // Quantity
              pw.Expanded(
                flex: 2,
                child: _buildNumberCell(qty.toAmount(decimal: 4), language, align: pw.TextAlign.right),
              ),
              // Total with currency
              pw.Expanded(
                flex: 3,
                child: _buildCurrencyCell(total, baseCurrency, language),
              ),
            ],
          ),
        ),
      );
    }

    return rows;
  }

  pw.Widget _buildCell(String text, String language) {
    return zText(
      text: text,
      fontSize: 8,
      textAlign: language == 'en' ? pw.TextAlign.left : pw.TextAlign.right,
    );
  }

  pw.Widget _buildNumberCell(String text, String language, {pw.TextAlign align = pw.TextAlign.right}) {
    return zText(
      text: text,
      fontSize: 8,
      fontWeight: pw.FontWeight.bold,
      textAlign: language == 'en' ? align : (align == pw.TextAlign.right ? pw.TextAlign.left : pw.TextAlign.right),
    );
  }

  pw.Widget _buildCurrencyCell(double amount, String? currency, String language) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        zText(
          text: amount.toAmount(decimal: 2),
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
          textAlign: language == 'en' ? pw.TextAlign.right : pw.TextAlign.left,
        ),
        pw.SizedBox(width: 2),
        zText(
          text: currency ?? '',
          fontSize: 7,
          color: pw.PdfColors.grey600,
          textAlign: language == 'en' ? pw.TextAlign.right : pw.TextAlign.left,
        ),
      ],
    );
  }

  // Grand Total - FIXED with consistent flex ratios
  pw.Widget _buildGrandTotal(double totalQuantity, double totalValue, String? baseCurrency, String language) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: pw.PdfColors.blue50,
        border: pw.Border.all(color: pw.PdfColors.blue200, width: 0.5),
        borderRadius: pw.BorderRadius.circular(2),
      ),
      child: pw.Row(
        children: [


          // Grand Total label (aligned with product name column)
          pw.Expanded(
            flex: 5,
            child: pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: zText(
                text: tr(text: 'grandTotal', tr: language),
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,

              ),
            ),
          ),

          // Empty for storage column
          pw.Expanded(flex: 2, child: pw.Container()),

          // Empty for unit price column
          pw.Expanded(flex: 2, child: pw.Container()),

          // Total Quantity
          pw.Expanded(
            flex: 2,
            child: zText(
              text: "${totalQuantity.toAmount(decimal: 2)} Ton",
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              textAlign: pw.TextAlign.right,
            ),
          ),

          // Total Value with currency
          pw.Expanded(
            flex: 3,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                zText(
                  text: totalValue.toAmount(decimal: 2),
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: pw.PdfColors.blue800,
                ),
                pw.SizedBox(width: 2),
                zText(
                  text: baseCurrency ?? '',
                  fontSize: 8,
                  color: pw.PdfColors.grey600,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getCurrentDate() {
    final now = DateTime.now();
    return now.toFullDateTime;
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
                  zText(
                    text: report.comName ?? "",
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    tightBounds: true,
                  ),
                  pw.SizedBox(height: 3),
                  pw.Row(
                    children: [
                      zText(
                        text: report.comAddress ?? "",
                        fontSize: 8,
                        color: pw.PdfColors.grey600,
                      ),
                      verticalDivider(height: 10, width: 1),
                      zText(
                        text: report.compPhone ?? "",
                        fontSize: 8,
                        color: pw.PdfColors.grey600,
                      ),
                      verticalDivider(height: 10, width: 1),
                      zText(
                        text: report.comEmail ?? "",
                        fontSize: 8,
                        color: pw.PdfColors.grey600,
                      ),
                    ]
                  )
                ],
              ),
            ),
            if (image != null)
              pw.Container(
                width: 40,
                height: 40,
                child: pw.Image(image, fit: pw.BoxFit.contain),
              ),
          ],
        ),
        pw.SizedBox(height: 5),
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
        pw.Divider(thickness: 0.5),
        pw.SizedBox(height: 3),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Row(
              children: [
                pw.Container(
                  height: 15,
                  child: pw.Image(logoImage),
                ),
                pw.SizedBox(width: 5),
                zText(
                  text: tr(text: 'producedBy', tr: language),
                  fontSize: 7,
                  color: pw.PdfColors.grey600,
                ),
              ],
            ),
            pw.Row(
              children: [
                zText(
                  text: report.compPhone ?? "",
                  fontSize: 7,
                  color: pw.PdfColors.grey600,
                ),
                if (report.comEmail != null && report.comEmail!.isNotEmpty) ...[
                  pw.SizedBox(width: 8),
                  zText(
                    text: report.comEmail!,
                    fontSize: 7,
                    color: pw.PdfColors.grey600,
                  ),
                ],
              ],
            ),
            buildPage(context.pageNumber, context.pagesCount, language),
          ],
        ),
      ],
    );
  }
}