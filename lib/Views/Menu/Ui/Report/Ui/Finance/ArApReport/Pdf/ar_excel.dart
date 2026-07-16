import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../../../../../../../Features/Other/extensions.dart';
import '../../../../../../../../Features/Other/toast.dart';
import '../../../../../../../../Features/Widgets/outline_button.dart';
import '../../../../../../../../Localizations/l10n/translations/app_localizations.dart';
import '../model/ar_ap_model.dart';

class ArApExcelService {
  static Future<void> exportToExcel({
    required List<ArApModel> accounts,
    required String reportType, // "AR" or "AP"
    required String fileName,
    required BuildContext context,
    String? companyName,
    String? companyAddress,
    String? companyPhone,
    String? companyEmail,
  }) async {
    if (accounts.isEmpty) {
      _showToast(context, "No data to export", isError: true);
      return;
    }

    try {
      final Workbook workbook = Workbook();
      final Worksheet sheet = workbook.worksheets[0];
      sheet.name = reportType == "AR" ? "Receivables" : "Payables";

      int currentRow = 1;

      /// TITLE
      final titleRange = sheet.getRangeByName('A$currentRow:H$currentRow');
      titleRange.merge();
      titleRange.setText(reportType == "AR"
          ? "ACCOUNTS RECEIVABLE REPORT"
          : "ACCOUNTS PAYABLE REPORT");

      titleRange.cellStyle
        ..fontSize = 16
        ..bold = true
        ..hAlign = HAlignType.center
        ..vAlign = VAlignType.center
        ..backColor = '#005994'
        ..fontColor = '#FFFFFF';

      currentRow++;

      /// COMPANY INFORMATION
      if (companyName != null && companyName.isNotEmpty) {
        final companyRange = sheet.getRangeByName('A$currentRow:H$currentRow');
        companyRange.merge();
        companyRange.setText(companyName);
        companyRange.cellStyle
          ..fontSize = 14
          ..bold = true
          ..hAlign = HAlignType.left;
        currentRow++;
      }

      if (companyAddress != null && companyAddress.isNotEmpty) {
        final addressRange = sheet.getRangeByName('A$currentRow:H$currentRow');
        addressRange.merge();
        addressRange.setText("Address: $companyAddress");
        addressRange.cellStyle
          ..fontSize = 11
          ..hAlign = HAlignType.left;
        currentRow++;
      }

      String contactInfo = "";
      if (companyPhone != null && companyPhone.isNotEmpty) {
        contactInfo += "Phone: $companyPhone";
      }
      if (companyEmail != null && companyEmail.isNotEmpty) {
        contactInfo += "${contactInfo.isNotEmpty ? " | " : ""}Email: $companyEmail";
      }
      if (contactInfo.isNotEmpty) {
        final contactRange = sheet.getRangeByName('A$currentRow:H$currentRow');
        contactRange.merge();
        contactRange.setText(contactInfo);
        contactRange.cellStyle
          ..fontSize = 11
          ..hAlign = HAlignType.left;
        currentRow++;
      }

      currentRow++;

      /// REPORT SUMMARY
      // Total accounts count
      final summaryRange1 = sheet.getRangeByName('A$currentRow:H$currentRow');
      summaryRange1.merge();
      summaryRange1.setText("Total ${reportType == "AR" ? "Receivables" : "Payables"} Accounts: ${accounts.length}");
      summaryRange1.cellStyle
        ..fontSize = 11
        ..bold = true
        ..hAlign = HAlignType.left
        ..backColor = '#E8F4FD';
      currentRow++;

      // Total amount by currency
      final totalsByCurrency = _calculateTotalsByCurrency(accounts);
      for (var entry in totalsByCurrency.entries) {
        final currencyRange = sheet.getRangeByName('A$currentRow:H$currentRow');
        currencyRange.merge();
        currencyRange.setText("Total ${entry.key}: ${entry.value.toAmount()} ${entry.key}");
        currencyRange.cellStyle
          ..fontSize = 11
          ..bold = true
          ..hAlign = HAlignType.left
          ..fontColor = entry.value < 0 ? '#FF0000' : '#008000';
        currentRow++;
      }

      currentRow++;

      /// GENERATED TIME
      final timeRange = sheet.getRangeByName('A$currentRow:H$currentRow');
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
        "Account No",
        "Account Name",
        "Signatory",
        "Phone",
        "Currency",
        "Status",
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
      Map<String, double> currencyTotals = {};

      for (int i = 0; i < accounts.length; i++) {
        var account = accounts[i];

        double balance = account.balance.abs();
        String currency = account.accCurrency ?? 'N/A';

        totalBalance += balance;
        currencyTotals[currency] = (currencyTotals[currency] ?? 0) + balance;

        String statusText = account.accStatus == 1 ? "Active" : "Blocked";

        List<dynamic> values = [
          i + 1,
          account.accNumber?.toString() ?? "",
          account.accName ?? "",
          account.fullName ?? "",
          account.perPhone ?? "",
          currency,
          statusText,
          balance,
        ];

        for (int col = 0; col < values.length; col++) {
          final cell = sheet.getRangeByIndex(currentRow, col + 1);

          // FIX 1: Handle index column separately (col 0) to avoid decimal formatting
          if (col == 0) {
            // Index column - set as integer, no decimal
            cell.setNumber((values[col] as int).toDouble());
            cell.numberFormat = '0'; // Integer format, no decimals
            cell.cellStyle.hAlign = HAlignType.center;
          } else if (col == 7) {
            // Balance column - format as currency with 2 decimals
            cell.setNumber((values[col] as num).toDouble());
            cell.numberFormat = '#,##0.00';
            cell.cellStyle.hAlign = HAlignType.right;

            // Color balance based on value
            if (account.balance < 0) {
              cell.cellStyle.fontColor = '#FF0000';
            } else {
              cell.cellStyle.fontColor = '#008000';
            }
          } else if (col == 6) {
            // Status column
            cell.setText(values[col].toString());
            cell.cellStyle.hAlign = HAlignType.center;

            // Color status
            if (account.accStatus == 1) {
              cell.cellStyle.fontColor = '#008000';
            } else {
              cell.cellStyle.fontColor = '#FF0000';
            }
          } else {
            // Other columns - set as text
            cell.setText(values[col].toString());
            cell.cellStyle.hAlign = col == 2 || col == 3 ? HAlignType.left : HAlignType.center;
          }

          cell.cellStyle.borders.all.lineStyle = LineStyle.thin;
        }

        currentRow++;
      }

      currentRow++;

      /// SUMMARY SECTION
      void summaryRow(String title, String value, {bool isBold = true, String? fontColor}) {
        final t = sheet.getRangeByIndex(currentRow, 1, currentRow, 3);
        t.merge();
        t.setText(title);
        t.cellStyle
          ..fontSize = 12
          ..bold = isBold
          ..hAlign = HAlignType.right;

        final v = sheet.getRangeByIndex(currentRow, 4, currentRow, 8);
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

      // Add a separator row
      currentRow++;

      summaryRow("GRAND TOTAL:", "${accounts.first.accCurrency ?? ''}${totalBalance.toAmount()}",
          fontColor: '#005994');

      // Currency-wise totals
      for (var entry in currencyTotals.entries) {
        summaryRow(
            "TOTAL ${entry.key}:",
            "${entry.value.toAmount()} ${entry.key}",
            fontColor: entry.value < 0 ? '#FF0000' : '#008000'
        );
      }

      currentRow++;

      /// SUMMARY STATISTICS
      // Active vs Blocked accounts
      int activeCount = accounts.where((a) => a.accStatus == 1).length;
      int blockedCount = accounts.where((a) => a.accStatus != 1).length;

      final statsRange1 = sheet.getRangeByName('A$currentRow:H$currentRow');
      statsRange1.merge();
      statsRange1.setText("Active Accounts: $activeCount | Blocked Accounts: $blockedCount");
      statsRange1.cellStyle
        ..fontSize = 11
        ..italic = true
        ..hAlign = HAlignType.left;
      currentRow++;

      /// SET COLUMN WIDTHS
      List<double> columnWidths = [
        8.0,   // A: No
        15.0,  // B: Account No
        30.0,  // C: Account Name
        25.0,  // D: Signatory
        18.0,  // E: Phone
        12.0,  // F: Currency
        15.0,  // G: Status
        18.0,  // H: Balance
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

      // Auto-fit specific columns
      for (int col = 0; col < 8; col++) {
        try {
          final column = sheet.getRangeByIndex(1, col + 1);
          column.autoFitColumns();
        } catch (e) {
          // Ignore auto-fit errors
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

  static Map<String, double> _calculateTotalsByCurrency(List<ArApModel> accounts) {
    final Map<String, double> totals = {};
    for (var account in accounts) {
      final currency = account.accCurrency ?? 'N/A';
      totals[currency] = (totals[currency] ?? 0.0) + account.balance.abs();
    }
    return totals;
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