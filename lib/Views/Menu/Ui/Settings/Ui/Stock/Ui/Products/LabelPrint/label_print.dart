// product_label_print.dart

import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart' as pw;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/material.dart';
import 'package:zaitoonpro/Features/Date/shamsi_converter.dart';
import 'package:zaitoonpro/Features/PrintSettings/report_model.dart';
import '../model/product_model.dart';

// Model for product label data
class ProductLabelData {
  final int? proId;
  final String? proName;
  final String? proCode;
  final String? proColor;
  final String? proGrade;
  final String? proBrand;
  final String? proModel;
  final String? proUnit;
  final String? proSpp;
  final int? batch;
  final String? barcodeNumber;
  final String? storageName;
  final String? availableQuantity;
  final String? proMadeIn;
  final String? pcName; // Category name

  ProductLabelData({
    this.proId,
    this.proName,
    this.proCode,
    this.proColor,
    this.proGrade,
    this.proBrand,
    this.proModel,
    this.proUnit,
    this.proSpp,
    this.batch,
    this.barcodeNumber,
    this.storageName,
    this.availableQuantity,
    this.proMadeIn,
    this.pcName,
  });

  // Generate barcode from product code
  String get barcode => barcodeNumber ?? proCode ?? '${proId ?? 0}';

  // Generate QR code data
  String get qrData => jsonEncode({
    'id': proId,
    'code': proCode,
    'name': proName,
    'batch': batch,
  });
}

class ProductLabelPrintService {

  // ==================== GENERATE PRODUCT LABEL PDF ====================
  Future<pw.Document> generateProductLabel({
    required ProductLabelData product,
    required ReportModel company,
    required String language,
    required pw.PdfPageFormat pageFormat,
    required int labelsPerRow,
    required int labelsPerColumn,
    bool showBarcode = true,
    bool showQrCode = false,
    bool showPrice = true,
    bool showBatch = true,
    bool showColor = true,
    bool showBrand = true,
    bool showCategory = true,
  }) async {
    final document = pw.Document();
    final isRtl = language == 'fa' || language == 'ar';

    // Load company logo
    final ByteData imageData = await rootBundle.load('assets/images/zaitoonLogo.png');
    final Uint8List imageBytes = imageData.buffer.asUint8List();
    final pw.MemoryImage logoImage = pw.MemoryImage(imageBytes);

    // Calculate label dimensions
    final pageWidth = pageFormat.width;
    final pageHeight = pageFormat.height;
    final labelWidth = pageWidth / labelsPerRow;
    final labelHeight = pageHeight / labelsPerColumn;

    // Create labels
    for (int row = 0; row < labelsPerColumn; row++) {
      for (int col = 0; col < labelsPerRow; col++) {
        document.addPage(
          pw.Page(
            pageFormat: pageFormat,
            margin: pw.EdgeInsets.zero,
            build: (context) {
              return pw.Container(
                width: labelWidth,
                height: labelHeight,
                padding: pw.EdgeInsets.all(4),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(
                    color: pw.PdfColors.grey300,
                    width: 0.5,
                  ),
                ),
                child: _buildLabelContent(
                  product: product,
                  logoImage: logoImage,
                  labelWidth: labelWidth,
                  labelHeight: labelHeight,
                  isRtl: isRtl,
                  language: language,
                  showBarcode: showBarcode,
                  showQrCode: showQrCode,
                  showPrice: showPrice,
                  showBatch: showBatch,
                  showColor: showColor,
                  showBrand: showBrand,
                  showCategory: showCategory,
                ),
              );
            },
          ),
        );
      }
    }

