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
                  ),
                  pw.SizedBox(height: 12),
                  _buildContractContent(data: data, language: language),
                  pw.SizedBox(height: 12),
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
                  ),
                  pw.SizedBox(height: 8),
                  _buildVoucherContent(data: data, language: language),
                  pw.SizedBox(height: 8),
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
                  ),
                  pw.SizedBox(height: 8),
                  _buildVoucherContent(data: data, language: language),
                  pw.SizedBox(height: 8),
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

        // Company and Reference Info
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Column(
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
                  text: "شرکت ساختمانی و سرکسازی استان سبز",
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

  // ==================== ORIGINAL VOUCHER METHODS (UNCHANGED) ====================

  pw.Widget _buildVoucherHeader({
    required ReportModel report,
    required ProjectTxnModel data,
    required String language,
    required String voucherType,
    required String copyLabel,
  }) {
    final isExpense = data.prpType?.toLowerCase() == 'expense';
    final typeText = isExpense ? 'expenseVoucher' : 'receiptVoucher';

    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              children: [
                zText(
                  text: tr(text: typeText, tr: language),
                  fontSize: 14, // Increased from 12
                  fontWeight: pw.FontWeight.bold,
                ),
              ],
            ),
            pw.SizedBox(height: 3),
            zText(
              text: '${tr(text: 'reference', tr: language)}: ${data.transaction?.trnReference ?? ''}',
              fontSize: 10, // Increased from 8
            ),
            zText(
              text: '${tr(text: 'date', tr: language)}: ${DateTime.now().toFormattedDate()} | ${DateTime.now().shamsiDateString}',
              fontSize: 10, // Increased from 8
            ),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(width: 1),
              ),
              child: zText(
                text: tr(text: copyLabel, tr: language).toUpperCase(),
                fontSize: 10, // Increased from 8
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 3),
            if (report.comName != null)
              zText(
                text: report.comName!,
                fontSize: 11, // Increased from 9
                fontWeight: pw.FontWeight.bold,
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
        {"title": "paymentType", "value": data.prpType ?? ""},
        {"title": "debitAccount", "value": _getAccountName(data.transaction?.debitAccount, language)},
        {"title": "creditAccount", "value": _getAccountName(data.transaction?.creditAccount, language)},
        {"title": "narration", "value": data.transaction?.narration ?? ""},
      ]);
    } else {
      // Receipt/Payment Voucher
      voucherRows.addAll([
        {"title": "projectName", "value": data.prjName ?? ""},
        {"title": "receivedFrom", "value": data.customerName ?? ""},
        {"title": "accountNumber", "value": _getAccountName(data.transaction?.creditAccount, language)},
        {"title": "paymentType", "value":  data.prpType??""},
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
          margin: const pw.EdgeInsets.symmetric(vertical: 6),
        ),

        // Amount row - shown prominently at the top
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
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
                fontSize: 14, // Larger, bold amount
                fontWeight: pw.FontWeight.bold,
              ),
            ],
          ),
        ),

        pw.SizedBox(height: 6),

        // Other voucher details
        ...voucherRows.map((r) => pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 3),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                width: 100,
                child: zText(
                  text: '${tr(text: r["title"]!, tr: language)}:',
                  fontSize: 10, // Increased from 8
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
                fontSize: 10, // Increased from 8
                fontWeight: pw.FontWeight.bold,
              ),
              pw.Expanded(
                child: zText(
                  text: '${NumberToWords.convert(parsedAmount, lang)} ${data.transaction?.currency ?? ''}',
                  fontSize: 10, // Increased from 8
                  fontWeight: pw.FontWeight.bold, // Made bold
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
                  text: '${tr(text: 'preparedBy', tr: language)}: ${data.transaction?.maker ?? ''}',
                  fontSize: 9, // Increased from 7
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
                  text: '${tr(text: 'authorizedBy', tr: language)} ${data.transaction?.checker ?? ''}',
                  fontSize: 9, // Increased from 7
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
                    fontSize: 9, // Increased from 7
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }
}