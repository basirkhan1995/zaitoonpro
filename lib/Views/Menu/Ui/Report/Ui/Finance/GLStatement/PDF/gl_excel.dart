import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../../../../../../../Features/Date/shamsi_converter.dart';
import '../../../../../../../../Features/Other/extensions.dart';
import '../../../../../../../../Features/Other/toast.dart';
import '../../../../../../../../Features/Widgets/outline_button.dart';
import '../../../../../../../../Localizations/l10n/translations/app_localizations.dart';
import '../model/gl_statement_model.dart';


class GlStatementExcelService {

  static Future<void> exportToExcel({
    required GlStatementModel glStatement,
    required String fromDate,
    required String toDate,
    required String currency,
    required String? branchName,
    required String fileName,
    required BuildContext context,
  }) async {

    final records = glStatement.records;
    if (records == null || records.isEmpty) {
      _showToast(context, "No data to export", isError: true);
      return;
    }

    try {
      final Workbook workbook = Workbook();
      final Worksheet sheet = workbook.worksheets[0];
      sheet.name = "GL Statement";

      int currentRow = 1;

      /// TITLE
      final titleRange = sheet.getRangeByName('A$currentRow:G$currentRow');
      titleRange.merge();
      titleRange.setText("GENERAL LEDGER STATEMENT");

      titleRange.cellStyle
        ..fontSize = 16
        ..bold = true
        ..hAlign = HAlignType.center
        ..vAlign = VAlignType.center
        ..backColor = '#005994'
        ..fontColor = '#FFFFFF';

      currentRow++;

      /// ACCOUNT INFORMATION
      // Account Name
      final accNameRange = sheet.getRangeByName('A$currentRow:G$currentRow');
      accNameRange.merge();
      accNameRange.setText("Account: ${glStatement.accNumber} - ${glStatement.accName ?? ''}");
      accNameRange.cellStyle
        ..fontSize = 12
        ..bold = true
        ..hAlign = HAlignType.left;
      currentRow++;

      // GL Category
      if (glStatement.glCategory != null && glStatement.glCategory!.isNotEmpty) {
        final categoryRange = sheet.getRangeByName('A$currentRow:G$currentRow');
        categoryRange.merge();
        categoryRange.setText("Category: ${glStatement.glCategory}");
        categoryRange.cellStyle
          ..fontSize = 11
          ..bold = true
          ..hAlign = HAlignType.left;
        currentRow++;
      }

      // Branch
      if (glStatement.brcName != null && glStatement.brcName!.isNotEmpty) {
        final branchRange = sheet.getRangeByName('A$currentRow:G$currentRow');
        branchRange.merge();
        branchRange.setText("Branch: ${glStatement.brcName} (${glStatement.brcId ?? ''})");
        branchRange.cellStyle
          ..fontSize = 11
          ..hAlign = HAlignType.left;
        currentRow++;
      }

      // Currency
      final currencyRange = sheet.getRangeByName('A$currentRow:G$currentRow');
      currencyRange.merge();
      String currencyText = "Currency: ${glStatement.ccyCode ?? ''}";
      if (glStatement.ccyName != null && glStatement.ccyName!.isNotEmpty) {
        currencyText += " - ${glStatement.ccyName}";
      }
      currencyText += " (${glStatement.ccySymbol ?? ''})";
      currencyRange.setText(currencyText);
      currencyRange.cellStyle
        ..fontSize = 11
        ..hAlign = HAlignType.left;
      currentRow++;

      /// DATE RANGE
      final dateRange = sheet.getRangeByName('A$currentRow:G$currentRow');
      dateRange.merge();
      dateRange.setText("Period: $fromDate to $toDate");
      dateRange.cellStyle
        ..fontSize = 11
        ..italic = true
        ..hAlign = HAlignType.center;
      currentRow++;

      /// BALANCE INFORMATION
      // Current Balance
      final curBalanceRange = sheet.getRangeByName('A$currentRow:G$currentRow');
      curBalanceRange.merge();
      double curBalance = double.tryParse(glStatement.curBalance ?? '0') ?? 0;
      curBalanceRange.setText("Current Balance: ${glStatement.ccySymbol ?? ''}${curBalance.toAmount()}");
      curBalanceRange.cellStyle
        ..fontSize = 11
        ..bold = true
        ..hAlign = HAlignType.left
        ..fontColor = curBalance < 0 ? '#FF0000' : '#008000';
      currentRow++;

      // Available Balance
      final avilBalanceRange = sheet.getRangeByName('A$currentRow:G$currentRow');
      avilBalanceRange.merge();
      double avilBalance = double.tryParse(glStatement.avilBalance ?? '0') ?? 0;
      avilBalanceRange.setText("Available Balance: ${glStatement.ccySymbol ?? ''}${avilBalance.toAmount()}");
      avilBalanceRange.cellStyle
        ..fontSize = 11
        ..bold = true
        ..hAlign = HAlignType.left
        ..fontColor = avilBalance < 0 ? '#FF0000' : '#008000';
      currentRow++;

      /// GENERATED TIME
      final timeRange = sheet.getRangeByName('A$currentRow:G$currentRow');
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
        "Date",
        "Reference",
        "Narration",
        "Debit",
        "Credit",
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
      double totalDebit = 0;
      double totalCredit = 0;

      for (int i = 0; i < records.length; i++) {
        var record = records[i];

        double debit = double.tryParse(record.debit ?? '0') ?? 0;
        double credit = double.tryParse(record.credit ?? '0') ?? 0;
        double balance = double.tryParse(record.total ?? '0') ?? 0;

        totalDebit += debit;
        totalCredit += credit;

        // Check if it's opening or closing balance
        bool isOpeningBalance = record.trdNarration == "Opening Balance" ||
            record.trdNarration == "بیلانس افتتاحیه";
        bool isClosingBalance = record.trdNarration == "Closing Balance";

        List<dynamic> values = [
          i + 1,
          record.trnEntryDate?.toFormattedDate() ?? "",
          record.trnReference ?? "",
          record.trdNarration ?? "",
          debit,
          credit,
          balance
        ];

        for (int col = 0; col < values.length; col++) {
          final cell = sheet.getRangeByIndex(currentRow, col + 1);

          // Handle index column separately to avoid decimal formatting
          if (col == 0) {
            // Index column - set as integer, no decimal
            cell.setNumber((values[col] as int).toDouble());
            cell.numberFormat = '0'; // Integer format, no decimals
            cell.cellStyle.hAlign = HAlignType.center;
          } else if (col >= 4 && col <= 6) {
            // Debit, Credit, Balance columns - format as currency with 2 decimals
            cell.setNumber((values[col] as num).toDouble());
            cell.numberFormat = '#,##0.00';
            cell.cellStyle.hAlign = HAlignType.right;
          } else {
            // Date, Reference, Narration columns - set as text
            cell.setText(values[col].toString());
            cell.cellStyle.hAlign = col == 3 ? HAlignType.left : HAlignType.center;
          }

          // Highlight opening/closing balance rows
          if (isOpeningBalance || isClosingBalance) {
            cell.cellStyle
              ..bold = true
              ..backColor = '#E8F4FD';
          }

          // Color negative balances in red
          if (col == 6 && balance < 0) {
            cell.cellStyle.fontColor = '#FF0000';
          }

          cell.cellStyle.borders.all.lineStyle = LineStyle.thin;
        }

        currentRow++;
      }

      currentRow++;

      /// SUMMARY
      void summaryRow(String title, String value, {bool isBold = true, String? fontColor}) {
        final t = sheet.getRangeByIndex(currentRow, 1, currentRow, 3);
        t.merge();
        t.setText(title);
        t.cellStyle
          ..fontSize = 12
          ..bold = isBold
          ..hAlign = HAlignType.right;

        final v = sheet.getRangeByIndex(currentRow, 4, currentRow, 7);
        v.merge();
        v.setText(value);
        v.cellStyle
          ..fontSize = 12
          ..bold = isBold
          ..hAlign = HAlignType.left;

        if (fontColor != null) {
          v.cellStyle.fontColor = fontColor;
        }

        currentRow++;
      }

      summaryRow("TOTAL TRANSACTIONS:", records.length.toString());
      summaryRow("TOTAL DEBIT:", "${glStatement.ccySymbol ?? ''}${totalDebit.toAmount()}");
      summaryRow("TOTAL CREDIT:", "${glStatement.ccySymbol ?? ''}${totalCredit.toAmount()}");

      double netBalance = totalCredit - totalDebit;
      String balanceColor = netBalance < 0 ? '#FF0000' : '#008000';
      summaryRow(
          "NET BALANCE:",
          "${glStatement.ccySymbol ?? ''}${netBalance.toAmount()}",
          fontColor: balanceColor
      );

      /// SET COLUMN WIDTHS
      List<double> columnWidths = [
        8.0,   // A: No
        15.0,  // B: Date
        30.0,  // C: Reference
        45.0,  // D: Narration
        18.0,  // E: Debit
        18.0,  // F: Credit
        18.0,  // G: Balance
      ];

      // Apply widths to each column
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

    ToastManager.show(
      context: context,
      title: isError ? "Error" : "Success Exported",
      message: message,
      type: isError ? ToastType.error : ToastType.success,
    );
  }
}