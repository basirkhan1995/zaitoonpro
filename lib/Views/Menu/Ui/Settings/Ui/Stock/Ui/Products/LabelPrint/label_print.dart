// product_label_print.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pdf/pdf.dart' as pw;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../../../../../../../Features/Generic/generic_drop.dart';
import '../../../../../../../../../Features/PrintSettings/Features/printers.dart';
import '../../../../../../../../../Features/PrintSettings/bloc/PageOrientation/page_orientation_cubit.dart';
import '../../../../../../../../../Features/PrintSettings/bloc/PageSize/paper_size_cubit.dart';
import '../../../../../../../../../Features/PrintSettings/bloc/Printer/printer_cubit.dart';
import '../../../../../../../../../Features/PrintSettings/print_services.dart';
import '../model/product_model.dart';

// ==================== PRODUCT LABEL DATA MODEL ====================
class ProductLabelData {
  final int? proId;
  final String? proName;
  final String? proCode;
  final String? proColor;
  final String? proUnit;
  final String? proSpp;
  final List<BatchOption> batches;

  ProductLabelData({
    this.proId,
    this.proName,
    this.proCode,
    this.proColor,
    this.proUnit,
    this.proSpp,
    this.batches = const [],
  });
}

// Batch option for selection
class BatchOption {
  final int batch;
  final int? storage;
  final String? availableQuantity;

  BatchOption({
    required this.batch,
    this.storage,
    this.availableQuantity,
  });
}

// ==================== PRODUCT LABEL PRINT SERVICE ====================
class ProductLabelPrintService extends PrintServices {