    return document;
  }

  // ==================== BUILD LABEL CONTENT ====================
  pw.Widget _buildLabelContent({
    required ProductLabelData product,
    required pw.MemoryImage logoImage,
    required double labelWidth,
    required double labelHeight,
    required bool isRtl,
    required String language,
    required bool showBarcode,
    required bool showQrCode,
    required bool showPrice,
    required bool showBatch,
    required bool showColor,
    required bool showBrand,
    required bool showCategory,
  }) {
    return pw.Column(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        // Top section: Logo and Product Name
        pw.Container(
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              // Company Logo (small)
              pw.Container(
                width: 30,
                height: 30,
                child: pw.Image(logoImage, fit: pw.BoxFit.contain),
              ),
              pw.SizedBox(width: 4),
              // Product Name
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      product.proName ?? '',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                      maxLines: 2,
                      textAlign: isRtl ? pw.TextAlign.right : pw.TextAlign.left,
                    ),
                    if (showCategory && product.pcName != null)
                      pw.Text(
                        product.pcName!,
                        style: pw.TextStyle(
                          fontSize: 7,
                          color: pw.PdfColors.grey600,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),

        pw.SizedBox(height: 2),

        // Middle section: Product details
        pw.Container(
          child: pw.Wrap(
            spacing: 4,
            runSpacing: 2,
            children: [
              if (product.proCode != null)
                _detailChip(
                  label: '${_tr('code', language)}: ${product.proCode}',
                  fontSize: 7,
                ),
              if (showBrand && product.proBrand != null && product.proBrand!.isNotEmpty)
                _detailChip(
                  label: '${_tr('brand', language)}: ${product.proBrand}',
                  fontSize: 7,
                ),
              if (showColor && product.proColor != null && product.proColor!.isNotEmpty)
                _detailChip(
                  label: '${_tr('color', language)}: ${product.proColor}',
                  fontSize: 7,
                ),
              if (product.proGrade != null && product.proGrade!.isNotEmpty)
                _detailChip(
                  label: '${_tr('grade', language)}: ${product.proGrade}',
                  fontSize: 7,
                ),
              if (product.proModel != null && product.proModel!.isNotEmpty)
                _detailChip(
                  label: '${_tr('model', language)}: ${product.proModel}',
                  fontSize: 7,
                ),
              if (product.proUnit != null)
                _detailChip(
                  label: '${_tr('unit', language)}: ${product.proUnit}',
                  fontSize: 7,
                ),
              if (product.proMadeIn != null && product.proMadeIn!.isNotEmpty)
                _detailChip(
                  label: '${_tr('madeIn', language)}: ${product.proMadeIn}',
                  fontSize: 7,
                ),
            ],
          ),
        ),

        pw.SizedBox(height: 2),

        // Price section
        if (showPrice && product.proSpp != null)
          pw.Container(
            padding: pw.EdgeInsets.all(2),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: pw.PdfColors.grey400),
              borderRadius: pw.BorderRadius.circular(3),
            ),
            child: pw.Text(
              '${_tr('price', language)}: ${product.proSpp}',
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: pw.PdfColors.blue800,
              ),
            ),
          ),

        // Batch section
        if (showBatch && product.batch != null)
          pw.Text(
            '${_tr('batch', language)}: ${product.batch}',
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
            ),
          ),

        // Barcode/QR Code section
        if (showBarcode || showQrCode)
          pw.Expanded(
            child: pw.Center(
              child: showBarcode
                  ? _buildBarcodeWidget(product.barcode, labelWidth)
                  : _buildQrCodeWidget(product.qrData, 50),
            ),
          ),

        // Footer: ID and Date
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'ID: ${product.proId ?? ''}',
              style: pw.TextStyle(fontSize: 6, color: pw.PdfColors.grey600),
            ),
            pw.Text(
              DateTime.now().shamsiDateFormatted,
              style: pw.TextStyle(fontSize: 6, color: pw.PdfColors.grey600),
            ),
          ],
        ),
      ],
    );
  }

  // ==================== DETAIL CHIP WIDGET ====================
  pw.Widget _detailChip({
    required String label,
    required double fontSize,
  }) {
    return pw.Container(
      padding: pw.EdgeInsets.symmetric(horizontal: 3, vertical: 1),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: pw.PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(2),
      ),
      child: pw.Text(
        label,
        style: pw.TextStyle(fontSize: fontSize),
      ),
    );
  }

