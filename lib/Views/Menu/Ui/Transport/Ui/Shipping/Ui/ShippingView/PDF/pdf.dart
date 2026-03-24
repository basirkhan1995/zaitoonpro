import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart' as pw;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:zaitoonpro/Features/Date/shamsi_converter.dart';
import 'package:zaitoonpro/Features/Other/extensions.dart';
import 'package:zaitoonpro/Features/PrintSettings/print_services.dart';
import 'package:zaitoonpro/Features/PrintSettings/report_model.dart';

import '../model/shipping_model.dart';

class AllShippingPdfServices extends PrintServices {
  final pdf = pw.Document();

  Future<void> createDocument({
    required List<ShippingModel> shippingList,
    required String language,
    required pw.PageOrientation orientation,
    required ReportModel company,
    required pw.PdfPageFormat pageFormat,
  }) async {
    try {
      final document = await generateShippingList(
        report: company,
        shippingList: shippingList,
        language: language,
        orientation: orientation,
        pageFormat: pageFormat,
      );

      // Save the document
      await saveDocument(
        suggestedName: "Shipping_List_${DateTime.now().toIso8601String()}.pdf",
        pdf: document,
      );
    } catch (e) {
      throw e.toString();
    }
  }

  Future<void> printDocument({
    required List<ShippingModel> shippingList,
    required String language,
    required pw.PageOrientation orientation,
    required ReportModel company,
    required Printer selectedPrinter,
    required pw.PdfPageFormat pageFormat,
    required int copies,
    required String pages,
  }) async {
    try {
      final document = await generateShippingList(
        report: company,
        shippingList: shippingList,
        language: language,
        orientation: orientation,
        pageFormat: pageFormat,
      );

      // Use copies parameter for multiple print jobs
      for (int i = 0; i < copies; i++) {
        await Printing.directPrintPdf(
          printer: selectedPrinter,
          onLayout: (pw.PdfPageFormat format) async {
            return document.save();
          },
        );

        // Optional: Add a small delay between copies if needed
        if (i < copies - 1) {
          await Future.delayed(Duration(milliseconds: 100));
        }
      }
    } catch (e) {
      throw e.toString();
    }
  }

  // Real Time document show
  Future<pw.Document> printPreview({
    required String language,
    required ReportModel company,
    required pw.PageOrientation orientation,
    required List<ShippingModel> shippingList,
    required pw.PdfPageFormat pageFormat,
  }) async {
    return generateShippingList(
      report: company,
      language: language,
      orientation: orientation,
      shippingList: shippingList,
      pageFormat: pageFormat,
    );
  }

