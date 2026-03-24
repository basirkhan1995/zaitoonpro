import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart' as pw;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:zaitoonpro/Features/Date/shamsi_converter.dart';
import 'package:zaitoonpro/Features/Other/extensions.dart';
import 'package:zaitoonpro/Features/PrintSettings/print_services.dart';
import 'package:zaitoonpro/Features/PrintSettings/report_model.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Projects/ProjectsById/model/project_by_id_model.dart';

class ProjectByIdPrintSettings extends PrintServices {

  Future<void> createDocument({
    required ProjectByIdModel data,
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
        suggestedName: "project_${data.prjId ?? 'report'}.pdf",
        pdf: document,
      );
    } catch (e) {
      throw e.toString();
    }
  }

  Future<void> printDocument({
    required ProjectByIdModel data,
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
    required ProjectByIdModel data,
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
        margin: const pw.EdgeInsets.symmetric(horizontal: 25, vertical: 10),
        pageFormat: pageFormat,
        textDirection: documentLanguage(language: language),
        orientation: orientation,
        build: (context) => [
          horizontalDivider(),
          pw.SizedBox(height: 5),
          _buildProjectReport(data, language),
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

  // Real Time document show
  Future<pw.Document> printPreview({
    required String language,
    required ReportModel company,
    required pw.PageOrientation orientation,
    required ProjectByIdModel data,
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
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Expanded(
              flex: 3,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  zText(text: report.comName ?? "", fontSize: 16, tightBounds: true),
                  pw.SizedBox(height: 2),
                  zText(text: report.statementDate ?? "", fontSize: 8),
                ],
              ),
            ),
            if (image != null)
              pw.Container(
                width: 35,
                height: 35,
                child: pw.Image(image, fit: pw.BoxFit.contain),
              ),
          ],
        ),
        pw.SizedBox(height: 3)
      ],
    );
  }

  @override
  pw.Widget footer({
    required ReportModel report,
    required pw.Context context,
    required String language,
    required pw.MemoryImage logoImage
  }) {
    return pw.Column(
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.start,
          children: [
            pw.Container(
              height: 16,
              child: pw.Image(logoImage),
            ),
            verticalDivider(height: 12, width: 0.5),
            zText(
              text: tr(text: 'producedBy', tr: language),
              fontWeight: pw.FontWeight.normal,
              fontSize: 6,
            ),
          ],
        ),
        pw.SizedBox(height: 2),
        horizontalDivider(),
        pw.SizedBox(height: 2),
        pw.Row(
          children: [
            zText(text: report.comAddress ?? "", fontSize: 7),
          ],
        ),
        pw.SizedBox(height: 2),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Row(
              children: [
                zText(text: report.compPhone ?? "", fontSize: 7),
                verticalDivider(height: 8, width: 0.8),
                zText(text: report.comEmail ?? "", fontSize: 7),
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

  pw.Widget _buildProjectReport(ProjectByIdModel data, String language) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Project Title
        pw.Row(
          children: [
            zText(
              text: data.prjName ?? tr(text: 'projectReport', tr: language),
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ]
        ),
        pw.SizedBox(height: 8),
        // Project Information Section
        _buildSection(
          title: tr(text: 'projectInformation', tr: language),
          children: [
            _buildInfoRow(tr(text: 'projectName', tr: language), data.prjName ?? '-'),
            _buildInfoRow(tr(text: 'projectId', tr: language), data.prjId?.toString() ?? '-'),
            _buildInfoRow(tr(text: 'location', tr: language), data.prjLocation ?? '-'),
            _buildInfoRow(tr(text: 'details', tr: language), data.prjDetails ?? '-', isMultiline: true),
            _buildInfoRow(tr(text: 'deadline', tr: language), data.prjDateLine?.toFormattedDate() ?? '-'),
            _buildInfoRow(tr(text: 'entryDate', tr: language), data.prjEntryDate?.toFormattedDate() ?? '-'),
            _buildStatusRow(
              tr(text: 'status', tr: language),
              data.prjStatus == 0 ? tr(text: 'inProgress', tr: language) : tr(text: 'completed', tr: language),
              isActive: data.prjStatus == 0,
            ),
          ],
        ),

        pw.SizedBox(height: 12),

        // Owner Information Section
        _buildSection(
          title: tr(text: 'ownerInformation', tr: language),
          children: [
            _buildInfoRow(tr(text: 'clientTitle', tr: language), data.prjOwnerfullName ?? '-'),
            _buildInfoRow(tr(text: 'accountNumber', tr: language), data.prjOwnerAccount?.toString() ?? '-'),
            _buildInfoRow(tr(text: 'currencyTitle', tr: language), data.actCurrency ?? '-'),
          ],
        ),

        pw.SizedBox(height: 10),

        // Services Section
        if ((data.projectServices?.length ?? 0) > 0) ...[
          _buildSection(
            title: tr(text: 'services', tr: language),
            children: [
              _buildServicesTable(data.projectServices ?? [], data.actCurrency ?? '', language),
            ],
          ),
          pw.SizedBox(height: 10),
        ],

        // Financial Summary Section
        _buildSection(
          title: tr(text: 'financialSummary', tr: language),
          children: [
            _buildFinancialSummary(data, language),
          ],
        ),

        pw.SizedBox(height: 10),

        // Transactions Section
        if ((data.projectPayments?.length ?? 0) > 0) ...[
          _buildSection(
            title: tr(text: 'transactions', tr: language),
            children: [
              _buildTransactionsTable(data.projectPayments ?? [], data.actCurrency ?? '', language),
            ],
          ),
        ],

      ],
    );
  }

  pw.Widget _buildSection({required String title, required List<pw.Widget> children}) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        zText(
          text: title,
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
        ),
        horizontalDivider(),

        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 1),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildInfoRow(String label, String value, {bool isMultiline = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 100,
            child: zText(
              text: "$label:",
              fontSize: 7,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.Expanded(
            child: zText(
              text: value,
              fontSize: 7,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildStatusRow(String label, String value, {required bool isActive}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Row(
        children: [
          pw.Container(
            width: 100,
            child: zText(
              text: "$label:",
              fontSize: 7,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: pw.BoxDecoration(
              color: isActive ? pw.PdfColors.orange100 : pw.PdfColors.green100,
              borderRadius: pw.BorderRadius.circular(1),
            ),
            child: zText(
              text: value,
              fontSize: 6,
              color: isActive ? pw.PdfColors.orange800 : pw.PdfColors.green800,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildServicesTable(List<ProjectService> services, String currency, String language) {
    double totalSum = 0;
    for (var service in services) {
      totalSum += double.tryParse(service.total ?? '0') ?? 0;
    }
    bool isEnglish = language == "en"? true : false;
    return pw.Column(
      children: [
        // Table Header
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 2),
          decoration: pw.BoxDecoration(
            color: pw.PdfColors.grey100,
          ),
          child: pw.Row(
            children: [
              pw.SizedBox(width: 18, child: zText(text: "#", fontSize: 7, fontWeight: pw.FontWeight.bold, textAlign: pw.TextAlign.center)),
              pw.Expanded(flex: 3, child: zText(text: tr(text: 'serviceName', tr: language), fontSize: 7, fontWeight: pw.FontWeight.bold, textAlign: isEnglish? pw.TextAlign.left : pw.TextAlign.right)),
              pw.Expanded(flex: 2, child: zText(text: tr(text: 'referenceNumber', tr: language), fontSize: 7, fontWeight: pw.FontWeight.bold, textAlign: isEnglish? pw.TextAlign.left : pw.TextAlign.right)),
              pw.Expanded(flex: 2, child: zText(text: tr(text: 'units', tr: language), fontSize: 7, fontWeight: pw.FontWeight.bold, textAlign: isEnglish? pw.TextAlign.left : pw.TextAlign.right)),
              pw.Expanded(flex: 2, child: zText(text: tr(text: 'unitPrice', tr: language), fontSize: 7, fontWeight: pw.FontWeight.bold, textAlign: isEnglish? pw.TextAlign.left : pw.TextAlign.right)),
              pw.Expanded(flex: 2, child: zText(text: tr(text: 'totalTitle', tr: language), fontSize: 7, fontWeight: pw.FontWeight.bold, textAlign: isEnglish? pw.TextAlign.left : pw.TextAlign.right)),
            ],
          ),
        ),

        // Table Rows
        ...List.generate(services.length, (index) {
          final service = services[index];
          final quantity = double.tryParse(service.pjdQuantity ?? '0') ?? 0;
          final price = double.tryParse(service.pjdPricePerQty ?? '0') ?? 0;
          final total = double.tryParse(service.total ?? '0') ?? 0;

          return pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 2),
            child: pw.Row(
              children: [
                pw.SizedBox(width: 18, child: zText(text: '${index + 1}', fontSize: 7, textAlign: pw.TextAlign.center)),
                pw.Expanded(flex: 3, child: zText(text: service.srvName ?? '-', fontSize: 7, textAlign: isEnglish? pw.TextAlign.left : pw.TextAlign.right)),
                pw.Expanded(flex: 2, child: zText(text: service.prpTrnRef ?? '-', fontSize: 7, textAlign: isEnglish? pw.TextAlign.left : pw.TextAlign.right)),
                pw.Expanded(flex: 2, child: zText(text: quantity.toString(), fontSize: 7, textAlign: isEnglish? pw.TextAlign.left : pw.TextAlign.right)),
                pw.Expanded(flex: 2, child: zText(text: '${price.toAmount()} $currency', fontSize: 7,  textAlign: isEnglish? pw.TextAlign.left : pw.TextAlign.right)),
                pw.Expanded(flex: 2, child: zText(text: '${total.toAmount()} $currency', fontSize: 7, fontWeight:  pw.FontWeight.bold, textAlign: isEnglish? pw.TextAlign.left : pw.TextAlign.right)),

              ],
            ),
          );
        }),

        // Total Row
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 10),
          decoration: pw.BoxDecoration(
            color: pw.PdfColors.grey100,
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              zText(text: "${tr(text: 'totalServices', tr: language)} ", fontSize: 7, fontWeight: pw.FontWeight.bold),
              zText(text: '${totalSum.toAmount()} $currency', fontSize: 7, fontWeight: pw.FontWeight.bold),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildTransactionsTable(List<ProjectPayment> payments, String currency, String language) {
    bool isEnglish = language == "en"? true : false;
    return pw.Column(
      children: [
        // Table Header
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 2),
          decoration: pw.BoxDecoration(
            color: pw.PdfColors.grey100,
          ),
          child: pw.Row(
            children: [
              pw.SizedBox(width: 18, child: zText(text: "#", fontSize: 7, fontWeight: pw.FontWeight.bold, textAlign: pw.TextAlign.center)),
              pw.Expanded(flex: 2, child: zText(text: tr(text: 'date', tr: language), fontSize: 7, fontWeight: pw.FontWeight.bold, textAlign: isEnglish? pw.TextAlign.left : pw.TextAlign.right)),
              pw.Expanded(flex: 3, child: zText(text: tr(text: 'referenceNumber', tr: language), fontSize: 7, fontWeight: pw.FontWeight.bold, textAlign:isEnglish? pw.TextAlign.left :  pw.TextAlign.right)),
              pw.Expanded(flex: 2, child: zText(text: tr(text: 'txnType', tr: language), fontSize: 7, fontWeight: pw.FontWeight.bold, textAlign: isEnglish? pw.TextAlign.left : pw.TextAlign.right)),
              pw.Expanded(flex: 2, child: zText(text: tr(text: 'amount', tr: language), fontSize: 7, fontWeight: pw.FontWeight.bold, textAlign: isEnglish? pw.TextAlign.left : pw.TextAlign.right)),
              pw.Expanded(flex: 2, child: zText(text: tr(text: 'status', tr: language), fontSize: 7, fontWeight: pw.FontWeight.bold, textAlign: isEnglish? pw.TextAlign.left : pw.TextAlign.right)),
            ],
          ),
        ),

        // Table Rows
        ...List.generate(payments.length, (index) {
          final payment = payments[index];
          final isPayment = payment.prpType == 'Payment';
          final isExpense = payment.prpType == 'Expense';
          final isEntry = payment.prpType == "Entry";

          final amount = double.tryParse(
              isPayment ? payment.payments ?? '0' : payment.expenses ?? '0'
          ) ?? 0;

          return pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 2),
            child: pw.Row(
              children: [
                pw.SizedBox(width: 18, child: zText(text: '${index + 1}', fontSize: 7, textAlign: pw.TextAlign.center)),
                pw.Expanded(flex: 2, child: zText(text: payment.trnEntryDate?.toFormattedDate() ?? '-', fontSize: 7, textAlign: isEnglish? pw.TextAlign.left : pw.TextAlign.right)),
                pw.Expanded(flex: 3, child: zText(text: payment.prpTrnRef ?? '-', fontSize: 7, textAlign: isEnglish? pw.TextAlign.left : pw.TextAlign.right)),
                pw.Expanded(
                  flex: 2,
                  child: zText(
                    text: isPayment
                        ? tr(text: 'payment', tr: language)
                        : isExpense
                        ? tr(text: 'expense', tr: language)
                        : isEntry ? tr(text: "entry", tr: language) : payment.prpType ?? '-',
                    fontSize: 7,
                    color: isPayment
                        ? pw.PdfColors.green800
                        : isExpense
                        ? pw.PdfColors.red800
                        : pw.PdfColors.grey800,
                    textAlign: isEnglish? pw.TextAlign.left : pw.TextAlign.right,
                  ),
                ),
                pw.Expanded(
                  flex: 2,
                  child: zText(
                    text: '${amount.toAmount()} $currency',
                    fontSize: 7,
                    color: isPayment
                        ? pw.PdfColors.green800
                        : isExpense
                        ? pw.PdfColors.red800
                        : pw.PdfColors.black,
                    fontWeight: pw.FontWeight.bold,
                    textAlign: isEnglish? pw.TextAlign.left : pw.TextAlign.right,
                  ),
                ),
                pw.Expanded(
                  flex: 2,
                  child: _buildStatusBadge(payment.trnStateText ?? '',language),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  pw.Widget _buildStatusBadge(String status, String language) {
    pw.PdfColor getColor() {
      switch (status.toLowerCase()) {
        case 'pending':
          return pw.PdfColors.orange800;
        case 'authorized':
          return pw.PdfColors.green800;
        case 'reversed':
          return pw.PdfColors.red800;
        default:
          return pw.PdfColors.grey800;
      }
    }

    pw.PdfColor getBgColor() {
      switch (status.toLowerCase()) {
        case 'pending':
          return pw.PdfColors.orange50;
        case 'authorized':
          return pw.PdfColors.green50;
        case 'reversed':
          return pw.PdfColors.red50;
        default:
          return pw.PdfColors.grey50;
      }
    }

    // Get translated status text
    String translatedStatus = '';
    switch (status.toLowerCase()) {
      case 'pending':
        translatedStatus = tr(text: 'pending', tr: language);
        break;
      case 'authorized':
        translatedStatus = tr(text: 'approved', tr: language);
        break;
      case 'reversed':
        translatedStatus = tr(text: 'reversed', tr: language);
        break;
      default:
        translatedStatus = status;
    }

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: pw.BoxDecoration(
        color: getBgColor(),
        borderRadius: pw.BorderRadius.circular(1),
      ),
      child: zText(
        text: translatedStatus,
        fontSize: 6,
        color: getColor(),
        fontWeight: pw.FontWeight.bold,
      ),
    );
  }

  pw.Widget _buildFinancialSummary(ProjectByIdModel data, String language) {
    double totalServices = _calculateTotalServices(data);
    double totalIncome = _calculateTotalPayments(data);
    double totalExpense = _calculateTotalExpenses(data);
    double balance = totalIncome - totalExpense;
    String currency = data.actCurrency ?? '';

    return pw.Column(
      children: [
        _buildFinancialRow(
          tr(text: 'totalServicesValue', tr: language),
          totalServices,
          currency,
          pw.PdfColors.blue,
        ),
        pw.Divider(height: 6),
        _buildFinancialRow(
          tr(text: 'totalPayment', tr: language),
          totalIncome,
          currency,
          pw.PdfColors.green,
        ),
        pw.Divider(height: 6),
        _buildFinancialRow(
          tr(text: 'totalExpense', tr: language),
          totalExpense,
          currency,
          pw.PdfColors.red,
        ),
        pw.Divider(height: 6),
        _buildFinancialRow(
          tr(text: 'balance', tr: language),
          balance,
          currency,
          balance >= 0 ? pw.PdfColors.blue : pw.PdfColors.orange,
          isBold: true,
        ),
      ],
    );
  }

  pw.Widget _buildFinancialRow(String label, double amount, String currency, pw.PdfColor color, {bool isBold = false}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        zText(
          text: label,
          fontSize: 8,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        zText(
          text: '${amount.toAmount()} $currency',
          fontSize: 8,
          color: color,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ],
    );
  }

  // Helper Methods
  double _calculateTotalServices(ProjectByIdModel project) {
    double total = 0;
    for (var service in project.projectServices ?? []) {
      total += double.tryParse(service.total ?? '0') ?? 0;
    }
    return total;
  }

  double _calculateTotalPayments(ProjectByIdModel project) {
    double total = 0;
    for (var payment in project.projectPayments ?? []) {
      if (payment.prpType == 'Payment') {
        total += double.tryParse(payment.payments ?? '0') ?? 0;
      }
    }
    return total;
  }

  double _calculateTotalExpenses(ProjectByIdModel project) {
    double total = 0;
    for (var payment in project.projectPayments ?? []) {
      if (payment.prpType == 'Expense') {
        total += double.tryParse(payment.expenses ?? '0') ?? 0;
      }
    }
    return total;
  }
}