import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart' as pw;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:zaitoonpro/Features/Date/shamsi_converter.dart';
import 'package:zaitoonpro/Features/Other/amount_to_word.dart';
import 'package:zaitoonpro/Features/Other/extensions.dart';
import 'package:zaitoonpro/Features/PrintSettings/print_services.dart';
import 'package:zaitoonpro/Features/PrintSettings/report_model.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Journal/Ui/ProjectTxn/model/project_txn_model.dart';

class ProjectTxnPrintSettings extends PrintServices {
  // Account number to friendly name mapping
  static const Map<int, String> _accountNames = {
    10101010: 'Cash',
    10101028: 'WIP',
  };

  String _getAccountName(int? accountNumber, String language) {
    if (accountNumber == null) return '';

    final friendlyName = _accountNames[accountNumber];
    if (friendlyName != null) {
      return '$friendlyName ($accountNumber)';
    }
    return accountNumber.toString();
  }

  // Get payment method based on debit account
  String _getPaymentMethod(int? debitAccount, String language) {
    if (debitAccount == 10101010) {
      return tr(text: 'cash', tr: language);
    }
    return tr(text: 'bankTransfer', tr: language);
  }

  Future<void> createDocument({
    required ProjectTxnModel data,
    required String language,
    required pw.PageOrientation orientation,
    required ReportModel company,
    required pw.PdfPageFormat pageFormat,
  }) async {
    try {
      final document = await generateStatement(
        report: company,
        data: data,
        language: language,
        orientation: orientation,
        pageFormat: pageFormat,
      );

      await saveDocument(
        suggestedName: "voucher_${data.transaction?.trnReference ?? 'unknown'}.pdf",
        pdf: document,
      );
    } catch (e) {
      throw e.toString();
    }
  }

  Future<void> printDocument({
    required ProjectTxnModel data,
    required String language,
    required pw.PageOrientation orientation,
    required ReportModel company,
    required Printer selectedPrinter,
    required pw.PdfPageFormat pageFormat,
    required int copies,
    required String pages,
  }) async {
    try {
      final document = await generateStatement(
        report: company,
        data: data,
        language: language,
        orientation: orientation,
        pageFormat: pageFormat,
      );

      for (int i = 0; i < copies; i++) {
        await Printing.directPrintPdf(
          printer: selectedPrinter,
          onLayout: (pw.PdfPageFormat format) async {
            return document.save();
          },
        );

        if (i < copies - 1) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }
    } catch (e) {
      throw e.toString();
    }
  }