  Future<pw.Document> generateShippingList({
    required String language,
    required ReportModel report,
    required List<ShippingModel> shippingList,
    required pw.PageOrientation orientation,
    required pw.PdfPageFormat pageFormat,
  }) async {
    final document = pw.Document();
    final prebuiltHeader = await header(report: report);

    // Load your image asset
    final ByteData imageData = await rootBundle.load('assets/images/zaitoonLogo.png');
    final Uint8List imageBytes = imageData.buffer.asUint8List();
    final pw.MemoryImage logoImage = pw.MemoryImage(imageBytes);

    document.addPage(
      pw.MultiPage(
        maxPages: 1000,
        margin: pw.EdgeInsets.symmetric(horizontal: 25, vertical: 10),
        pageFormat: pageFormat,
        textDirection: documentLanguage(language: language),
        orientation: orientation,
        build: (context) => [
          pw.SizedBox(height: 5),
          horizontalDivider(),
          pw.SizedBox(height: 10),
          shippingSummaryWidget(
            language: language,
            shippingList: shippingList,
            baseCurrency: "USD",
          ),
          pw.SizedBox(height: 15),
          shippingTableWidget(
            shippingList: shippingList,
            language: language,
            baseCurrency: "USD",
          ),
        ],
        header: (context) => prebuiltHeader,
        footer: (context) => footer(
          report: report,
          context: context,
          language: language,
          logoImage: logoImage,
        ),
      ),
    );
    return document;
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
            // Company info (left side)
            pw.Expanded(
              flex: 3,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  zText(text: report.comName ?? "", fontSize: 25, tightBounds: true),
                  pw.SizedBox(height: 3),
                  zText(text: report.statementDate ?? "", fontSize: 10),
                ],
              ),
            ),
            // Logo (right side)
            if (image != null)
              pw.Container(
                width: 50,
                height: 50,
                child: pw.Image(image, fit: pw.BoxFit.contain),
              ),
          ],
        ),
        pw.SizedBox(height: 5)
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
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.start,
          children: [
            pw.Container(
              height: 20,
              child: pw.Image(logoImage),
            ),
            verticalDivider(height: 15, width: 0.6),
            zText(
              text: tr(text: 'producedBy', tr: language),
              fontWeight: pw.FontWeight.normal,
              fontSize: 8,
            ),
          ],
        ),
        pw.SizedBox(height: 3),
        horizontalDivider(),
        pw.SizedBox(height: 3),
        pw.Row(
          children: [
            zText(text: report.comAddress ?? "", fontSize: 9),
          ],
        ),
        pw.SizedBox(height: 3),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Row(
              children: [
                zText(text: report.compPhone ?? "", fontSize: 9),
                verticalDivider(height: 10, width: 1),
                zText(text: report.comEmail ?? "", fontSize: 9),
              ],
            ),
            pw.Row(
              children: [
                buildPage(context.pageNumber, context.pagesCount, language),
              ],
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget shippingSummaryWidget({
    required String language,
    required List<ShippingModel> shippingList,
    required String baseCurrency,
  }) {
    // Calculate statistics
    int totalShipments = shippingList.length;
    int completedShipments = 0;
    int pendingShipments = 0;

    double totalRevenue = 0.0;


    double totalUnloadingSize = 0.0;

    String unit = "";

    // Helper function to parse string to double
    double parseStringToDouble(String? value) {
      if (value == null || value.isEmpty) return 0.0;
      try {
        // Remove any commas and convert to double
        return double.tryParse(value.replaceAll(',', '')) ?? 0.0;
      } catch (e) {
        return 0.0;
      }
    }

    for (var shp in shippingList) {
      if (shp.shpStatus == 1) {
        completedShipments++;
      } else {
        pendingShipments++;
      }

      // Parse string values to double before adding
      totalRevenue += parseStringToDouble(shp.total);
      totalUnloadingSize += parseStringToDouble(shp.shpUnloadSize);

      if (unit.isEmpty && shp.shpUnit != null && shp.shpUnit!.isNotEmpty) {
        unit = shp.shpUnit!;
      }
    }
    double avgUnloadingSize = totalShipments > 0 ? totalUnloadingSize / totalShipments : 0.0;

    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: pw.PdfColors.grey300, width: 0.7),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      padding: pw.EdgeInsets.all(10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          zText(
            text: tr(text: 'shippingSummary', tr: language),
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
          ),
          pw.SizedBox(height: 8),
          horizontalDivider(),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryItem(
                label: tr(text: 'totalShipments', tr: language),
                value: totalShipments.toString(),
                language: language,
              ),
              _buildSummaryItem(
                label: tr(text: 'completed', tr: language),
                value: completedShipments.toString(),
                language: language,
              ),
              _buildSummaryItem(
                label: tr(text: 'pending', tr: language),
                value: pendingShipments.toString(),
                language: language,
              ),

              _buildSummaryItem(
                label: tr(text: 'avgUnLoadSize', tr: language),
                value: "${avgUnloadingSize.toStringAsFixed(2)} $unit",
                language: language,
              ),
              _buildSummaryItem(
                label: tr(text: 'avgLoadSize', tr: language),
                value: "${avgUnloadingSize.toStringAsFixed(2)} $unit",
                language: language,
              ),

              _buildSummaryItem(
                label: tr(text: 'totalRevenue', tr: language),
                value: "${totalRevenue.toAmount()} $baseCurrency",
                language: language,
              ),
            ],
          ),
        ],
      ),
    );
  }
  pw.Widget _buildSummaryItem({
    required String label,
    required String value,
    required String language,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        zText(
          text: label,
          fontSize: 9,
          color: pw.PdfColors.grey600,
        ),
        pw.SizedBox(height: 2),
        zText(
          text: value,
          fontSize: 12,
          fontWeight: pw.FontWeight.bold,
        ),
      ],
    );
  }

  pw.Widget shippingTableWidget({
    required List<ShippingModel> shippingList,
    required String language,
    required String baseCurrency,
  }) {
    const idWidth = 30.0;
    const dateWidth = 60.0;
    const productWidth = 90.0;
    const customerWidth = 65.0;
    const rentWidth = 60.0;
    const unloadWidth = 60.0;
    const totalWidth = 80.0;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Table Header
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(vertical: 6),
          decoration: pw.BoxDecoration(
            color: pw.PdfColors.grey100,
            border: pw.Border(
              bottom: pw.BorderSide(width: 1, color: pw.PdfColors.grey400),
            ),
          ),
          child: pw.Row(
            children: [
              pw.SizedBox(
                width: idWidth,
                child: zText(
                  text: tr(text: "id", tr: language),
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.SizedBox(
                width: dateWidth,
                child: zText(
                  text: tr(text: "date", tr: language),
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Expanded(
                child: zText(
                  text: tr(text: "vehicles", tr: language),
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(
                width: productWidth,
                child: zText(
                  text: tr(text: "products", tr: language),
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(
                width: customerWidth,
                child: zText(
                  text: tr(text: "customer", tr: language),
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(
                width: rentWidth,
                child: zText(
                  text: tr(text: "shippingRent", tr: language),
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  textAlign: pw.TextAlign.right,
                ),
              ),
              // pw.SizedBox(
              //   width: loadWidth,
              //   child: buildTextWidget(
              //     text: getTranslation(locale: "loadingSize", language: language),
              //     fontSize: 9,
              //     fontWeight: pw.FontWeight.bold,
              //     textAlign: pw.TextAlign.right,
              //   ),
              // ),
              pw.SizedBox(
                width: unloadWidth,
                child: zText(
                  text: tr(text: "unloadingSize", tr: language),
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  textAlign: pw.TextAlign.right,
                ),
              ),
              pw.SizedBox(
                width: totalWidth,
                child: zText(
                  text: tr(text: "total", tr: language),
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  textAlign: pw.TextAlign.right,
                ),
              ),
              // pw.SizedBox(
              //   width: statusWidth,
              //   child: buildTextWidget(
              //     text: getTranslation(locale: "status", language: language),
              //     fontSize: 9,
              //     fontWeight: pw.FontWeight.bold,
              //     textAlign: pw.TextAlign.center,
              //   ),
              // ),
            ],
          ),
        ),

        // Data Rows
        for (var i = 0; i < shippingList.length; i++)
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(vertical: 6),
            decoration: pw.BoxDecoration(
              color: i.isOdd ? pw.PdfColors.grey50 : null,
              border: pw.Border(
                bottom: pw.BorderSide(width: 0.25, color: pw.PdfColors.grey300),
              ),
            ),
            child: pw.Row(
              children: [
                // ID
                pw.SizedBox(
                  width: idWidth,
                  child: zText(
                    text: shippingList[i].shpId?.toString() ?? "-",
                    fontSize: 8,
                    textAlign: pw.TextAlign.center,
                  ),
                ),

                // Date
                pw.SizedBox(
                  width: dateWidth,
                  child: zText(
                    text: shippingList[i].shpMovingDate?.toFormattedDate() ?? "-",
                    fontSize: 8,
                  ),
                ),

                // Vehicle
                pw.Expanded(

                  child: zText(
                    text: shippingList[i].vehicle ?? "-",
                    fontSize: 8,
                  ),
                ),

                // Product
                pw.SizedBox(
                  width: productWidth,
                  child: zText(
                    text: shippingList[i].proName ?? "-",
                    fontSize: 8,
                  ),
                ),

                // Customer
                pw.SizedBox(
                  width: customerWidth,
                  child: zText(
                    text: shippingList[i].customer ?? "-",
                    fontSize: 8,
                  ),
                ),

                // Rent
                pw.SizedBox(
                  width: rentWidth,
                  child: zText(
                    text: shippingList[i].shpRent?.toAmount() ?? "0.00",
                    fontSize: 8,
                    textAlign: pw.TextAlign.right,
                  ),
                ),

                // Load Size
                // pw.SizedBox(
                //   width: loadWidth,
                //   child: buildTextWidget(
                //     text: "${shippingList[i].shpLoadSize?.toAmount()} ${shippingList[i].shpUnit ?? ""}",
                //     fontSize: 8,
                //     textAlign: pw.TextAlign.right,
                //   ),
                // ),

                // Unload Size
                pw.SizedBox(
                  width: unloadWidth,
                  child: zText(
                    text: "${shippingList[i].shpUnloadSize?.toAmount()} ${shippingList[i].shpUnit ?? ""}",
                    fontSize: 8,
                    textAlign: pw.TextAlign.right,
                  ),
                ),

                // Total
                pw.SizedBox(
                  width: totalWidth,
                  child: zText(
                    text: "${shippingList[i].total?.toAmount()} $baseCurrency",
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                    textAlign: pw.TextAlign.right,
                  ),
                ),

                // Status
                // pw.SizedBox(
                //   width: statusWidth,
                //   child: _buildStatusBadge(
                //     status: shippingList[i].shpStatus ?? 0,
                //     language: language,
                //   ),
                // ),
              ],
            ),
          ),
      ],
    );
  }
}