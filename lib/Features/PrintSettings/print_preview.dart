import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart'; // Add this dependency
import 'package:path_provider/path_provider.dart'; // Add this dependency
import 'package:zaitoon_petroleum/Features/PrintSettings/print_services.dart';
import 'dart:io';
import 'package:zaitoon_petroleum/Features/PrintSettings/report_model.dart';
import '../../Localizations/Bloc/localizations_bloc.dart';
import '../../Localizations/l10n/translations/app_localizations.dart';
import '../Widgets/button.dart';
import '../Widgets/outline_button.dart';
import 'Features/document_locale.dart';
import 'Features/printers.dart';
import 'PageOrientation/paper_orientation.dart';
import 'PaperSize/paper_size.dart';
import 'bloc/Language/print_language_cubit.dart';
import 'bloc/PageOrientation/page_orientation_cubit.dart';
import 'bloc/PageSize/paper_size_cubit.dart';
import 'bloc/Printer/printer_cubit.dart';

class PrintPreviewDialog<T> extends StatefulWidget {
  final T data;
  final ReportModel company;

  final Future<pw.Document> Function({
  required T data,
  required String language,
  required pw.PageOrientation orientation,
  required PdfPageFormat pageFormat,
  }) buildPreview;

  final Future<void> Function({
  required T data,
  required String language,
  required pw.PageOrientation orientation,
  required PdfPageFormat pageFormat,
  required Printer selectedPrinter,
  required int copies,
  required String pages,
  }) onPrint;

  final Future<void> Function({
  required T data,
  required String language,
  required pw.PageOrientation orientation,
  required PdfPageFormat pageFormat,
  }) onSave;

  const PrintPreviewDialog({
    super.key,
    required this.company,
    required this.data,
    required this.buildPreview,
    required this.onPrint,
    required this.onSave,
  });

  @override
  State<PrintPreviewDialog<T>> createState() => _PrintPreviewDialogState<T>();
}