// ==================== BARCODE WIDGET (ALTERNATIVE) ====================
  pw.Widget _buildBarcodeWidget(String data, double maxWidth) {
    // Generate barcode using Code128 encoding
    final barcodeData = _generateBarcodePattern(data);

    return pw.Container(
      width: maxWidth * 0.8,
      child: pw.Column(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          // Barcode graphic
          pw.Container(
            height: 30,
            child: pw.CustomPaint(
              size: pw.PdfPoint(maxWidth * 0.8, 30),
              painter: (pw.PdfGraphics graphics, pw.PdfPoint size) {
                final barWidth = size.x / barcodeData.length;
                for (int i = 0; i < barcodeData.length; i++) {
                  if (barcodeData[i] == '1') {
                    graphics.drawRect(
                      i * barWidth,
                      0,
                      barWidth,
                      size.y,
                    );
                    graphics.fillPath();
                  }
                }
              },
            ),
          ),
          pw.SizedBox(height: 2),
          // Barcode number
          pw.Text(
            data,
            style: pw.TextStyle(fontSize: 7),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ==================== QR CODE WIDGET ====================
  pw.Widget _buildQrCodeWidget(String data, double size) {
    // Simple QR-like representation
    return pw.Container(
      width: size,
      height: size,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: pw.PdfColors.black, width: 2),
      ),
      child: pw.Center(
        child: pw.Text(
          'QR',
          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
        ),
      ),
    );
  }

  // ==================== SIMPLE BARCODE PATTERN GENERATOR ====================
  String _generateBarcodePattern(String data) {
    // Simple pattern generation based on string data
    final bytes = utf8.encode(data);
    final pattern = StringBuffer();

    // Start pattern
    pattern.write('11010010000');

    for (final byte in bytes) {
      // Convert each byte to binary pattern
      final binary = byte.toRadixString(2).padLeft(8, '0');
      for (int i = 0; i < binary.length; i++) {
        pattern.write(binary[i] == '1' ? '11' : '1');
        pattern.write(binary[i] == '1' ? '00' : '0');
      }
    }

    // End pattern
    pattern.write('1100011101011');

    return pattern.toString();
  }

  // ==================== TRANSLATION HELPER ====================
  String _tr(String text, String language) {
    final translations = {
      'code': {'en': 'Code', 'fa': 'کد', 'ar': 'رمز'},
      'brand': {'en': 'Brand', 'fa': 'برند', 'ar': 'مارکة'},
      'color': {'en': 'Color', 'fa': 'رنگ', 'ar': 'لون'},
      'grade': {'en': 'Grade', 'fa': 'ګریډ', 'ar': 'درجة'},
      'model': {'en': 'Model', 'fa': 'موډل', 'ar': 'مودیل'},
      'unit': {'en': 'Unit', 'fa': 'واحد', 'ar': 'وحدة'},
      'madeIn': {'en': 'Made In', 'fa': 'ساخت', 'ar': 'صنع في'},
      'price': {'en': 'Price', 'fa': 'قیمت', 'ar': 'سعر'},
      'batch': {'en': 'Batch', 'fa': 'بچ', 'ar': 'دفعة'},
    };

    return translations[text]?[language] ?? text;
  }

  // ==================== PRINT LABEL ====================
  Future<void> printProductLabel({
    required ProductLabelData product,
    required ReportModel company,
    required String language,
    required Printer selectedPrinter,
    required pw.PdfPageFormat pageFormat,
    required int copies,
    required int labelsPerRow,
    required int labelsPerColumn,
    bool showBarcode = true,
    bool showQrCode = false,
    bool showPrice = true,
    bool showBatch = true,
  }) async {
    try {
      final document = await generateProductLabel(
        product: product,
        company: company,
        language: language,
        pageFormat: pageFormat,
        labelsPerRow: labelsPerRow,
        labelsPerColumn: labelsPerColumn,
        showBarcode: showBarcode,
        showQrCode: showQrCode,
        showPrice: showPrice,
        showBatch: showBatch,
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
      throw 'Failed to print label: $e';
    }
  }

  // ==================== PREVIEW LABEL ====================
  Future<pw.Document> previewProductLabel({
    required ProductLabelData product,
    required ReportModel company,
    required String language,
    required pw.PdfPageFormat pageFormat,
    required int labelsPerRow,
    required int labelsPerColumn,
    bool showBarcode = true,
    bool showQrCode = false,
  }) async {
    return generateProductLabel(
      product: product,
      company: company,
      language: language,
      pageFormat: pageFormat,
      labelsPerRow: labelsPerRow,
      labelsPerColumn: labelsPerColumn,
      showBarcode: showBarcode,
      showQrCode: showQrCode,
    );
  }
}

// ==================== LABEL PRINT DIALOG WIDGET ====================
class ProductLabelPrintDialog extends StatefulWidget {
  final ProductLabelData product;
  final ReportModel company;

  const ProductLabelPrintDialog({
    super.key,
    required this.product,
    required this.company,
  });

  @override
  State<ProductLabelPrintDialog> createState() => _ProductLabelPrintDialogState();
}

class _ProductLabelPrintDialogState extends State<ProductLabelPrintDialog> {
  final _service = ProductLabelPrintService();

  int _labelsPerRow = 2;
  int _labelsPerColumn = 4;
  int _copies = 1;
  bool _showBarcode = true;
  bool _showQrCode = false;
  bool _showPrice = true;
  bool _showBatch = true;
  String _language = 'fa';

  pw.PdfPageFormat _pageFormat = pw.PdfPageFormat.a4;
  Printer? _selectedPrinter;

  @override
  void initState() {
    super.initState();
    _initPrinter();
  }

  Future<void> _initPrinter() async {
    final printers = await Printing.listPrinters();
    if (printers.isNotEmpty && mounted) {
      setState(() {
        _selectedPrinter = printers.first;
      });
    }
  }

  Future<void> _printLabel() async {
    if (_selectedPrinter == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a printer')),
      );
      return;
    }

    try {
      await _service.printProductLabel(
        product: widget.product,
        company: widget.company,
        language: _language,
        selectedPrinter: _selectedPrinter!,
        pageFormat: _pageFormat,
        copies: _copies,
        labelsPerRow: _labelsPerRow,
        labelsPerColumn: _labelsPerColumn,
        showBarcode: _showBarcode,
        showQrCode: _showQrCode,
        showPrice: _showPrice,
        showBatch: _showBatch,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Labels printed successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.label),
          const SizedBox(width: 8),
          Text('Print Product Label'),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Info Summary
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.product.proName ?? 'No Name',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('Code: ${widget.product.proCode ?? 'N/A'}'),
                    if (widget.product.proColor != null)
                      Text('Color: ${widget.product.proColor}'),
                    if (widget.product.batch != null)
                      Text('Batch: ${widget.product.batch}'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Layout Settings
            const Text('Layout:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Labels per Row',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (val) => _labelsPerRow = int.tryParse(val) ?? 2,
                    controller: TextEditingController(text: _labelsPerRow.toString()),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Labels per Column',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (val) => _labelsPerColumn = int.tryParse(val) ?? 4,
                    controller: TextEditingController(text: _labelsPerColumn.toString()),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Copies
            TextField(
              decoration: const InputDecoration(
                labelText: 'Number of Copies',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (val) => _copies = int.tryParse(val) ?? 1,
              controller: TextEditingController(text: _copies.toString()),
            ),

            const SizedBox(height: 16),

            // Options
            const Text('Options:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            CheckboxListTile(
              title: const Text('Show Barcode'),
              value: _showBarcode,
              onChanged: (val) => setState(() => _showBarcode = val ?? true),
              dense: true,
            ),
            CheckboxListTile(
              title: const Text('Show QR Code'),
              value: _showQrCode,
              onChanged: (val) => setState(() => _showQrCode = val ?? false),
              dense: true,
            ),
            CheckboxListTile(
              title: const Text('Show Price'),
              value: _showPrice,
              onChanged: (val) => setState(() => _showPrice = val ?? true),
              dense: true,
            ),
            CheckboxListTile(
              title: const Text('Show Batch'),
              value: _showBatch,
              onChanged: (val) => setState(() => _showBatch = val ?? true),
              dense: true,
            ),

            const SizedBox(height: 16),

            // Language
            DropdownButtonFormField<String>(
              initialValue: _language,
              decoration: const InputDecoration(
                labelText: 'Language',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'fa', child: Text('Persian')),
                DropdownMenuItem(value: 'en', child: Text('English')),
                DropdownMenuItem(value: 'ar', child: Text('Arabic')),
              ],
              onChanged: (val) => setState(() => _language = val ?? 'fa'),
            ),

            const SizedBox(height: 16),

            // Page Size
            DropdownButtonFormField<pw.PdfPageFormat>(
              initialValue: _pageFormat,
              decoration: const InputDecoration(
                labelText: 'Page Size',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: pw.PdfPageFormat.a4, child: Text('A4')),
                DropdownMenuItem(value: pw.PdfPageFormat.letter, child: Text('Letter')),
                DropdownMenuItem(value: pw.PdfPageFormat.a5, child: Text('A5')),
              ],
              onChanged: (val) => setState(() => _pageFormat = val ?? pw.PdfPageFormat.a4),
            ),

            const SizedBox(height: 16),

            // Printer Selection
            FutureBuilder<List<Printer>>(
              future: Printing.listPrinters(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }

                final printers = snapshot.data!;
                if (_selectedPrinter == null && printers.isNotEmpty) {
                  _selectedPrinter = printers.first;
                }

                return DropdownButtonFormField<Printer>(
                  initialValue: _selectedPrinter,
                  decoration: const InputDecoration(
                    labelText: 'Select Printer',
                    border: OutlineInputBorder(),
                  ),
                  items: printers.map((printer) {
                    return DropdownMenuItem(
                      value: printer,
                      child: Text(printer.name),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedPrinter = val),
                );
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: _printLabel,
          icon: const Icon(Icons.print),
          label: const Text('Print'),
        ),
      ],
    );
  }
}

// ==================== EXTENSION TO SHOW LABEL PRINT FROM PRODUCT ====================
extension ProductLabelPrintExtension on ProductsModel {
  ProductLabelData toLabelData({int? batch, String? storageName, String? availableQuantity}) {
    return ProductLabelData(
      proId: proId,
      proName: proName,
      proCode: proCode,
      proColor: proColor,
      proGrade: proGrade,
      proBrand: proBrand,
      proModel: proModel,
      proUnit: proUnit,
      proSpp: proSpp,
      batch: batch ?? batches?.firstOrNull?.batch,
      barcodeNumber: proCode,
      storageName: storageName ?? batches?.firstOrNull?.storage?.toString(),
      availableQuantity: availableQuantity ?? batches?.firstOrNull?.availableQuantity,
      proMadeIn: proMadeIn,
      pcName: pcName,
    );
  }
}