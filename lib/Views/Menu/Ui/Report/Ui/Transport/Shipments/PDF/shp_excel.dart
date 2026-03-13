import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:zaitoon_petroleum/Features/Other/toast.dart';
import 'package:zaitoon_petroleum/Features/Widgets/outline_button.dart';
import 'package:zaitoon_petroleum/Localizations/l10n/translations/app_localizations.dart';
import '../model/shp_report_model.dart';
import 'package:zaitoon_petroleum/Features/Date/shamsi_converter.dart';

class ShippingReportExcelService {

  static Future<void> exportToExcel({
    required List<ShippingReportModel> shippingList,
    required String fromDate,
    required String toDate,
    required String? filterCustomer,
    required String? filterVehicle,
    required String? filterStatus,
    required String baseCurrency,
    required String fileName,
    required BuildContext context,
  }) async {
    if (shippingList.isEmpty) {
      _showToast(context, "No data to export", isError: true);
      return;
    }

    try {
      // Create a new Excel document
      final Workbook workbook = Workbook();

      // Access the sheet
      final Worksheet sheet = workbook.worksheets[0];
      sheet.name = "Shipping Report";

      // After populating all data, auto-fit all columns with proper error handling
      for (int i = 1; i <= 14; i++) {
        try {
          // Auto-fit the column based on content
          sheet.autoFitColumn(i);
        } catch (e) {
          // If auto-fit fails, set a default width using range
          try {
            // Get the first cell in the column and set its column width
            // Column widths are set in points (character units)
            final range = sheet.getRangeByIndex(1, i); // Row 1, Column i
            range.columnWidth = 15; // 15 characters width as fallback
          } catch (e2) {
            // Silently fail - better to have default Excel widths than crash
          }
        }
      }

      int currentRow = 1;

      // Add title - merged across all columns
      final titleRange = sheet.getRangeByName('A$currentRow:N$currentRow');
      titleRange.merge();
      titleRange.setText("SHIPPING REPORT");

      final titleStyle = titleRange.cellStyle;
      titleStyle.fontSize = 16;
      titleStyle.bold = true;
      titleStyle.hAlign = HAlignType.center;  // Note: lowercase 'c'
      titleStyle.vAlign = VAlignType.center;  // Note: lowercase 'c'
      titleStyle.backColor = '#005994';
      titleStyle.fontColor = '#FFFFFF';
      currentRow++;

      // Add date range - merged
      final dateRange = sheet.getRangeByName('A$currentRow:N$currentRow');
      dateRange.merge();
      dateRange.setText("Date Range: $fromDate to $toDate");

      final dateStyle = dateRange.cellStyle;
      dateStyle.fontSize = 11;
      dateStyle.italic = true;
      dateStyle.hAlign = HAlignType.center;
      currentRow++;

      // Add filters if any - merged
      if (filterCustomer != null || filterVehicle != null || filterStatus != null) {
        String filterText = "";
        if (filterCustomer != null) filterText += "Customer: $filterCustomer";
        if (filterVehicle != null) filterText += "${filterText.isNotEmpty ? " | " : ""}Vehicle: $filterVehicle";
        if (filterStatus != null) filterText += "${filterText.isNotEmpty ? " | " : ""}Status: $filterStatus";

        final filterRange = sheet.getRangeByName('A$currentRow:N$currentRow');
        filterRange.merge();
        filterRange.setText(filterText);

        final filterStyle = filterRange.cellStyle;
        filterStyle.fontSize = 11;
        filterStyle.italic = true;
        filterStyle.hAlign = HAlignType.center;
        currentRow++;
      }

      // Add generation timestamp - merged
      final timeRange = sheet.getRangeByName('A$currentRow:N$currentRow');
      timeRange.merge();
      timeRange.setText("Generated: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}");

      final timeStyle = timeRange.cellStyle;
      timeStyle.fontSize = 10;
      timeStyle.italic = true;
      timeStyle.hAlign = HAlignType.center;
      currentRow += 2; // Add extra row for spacing

      // Headers row
      List<String> headers = [
        "No", "Loading Date", "Customer", "Product", "Vehicle",
        "Driver", "From", "To", "Load Weight", "Unload Weight",
        "Unit", "Rent", "Total", "Status"
      ];

      for (int col = 0; col < headers.length; col++) {
        final cell = sheet.getRangeByIndex(currentRow, col + 1);
        cell.setText(headers[col]);

        final cellStyle = cell.cellStyle;
        cellStyle.fontSize = 12;
        cellStyle.bold = true;
        cellStyle.hAlign = HAlignType.center;
        cellStyle.vAlign = VAlignType.center;
        cellStyle.backColor = '#005994';
        cellStyle.fontColor = '#FFFFFF';

        final border = cellStyle.borders;
        border.all.lineStyle = LineStyle.thin;  // Note: lowercase 't'
      }
      currentRow++;

      // Data rows
      double totalRevenue = 0;
      double totalRent = 0;
      double totalLoadSize = 0;
      double totalUnloadSize = 0;
      int completed = 0;
      int pending = 0;

      for (int i = 0; i < shippingList.length; i++) {
        var shp = shippingList[i];

        // Calculate totals
        double loadSize = double.tryParse(shp.shpLoadSize ?? '0') ?? 0;
        double unloadSize = double.tryParse(shp.shpUnloadSize ?? '0') ?? 0;
        double rent = double.tryParse(shp.shpRent ?? '0') ?? 0;
        double total = double.tryParse(shp.total ?? '0') ?? 0;

        totalRevenue += total;
        totalRent += rent;
        totalLoadSize += loadSize;
        totalUnloadSize += unloadSize;

        if (shp.shpStatus == 1) {
          completed++;
        } else {
          pending++;
        }

        // No.
        var cell1 = sheet.getRangeByIndex(currentRow, 1);
        cell1.setNumber(i + 1);
        cell1.cellStyle.hAlign = HAlignType.center;
        cell1.cellStyle.borders.all.lineStyle = LineStyle.thin;

        // Date
        var cell2 = sheet.getRangeByIndex(currentRow, 2);
        cell2.setText(shp.shpMovingDate?.toFormattedDate() ?? "");
        cell2.cellStyle.hAlign = HAlignType.center;
        cell2.cellStyle.borders.all.lineStyle = LineStyle.thin;

        // Customer
        var cell3 = sheet.getRangeByIndex(currentRow, 3);
        cell3.setText(shp.customerName ?? "");
        cell3.cellStyle.borders.all.lineStyle = LineStyle.thin;

        // Product
        var cell4 = sheet.getRangeByIndex(currentRow, 4);
        cell4.setText(shp.proName ?? "");
        cell4.cellStyle.borders.all.lineStyle = LineStyle.thin;

        // Vehicle
        var cell5 = sheet.getRangeByIndex(currentRow, 5);
        cell5.setText(shp.vehicle ?? "");
        cell5.cellStyle.borders.all.lineStyle = LineStyle.thin;

        // Driver
        var cell6 = sheet.getRangeByIndex(currentRow, 6);
        cell6.setText(shp.driverName ?? "");
        cell6.cellStyle.borders.all.lineStyle = LineStyle.thin;

        // From
        var cell7 = sheet.getRangeByIndex(currentRow, 7);
        cell7.setText(shp.shpFrom ?? "");
        cell7.cellStyle.borders.all.lineStyle = LineStyle.thin;

        // To
        var cell8 = sheet.getRangeByIndex(currentRow, 8);
        cell8.setText(shp.shpTo ?? "");
        cell8.cellStyle.borders.all.lineStyle = LineStyle.thin;

        // Load Size
        var cell9 = sheet.getRangeByIndex(currentRow, 9);
        cell9.setNumber(loadSize);
        cell9.cellStyle.hAlign = HAlignType.right;  // Note: lowercase 'r'
        cell9.cellStyle.borders.all.lineStyle = LineStyle.thin;

        // Unload Size
        var cell10 = sheet.getRangeByIndex(currentRow, 10);
        cell10.setNumber(unloadSize);
        cell10.cellStyle.hAlign = HAlignType.right;
        cell10.cellStyle.borders.all.lineStyle = LineStyle.thin;

        // Unit
        var cell11 = sheet.getRangeByIndex(currentRow, 11);
        cell11.setText(shp.shpUnit ?? "");
        cell11.cellStyle.hAlign = HAlignType.center;
        cell11.cellStyle.borders.all.lineStyle = LineStyle.thin;

        // Rent
        var cell12 = sheet.getRangeByIndex(currentRow, 12);
        cell12.setNumber(rent);
        cell12.cellStyle.hAlign = HAlignType.right;
        cell12.cellStyle.borders.all.lineStyle = LineStyle.thin;

        // Total
        var cell13 = sheet.getRangeByIndex(currentRow, 13);
        cell13.setNumber(total);
        cell13.cellStyle.hAlign = HAlignType.right;
        cell13.cellStyle.bold = true;
        cell13.cellStyle.borders.all.lineStyle = LineStyle.thin;

        // Status
        var cell14 = sheet.getRangeByIndex(currentRow, 14);
        cell14.setText(shp.shpStatus == 1 ? "Delivered" : "Pending");
        cell14.cellStyle.hAlign = HAlignType.center;
        cell14.cellStyle.borders.all.lineStyle = LineStyle.thin;

        if (shp.shpStatus == 1) {
          cell14.cellStyle.backColor = '#C6EFCE';
          cell14.cellStyle.fontColor = '#006100';
        } else {
          cell14.cellStyle.backColor = '#FFEB9C';
          cell14.cellStyle.fontColor = '#9C5700';
        }

        currentRow++;
      }

      // Add empty row before summary
      currentRow++;

      // Summary section - merged columns for better presentation

      // Total Shipments
      var totalShipmentsRange = sheet.getRangeByIndex(currentRow, 1, currentRow, 6);
      totalShipmentsRange.merge();
      totalShipmentsRange.setText("TOTAL SHIPMENTS:");
      totalShipmentsRange.cellStyle.fontSize = 12;
      totalShipmentsRange.cellStyle.bold = true;
      totalShipmentsRange.cellStyle.hAlign = HAlignType.right;

      var totalShipmentsValue = sheet.getRangeByIndex(currentRow, 7, currentRow, 8);
      totalShipmentsValue.merge();
      totalShipmentsValue.setText(shippingList.length.toString());
      totalShipmentsValue.cellStyle.fontSize = 12;
      totalShipmentsValue.cellStyle.bold = true;
      totalShipmentsValue.cellStyle.hAlign = HAlignType.left;  // Note: lowercase 'l'
      currentRow++;

      // Total Revenue
      var totalRevenueRange = sheet.getRangeByIndex(currentRow, 1, currentRow, 6);
      totalRevenueRange.merge();
      totalRevenueRange.setText("TOTAL REVENUE:");
      totalRevenueRange.cellStyle.fontSize = 12;
      totalRevenueRange.cellStyle.bold = true;
      totalRevenueRange.cellStyle.hAlign = HAlignType.right;

      var totalRevenueValue = sheet.getRangeByIndex(currentRow, 7, currentRow, 8);
      totalRevenueValue.merge();
      totalRevenueValue.setText("${totalRevenue.toStringAsFixed(2)} $baseCurrency");
      totalRevenueValue.cellStyle.fontSize = 12;
      totalRevenueValue.cellStyle.bold = true;
      totalRevenueValue.cellStyle.hAlign = HAlignType.left;
      currentRow++;

      // Total Rent
      var totalRentRange = sheet.getRangeByIndex(currentRow, 1, currentRow, 6);
      totalRentRange.merge();
      totalRentRange.setText("TOTAL RENT:");
      totalRentRange.cellStyle.fontSize = 12;
      totalRentRange.cellStyle.bold = true;
      totalRentRange.cellStyle.hAlign = HAlignType.right;

      var totalRentValue = sheet.getRangeByIndex(currentRow, 7, currentRow, 8);
      totalRentValue.merge();
      totalRentValue.setText("${totalRent.toStringAsFixed(2)} $baseCurrency");
      totalRentValue.cellStyle.fontSize = 12;
      totalRentValue.cellStyle.bold = true;
      totalRentValue.cellStyle.hAlign = HAlignType.left;
      currentRow++;

      // Total Load Size
      var totalLoadRange = sheet.getRangeByIndex(currentRow, 1, currentRow, 6);
      totalLoadRange.merge();
      totalLoadRange.setText("TOTAL LOAD WEIGHT:");
      totalLoadRange.cellStyle.fontSize = 12;
      totalLoadRange.cellStyle.bold = true;
      totalLoadRange.cellStyle.hAlign = HAlignType.right;

      var totalLoadValue = sheet.getRangeByIndex(currentRow, 7, currentRow, 8);
      totalLoadValue.merge();
      totalLoadValue.setText("${totalLoadSize.toStringAsFixed(2)} ${shippingList.first.shpUnit ?? 'TN'}");
      totalLoadValue.cellStyle.fontSize = 12;
      totalLoadValue.cellStyle.bold = true;
      totalLoadValue.cellStyle.hAlign = HAlignType.left;
      currentRow++;

      // Total Unload Size
      var totalUnloadRange = sheet.getRangeByIndex(currentRow, 1, currentRow, 6);
      totalUnloadRange.merge();
      totalUnloadRange.setText("TOTAL UNLOAD WEIGHT:");
      totalUnloadRange.cellStyle.fontSize = 12;
      totalUnloadRange.cellStyle.bold = true;
      totalUnloadRange.cellStyle.hAlign = HAlignType.right;

      var totalUnloadValue = sheet.getRangeByIndex(currentRow, 7, currentRow, 8);
      totalUnloadValue.merge();
      totalUnloadValue.setText("${totalUnloadSize.toStringAsFixed(2)} ${shippingList.first.shpUnit ?? 'TN'}");
      totalUnloadValue.cellStyle.fontSize = 12;
      totalUnloadValue.cellStyle.bold = true;
      totalUnloadValue.cellStyle.hAlign = HAlignType.left;
      currentRow += 2;

      // Status Breakdown
      var statusHeaderRange = sheet.getRangeByIndex(currentRow, 1, currentRow, 14);
      statusHeaderRange.merge();
      statusHeaderRange.setText("STATUS BREAKDOWN");
      statusHeaderRange.cellStyle.fontSize = 14;
      statusHeaderRange.cellStyle.bold = true;
      statusHeaderRange.cellStyle.hAlign = HAlignType.center;
      statusHeaderRange.cellStyle.backColor = '#005994';
      statusHeaderRange.cellStyle.fontColor = '#FFFFFF';
      currentRow++;

      // Completed
      var completedRange = sheet.getRangeByIndex(currentRow, 1, currentRow, 6);
      completedRange.merge();
      completedRange.setText("COMPLETED:");
      completedRange.cellStyle.fontSize = 12;
      completedRange.cellStyle.bold = true;
      completedRange.cellStyle.hAlign = HAlignType.right;

      var completedValue = sheet.getRangeByIndex(currentRow, 7, currentRow, 8);
      completedValue.merge();
      completedValue.setText(completed.toString());
      completedValue.cellStyle.fontSize = 12;
      completedValue.cellStyle.bold = true;
      completedValue.cellStyle.hAlign = HAlignType.left;
      completedValue.cellStyle.backColor = '#C6EFCE';
      completedValue.cellStyle.fontColor = '#006100';
      currentRow++;

      // Pending
      var pendingRange = sheet.getRangeByIndex(currentRow, 1, currentRow, 6);
      pendingRange.merge();
      pendingRange.setText("PENDING:");
      pendingRange.cellStyle.fontSize = 12;
      pendingRange.cellStyle.bold = true;
      pendingRange.cellStyle.hAlign = HAlignType.right;

      var pendingValue = sheet.getRangeByIndex(currentRow, 7, currentRow, 8);
      pendingValue.merge();
      pendingValue.setText(pending.toString());
      pendingValue.cellStyle.fontSize = 12;
      pendingValue.cellStyle.bold = true;
      pendingValue.cellStyle.hAlign = HAlignType.left;
      pendingValue.cellStyle.backColor = '#FFEB9C';
      pendingValue.cellStyle.fontColor = '#9C5700';

      // Auto-fit columns for better display
      for (int i = 1; i <= 14; i++) {
        sheet.autoFitColumn(i);
      }

      // Save the workbook
      final List<int> bytes = workbook.saveAsStream();
      workbook.dispose();

      // Save file
      await _saveFile(bytes, fileName, context);

    } catch (e) {
      if (context.mounted) {
        _showToast(context, "Error exporting to Excel: $e", isError: true);
      }
    }
  }