class _PrintPreviewDialogState<T> extends State<PrintPreviewDialog<T>> {
  late TextEditingController _copiesController;
  late TextEditingController _pagesController;
  int copies = 1;
  String pages = "all";
  bool _isPanelVisible = false;
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();
    _copiesController = TextEditingController(text: "1");
    _pagesController = TextEditingController(text: "");
    _initializeFonts();
  }

  @override
  void dispose() {
    _copiesController.dispose();
    _pagesController.dispose();
    super.dispose();
  }

  void updateCopies(int value, {bool fromTyping = false}) {
    if (value < 1) value = 1;
    if (value > 200) value = 200;

    setState(() {
      copies = value;

      if (!fromTyping) {
        _copiesController.text = value.toString();
        _copiesController.selection = TextSelection.collapsed(
          offset: _copiesController.text.length,
        );
      }
    });
  }

  void updatePages(String value) {
    setState(() {
      pages = value.trim().isEmpty ? "all" : value;
    });
  }
  Future<void> _initializeFonts() async {
    await PrintServices.initializeFonts();
  }
  Future<void> _sharePDF() async {
    if (!mounted) return;

    setState(() {
      _isSharing = true;
    });

    try {
      final language = context.read<PrintLanguageCubit>().state ??
          context.read<LocalizationBloc>().toString();
      final pageFormat = context.read<PaperSizeCubit>().state;
      final orientation = context.read<PageOrientationCubit>().state;

      // Generate PDF
      final pdf = await widget.buildPreview(
        data: widget.data,
        language: language,
        orientation: orientation,
        pageFormat: pageFormat,
      );

      if (!mounted) return;

      // Save PDF
      final bytes = await pdf.save();
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'document_$timestamp.pdf';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(bytes);

      if (!mounted) return;

      final xFile = XFile(
        file.path,
        mimeType: 'application/pdf',
        name: fileName,
      );

      // ✅ NEW share_plus 12+ way
      await SharePlus.instance.share(
        ShareParams(
          files: [xFile],
          text: 'Document from Zaitoon Petroleum',
        ),
      );

      // Optional delete
      Future.delayed(const Duration(seconds: 2), () async {
        if (await file.exists()) {
          await file.delete();
        }
      });

    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sharing PDF: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSharing = false;
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 900;
    final isDesktop = screenWidth >= 900;

    return AlertDialog(
      contentPadding: EdgeInsets.zero,
      insetPadding: EdgeInsets.zero,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
      content: Container(
        height: MediaQuery.sizeOf(context).height * (isMobile ? 1.0 : 0.95),
        width: isMobile
            ? MediaQuery.sizeOf(context).width
            : MediaQuery.sizeOf(context).width * (isTablet ? 0.95 : 0.9),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            // Mobile/Tablet Header with Settings Toggle and Share
            if (isMobile || isTablet) _buildMobileHeader(context, locale),

            Expanded(
              child: isDesktop
                  ? _buildDesktopLayout(context, locale)
                  : _buildMobileTabletLayout(context, locale),
            ),
          ],
        ),
      ),
    );
  }

  // Desktop Layout (Sidebar + Preview)
  Widget _buildDesktopLayout(BuildContext context, AppLocalizations locale) {
    return Row(
      children: [
        _buildSidebar(context, locale),
        _buildPreview(context),
      ],
    );
  }

  // Mobile/Tablet Layout (Settings Panel Toggle)
  Widget _buildMobileTabletLayout(BuildContext context, AppLocalizations locale) {
    return Stack(
      children: [
        // Full screen PDF Preview
        _buildPreview(context),

        // Settings Panel (slides in from left)
        if (_isPanelVisible)
          Container(
            color: Colors.black54,
            child: GestureDetector(
              onTap: () => setState(() => _isPanelVisible = false),
              child: Container(
                color: Colors.transparent,
              ),
            ),
          ),

        if (_isPanelVisible)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.8,
              child: _buildSidebar(context, locale),
            ),
          ),

        // FAB to toggle settings
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            onPressed: () => setState(() => _isPanelVisible = !_isPanelVisible),
            child: Icon(_isPanelVisible ? Icons.close : Icons.settings),
          ),
        ),
      ],
    );
  }

  // Mobile/Tablet Header with Share button
  Widget _buildMobileHeader(BuildContext context, AppLocalizations locale) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const Spacer(),
          Text(
            locale.printPreview,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const Spacer(),
          // Share button
          IconButton(
            icon: _isSharing
                ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2)
            )
                : const Icon(Icons.share),
            onPressed: _isSharing ? null : _sharePDF,
          ),
          const SizedBox(width: 8),
          // Print button
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () {
              final printer = context.read<PrinterCubit>().state!;

              final language = context.read<PrintLanguageCubit>().state ??
                  context.read<LocalizationBloc>().toString();
              final size = context.read<PaperSizeCubit>().state;
              final orientation = context.read<PageOrientationCubit>().state;

              Navigator.of(context).pop();
              widget.onPrint(
                data: widget.data,
                language: language,
                pageFormat: size,
                orientation: orientation,
                selectedPrinter: printer,
                copies: copies,
                pages: pages,
              );
            },
          ),
        ],
      ),
    );
  }

  // Original Sidebar (now used by both layouts)
  Widget _buildSidebar(BuildContext context, AppLocalizations locale) {
    final currentLocale = context.watch<LocalizationBloc>();
    String sysLanguage = currentLocale.toString();
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(12),
      width: isMobile ? double.infinity : 220,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(5),
        boxShadow: [
          BoxShadow(
            blurRadius: 1,
            color: Theme.of(context).colorScheme.surfaceContainer,
          ),
        ],
      ),
      child: Column(
        spacing: 5,
        children: [
          if (!isMobile) // Hide title on mobile (already in header)
            Row(
              spacing: 5,
              children: [
                Icon(Icons.print_rounded, color: Theme.of(context).colorScheme.outline),
                Text(locale.print, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
          if (!isMobile) SizedBox(height: 5),

          // Copies field and print button
          Row(
            spacing: 8,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: _buildCopiesField(context)),
              Expanded(
                child: ZOutlineButton(
                  isActive: true,
                  width: double.infinity,
                  backgroundHover: Theme.of(context).colorScheme.primary,
                  height: 40,
                  icon: Icons.print,
                  label: Text(locale.print),
                  onPressed: () {

                    final printer = context.read<PrinterCubit>().state!;
                    final language = context.read<PrintLanguageCubit>().state ?? sysLanguage;
                    final size = context.read<PaperSizeCubit>().state;
                    final orientation = context.read<PageOrientationCubit>().state;

                    Navigator.of(context).pop();
                    widget.onPrint(
                      data: widget.data,
                      language: language,
                      pageFormat: size,
                      orientation: orientation,
                      selectedPrinter: printer,
                      copies: copies,
                      pages: pages,
                    );

                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 5),

          PrinterDropdown(
            onPrinterSelected: (value) => context.read<PrinterCubit>().setPrinter(value),
          ),
          const SizedBox(height: 1),

          PageFormatDropdown(
            onFormatSelected: (format) {
              context.read<PaperSizeCubit>().setPaperSize(format);
            },
          ),
          const SizedBox(height: 1),

          PageOrientationDropdown(
            onOrientationSelected: (orientation) =>
                context.read<PageOrientationCubit>().setOrientation(orientation),
          ),
          const SizedBox(height: 1),

          LanguageDropdown(
            onLanguageSelected: (value) =>
                context.read<PrintLanguageCubit>().setLanguage(value.code),
          ),

          const Spacer(),

          // PDF, Share, and Cancel buttons (Desktop)
          if (isMobile) ...[
            // Share button for mobile sidebar
            ZOutlineButton(
              width: double.infinity,
              height: 40,
              icon: Icons.share,
              label: Text(locale.share),
              onPressed: _isSharing ? null : _sharePDF,
            ),
            const SizedBox(height: 0),
          ],

          Row(
            spacing: 8,
            children: [
              Expanded(
                child: ZButton(
                  width: double.infinity,
                  height: 40,
                  label: Text(locale.cancel),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              Expanded(
                child: ZOutlineButton(
                  width: double.infinity,
                  height: 40,
                  icon: FontAwesomeIcons.solidFilePdf,
                  label: Text(locale.saveTitle),
                  onPressed: () {
                    final language =
                        context.read<PrintLanguageCubit>().state ?? sysLanguage;
                    final size = context.read<PaperSizeCubit>().state;
                    final orientation =
                        context.read<PageOrientationCubit>().state;

                    widget.onSave(
                      data: widget.data,
                      language: language,
                      pageFormat: size,
                      orientation: orientation,
                    );
                  },
                ),
              ),
            ],
          ),

          // Desktop share button
          if (!isMobile) ...[
            const SizedBox(height: 0),
            ZOutlineButton(
              width: double.infinity,
              height: 40,
              icon: Icons.share,
              label: Text(locale.share),
              onPressed: _isSharing ? null : _sharePDF,
            ),
          ],
        ],
      ),
    );
  }

  // Original Copies Field
  Widget _buildCopiesField(BuildContext context) {
    final bool isRTL = Directionality.of(context) == TextDirection.rtl;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.copies,
          style: TextStyle(
            fontSize: 13,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),

        Container(
          height: 40,
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: .5),
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

                    updateCopies(val, fromTyping: true);
                  },
                ),
              ),

              Container(
                width: 30,
                decoration: BoxDecoration(
                  border: Border(
                    left: isRTL ? BorderSide.none : BorderSide(
                      color: Theme.of(context).colorScheme.outline.withValues(alpha: .5),
                    ),
                    right: isRTL ? BorderSide(
                      color: Theme.of(context).colorScheme.outline.withValues(alpha: .5),
                    ) : BorderSide.none,
                  ),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: Material(
                        child: InkWell(
                          onTap: () => updateCopies(copies + 1),
                          hoverColor: Theme.of(context).colorScheme.outline.withValues(alpha: .1),
                          child: Center(
                            child: Icon(Icons.arrow_drop_up, size: 16),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Material(
                        child: InkWell(
                          onTap: () => updateCopies(copies - 1),
                          hoverColor: Theme.of(context).colorScheme.outline.withValues(alpha: .1),
                          child: Center(
                            child: Icon(Icons.arrow_drop_down, size: 16),
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

  // Original Preview Panel
  Widget _buildPreview(BuildContext context) {
    final currentLocale = context.watch<LocalizationBloc>();
    String sysLanguage = currentLocale.toString();
    final language = context.watch<PrintLanguageCubit>().state ?? sysLanguage;
    final pageFormat = context.watch<PaperSizeCubit>().state;
    final orientation = context.watch<PageOrientationCubit>().state;

    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              blurRadius: 1,
              color: Colors.grey.withValues(alpha: .3),
            ),
          ],
        ),
        child: PdfPreview(
          padding: EdgeInsets.zero,
          useActions: false,
          previewPageMargin: EdgeInsets.zero,
          maxPageWidth: double.infinity,
          dynamicLayout: true,
          shouldRepaint: true,
          canChangeOrientation: true,
          canChangePageFormat: true,
          pdfPreviewPageDecoration: const BoxDecoration(color: Colors.white),
          build: (context) => widget.buildPreview(
            data: widget.data,
            language: language,
            orientation: orientation,
            pageFormat: pageFormat,
          ).then((doc) => doc.save()),
        ),
      ),
    );
  }
}