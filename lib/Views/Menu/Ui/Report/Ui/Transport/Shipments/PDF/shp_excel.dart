import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:zaitoon_petroleum/Features/Other/extensions.dart';
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

      final Workbook workbook = Workbook();
      final Worksheet sheet = workbook.worksheets[0];
      sheet.name = "Shipping Report";

      int currentRow = 1;

      /// TITLE
      final titleRange = sheet.getRangeByName('A$currentRow:N$currentRow');
      titleRange.merge();
      titleRange.setText("SHIPPING REPORT");

      titleRange.cellStyle
        ..fontSize = 16
        ..bold = true
        ..hAlign = HAlignType.center
        ..vAlign = VAlignType.center
        ..backColor = '#005994'
        ..fontColor = '#FFFFFF';

      currentRow++;

      /// DATE RANGE
      final dateRange = sheet.getRangeByName('A$currentRow:N$currentRow');
      dateRange.merge();
      dateRange.setText("Date Range: $fromDate to $toDate");

      dateRange.cellStyle
        ..fontSize = 11
        ..italic = true
        ..hAlign = HAlignType.center;

      currentRow++;

      /// FILTER
      if (filterCustomer != null || filterVehicle != null || filterStatus != null) {

        String filterText = "";

        if (filterCustomer != null) filterText += "Customer: $filterCustomer";
        if (filterVehicle != null) {
          filterText += "${filterText.isNotEmpty ? " | " : ""}Vehicle: $filterVehicle";
        }
        if (filterStatus != null) {
          filterText += "${filterText.isNotEmpty ? " | " : ""}Status: $filterStatus";
        }

        final filterRange = sheet.getRangeByName('A$currentRow:N$currentRow');
        filterRange.merge();
        filterRange.setText(filterText);

        filterRange.cellStyle
          ..fontSize = 11
          ..italic = true
          ..hAlign = HAlignType.center;

        currentRow++;
      }

      /// GENERATED TIME
      final timeRange = sheet.getRangeByName('A$currentRow:N$currentRow');
      timeRange.merge();
      timeRange.setText(
          "Generated: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}");

      timeRange.cellStyle
        ..fontSize = 10
        ..italic = true
        ..hAlign = HAlignType.center;

      currentRow += 2;

      /// HEADERS
      List<String> headers = [
        "No","Loading Date","Customer","Product","Vehicle",
        "Driver","From","To","Load Weight","Unload Weight",
        "Unit","Rent","Total","Status"
      ];

      for (int col = 0; col < headers.length; col++) {

        final cell = sheet.getRangeByIndex(currentRow, col + 1);
        cell.setText(headers[col]);

        cell.cellStyle
          ..fontSize = 12
          ..bold = true
          ..hAlign = HAlignType.center
          ..vAlign = VAlignType.center
          ..backColor = '#005994'
          ..fontColor = '#FFFFFF';

        cell.cellStyle.borders.all.lineStyle = LineStyle.thin;
      }

      currentRow++;

      /// DATA
      double totalRevenue = 0;
      double totalLoadSize = 0;
      double totalUnloadSize = 0;
      int completed = 0;
      int pending = 0;

      for (int i = 0; i < shippingList.length; i++) {

        var shp = shippingList[i];

        double loadSize = double.tryParse(shp.shpLoadSize ?? '0') ?? 0;
        double unloadSize = double.tryParse(shp.shpUnloadSize ?? '0') ?? 0;
        double rent = double.tryParse(shp.shpRent ?? '0') ?? 0;
        double total = double.tryParse(shp.total ?? '0') ?? 0;

        totalRevenue += total;
        totalLoadSize += loadSize;
        totalUnloadSize += unloadSize;

        if (shp.shpStatus == 1) {
          completed++;
        } else {
          pending++;
        }

        List<dynamic> values = [
          i + 1,
          shp.shpMovingDate?.toFormattedDate() ?? "",
          shp.customerName ?? "",
          shp.proName ?? "",
          shp.vehicle ?? "",
          shp.driverName ?? "",
          shp.shpFrom ?? "",
          shp.shpTo ?? "",
          loadSize,
          unloadSize,
          shp.shpUnit ?? "",
          rent,
          total,
          shp.shpStatus == 1 ? "Delivered" : "Pending"
        ];

        for (int col = 0; col < values.length; col++) {

          final cell = sheet.getRangeByIndex(currentRow, col + 1);

          if (values[col] is double || values[col] is int) {
            cell.setNumber((values[col] as num).toDouble());
            cell.cellStyle.hAlign = HAlignType.right;
          } else {
            cell.setText(values[col].toString());
          }

          cell.cellStyle.borders.all.lineStyle = LineStyle.thin;
        }

        currentRow++;
      }

      currentRow++;

      /// SUMMARY
      // Calculate difference as Unload - Load (positive means extra unloaded, negative means shortage)
      double weightDifference = totalUnloadSize - totalLoadSize;

      void summaryRow(String title, String value, {bool isBold = true}) {
        final t = sheet.getRangeByIndex(currentRow, 1, currentRow, 6);
        t.merge();
        t.setText(title);
        t.cellStyle
          ..fontSize = 12
          ..bold = isBold
          ..hAlign = HAlignType.right;

        final v = sheet.getRangeByIndex(currentRow, 7, currentRow, 8);
        v.merge();
        v.setText(value);
        v.cellStyle
          ..fontSize = 12
          ..bold = isBold
          ..hAlign = HAlignType.left;

        currentRow++;
      }

      summaryRow("TOTAL SHIPMENTS:", shippingList.length.toString());
      summaryRow("TOTAL REVENUE:", "${totalRevenue.toAmount()} $baseCurrency");
      summaryRow("TOTAL LOAD:", totalLoadSize.toAmount());
      summaryRow("TOTAL UNLOAD:", totalUnloadSize.toAmount());

      /// WEIGHT DIFFERENCE (Unload - Load)
      String differenceText;
      if (weightDifference > 0) {
        differenceText = "+${weightDifference.toAmount()} (Extra Unloaded)";
      } else if (weightDifference < 0) {
        differenceText = "${weightDifference.toAmount()} (Shortage)";
      } else {
        differenceText = "${weightDifference.toAmount()} (Balanced)";
      }

      summaryRow(
          "WEIGHT DIFFERENCE:",
          differenceText,
          isBold: true
      );

      summaryRow("DELIVERED:", completed.toString());
      summaryRow("PENDING:", pending.toString());

      /// SET COLUMN WIDTHS
      // Column widths in Excel units
      List<double> columnWidths = [
        5.0,   // A: No (very narrow)
        18.0,  // B: Loading Date
        35.0,  // C: Customer (very wide)
        30.0,  // D: Product (wide)
        20.0,  // E: Vehicle
        30.0,  // F: Driver (wide)
        18.0,  // G: From
        18.0,  // H: To
        15.0,  // I: Load Weight
        15.0,  // J: Unload Weight
        8.0,   // K: Unit (narrow)
        15.0,  // L: Rent
        15.0,  // M: Total
        15.0,  // N: Status
      ];

      // Apply widths to each column
      for (int col = 0; col < columnWidths.length; col++) {
        try {
          final column = sheet.getRangeByIndex(1, col + 1);
          column.columnWidth = columnWidths[col];
        } catch (e) {
          "";
        }
      }

      final bytes = workbook.saveAsStream();
      workbook.dispose();

      if (!context.mounted) return;

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