  Future<pw.Document> generateStatement({
    required String language,
    required ReportModel report,
    required ProjectTxnModel data,
    required pw.PageOrientation orientation,
    required pw.PdfPageFormat pageFormat,
  }) async {
    final document = pw.Document();

    // Load logo if available
    pw.ImageProvider? logoProvider;
    if (report.comLogo != null && report.comLogo is Uint8List && report.comLogo!.isNotEmpty) {
      logoProvider = pw.MemoryImage(report.comLogo!);
    }

    final prpType = data.prpType?.toLowerCase() ?? '';
    final isEntry = prpType == 'entry';
    final isExpense = prpType == 'expense';

    // For Entry type, show only one copy (contract)
    if (isEntry) {
      document.addPage(
        pw.MultiPage(
          maxPages: 1000,
          margin: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          pageFormat: pageFormat,
          textDirection: documentLanguage(language: language),
          orientation: orientation,
          build: (context) => [
            // Contract - Single Copy Only
            pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(width: 2), // Thicker border for contract
              ),
              padding: const pw.EdgeInsets.all(15),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _buildContractHeader(
                    report: report,
                    data: data,
                    language: language,
                    logoProvider: logoProvider,
                  ),
                  pw.SizedBox(height: 6),
                  _buildContractContent(data: data, language: language),
                  pw.SizedBox(height: 6),
                  _buildContractFooter(data: data, language: language),
                ],
              ),
            ),
          ],
          header: (context) => pw.SizedBox.shrink(),
        ),
      );
    } else {
      // Payment or Expense - Show two copies
      final voucherType = isExpense ? 'expenseVoucher' : 'receiptVoucher';

      document.addPage(
        pw.MultiPage(
          maxPages: 1000,
          margin: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          pageFormat: pageFormat,
          textDirection: documentLanguage(language: language),
          orientation: orientation,
          build: (context) => [
            // First Copy (Original)
            pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(width: 1),
              ),
              padding: const pw.EdgeInsets.all(10),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _buildVoucherHeader(
                    report: report,
                    data: data,
                    language: language,
                    voucherType: voucherType,
                    copyLabel: 'original',
                    logoProvider: logoProvider,
                  ),
                  pw.SizedBox(height: 2),
                  _buildVoucherContent(data: data, language: language),
                  pw.SizedBox(height: 2),
                  _buildVoucherFooter(data: data, language: language),
                ],
              ),
            ),

            pw.SizedBox(height: 10),

            // Divider between copies
            pw.Container(
              height: 1,
              color: pw.PdfColors.black,
              margin: const pw.EdgeInsets.symmetric(vertical: 5),
            ),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(
                  '~ ' * 20,
                  style: pw.TextStyle(fontSize: 6),
                ),
              ],
            ),
            pw.Container(
              height: 1,
              color: pw.PdfColors.black,
              margin: const pw.EdgeInsets.symmetric(vertical: 5),
            ),
            pw.SizedBox(height: 10),

            // Second Copy (Duplicate)
            pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(width: 1),
              ),
              padding: const pw.EdgeInsets.all(10),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _buildVoucherHeader(
                    report: report,
                    data: data,
                    language: language,
                    voucherType: voucherType,
                    copyLabel: 'duplicate',
                    logoProvider: logoProvider,
                  ),
                  pw.SizedBox(height: 3),
                  _buildVoucherContent(data: data, language: language),
                  pw.SizedBox(height: 3),
                  _buildVoucherFooter(data: data, language: language),
                ],
              ),
            ),
          ],
          header: (context) => pw.SizedBox.shrink(),
        ),
      );
    }
    return document;
  }

  // Real Time document show
  Future<pw.Document> printPreview({
    required String language,
    required ReportModel company,
    required pw.PageOrientation orientation,
    required ProjectTxnModel data,
    required pw.PdfPageFormat pageFormat,
  }) async {
    return generateStatement(
      report: company,
      language: language,
      orientation: orientation,
      data: data,
      pageFormat: pageFormat,
    );
  }

  // ==================== CONTRACT METHODS FOR ENTRY TYPE ====================

  pw.Widget _buildContractHeader({
    required ReportModel report,
    required ProjectTxnModel data,
    required String language,
    pw.ImageProvider? logoProvider,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Centered title
        pw.Center(
          child: pw.Column(
            children: [
              zText(
                text: tr(text: 'contractAgreement', tr: language),
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
              ),
            ],
          ),
        ),

        pw.SizedBox(height: 12),

        // Company and Reference Info with Logo
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Company Info
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (report.comName != null)
                    zText(
                      text: report.comName!,
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  zText(
                    text: '${tr(text: 'date', tr: language)}: ${DateTime.now().toFormattedDate()} | ${DateTime.now().shamsiDateString}',
                    fontSize: 10,
                  ),
                ],
              ),
            ),

            // Logo
            if (logoProvider != null)
              pw.Container(
                width: 70,
                height: 35,
                margin: const pw.EdgeInsets.only(left: 10),
                child: pw.Image(logoProvider, fit: pw.BoxFit.contain),
              ),

            // Original badge
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(width: 1),
                color: pw.PdfColors.grey200,
              ),
              child: zText(
                text: tr(text: 'original', tr: language).toUpperCase(),
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),

        pw.SizedBox(height: 8),
        pw.Container(height: 1, color: pw.PdfColors.black),
        pw.SizedBox(height: 8),

        // Client Information
        zText(
          text: '${tr(text: 'client', tr: language)}: ${data.customerName ?? ""}',
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
        ),
        pw.SizedBox(height: 3),
        zText(
          text: '${tr(text: 'projectName', tr: language)}: ${data.prjName ?? ""}',
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
        ),
        if (data.prjDetails != null && data.prjDetails!.isNotEmpty) ...[
          pw.SizedBox(height: 3),
          zText(
            text: '${tr(text: 'projectDetails', tr: language)}: ${data.prjDetails}',
            fontSize: 10,
          ),
        ],
        if (data.prjDateLine != null && data.prjDateLine.toFormattedDate().isNotEmpty) ...[
          pw.SizedBox(height: 3),
          zText(
            text: '${tr(text: 'deadline', tr: language)}: ${data.prjDateLine.toFormattedDate()}',
            fontSize: 10,
          ),
        ],
      ],
    );
  }

  pw.Widget _buildContractContent({
    required ProjectTxnModel data,
    required String language,
  }) {
    final cleanAmount = data.transaction?.amount?.replaceAll(',', '') ?? "0";
    final parsedAmount = int.tryParse(
      double.tryParse(cleanAmount)?.toStringAsFixed(0) ?? "0",
    ) ?? 0;

    final lang = NumberToWords.getLanguageFromLocale(Locale(language));

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(height: 1, color: pw.PdfColors.black),
        pw.SizedBox(height: 8),

        // Contract Amount
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(width: 1),
            color: pw.PdfColors.grey100,
          ),
          child: pw.Column(
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  zText(
                    text: '${tr(text: 'contractAmount', tr: language)}:',
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  zText(
                    text: '${data.transaction?.amount?.toAmount()} ${data.transaction?.currency}',
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ],
              ),
              pw.SizedBox(height: 6),
              pw.Container(
                padding: const pw.EdgeInsets.all(6),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(width: 0.5),
                  color: pw.PdfColors.white,
                ),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      child: zText(
                        text: '${tr(text: 'amountInWords', tr: language)}: ${NumberToWords.convert(parsedAmount, lang)} ${data.transaction?.currency ?? ''}',
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        pw.SizedBox(height: 10),

        // Narration
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(width: 0.5),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              zText(
                text: '${tr(text: 'narration', tr: language)}:',
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
              ),
              pw.SizedBox(height: 3),
              zText(
                text: data.transaction?.narration ?? '',
                fontSize: 9,
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildContractFooter({
    required ProjectTxnModel data,
    required String language,
  }) {
    return pw.Column(
      children: [
        pw.Container(height: 1, color: pw.PdfColors.black),
        pw.SizedBox(height: 15),

        // Terms and Conditions
        pw.Container(
          padding: const pw.EdgeInsets.all(6),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(width: 0.5),
          ),
          child: zText(
            text: tr(text: 'contractTerms', tr: language),
            fontSize: 8,
            textAlign: pw.TextAlign.center,
          ),
        ),

        pw.SizedBox(height: 20),

        // Signature Section
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            // Company Representative
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Container(
                  width: 120,
                  height: 30,
                  decoration: pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(width: 0.5),
                    ),
                  ),
                ),
                pw.SizedBox(height: 4),
                zText(
                  text: tr(text: 'companyRepresentative', tr: language),
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                ),
                pw.SizedBox(height: 2),
                zText(
                  text: data.transaction?.maker ?? '___________',
                  fontSize: 8,
                ),
              ],
            ),

            // Client Signature
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Container(
                  width: 120,
                  height: 30,
                  decoration: pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(width: 0.5),
                    ),
                  ),
                ),
                pw.SizedBox(height: 4),
                zText(
                  text: tr(text: 'clientSignature', tr: language),
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                ),
                pw.SizedBox(height: 2),
                zText(
                  text: data.customerName ?? '',
                  fontSize: 8,
                ),
              ],
            ),

          ],
        ),
      ],
    );
  }

  // ==================== ORIGINAL VOUCHER METHODS (UPDATED WITH LOGO) ====================

  pw.Widget _buildVoucherHeader({
    required ReportModel report,
    required ProjectTxnModel data,
    required String language,
    required String voucherType,
    required String copyLabel,
    pw.ImageProvider? logoProvider,
  }) {
    final isExpense = data.prpType?.toLowerCase() == 'expense';
    final typeText = isExpense ? 'expenseVoucher' : 'receiptVoucher';

    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Company Info and Logo
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Logo
            if (logoProvider != null)
              pw.Container(
                width: 60,
                height: 60,
                child: pw.Image(logoProvider, fit: pw.BoxFit.contain),
              ),
            // Company Name
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (report.comName != null)
                  zText(
                    text: report.comName!,
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                zText(
                  text: report.comAddress??"",
                  fontSize: 9,
                ),
                zText(
                  text: report.comEmail??"",
                  fontSize: 9,
                ),
                zText(
                  text: report.compPhone??"",
                  fontSize: 9,
                ),

              ],
            ),
          ],
        ),

        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          mainAxisAlignment: pw.MainAxisAlignment.end,
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(width: 1),
              ),
              child: zText(
                text: tr(text: typeText, tr: language),
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
              ),
            ),

            pw.SizedBox(height: 10),
            zText(
              text: data.transaction?.trnReference ?? '',
              fontSize: 10,
            ),
            zText(
              text: '${DateTime.now().toFormattedDate()} | ${DateTime.now().shamsiDateString}',
              fontSize: 10,
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildVoucherContent({
    required ProjectTxnModel data,
    required String language,
  }) {
    final isExpense = data.prpType?.toLowerCase() == 'expense';
    final cleanAmount = data.transaction?.amount?.replaceAll(',', '') ?? "0";
    final parsedAmount = int.tryParse(
      double.tryParse(cleanAmount)?.toStringAsFixed(0) ?? "0",
    ) ?? 0;

    final lang = NumberToWords.getLanguageFromLocale(Locale(language));

    // Build rows based on voucher type
    final List<Map<String, String>> voucherRows = [];

    if (isExpense) {
      // Expense Voucher
      voucherRows.addAll([
        {"title": "projectName", "value": data.prjName ?? ""},
        {"title": "client", "value": data.customerName ?? ""},
        {"title": "paymentType", "value": tr(text: 'expense', tr: language)},
        {"title": "debitAccount", "value": _getAccountName(data.transaction?.debitAccount, language)},
        {"title": "creditAccount", "value": _getAccountName(data.transaction?.creditAccount, language)},
        {"title": "narration", "value": data.transaction?.narration ?? ""},
      ]);
    } else {
      // Receipt/Payment Voucher
      final paymentMethod = _getPaymentMethod(data.transaction?.debitAccount, language);

      voucherRows.addAll([
        {"title": "projectName", "value": data.prjName ?? ""},
        {"title": "receivedFrom", "value": data.customerName ?? ""},
        {"title": "accountNumber", "value": _getAccountName(data.transaction?.creditAccount, language)},
        {"title": "paymentType", "value": paymentMethod},
        {"title": "narration", "value": data.transaction?.narration ?? ""},
      ]);
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Horizontal header line
        pw.Container(
          height: 1,
          color: pw.PdfColors.black,
          margin: const pw.EdgeInsets.symmetric(vertical: 2),
        ),

        // Amount row - shown prominently at the top
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 1, horizontal: 8),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(width: 0.5),
            color: pw.PdfColors.grey100,
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              zText(
                text: '${tr(text: 'amount', tr: language)}:',
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
              ),
              zText(
                text: '${data.transaction?.amount?.toAmount()} ${data.transaction?.currency}',
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
              ),
            ],
          ),
        ),

        pw.SizedBox(height: 6),

        // Other voucher details
        ...voucherRows.map((r) => pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 1),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                width: 100,
                child: zText(
                  text: '${tr(text: r["title"]!, tr: language)}:',
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(width: 5),
              pw.SizedBox(
                child: zText(
                  text: r["value"]!,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        )),

        pw.SizedBox(height: 6),

        // Amount in words with box
        pw.Container(
          padding: const pw.EdgeInsets.all(6),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(width: 0.5),
          ),
          child: pw.Row(
            children: [
              zText(
                text: '${tr(text: 'amountInWords', tr: language)}: ',
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
              ),
              pw.Expanded(
                child: zText(
                  text: '${NumberToWords.convert(parsedAmount, lang)} ${data.transaction?.currency ?? ''}',
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildVoucherFooter({
    required ProjectTxnModel data,
    required String language,
  }) {
    final isExpense = data.prpType?.toLowerCase() == 'expense';

    return pw.Column(
      children: [
        pw.SizedBox(height: 10),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            // Maker/Prepared by
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Container(
                  width: 100,
                  height: 25,
                  decoration: pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(width: 0.5),
                    ),
                  ),
                ),
                pw.SizedBox(height: 3),
                zText(
                  text: tr(text: 'preparedBy', tr: language),
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                ),
                pw.SizedBox(height: 1),
                zText(
                  text: data.transaction?.maker ?? '___________',
                  fontSize: 9,
                ),
              ],
            ),

            // Checker/Authorized by
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Container(
                  width: 100,
                  height: 25,
                  decoration: pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(width: 0.5),
                    ),
                  ),
                ),
                pw.SizedBox(height: 3),
                zText(
                  text: tr(text: 'authorizedBy', tr: language),
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                ),
                pw.SizedBox(height: 1),
                zText(
                  text: data.transaction?.checker ?? '___________',
                  fontSize: 9,
                ),
              ],
            ),

            // Receiver signature (for receipts/payments)
            if(!isExpense)
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Container(
                    width: 100,
                    height: 25,
                    decoration: pw.BoxDecoration(
                      border: pw.Border(
                        bottom: pw.BorderSide(width: 0.5),
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 3),
                  zText(
                    text: tr(text: 'clientSignature', tr: language),
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  pw.SizedBox(height: 1),
                  zText(
                    text: data.customerName ?? '___________',
                    fontSize: 9,
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }
}