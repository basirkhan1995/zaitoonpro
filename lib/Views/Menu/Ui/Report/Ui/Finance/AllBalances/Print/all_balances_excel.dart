import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../../../../../../../../Features/Other/extensions.dart';
import '../../../../../../../../../Features/Other/toast.dart';
import '../model/all_balances_model.dart';

class AllBalancesExcelService {

  static Future<void> exportToExcel({
    required List<AllBalancesModel> balances,
    required String fileName,
    required BuildContext context,
    String? filterCategory,
  }) async {

    if (balances.isEmpty) {
      _showToast(context, "No data to export", isError: true);
      return;
    }

    try {
      final Workbook workbook = Workbook();
      final Worksheet sheet = workbook.worksheets[0];
      sheet.name = "All Balances";

      int currentRow = 1;

      /// TITLE
      final titleRange = sheet.getRangeByName('A$currentRow:F$currentRow');
      titleRange.merge();
      titleRange.setText("ALL ACCOUNTS BALANCES REPORT");

      titleRange.cellStyle
        ..fontSize = 16
        ..bold = true
        ..hAlign = HAlignType.center
        ..vAlign = VAlignType.center
        ..backColor = '#005994'
        ..fontColor = '#FFFFFF';

      currentRow++;

      /// FILTER INFORMATION (if applied)
      if (filterCategory != null && filterCategory.isNotEmpty) {
        final filterRange = sheet.getRangeByName('A$currentRow:F$currentRow');
        filterRange.merge();
        filterRange.setText("Filter: $filterCategory");
        filterRange.cellStyle
          ..fontSize = 12
          ..italic = true
          ..hAlign = HAlignType.center;
        currentRow++;
      }

      /// GENERATED TIME
      final timeRange = sheet.getRangeByName('A$currentRow:F$currentRow');
      timeRange.merge();
      timeRange.setText("Generated: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}");
      timeRange.cellStyle
        ..fontSize = 10
        ..italic = true
        ..hAlign = HAlignType.center;
      currentRow += 2;

      /// HEADERS
      List<String> headers = [
        "No",
        "Account Number",
        "Account Name",
        "Branch",
        "Category",
        "Balance"
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
      double totalBalance = 0;
      Map<String, double> categoryTotals = {};

      for (int i = 0; i < balances.length; i++) {
        var balance = balances[i];

        double balanceAmount = double.tryParse(balance.balance ?? '0') ?? 0;
        totalBalance += balanceAmount;

        // Track category totals
        String categoryName = balance.acgName ?? 'Uncategorized';
        categoryTotals[categoryName] = (categoryTotals[categoryName] ?? 0) + balanceAmount;

        List<dynamic> values = [
          i + 1,
          balance.trdAccount?.toString() ?? '',
          balance.accName ?? '',
          balance.trdBranch?.toString() ?? '',
          balance.acgName ?? '',
          balanceAmount
        ];

        for (int col = 0; col < values.length; col++) {
          final cell = sheet.getRangeByIndex(currentRow, col + 1);

          // FIX: Handle number formatting
          if (col == 0) {
            // Index column - integer format
            cell.setNumber((values[col] as int).toDouble());
            cell.numberFormat = '0';
            cell.cellStyle.hAlign = HAlignType.center;
          } else if (col == 5) {
            // Balance column - format as currency with 2 decimals
            cell.setNumber((values[col] as num).toDouble());
            cell.numberFormat = '#,##0.00';
            cell.cellStyle.hAlign = HAlignType.right;

            // Color negative balances in red
            if (balanceAmount < 0) {
              cell.cellStyle.fontColor = '#FF0000';
            }
          } else {
            // Other columns - set as text
            cell.setText(values[col].toString());
            cell.cellStyle.hAlign = col == 2 ? HAlignType.left : HAlignType.center;
          }

          // Add currency symbol to balance if needed
          if (col == 5 && balance.trdCcy != null && balance.trdCcy!.isNotEmpty) {
            // We'll handle currency in the summary, not in individual cells
          }

          cell.cellStyle.borders.all.lineStyle = LineStyle.thin;
        }

        currentRow++;
      }

      currentRow += 2;

      /// SUMMARY SECTION
      void summaryRow(String title, String value, {bool isBold = true, String? fontColor}) {
        final titleCell = sheet.getRangeByIndex(currentRow, 1, currentRow, 3);
        titleCell.merge();
        titleCell.setText(title);
        titleCell.cellStyle
          ..fontSize = 12
          ..bold = isBold
          ..hAlign = HAlignType.right;

        final valueCell = sheet.getRangeByIndex(currentRow, 4, currentRow, 6);
        valueCell.merge();
        valueCell.setText(value);
        valueCell.cellStyle
          ..fontSize = 12
          ..bold = isBold
          ..hAlign = HAlignType.left;

        if (fontColor != null) {
          valueCell.cellStyle.fontColor = fontColor;
        }

        currentRow++;
      }

      // Total Transactions
      summaryRow("TOTAL ACCOUNTS:", balances.length.toString());

      // Total Balance
      String balanceColor = totalBalance < 0 ? '#FF0000' : '#008000';
      summaryRow(
          "TOTAL BALANCE:",
          totalBalance.toAmount(),
          fontColor: balanceColor
      );

      currentRow++;

      // Category-wise Summary
      final categoryHeaderRange = sheet.getRangeByName('A$currentRow:F$currentRow');
      categoryHeaderRange.merge();
      categoryHeaderRange.setText("CATEGORY WISE SUMMARY");
      categoryHeaderRange.cellStyle
        ..fontSize = 14
        ..bold = true
        ..hAlign = HAlignType.center
        ..backColor = '#E8F4FD';
      currentRow++;

      // Category Headers
      List<String> categoryHeaders = ["No", "Category", "Total Balance", "Account Count"];
      for (int col = 0; col < categoryHeaders.length; col++) {
        final cell = sheet.getRangeByIndex(currentRow, col + 1);
        cell.setText(categoryHeaders[col]);
        cell.cellStyle
          ..fontSize = 11
          ..bold = true
          ..hAlign = HAlignType.center
          ..backColor = '#F0F0F0';
        cell.cellStyle.borders.all.lineStyle = LineStyle.thin;
      }
      currentRow++;

      int catIndex = 1;
      categoryTotals.forEach((category, total) {
        int count = balances.where((b) => (b.acgName ?? 'Uncategorized') == category).length;

        final cell1 = sheet.getRangeByIndex(currentRow, 1);
        cell1.setNumber(catIndex.toDouble());
        cell1.numberFormat = '0';
        cell1.cellStyle.hAlign = HAlignType.center;

        final cell2 = sheet.getRangeByIndex(currentRow, 2);
        cell2.setText(category);

        final cell3 = sheet.getRangeByIndex(currentRow, 3);
        cell3.setNumber(total);
        cell3.numberFormat = '#,##0.00';
        cell3.cellStyle.hAlign = HAlignType.right;
        if (total < 0) {
          cell3.cellStyle.fontColor = '#FF0000';
        }

        final cell4 = sheet.getRangeByIndex(currentRow, 4);
        cell4.setNumber(count.toDouble());
        cell4.numberFormat = '0';
        cell4.cellStyle.hAlign = HAlignType.center;

        // Apply borders
        for (int col = 1; col <= 4; col++) {
          sheet.getRangeByIndex(currentRow, col).cellStyle.borders.all.lineStyle = LineStyle.thin;
        }

        currentRow++;
        catIndex++;
      });

      currentRow += 2;

      /// SET COLUMN WIDTHS
      List<double> columnWidths = [
        8.0,   // A: No
        18.0,  // B: Account Number
        35.0,  // C: Account Name
        12.0,  // D: Branch
        25.0,  // E: Category
        18.0,  // F: Balance
      ];

      for (int col = 0; col < columnWidths.length; col++) {
        try {
          final column = sheet.getRangeByIndex(1, col + 1);
          column.columnWidth = columnWidths[col];
        } catch (e) {
          // Ignore column width errors
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
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(bytes);

      if (!context.mounted) return;

      _showToast(
        context,
        "Excel file saved successfully",
        isError: false,
      );

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
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Open'),
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
      }) {
    if (!context.mounted) return;

    ToastManager.show(
      context: context,
      title: isError ? "Error" : "Success",
      message: message,
      type: isError ? ToastType.error : ToastType.success,
    );
  }
}