import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart' as pw;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:zaitoonpro/Features/Date/shamsi_converter.dart';
import 'package:zaitoonpro/Features/Other/extensions.dart';
import 'package:zaitoonpro/Features/PrintSettings/print_services.dart';
import 'package:zaitoonpro/Features/PrintSettings/report_model.dart';
import '../model/shp_report_model.dart';

class ShippingReportPdfServices extends PrintServices {
  Future<void> createDocument({
    required List<ShippingReportModel> shippingList,
    required String language,
    required ReportModel company,
    required pw.PdfPageFormat pageFormat,
    required String? filterFromDate,
    required String? filterToDate,
    required String? filterCustomer,
    required String? filterVehicle,
    required String? filterStatus,
  }) async {
    try {
      final document = await generateShippingReport(
        report: company,
        shippingList: shippingList,
        language: language,
        pageFormat: pageFormat,
        filterFromDate: filterFromDate,
        filterToDate: filterToDate,
        filterCustomer: filterCustomer,
        filterVehicle: filterVehicle,
        filterStatus: filterStatus,
      );

      // Save the document
      await saveDocument(
        suggestedName: "Shipping_Report_${company.comName}.pdf",
        pdf: document,
      );
    } catch (e) {
      throw e.toString();
    }
  }

  Future<void> printDocument({
    required List<ShippingReportModel> shippingList,
    required String language,
    required ReportModel company,
    required Printer selectedPrinter,
    required pw.PdfPageFormat pageFormat,
    required int copies,
    required String pages,
    required String? filterFromDate,
    required String? filterToDate,
    required String? filterCustomer,
    required String? filterVehicle,
    required String? filterStatus,
  }) async {
    try {
      final document = await generateShippingReport(
        report: company,
        shippingList: shippingList,
        language: language,
        pageFormat: pageFormat,
        filterFromDate: filterFromDate,
        filterToDate: filterToDate,
        filterCustomer: filterCustomer,
        filterVehicle: filterVehicle,
        filterStatus: filterStatus,
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
    required List<ShippingReportModel> shippingList,
    required String language,
    required ReportModel company,
    required pw.PdfPageFormat pageFormat,
    required String? filterFromDate,
    required String? filterToDate,
    required String? filterCustomer,
    required String? filterVehicle,
    required String? filterStatus,
  }) async {
    return generateShippingReport(
      report: company,
      language: language,
      shippingList: shippingList,
      pageFormat: pageFormat,
      filterFromDate: filterFromDate,
      filterToDate: filterToDate,
      filterCustomer: filterCustomer,
      filterVehicle: filterVehicle,
      filterStatus: filterStatus,
    );
  }

  Future<pw.Document> generateShippingReport({
    required String language,
    required ReportModel report,
    required List<ShippingReportModel> shippingList,
    required pw.PdfPageFormat pageFormat,
    required String? filterFromDate,
    required String? filterToDate,
    required String? filterCustomer,
    required String? filterVehicle,
    required String? filterStatus,
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
        margin: pw.EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        pageFormat: pageFormat,
        textDirection: documentLanguage(language: language),
        orientation: pw.PageOrientation.landscape, // Always landscape
        build: (context) => [
          pw.SizedBox(height: 5),
          horizontalDivider(),
          pw.SizedBox(height: 10),
          // Filters information
          if (filterFromDate != null || filterToDate != null ||
              filterCustomer != null || filterVehicle != null ||
              filterStatus != null)
            pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: pw.PdfColors.grey300, width: 0.7),
                borderRadius: pw.BorderRadius.circular(5),
              ),
              padding: pw.EdgeInsets.all(10),
              child: _buildFiltersWidget(
                language: language,
                filterFromDate: filterFromDate,
                filterToDate: filterToDate,
                filterCustomer: filterCustomer,
                filterVehicle: filterVehicle,
                filterStatus: filterStatus,
              ),
            ),
          pw.SizedBox(height: 15),
          shippingReportSummaryWidget(
            language: language,
            shippingList: shippingList,
            baseCurrency: report.baseCurrency ?? "",
          ),
          pw.SizedBox(height: 15),
          shippingReportTableWidget(
            shippingList: shippingList,
            language: language,
            baseCurrency: report.baseCurrency ?? "",
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

  pw.Widget _buildFiltersWidget({
    required String language,
    required String? filterFromDate,
    required String? filterToDate,
    required String? filterCustomer,
    required String? filterVehicle,
    required String? filterStatus,
  }) {
    final filters = <pw.Widget>[];

    if (filterFromDate != null || filterToDate != null) {
      filters.add(
        pw.Row(
          children: [
            zText(
              text: "${tr(text: 'dateRange', tr: language)}: ",
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
            ),
            zText(
              text: "${filterFromDate ?? ''} - ${filterToDate ?? ''}",
              fontSize: 9,
            ),
          ],
        ),
      );
    }

    if (filterCustomer != null) {
      filters.add(
        pw.Row(
          children: [
            zText(
              text: "${tr(text: 'customer', tr: language)}: ",
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
            ),
            zText(text: filterCustomer, fontSize: 9),
          ],
        ),
      );
    }

    if (filterVehicle != null) {
      filters.add(
        pw.Row(
          children: [
            zText(
              text: "${tr(text: 'vehicle', tr: language)}: ",
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
            ),
            zText(text: filterVehicle, fontSize: 9),
          ],
        ),
      );
    }

    if (filterStatus != null) {
      String statusText = filterStatus;
      if (filterStatus == "1") {
        statusText = tr(text: 'completed', tr: language);
      } else if (filterStatus == "0") {
        statusText = tr(text: 'pending', tr: language);
      }

      filters.add(
        pw.Row(
          children: [
            zText(
              text: "${tr(text: 'status', tr: language)}: ",
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
            ),
            zText(text: statusText, fontSize: 9),
          ],
        ),
      );
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        zText(
          text: tr(text: 'details', tr: language),
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
        ),
        pw.SizedBox(height: 5),
        horizontalDivider(),
        pw.SizedBox(height: 8),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: filters,
        ),
      ],
    );
  }





