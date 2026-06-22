import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../../../../../Features/Date/shamsi_converter.dart';
import '../../../../../../Features/Other/extensions.dart';
import '../../../../../../Features/Other/toast.dart';
import '../../../../../../Features/Widgets/outline_button.dart';
import '../../../../../../Localizations/l10n/translations/app_localizations.dart';
import '../model/project_by_id_model.dart';

class ProjectExcelService {

  static Future<void> exportToExcel({
    required ProjectByIdModel project,
    required String fileName,
    required BuildContext context,
  }) async {

    try {
      final Workbook workbook = Workbook();

      // Sheet 1: Project Overview
      final Worksheet overviewSheet = workbook.worksheets[0];
      overviewSheet.name = "Overview";

      // Sheet 2: Services (if exist)
      Worksheet? servicesSheet;
      if (project.projectServices != null && project.projectServices!.isNotEmpty) {
        servicesSheet = workbook.worksheets.add();
        servicesSheet.name = "Services";
      }

      // Sheet 3: Payments/Transactions (if exist)
      Worksheet? paymentsSheet;
      if (project.projectPayments != null && project.projectPayments!.isNotEmpty) {
        paymentsSheet = workbook.worksheets.add();
        paymentsSheet.name = "Transactions";
      }

      // ============================================
      // SHEET 1: PROJECT OVERVIEW
      // ============================================
      _createOverviewSheet(overviewSheet, project);

      // ============================================
      // SHEET 2: SERVICES
      // ============================================
      if (servicesSheet != null && project.projectServices != null) {
        _createServicesSheet(servicesSheet, project);
      }

      // ============================================
      // SHEET 3: TRANSACTIONS
      // ============================================
      if (paymentsSheet != null && project.projectPayments != null) {
        _createPaymentsSheet(paymentsSheet, project);
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

  static void _createOverviewSheet(Worksheet sheet, ProjectByIdModel project) {
    int currentRow = 1;
    final String currency = project.actCurrency ?? '';

    /// TITLE
    final titleRange = sheet.getRangeByName('A$currentRow:F$currentRow');
    titleRange.merge();
    titleRange.setText("PROJECT REPORT");
    titleRange.cellStyle
      ..fontSize = 16
      ..bold = true
      ..hAlign = HAlignType.center
      ..vAlign = VAlignType.center
      ..backColor = '#005994'
      ..fontColor = '#FFFFFF';

    currentRow += 2;

    /// PROJECT INFORMATION SECTION
    final projectHeader = sheet.getRangeByName('A$currentRow:F$currentRow');
    projectHeader.merge();
    projectHeader.setText("PROJECT INFORMATION");
    projectHeader.cellStyle
      ..fontSize = 13
      ..bold = true
      ..hAlign = HAlignType.left
      ..backColor = '#E8F4FD'
      ..fontColor = '#005994';
    currentRow++;

    void detailRow(String label, String value, {bool isBold = false, String? fontColor}) {
      final labelCell = sheet.getRangeByName('A$currentRow:B$currentRow');
      labelCell.merge();
      labelCell.setText("$label:");
      labelCell.cellStyle
        ..fontSize = 11
        ..bold = true
        ..hAlign = HAlignType.left;

      final valueCell = sheet.getRangeByName('C$currentRow:F$currentRow');
      valueCell.merge();
      valueCell.setText(value);
      valueCell.cellStyle
        ..fontSize = 11
        ..bold = isBold
        ..hAlign = HAlignType.left;

      if (fontColor != null) {
        valueCell.cellStyle.fontColor = fontColor;
      }

      currentRow++;
    }

    detailRow("Project Name", project.prjName ?? '-', isBold: true);
    detailRow("Project ID", project.prjId?.toString() ?? '-');
    detailRow("Location", project.prjLocation ?? '-');
    detailRow("Details", project.prjDetails ?? '-');
    detailRow("Deadline", project.prjDateLine?.toFormattedDate() ?? '-');
    detailRow("Entry Date", project.prjEntryDate?.toFormattedDate() ?? '-');

    String statusText = project.prjStatus == 0 ? "In Progress" : "Completed";
    String statusColor = project.prjStatus == 0 ? '#FF8C00' : '#008000';
    detailRow("Status", statusText, isBold: true, fontColor: statusColor);

    currentRow++;

    /// OWNER INFORMATION SECTION
    final ownerHeader = sheet.getRangeByName('A$currentRow:F$currentRow');
    ownerHeader.merge();
    ownerHeader.setText("OWNER INFORMATION");
    ownerHeader.cellStyle
      ..fontSize = 13
      ..bold = true
      ..hAlign = HAlignType.left
      ..backColor = '#E8F4FD'
      ..fontColor = '#005994';
    currentRow++;

    detailRow("Client/Owner", project.prjOwnerfullName ?? '-', isBold: true);
    detailRow("Account Number", project.prjOwnerAccount?.toString() ?? '-');
    detailRow("Currency", currency);

    currentRow++;

    /// FINANCIAL SUMMARY SECTION
    final financialHeader = sheet.getRangeByName('A$currentRow:F$currentRow');
    financialHeader.merge();
    financialHeader.setText("FINANCIAL SUMMARY");
    financialHeader.cellStyle
      ..fontSize = 13
      ..bold = true
      ..hAlign = HAlignType.left
      ..backColor = '#E8F4FD'
      ..fontColor = '#005994';
    currentRow++;

    // Calculate totals
    double totalServices = 0;
    double totalIncome = 0;
    double totalExpense = 0;

    if (project.projectServices != null) {
      for (var service in project.projectServices!) {
        totalServices += double.tryParse(service.total ?? '0') ?? 0;
      }
    }

    if (project.projectPayments != null) {
      for (var payment in project.projectPayments!) {
        if (payment.prpType == "Payment") {
          totalIncome += double.tryParse(payment.payments ?? '0') ?? 0;
        } else if (payment.prpType == "Expense") {
          totalExpense += double.tryParse(payment.expenses ?? '0') ?? 0;
        }
      }
    }

    double balance = totalIncome - totalExpense;
    double outstanding = totalServices - totalIncome + totalExpense;

    // Financial Table
    void financialRow(String label, double value, {String? fontColor, bool isBold = false}) {
      final labelCell = sheet.getRangeByIndex(currentRow, 1, currentRow, 4);
      labelCell.merge();
      labelCell.setText(label);
      labelCell.cellStyle
        ..fontSize = 11
        ..bold = isBold
        ..hAlign = HAlignType.left;
      labelCell.cellStyle.borders.all.lineStyle = LineStyle.thin;

      final valueCell = sheet.getRangeByIndex(currentRow, 5, currentRow, 6);
      valueCell.merge();
      valueCell.setNumber(value);
      valueCell.numberFormat = '#,##0.00';
      valueCell.cellStyle
        ..fontSize = 11
        ..bold = true
        ..hAlign = HAlignType.right;
      valueCell.cellStyle.borders.all.lineStyle = LineStyle.thin;

      if (fontColor != null) {
        valueCell.cellStyle.fontColor = fontColor;
      }

      currentRow++;
    }

    financialRow("Total Services Value:", totalServices, fontColor: '#005994');
    financialRow("Total Income (Payments):", totalIncome, fontColor: '#008000');
    financialRow("Total Expenses:", totalExpense, fontColor: '#FF0000');
    financialRow("Balance (Income - Expenses):", balance,
        fontColor: balance >= 0 ? '#008000' : '#FF0000', isBold: true);
    financialRow("Outstanding (Services - Balance):", outstanding,
        fontColor: outstanding > 0 ? '#FF0000' : '#008000');

    currentRow += 2;

    /// GENERATED TIME
    final timeRange = sheet.getRangeByName('A$currentRow:F$currentRow');
    timeRange.merge();
    timeRange.setText("Generated: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}");
    timeRange.cellStyle
      ..fontSize = 10
      ..italic = true
      ..hAlign = HAlignType.center;

    // Set column widths for overview sheet
    List<double> columnWidths = [18.0, 18.0, 18.0, 18.0, 18.0, 18.0];
    for (int col = 0; col < columnWidths.length; col++) {
      try {
        final column = sheet.getRangeByIndex(1, col + 1);
        column.columnWidth = columnWidths[col];
      } catch (e) {
        throw e.toString();
      }
    }
  }

  static void _createServicesSheet(Worksheet sheet, ProjectByIdModel project) {
    int currentRow = 1;
    final services = project.projectServices!;
    final String currency = project.actCurrency ?? '';

    /// TITLE
    final titleRange = sheet.getRangeByName('A$currentRow:G$currentRow');
    titleRange.merge();
    titleRange.setText("PROJECT SERVICES - ${project.prjName ?? ''}");
    titleRange.cellStyle
      ..fontSize = 16
      ..bold = true
      ..hAlign = HAlignType.center
      ..vAlign = VAlignType.center
      ..backColor = '#005994'
      ..fontColor = '#FFFFFF';

    currentRow += 2;

    /// HEADERS
    List<String> headers = [
      "No",
      "Service Name",
      "Reference",
      "Quantity",
      "Unit Price",
      "Total",
      "Status"
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
    double totalSum = 0;

    for (int i = 0; i < services.length; i++) {
      var service = services[i];

      double quantity = double.tryParse(service.pjdQuantity ?? '0') ?? 0;
      double pricePerQty = double.tryParse(service.pjdPricePerQty ?? '0') ?? 0;
      double total = double.tryParse(service.total ?? '0') ?? 0;
      totalSum += total;

      List<dynamic> values = [
        i + 1,
        service.srvName ?? "",
        service.prpTrnRef ?? "",
        quantity,
        pricePerQty,
        total,
        service.pjdStatus == 0 ? "Pending" : "Completed"
      ];

      for (int col = 0; col < values.length; col++) {
        final cell = sheet.getRangeByIndex(currentRow, col + 1);

        if (col == 0) {
          cell.setNumber((values[col] as int).toDouble());
          cell.numberFormat = '0';
          cell.cellStyle.hAlign = HAlignType.center;
        } else if (col >= 3 && col <= 5) {
          cell.setNumber((values[col] as num).toDouble());
          cell.numberFormat = '#,##0.00';
          cell.cellStyle.hAlign = HAlignType.right;
        } else {
          cell.setText(values[col].toString());
          cell.cellStyle.hAlign = HAlignType.left;
        }

        // Bold for total column
        if (col == 5) {
          cell.cellStyle.bold = true;
          cell.cellStyle.fontColor = '#005994';
        }

        // Color status
        if (col == 6) {
          cell.cellStyle.fontColor = values[col] == "Pending" ? '#FF8C00' : '#008000';
        }

        // Highlight alternate rows
        if (i.isOdd) {
          cell.cellStyle.backColor = '#F5F5F5';
        }

        cell.cellStyle.borders.all.lineStyle = LineStyle.thin;
      }
      currentRow++;
    }

    // Total Row
    currentRow++;
    final totalLabel = sheet.getRangeByIndex(currentRow, 1, currentRow, 4);
    totalLabel.merge();
    totalLabel.setText("TOTAL SERVICES VALUE");
    totalLabel.cellStyle
      ..fontSize = 11
      ..bold = true
      ..hAlign = HAlignType.right;
    totalLabel.cellStyle.borders.all.lineStyle = LineStyle.thin;

    final totalValue = sheet.getRangeByIndex(currentRow, 5, currentRow, 6);
    totalValue.merge();
    totalValue.setNumber(totalSum);
    totalValue.numberFormat = '#,##0.00';
    totalValue.cellStyle
      ..fontSize = 11
      ..bold = true
      ..hAlign = HAlignType.right
      ..fontColor = '#005994'
      ..backColor = '#E8F4FD';
    totalValue.cellStyle.borders.all.lineStyle = LineStyle.thin;

    final currencyLabel = sheet.getRangeByIndex(currentRow, 7);
    currencyLabel.setText(currency);
    currencyLabel.cellStyle
      ..bold = true
      ..backColor = '#E8F4FD';
    currencyLabel.cellStyle.borders.all.lineStyle = LineStyle.thin;

    // Set column widths
    List<double> columnWidths = [8.0, 35.0, 25.0, 15.0, 18.0, 18.0, 15.0];
    for (int col = 0; col < columnWidths.length; col++) {
      try {
        final column = sheet.getRangeByIndex(1, col + 1);
        column.columnWidth = columnWidths[col];
      } catch (e) {
        throw e.toString();
      }
    }
  }

  static void _createPaymentsSheet(Worksheet sheet, ProjectByIdModel project) {
    int currentRow = 1;
    final payments = project.projectPayments!;
    final String currency = project.actCurrency ?? '';

    /// TITLE
    final titleRange = sheet.getRangeByName('A$currentRow:H$currentRow');
    titleRange.merge();
    titleRange.setText("PROJECT TRANSACTIONS - ${project.prjName ?? ''}");
    titleRange.cellStyle
      ..fontSize = 16
      ..bold = true
      ..hAlign = HAlignType.center
      ..vAlign = VAlignType.center
      ..backColor = '#005994'
      ..fontColor = '#FFFFFF';

    currentRow += 2;

    /// HEADERS
    List<String> headers = [
      "No",
      "Date",
      "Reference",
      "Type",
      "Amount",
      "Currency",
      "Status",
      "Balance Impact"
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
    double totalIncome = 0;
    double totalExpense = 0;

    for (int i = 0; i < payments.length; i++) {
      var payment = payments[i];
      final isPayment = payment.prpType == 'Payment';
      final isExpense = payment.prpType == 'Expense';
      final isEntry = payment.prpType == 'Entry';

      double amount = double.tryParse(
          isPayment ? payment.payments ?? '0' : payment.expenses ?? '0'
      ) ?? 0;

      if (isPayment) totalIncome += amount;
      if (isExpense) totalExpense += amount;

      String typeText = isPayment ? "Payment" : isExpense ? "Expense" : isEntry ? "Entry" : (payment.prpType ?? '-');
      String balanceImpact = isPayment ? "+${amount.toAmount()}" : isExpense ? "-${amount.toAmount()}" : "0";

      List<dynamic> values = [
        i + 1,
        payment.trnEntryDate?.toFormattedDate() ?? "",
        payment.prpTrnRef ?? "",
        typeText,
        amount,
        payment.trdCcy ?? currency,
        payment.trnStateText ?? "",
        balanceImpact
      ];

      for (int col = 0; col < values.length; col++) {
        final cell = sheet.getRangeByIndex(currentRow, col + 1);

        if (col == 0) {
          cell.setNumber((values[col] as int).toDouble());
          cell.numberFormat = '0';
          cell.cellStyle.hAlign = HAlignType.center;
        } else if (col == 4) {
          cell.setNumber((values[col] as num).toDouble());
          cell.numberFormat = '#,##0.00';
          cell.cellStyle.hAlign = HAlignType.right;

          // Color code amounts
          if (isPayment) {
            cell.cellStyle.fontColor = '#008000'; // Green for income
          } else if (isExpense) {
            cell.cellStyle.fontColor = '#FF0000'; // Red for expense
          }
        } else {
          cell.setText(values[col].toString());
          cell.cellStyle.hAlign = HAlignType.left;
        }

        // Color code type column
        if (col == 3) {
          if (isPayment) {
            cell.cellStyle.fontColor = '#008000';
          } else if (isExpense) {
            cell.cellStyle.fontColor = '#FF0000';
          }
          cell.cellStyle.bold = true;
        }

        // Color code status
        if (col == 6) {
          String status = payment.trnStateText?.toLowerCase() ?? '';
          if (status == 'pending') {
            cell.cellStyle.fontColor = '#FF8C00';
          } else if (status == 'authorized' || status == 'approved') {
            cell.cellStyle.fontColor = '#008000';
          } else if (status == 'reversed') {
            cell.cellStyle.fontColor = '#FF0000';
          }
          cell.cellStyle.bold = true;
        }

        // Balance impact formatting
        if (col == 7) {
          cell.cellStyle.hAlign = HAlignType.right;
          cell.cellStyle.bold = true;
          if (isPayment) {
            cell.cellStyle.fontColor = '#008000';
          } else if (isExpense) {
            cell.cellStyle.fontColor = '#FF0000';
          }
        }

        // Highlight alternate rows
        if (i.isOdd) {
          cell.cellStyle.backColor = '#F5F5F5';
        }

        cell.cellStyle.borders.all.lineStyle = LineStyle.thin;
      }
      currentRow++;
    }

    // Summary Section
    currentRow++;

    void summaryRow(String label, double value, {String? fontColor}) {
      final labelCell = sheet.getRangeByIndex(currentRow, 1, currentRow, 5);
      labelCell.merge();
      labelCell.setText(label);
      labelCell.cellStyle
        ..fontSize = 11
        ..bold = true
        ..hAlign = HAlignType.right;
      labelCell.cellStyle.borders.all.lineStyle = LineStyle.thin;

      final valueCell = sheet.getRangeByIndex(currentRow, 6, currentRow, 7);
      valueCell.merge();
      valueCell.setNumber(value);
      valueCell.numberFormat = '#,##0.00';
      valueCell.cellStyle
        ..fontSize = 11
        ..bold = true
        ..hAlign = HAlignType.right;
      valueCell.cellStyle.borders.all.lineStyle = LineStyle.thin;

      if (fontColor != null) {
        valueCell.cellStyle.fontColor = fontColor;
      }

      final currencyCell = sheet.getRangeByIndex(currentRow, 8);
      currencyCell.setText(currency);
      currencyCell.cellStyle
        ..bold = true
        ..hAlign = HAlignType.left;
      currencyCell.cellStyle.borders.all.lineStyle = LineStyle.thin;

      currentRow++;
    }

    summaryRow("TOTAL INCOME:", totalIncome, fontColor: '#008000');
    summaryRow("TOTAL EXPENSES:", totalExpense, fontColor: '#FF0000');

    double netBalance = totalIncome - totalExpense;
    summaryRow("NET BALANCE:", netBalance,
        fontColor: netBalance >= 0 ? '#008000' : '#FF0000');

    // Set column widths
    List<double> columnWidths = [8.0, 18.0, 30.0, 15.0, 18.0, 12.0, 15.0, 18.0];
    for (int col = 0; col < columnWidths.length; col++) {
      try {
        final column = sheet.getRangeByIndex(1, col + 1);
        column.columnWidth = columnWidths[col];
      } catch (e) {
        throw e.toString();
      }
    }
  }

  // ==================== UTILITY METHODS ====================

  static Future<void> _saveFile(List<int> bytes, String fileName, BuildContext context) async {
    try {
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(bytes);

      if (!context.mounted) return;

      _showToast(context, "Excel file saved successfully", isError: false);

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
          title: const Text('Export Successful', style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text('Do you want to open the Excel file?', style: TextStyle(fontSize: 14)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          titlePadding: const EdgeInsets.fromLTRB(15, 20, 15, 8),
          contentPadding: const EdgeInsets.fromLTRB(15, 8, 15, 16),
          actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          actions: [
            ZOutlineButton(
              width: 80,
              height: 40,
              onPressed: () => Navigator.of(dialogContext).pop(false),
              label: Text(AppLocalizations.of(context)!.cancel),
            ),
            ZOutlineButton(
              height: 38,
              width: 80,
              isActive: true,
              onPressed: () => Navigator.of(dialogContext).pop(true),
              label: Text(AppLocalizations.of(context)!.yes),
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
          _showToast(context, "Could not open file. Please open manually at:\n$filePath",
              isError: true, duration: const Duration(seconds: 5));
        }
      }
    } catch (e) {
      if (context.mounted) {
        _showToast(context, "Error opening file: $e", isError: true);
      }
    }
  }

  static void _showToast(BuildContext context, String message,
      {bool isError = false, Duration duration = const Duration(seconds: 3)}) {
    if (!context.mounted) return;

    ToastManager.show(
      context: context,
      title: isError ? "Error" : "Success Exported",
      message: message,
      type: isError ? ToastType.error : ToastType.success,
    );
  }
}