  Future<pw.Document> generateLabel({
    required ProductLabelData product,
    required pw.PdfPageFormat pageFormat,
    required pw.PageOrientation orientation,
    required int selectedBatch,
    bool showBarcode = true,
    bool showPrice = true,
    bool showBatch = true,
    bool showColor = true,
    bool showUnit = true,
  }) async {
    final document = pw.Document();

    document.addPage(
      pw.Page(
        pageFormat: pageFormat,
        orientation: orientation,
        margin: pw.EdgeInsets.all(10),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              // Product Info Section
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Product Name
                  zText(
                    text: product.proName ?? '',
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),

                  pw.SizedBox(height: 8),

                  // Color
                  if (showColor && product.proColor != null && product.proColor!.isNotEmpty)
                    zText(
                      text: 'رنگ: ${product.proColor}',
                      fontSize: 10,
                    ),

                  // Unit
                  if (showUnit && product.proUnit != null && product.proUnit!.isNotEmpty)
                    zText(
                      text: 'واحد: ${product.proUnit}',
                      fontSize: 10,
                    ),

                  // Price & Batch Row
                  if ((showPrice && product.proSpp != null) || showBatch)
                    pw.SizedBox(height: 8),

                  pw.Row(
                    children: [
                      // Price Tag
                      if (showPrice && product.proSpp != null)
                        pw.Container(
                          padding: pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: pw.BoxDecoration(
                            color: pw.PdfColors.blue50,
                            border: pw.Border.all(color: pw.PdfColors.blue400, width: 1.5),
                            borderRadius: pw.BorderRadius.circular(6),
                          ),
                          child: zText(
                            text: '${product.proSpp} AFN',
                            fontSize: 13,
                            fontWeight: pw.FontWeight.bold,
                            color: pw.PdfColors.blue900,
                          ),
                        ),

                      if (showPrice && product.proSpp != null && showBatch)
                        pw.SizedBox(width: 8),

                      // Batch Tag
                      if (showBatch)
                        pw.Container(
                          padding: pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: pw.BoxDecoration(
                            color: pw.PdfColors.grey100,
                            border: pw.Border.all(color: pw.PdfColors.grey500, width: 1.5),
                            borderRadius: pw.BorderRadius.circular(6),
                          ),
                          child: zText(
                            text: 'بچ: $selectedBatch',
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                            color: pw.PdfColors.grey800,
                          ),
                        ),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 20),

              // Barcode Section
              if (showBarcode)
                pw.Center(
                  child: pw.BarcodeWidget(
                    barcode: pw.Barcode.code128(),
                    data: product.proCode ?? '${product.proId ?? 0}',
                    width: pageFormat.width * 0.75,
                    height: 50,
                  ),
                ),

              // Footer
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'ID: ${product.proId ?? ''}',
                    style: const pw.TextStyle(fontSize: 8, color: pw.PdfColors.grey600),
                  ),
                  if (product.proCode != null)
                    pw.Text(
                      product.proCode!,
                      style: const pw.TextStyle(fontSize: 8, color: pw.PdfColors.grey600),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return document;
  }
}

// ==================== LABEL PRINT PREVIEW DIALOG ====================
class ProductLabelPreviewDialog extends StatefulWidget {
  final ProductLabelData product;

  const ProductLabelPreviewDialog({
    super.key,
    required this.product,
  });

  @override
  State<ProductLabelPreviewDialog> createState() => _ProductLabelPreviewDialogState();
}

class _ProductLabelPreviewDialogState extends State<ProductLabelPreviewDialog> {
  final _service = ProductLabelPrintService();

  // Settings
  int _copies = 1;
  final _copiesController = TextEditingController(text: '1');
  bool _fontsInitialized = false;

  // Selected batch
  late int _selectedBatch;

  // Visibility Options
  bool _showBarcode = true;
  bool _showPrice = true;
  bool _showBatch = true;
  bool _showColor = true;
  bool _showUnit = true;

  // Label paper sizes
  static final Map<String, pw.PdfPageFormat> _labelFormats = {
    'Label 70×35mm': pw.PdfPageFormat(70 * 2.83465, 35 * 2.83465),
    'Label 100×50mm': pw.PdfPageFormat(100 * 2.83465, 50 * 2.83465),
    'Label 100×100mm': pw.PdfPageFormat(100 * 2.83465, 100 * 2.83465),
  };

  @override
  void initState() {
    super.initState();
    // Set default batch to first one if available
    if (widget.product.batches.isNotEmpty) {
      _selectedBatch = widget.product.batches.first.batch;
    } else {
      _selectedBatch = 0;
    }
    _initialize();
  }

  Future<void> _initialize() async {
    await PrintServices.initializeFonts();
    if (mounted) {
      setState(() => _fontsInitialized = true);
    }
  }

  @override
  void dispose() {
    _copiesController.dispose();
    super.dispose();
  }

  void _updateCopies(String value) {
    final copies = int.tryParse(value);
    if (copies != null && copies >= 1 && copies <= 200) {
      setState(() => _copies = copies);
    }
  }

  Future<void> _handlePrint() async {
    final printerCubit = context.read<PrinterCubit>();
    final selectedPrinter = printerCubit.state;

    if (selectedPrinter == null) {
      _showSnackBar('Please select a printer', isError: true);
      return;
    }

    try {
      final paperSizeCubit = context.read<PaperSizeCubit>();
      final orientationCubit = context.read<PageOrientationCubit>();

      final doc = await _service.generateLabel(
        product: widget.product,
        pageFormat: paperSizeCubit.state,
        orientation: orientationCubit.state,
        selectedBatch: _selectedBatch,
        showBarcode: _showBarcode,
        showPrice: _showPrice,
        showBatch: _showBatch,
        showColor: _showColor,
        showUnit: _showUnit,
      );

      for (int i = 0; i < _copies; i++) {
        await Printing.directPrintPdf(
          printer: selectedPrinter,
          onLayout: (_) async => doc.save(),
        );
        if (i < _copies - 1) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }

      if (mounted) {
        _showSnackBar('Label printed successfully');
        Navigator.pop(context);
      }
    } catch (e) {
      _showSnackBar('Print failed: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isMobile = screenWidth < 600;

    if (!_fontsInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return AlertDialog(
      contentPadding: EdgeInsets.zero,
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      content: Container(
        width: isMobile ? screenWidth : screenWidth * 0.9,
        height: isMobile ? screenHeight : screenHeight * 0.9,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  Icon(Icons.print, color: colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Print Preview',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),

            // Body
            Expanded(
              child: isMobile
                  ? _buildMobileLayout(colorScheme, textTheme)
                  : _buildDesktopLayout(colorScheme, textTheme),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== DESKTOP LAYOUT ====================
  Widget _buildDesktopLayout(ColorScheme colorScheme, TextTheme textTheme) {
    return Row(
      children: [
        // Sidebar
        Container(
          width: 260,
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(color: colorScheme.outline.withValues(alpha: 0.1)),
            ),
          ),
          child: _buildSidebar(colorScheme, textTheme),
        ),

        // Preview
        Expanded(
          child: Container(
            color: Colors.grey[100],
            child: _buildPreview(),
          ),
        ),
      ],
    );
  }

  // ==================== MOBILE LAYOUT ====================
  Widget _buildMobileLayout(ColorScheme colorScheme, TextTheme textTheme) {
    return Stack(
      children: [
        Container(
          color: Colors.grey[100],
          child: _buildPreview(),
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            heroTag: 'label_settings',
            onPressed: () => _showMobileSettings(colorScheme, textTheme),
            child: const Icon(Icons.settings),
          ),
        ),
      ],
    );
  }

  void _showMobileSettings(ColorScheme colorScheme, TextTheme textTheme) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: _buildSidebar(colorScheme, textTheme),
      ),
    );
  }

  // ==================== SIDEBAR ====================
  Widget _buildSidebar(ColorScheme colorScheme, TextTheme textTheme) {

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Copies field and Print button (like your PrintPreviewDialog)
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: _buildCopiesField()),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: ElevatedButton.icon(
                    onPressed: _handlePrint,
                    icon: const Icon(Icons.print, size: 18),
                    label: const Text('Print'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          // Printer
          PrinterDropdown(
            onPrinterSelected: (printer) {
              context.read<PrinterCubit>().setPrinter(printer);
            },
          ),

          const SizedBox(height: 12),

          // Paper Size using CustomDropdown
          CustomDropdown<String>(
            title: 'Paper Size',
            items: _labelFormats.keys.toList(),
            initialValue: _getCurrentFormatKey(),
            itemLabel: (key) => key,
            onItemSelected: (value) {
              if (_labelFormats.containsKey(value)) {
                context.read<PaperSizeCubit>().setPaperSize(_labelFormats[value]!);
              }
            },
          ),

          const SizedBox(height: 12),

          // Batch Selection using CustomDropdown
          if (widget.product.batches.isNotEmpty)
            CustomDropdown<int>(
              title: 'Select Batch',
              items: widget.product.batches.map((b) => b.batch).toList(),
              initialValue: _selectedBatch.toString(),
              itemLabel: (batch) {
                final batchOption = widget.product.batches.firstWhere(
                      (b) => b.batch == batch,
                  orElse: () => BatchOption(batch: batch),
                );
                return 'بچ $batch${batchOption.availableQuantity != null ? ' (${batchOption.availableQuantity})' : ''}';
              },
              onItemSelected: (value) {
                setState(() => _selectedBatch = value);
              },
            ),

          const SizedBox(height: 16),

          // Display Options
          Text('Display Options', style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          SwitchListTile(
            title: const Text('Show Barcode', style: TextStyle(fontSize: 13)),
            value: _showBarcode,
            onChanged: (v) => setState(() => _showBarcode = v),
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            title: const Text('Show Price', style: TextStyle(fontSize: 13)),
            value: _showPrice,
            onChanged: (v) => setState(() => _showPrice = v),
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            title: const Text('Show Batch', style: TextStyle(fontSize: 13)),
            value: _showBatch,
            onChanged: (v) => setState(() => _showBatch = v),
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            title: const Text('Show Color', style: TextStyle(fontSize: 13)),
            value: _showColor,
            onChanged: (v) => setState(() => _showColor = v),
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            title: const Text('Show Unit', style: TextStyle(fontSize: 13)),
            value: _showUnit,
            onChanged: (v) => setState(() => _showUnit = v),
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),

          const SizedBox(height: 16),

          // Orientation
          Text('Orientation', style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _orientationButton(
                  label: 'Portrait',
                  icon: Icons.stay_current_portrait,
                  selected: context.watch<PageOrientationCubit>().state == pw.PageOrientation.portrait,
                  onTap: () => context.read<PageOrientationCubit>().setOrientation(pw.PageOrientation.portrait),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _orientationButton(
                  label: 'Landscape',
                  icon: Icons.stay_current_landscape,
                  selected: context.watch<PageOrientationCubit>().state == pw.PageOrientation.landscape,
                  onTap: () => context.read<PageOrientationCubit>().setOrientation(pw.PageOrientation.landscape),
                ),
              ),
            ],
          ),

        ],
      ),
    );
  }

  // ==================== COPIES FIELD (Same style as PrintPreviewDialog) ====================
  Widget _buildCopiesField() {
    final bool isRTL = Directionality.of(context) == TextDirection.rtl;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Copies',
          style: TextStyle(
            fontSize: 13,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 40,
          decoration: BoxDecoration(
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.5),
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _copiesController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(3),
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: const InputDecoration(
                    isCollapsed: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    constraints: BoxConstraints(),
                    border: InputBorder.none,
                  ),
                  onChanged: (value) {
                    if (value.isEmpty) return;
                    int val = int.tryParse(value) ?? 1;
                    if (val > 200) {
                      val = 200;
                      _copiesController.text = "200";
                      _copiesController.selection = TextSelection.fromPosition(
                        TextPosition(offset: _copiesController.text.length),
                      );
                    }
                    _updateCopies(val.toString());
                  },
                ),
              ),
              Container(
                width: 30,
                decoration: BoxDecoration(
                  border: Border(
                    left: isRTL ? BorderSide.none : BorderSide(
                      color: colorScheme.outline.withValues(alpha: 0.5),
                    ),
                    right: isRTL ? BorderSide(
                      color: colorScheme.outline.withValues(alpha: 0.5),
                    ) : BorderSide.none,
                  ),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            final newVal = _copies + 1;
                            if (newVal <= 200) {
                              setState(() => _copies = newVal);
                              _copiesController.text = newVal.toString();
                            }
                          },
                          child: Center(
                            child: Icon(Icons.arrow_drop_up, size: 16, color: colorScheme.outline),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            final newVal = _copies - 1;
                            if (newVal >= 1) {
                              setState(() => _copies = newVal);
                              _copiesController.text = newVal.toString();
                            }
                          },
                          child: Center(
                            child: Icon(Icons.arrow_drop_down, size: 16, color: colorScheme.outline),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==================== GET CURRENT FORMAT KEY ====================
  String _getCurrentFormatKey() {
    final currentFormat = context.read<PaperSizeCubit>().state;
    for (final entry in _labelFormats.entries) {
      if (entry.value == currentFormat) {
        return entry.key;
      }
    }
    return _labelFormats.keys.first;
  }

  // ==================== ORIENTATION BUTTON ====================
  Widget _orientationButton({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          border: Border.all(
            color: selected ? colorScheme.primary : Colors.grey[300]!,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: selected ? colorScheme.primary.withValues(alpha: 0.1) : null,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 20,
              color: selected ? colorScheme.primary : Colors.grey[600],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                color: selected ? colorScheme.primary : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== PDF PREVIEW ====================
  Widget _buildPreview() {
    if (!_fontsInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    final paperSizeCubit = context.watch<PaperSizeCubit>();
    final orientationCubit = context.watch<PageOrientationCubit>();

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: PdfPreview(
        padding: const EdgeInsets.all(16),
        useActions: false,
        previewPageMargin: const EdgeInsets.all(20),
        maxPageWidth: 800,
        canChangeOrientation: false,
        canChangePageFormat: false,
        build: (_) async {
          final doc = await _service.generateLabel(
            product: widget.product,
            pageFormat: paperSizeCubit.state,
            orientation: orientationCubit.state,
            selectedBatch: _selectedBatch,
            showBarcode: _showBarcode,
            showPrice: _showPrice,
            showBatch: _showBatch,
            showColor: _showColor,
            showUnit: _showUnit,
          );
          return doc.save();
        },
      ),
    );
  }
}

// ==================== EXTENSION ====================
extension ProductLabelPrintExtension on ProductsModel {
  ProductLabelData toLabelData() {
    return ProductLabelData(
      proId: proId,
      proName: proName,
      proCode: proCode,
      proColor: proColor,
      proUnit: proUnit,
      proSpp: proSpp,
      batches: batches?.map((b) => BatchOption(
        batch: b.batch ?? 0,
        storage: b.storage,
        availableQuantity: b.availableQuantity,
      )).toList() ?? [],
    );
  }
}