  pw.Widget shippingReportSummaryWidget({
    required String language,
    required List<ShippingReportModel> shippingList,
    required String baseCurrency,
  }) {
    // Calculate statistics
    int totalShipments = shippingList.length;
    int completedShipments = 0;
    int pendingShipments = 0;
    double totalRevenue = 0.0;
    double totalLoadSize = 0.0;
    double totalUnloadingSize = 0.0;
    double totalDifference = 0.0;
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
      totalLoadSize += parseStringToDouble(shp.shpLoadSize);
      totalUnloadingSize += parseStringToDouble(shp.shpUnloadSize);

      // Calculate difference between load and unload
      final load = parseStringToDouble(shp.shpLoadSize);
      final unload = parseStringToDouble(shp.shpUnloadSize);
      totalDifference += (unload - load).abs();

      if (unit.isEmpty && shp.shpUnit != null && shp.shpUnit!.isNotEmpty) {
        unit = shp.shpUnit!;
      }
    }

    double avgLoadSize = totalShipments > 0 ? totalLoadSize / totalShipments : 0.0;
    double avgUnloadingSize = totalShipments > 0 ? totalUnloadingSize / totalShipments : 0.0;
    double avgDifference = totalShipments > 0 ? totalDifference / totalShipments : 0.0;
    double avgRent = totalUnloadingSize > 0 ? totalRevenue / totalUnloadingSize : 0.0;

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
            text: tr(text: 'shippingReportSummary', tr: language),
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
          ),
          pw.SizedBox(height: 8),
          horizontalDivider(),
          pw.SizedBox(height: 8),
          pw.Wrap(
            spacing: 25,
            runSpacing: 10,
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
                label: tr(text: 'totalLoadSize', tr: language),
                value: "${totalLoadSize.toStringAsFixed(2)} $unit",
                language: language,
              ),
              _buildSummaryItem(
                label: tr(text: 'totalUnLoadSize', tr: language),
                value: "${totalUnloadingSize.toStringAsFixed(2)} $unit",
                language: language,
              ),
              _buildSummaryItem(
                label: tr(text: 'avgLoadSize', tr: language),
                value: "${avgLoadSize.toStringAsFixed(2)} $unit",
                language: language,
              ),
              _buildSummaryItem(
                label: tr(text: 'avgUnLoadSize', tr: language),
                value: "${avgUnloadingSize.toStringAsFixed(2)} $unit",
                language: language,
              ),
              _buildSummaryItem(
                label: tr(text: 'avgDifference', tr: language),
                value: "${avgDifference.toStringAsFixed(2)} $unit",
                language: language,
              ),
              _buildSummaryItem(
                label: tr(text: 'totalRevenue', tr: language),
                value: "${totalRevenue.toAmount()} $baseCurrency",
                language: language,
              ),
              _buildSummaryItem(
                label: tr(text: 'avgRentPerUnit', tr: language),
                value: "${avgRent.toStringAsFixed(2)} $baseCurrency/$unit",
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
    return pw.Container(
      child: pw.Column(
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
      ),
    );
  }

  pw.Widget shippingReportTableWidget({
    required List<ShippingReportModel> shippingList,
    required String language,
    required String baseCurrency,
  }) {
    // Column widths optimized for landscape A4 (842 points wide)
    const noWidth = 10.0;
    const loadDateWidth = 50.0;
    const unloadDateWidth = 50.0;
    const vehicleWidth = 90.0;
    const driverWidth = 60.0;
    const productWidth = 70.0;
    const customerWidth = 90.0;
    const fromWidth = 60.0;
    const toWidth = 60.0;
    const loadSizeWidth = 50.0;
    const unloadSizeWidth = 50.0;
    const rentWidth = 50.0;
    const totalWidth = 70.0;
    const statusWidth = 50.0;

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
                width: noWidth,
                child: zText(
                  text: tr(text: "no", tr: language),
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.SizedBox(
                width: loadDateWidth,
                child: zText(
                  text: "Load Date",
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.SizedBox(
                width: unloadDateWidth,
                child: zText(
                  text: "Unload Date",
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.SizedBox(
                width: vehicleWidth,
                child: zText(
                  text: tr(text: "vehicle", tr: language),
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(
                width: driverWidth,
                child: zText(
                  text: tr(text: "driver", tr: language),
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(
                width: productWidth,
                child: zText(
                  text: tr(text: "product", tr: language),
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(
                width: customerWidth,
                child: zText(
                  text: tr(text: "customer", tr: language),
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(
                width: fromWidth,
                child: zText(
                  text: "From",
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(
                width: toWidth,
                child: zText(
                  text: "To",
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(
                width: loadSizeWidth,
                child: zText(
                  text: "Load",
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                  textAlign: pw.TextAlign.right,
                ),
              ),
              pw.SizedBox(
                width: unloadSizeWidth,
                child: zText(
                  text: "Unload",
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                  textAlign: pw.TextAlign.right,
                ),
              ),
              pw.SizedBox(
                width: rentWidth,
                child: zText(
                  text: "Rent",
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                  textAlign: pw.TextAlign.right,
                ),
              ),
              pw.SizedBox(
                width: totalWidth,
                child: zText(
                  text: "Total",
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                  textAlign: pw.TextAlign.right,
                ),
              ),
              pw.SizedBox(
                width: statusWidth,
                child: zText(
                  text: "Status",
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                  textAlign: pw.TextAlign.center,
                ),
              ),
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
                // Serial No
                pw.SizedBox(
                  width: noWidth,
                  child: zText(
                    text: shippingList[i].no?.toString() ?? "-",
                    fontSize: 7,
                    textAlign: pw.TextAlign.center,
                  ),
                ),

                // Load Date
                pw.SizedBox(
                  width: loadDateWidth,
                  child: zText(
                    text: shippingList[i].shpMovingDate?.toFormattedDate() ?? "-",
                    fontSize: 7,
                    textAlign: pw.TextAlign.center,
                  ),
                ),

                // Unload Date
                pw.SizedBox(
                  width: unloadDateWidth,
                  child: zText(
                    text: shippingList[i].shpArriveDate?.toFormattedDate() ?? "-",
                    fontSize: 7,
                    textAlign: pw.TextAlign.center,
                  ),
                ),

                // Vehicle
                pw.SizedBox(
                  width: vehicleWidth,
                  child: zText(
                    text: shippingList[i].vehicle ?? "-",
                    fontSize: 7,
                  ),
                ),

                // Driver
                pw.SizedBox(
                  width: driverWidth,
                  child: zText(
                    text: shippingList[i].driverName ?? "-",
                    fontSize: 7,
                  ),
                ),

                // Product
                pw.SizedBox(
                  width: productWidth,
                  child: zText(
                    text: shippingList[i].proName ?? "-",
                    fontSize: 7,
                  ),
                ),

                // Customer
                pw.SizedBox(
                  width: customerWidth,
                  child: zText(
                    text: shippingList[i].customerName ?? "-",
                    fontSize: 7,
                  ),
                ),

                // From
                pw.SizedBox(
                  width: fromWidth,
                  child: zText(
                    text: shippingList[i].shpFrom ?? "-",
                    fontSize: 7,
                  ),
                ),

                // To
                pw.SizedBox(
                  width: toWidth,
                  child: zText(
                    text: shippingList[i].shpTo ?? "-",
                    fontSize: 7,
                  ),
                ),

                // Load Size
                pw.SizedBox(
                  width: loadSizeWidth,
                  child: zText(
                    text: "${shippingList[i].shpLoadSize?.toAmount()} ${shippingList[i].shpUnit ?? ""}",
                    fontSize: 7,
                    textAlign: pw.TextAlign.right,
                  ),
                ),

                // Unload Size
                pw.SizedBox(
                  width: unloadSizeWidth,
                  child: zText(
                    text: "${shippingList[i].shpUnloadSize?.toAmount()} ${shippingList[i].shpUnit ?? ""}",
                    fontSize: 7,
                    textAlign: pw.TextAlign.right,
                  ),
                ),

                // Rent
                pw.SizedBox(
                  width: rentWidth,
                  child: zText(
                    text: shippingList[i].shpRent?.toAmount() ?? "0.00",
                    fontSize: 7,
                    textAlign: pw.TextAlign.right,
                  ),
                ),

                // Total
                pw.SizedBox(
                  width: totalWidth,
                  child: zText(
                    text: "${shippingList[i].total?.toAmount()} $baseCurrency",
                    fontSize: 7,
                    fontWeight: pw.FontWeight.bold,
                    textAlign: pw.TextAlign.right,
                  ),
                ),

                // Status - Simple text
                pw.SizedBox(
                  width: statusWidth,
                  child: zText(
                    text: shippingList[i].shpStatus == 1 ? "Delivered" : "Pending",
                    fontSize: 7,
                    color: shippingList[i].shpStatus == 1 ? pw.PdfColors.green800 : pw.PdfColors.orange800,
                    textAlign: pw.TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}