  static Future<void> _saveFile(List<int> bytes, String fileName, BuildContext context) async {
    try {
      // Get temporary directory
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(bytes);

      if (!context.mounted) return;

      // Show success message with file location
      _showToast(
        context,
        "Excel file saved successfully",
        isError: false,
      );

      // Ask user if they want to open the file
      final openFile = await _showOpenFileDialog(context);

      if (openFile == true && context.mounted) {
        await _openFile(file.path, context);
      }

    } catch (e) {
      if (context.mounted) {
        _showToast(context, "Error saving file: $e", isError: true);
      }
    }
  }

  static Future<bool?> _showOpenFileDialog(BuildContext context) async {
    if (!context.mounted) return false;

    return await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          elevation: 0,

          title: const Text(
            'Export Successful',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Do you want to open the Excel file?',
            style: TextStyle(fontSize: 14),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          titlePadding: const EdgeInsets.fromLTRB(15, 20, 15, 8),
          contentPadding: const EdgeInsets.fromLTRB(15, 8, 15, 16),
          actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          actions: [
            ZOutlineButton(
              width: 80,
              height: 40,
              onPressed: () => Navigator.of(dialogContext).pop(false),
              label: Text(
                AppLocalizations.of(context)!.cancel,
              ),
            ),
            ZOutlineButton(
              height: 38,
              width: 80,
              isActive: true,
              onPressed: () => Navigator.of(dialogContext).pop(true),
              label: Text(
                AppLocalizations.of(context)!.yes,
              ),
            ),
          ],
        );
      },
    );
  }

  static Future<void> _openFile(String filePath, BuildContext context) async {
    try {
      final Uri fileUri = Uri.file(filePath);

      if (await canLaunchUrl(fileUri)) {
        await launchUrl(fileUri);
      } else {
        if (context.mounted) {
          _showToast(
            context,
            "Could not open file. Please open manually at:\n$filePath",
            isError: true,
            duration: const Duration(seconds: 5),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        _showToast(
          context,
          "Error opening file: $e",
          isError: true,
        );
      }
    }
  }

  static void _showToast(
      BuildContext context,
      String message, {
        bool isError = false,
        Duration duration = const Duration(seconds: 3),
      }) {
    if (!context.mounted) return;

    ToastManager.show(context: context,
        title: isError? "Error" : "Success Exported",
        message: message, type: isError? ToastType.error : ToastType.success);
  }
}