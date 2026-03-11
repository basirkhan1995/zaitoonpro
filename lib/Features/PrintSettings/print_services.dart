import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:zaitoon_petroleum/Features/PrintSettings/report_model.dart';
import 'package:pdf/pdf.dart' as pw;
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;

abstract class PrintServices {

  static late pw.Font _englishRegular;
  static late pw.Font _englishBold;
  static late pw.Font _persianRegular;
  static late pw.Font _persianBold;

  // Initialize fonts
  static Future<void> initializeFonts() async {
    await _loadEnglishFonts();
    await _loadPersianFonts();
  }

  // Load English fonts (regular and bold)
  static Future<void> _loadEnglishFonts() async {
    try {
      // Load regular font
      final ByteData englishRegularData = await rootBundle.load(
        'assets/fonts/OpenSans/OpenSans-Regular.ttf',
      );
      _englishRegular = pw.Font.ttf(englishRegularData);

      // Load bold font
      final ByteData englishBoldData = await rootBundle.load(
        'assets/fonts/OpenSans/OpenSans-Bold.ttf',
      );
      _englishBold = pw.Font.ttf(englishBoldData);
    } catch (e) {
      debugPrint('❌ English font loading failed: $e');
      _englishRegular = _englishBold = pw.Font.courier();
    }
  }

  // Load Persian fonts with platform-specific handling
  static Future<void> _loadPersianFonts() async {
    try {
      if (kIsWeb) {
        // For web, try Amiri first (better Arabic/Persian support)
        await _loadWebPersianFonts();
      } else {
        // For mobile/desktop, use NotoNaskh
        await _loadNativePersianFonts();
      }
    } catch (e) {
      debugPrint('❌ Persian font loading failed: $e');
      _persianRegular = _persianBold = pw.Font.courier();
    }
  }

  static Future<void> _loadWebPersianFonts() async {
    try {
      // Try Amiri Regular for web
      final ByteData persianRegularData = await rootBundle.load(
        'assets/fonts/Amiri/Amiri-Regular.ttf',
      );
      _persianRegular = pw.Font.ttf(persianRegularData);

      // Try Amiri Bold for web
      final ByteData persianBoldData = await rootBundle.load(
        'assets/fonts/Amiri/Amiri-Bold.ttf',
      );
      _persianBold = pw.Font.ttf(persianBoldData);

      debugPrint('✅ Amiri font loaded successfully for web');
    } catch (e) {
      debugPrint('❌ Amiri font failed, trying NotoNaskh: $e');
      // Fallback to NotoNaskh
      await _loadNativePersianFonts();
    }
  }

  static Future<void> _loadNativePersianFonts() async {
    try {
      // Load regular font
      final ByteData persianRegularData = await rootBundle.load(
        'assets/fonts/NotoNaskh/NotoNaskhArabic-Regular.ttf',
      );
      _persianRegular = pw.Font.ttf(persianRegularData);

      // Load bold font
      final ByteData persianBoldData = await rootBundle.load(
        'assets/fonts/NotoNaskh/NotoNaskhArabic-Bold.ttf',
      );
      _persianBold = pw.Font.ttf(persianBoldData);

      debugPrint('✅ NotoNaskh font loaded successfully');
    } catch (e) {
      debugPrint('❌ NotoNaskh font failed: $e');
      rethrow;
    }
  }

  // Get appropriate font based on text and weight
  static pw.Font _getFont({required String text, required pw.FontWeight? fontWeight}) {
    final isPersian = _isPersian(text);

    try {
      // Use bold font if fontWeight is bold or heavier
      if (fontWeight != null && fontWeight.index >= pw.FontWeight.bold.index) {
        return isPersian ? _persianBold : _englishBold;
      } else {
        return isPersian ? _persianRegular : _englishRegular;
      }
    } catch (e) {
      // Ultimate fallback
      return pw.Font.courier();
    }
  }

  static bool _isPersian(String text) {
    final persianRegex = RegExp(r'[\u0600-\u06FF]');
    return persianRegex.hasMatch(text);
  }

  static pw.TextDirection _textDirection({required String text}) {
    return _isPersian(text) ? pw.TextDirection.rtl : pw.TextDirection.ltr;
  }

  static pw.TextStyle _textStyle({
    required String text,
    double? fontSize,
    PdfColor? color,
    pw.FontWeight? fontWeight,
    pw.FontStyle? fontStyle,
  }) {
    return pw.TextStyle(
      color: color,
      font: _getFont(text: text, fontWeight: fontWeight),
      fontWeight: fontWeight,
      fontSize: fontSize,
      fontStyle: fontStyle,
    );
  }

  Future<pw.Widget> header({required ReportModel report}) async {
    // Check if company logo exists and is valid
    final bool hasCompanyLogo = report.comLogo != null &&
        report.comLogo is Uint8List &&
        report.comLogo!.isNotEmpty;

    pw.ImageProvider? logoImage;

    // Only load company logo if it exists
    if (hasCompanyLogo) {
      logoImage = pw.MemoryImage(report.comLogo!);
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Company info (left side)
            pw.Expanded(
              flex: 3,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  zText(
                      text: report.comName ?? "",
                      fontSize: 25,
                      tightBounds: true,
                      fontWeight: pw.FontWeight.bold
                  ),
                  pw.SizedBox(height: 5),
                  pw.Row(
                      children: [
                        if (report.comAddress != null && report.comAddress!.isNotEmpty) ...[
                          zText(
                            text: report.comAddress ?? "",
                            fontSize: 10,
                            color: pw.PdfColors.grey600,
                          ),
                        ],
                        if (report.compPhone != null && report.compPhone!.isNotEmpty) ...[
                          verticalDivider(height: 10, width: 1),
                          zText(
                            text: report.compPhone ?? "",
                            fontSize: 9,
                            color: pw.PdfColors.grey600,
                          ),
                        ],
                        if (report.comEmail != null && report.comEmail!.isNotEmpty) ...[
                          verticalDivider(height: 10, width: 1),
                          zText(
                            text: report.comEmail ?? "",
                            fontSize: 9,
                            color: pw.PdfColors.grey600,
                          ),
                        ]
                      ]
                  )
                ],
              ),
            ),
            // Logo (right side) - only show if company logo exists
            if (logoImage != null)
              pw.Container(
                width: 50,
                height: 50,
                child: pw.Image(logoImage, fit: pw.BoxFit.contain),
              ),
          ],
        ),
        pw.SizedBox(height: 8),
        horizontalDivider(),
      ],
    );
  }

  pw.Widget footer({
    required ReportModel report,
    required pw.Context context,
    required String language,
    required pw.MemoryImage logoImage,
  }) {
    return pw.Column(
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.start,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
              height: 20,
              child: pw.Image(logoImage),
            ),
            verticalDivider(height: 15, width: 0.6),
            zText(
              text: tr(text: 'producedBy', tr: language),
              fontWeight: pw.FontWeight.normal,
              fontSize: 8,
            ),
          ],
        ),
        pw.SizedBox(height: 3),
        horizontalDivider(),
        pw.SizedBox(height: 3),
        pw.Row(
            children: [
              zText(text: "${report.compPhone ?? ""} | ${report.comEmail ?? ""}", fontSize: 9),
            ]
        ),
        pw.SizedBox(height: 3),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            zText(text: report.comAddress ?? "", fontSize: 9),
            buildPage(context.pageNumber, context.pagesCount, language),
          ],
        ),
      ],
    );
  }

  Future<File?> saveDocument({required String suggestedName, required pw.Document pdf}) async {
    try {
      final FileSaveLocation? fileSaveLocation = await getSaveLocation(
        suggestedName: suggestedName,
        acceptedTypeGroups: [
          const XTypeGroup(
            label: 'PDF Files',
            extensions: ['pdf'],
          ),
        ],
      );

      if (fileSaveLocation == null) {
        return null;
      }

      // Ensure the file path has a .pdf extension
      String filePath = fileSaveLocation.path;
      if (!filePath.toLowerCase().endsWith('.pdf')) {
        filePath += '.pdf';
      }

      // Save the PDF document to the selected path
      final bytes = await pdf.save();

      // Write the bytes to the file
      final file = File(filePath);
      await file.writeAsBytes(bytes);
      return file;
    } catch (e) {
      return null;
    }
  }

  // Common widgets
  pw.Widget zText({
    required String text,
    double? fontSize,
    pw.FontWeight? fontWeight,
    bool? tightBounds,
    PdfColor? color,
    pw.TextAlign? textAlign,
    pw.FontStyle? fontStyle,
  }) {
    if (text.isEmpty) return pw.SizedBox();

    return pw.Text(
      text,
      textAlign: textAlign,
      style: _textStyle(
        text: text,
        color: color,
        fontSize: fontSize,
        fontWeight: fontWeight,
        fontStyle: fontStyle,
      ),
      textDirection: _textDirection(text: text),
    );
  }

  pw.Widget buildPage(int currentPage, int totalPages, String language) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 1),
      child: zText(
        text: '${tr(text: 'page', tr: language)} $currentPage ${tr(text: 'of', tr: language)} $totalPages',
        fontSize: 8,
      ),
    );
  }

  Future<pw.ImageProvider?> loadNetworkImage(String? url) async {
    if (url == null || url.isEmpty) return null;
    try {
      final response = await http.get(Uri.parse('https://www.zaitoonsoft.com/rapi/uploads/$url'));
      if (response.statusCode == 200) {
        return pw.MemoryImage(response.bodyBytes);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  pw.Widget verticalDivider({
    required double height,
    required double width,
  }) {
    return pw.Container(
      height: height,
      width: width,
      color: PdfColors.grey300,
      margin: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 8),
    );
  }

  pw.Widget horizontalDivider({double? width}) {
    return pw.Container(
      height: 0.5,
      width: width ?? double.infinity,
      color: PdfColors.grey300,
      margin: const pw.EdgeInsets.symmetric(vertical: 1, horizontal: 0),
    );
  }

  pw.Widget buildSummary({
    required String label,
    required String value,
    double? fontSize,
    PdfColor? color,
    double distance = 100,
    bool isEmphasized = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 0),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.SizedBox(
            width: distance,
            child: zText(
              color: color,
              text: label,
              fontWeight: isEmphasized ? pw.FontWeight.bold : pw.FontWeight.normal,
              fontSize: fontSize ?? 8,
            ),
          ),
          zText(
            text: value,
            fontSize: fontSize ?? 8,
            fontWeight: isEmphasized ? pw.FontWeight.bold : pw.FontWeight.normal,
            textAlign: pw.TextAlign.right,
          ),
        ],
      ),
    );
  }

  PdfColor hexToPdfColor(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    } else if (hexColor.length == 8) {
      hexColor = '${hexColor.substring(6,8)}${hexColor.substring(0,6)}';
    }

    try {
      return PdfColor.fromInt(int.parse(hexColor, radix: 16));
    } catch (e) {
      return PdfColors.black;
    }
  }

  pw.Widget buildTotalSummary({
    required String label,
    required String value,
    double? width,
    double? space,
    PdfColor? color,
    String? ccySymbol,
    pw.TextAlign? align,
    bool isEmphasized = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 0),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.SizedBox(
            width: width ?? 100,
            child: zText(
              color: color,
              text: label,
              fontWeight: isEmphasized ? pw.FontWeight.bold : pw.FontWeight.normal,
              fontSize: 9,
            ),
          ),
          pw.SizedBox(width: space ?? 30),
          pw.Row(
            children: [
              pw.Text(
                value,
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: isEmphasized ? pw.FontWeight.bold : pw.FontWeight.normal,
                  font: _englishBold,
                ),
                textAlign: align ?? pw.TextAlign.center,
              ),
              if (ccySymbol != null && ccySymbol.isNotEmpty) ...[
                pw.SizedBox(width: 3),
                zText(
                  text: ccySymbol,
                  tightBounds: true,
                  fontSize: 8,
                  fontWeight: isEmphasized ? pw.FontWeight.bold : pw.FontWeight.normal,
                )
              ]
            ],
          ),
        ],
      ),
    );
  }

  pw.TextDirection documentLanguage({required String language}) {
    return language == 'en' ? pw.TextDirection.ltr : pw.TextDirection.rtl;
  }

  String tr({required String text, required String tr}) {
    const translation = {

      'moneyReceipt' : {
        'en':"Money Receipt",
        'fa':"رسید پول",
        "ar":"پول رسید"  // Pashto (kept as "ar" key)
      },
      'currencyBreakdown' : {
        'en':"Currency Breakdown",
        'fa':"خلاصه حسابها",
        "ar":"حسابونه خلاصه"
      },
      'totalAccounts' : {
        'en':"Total Accounts",
        'fa':"همه حسابها",
        "ar":"تول حسابونه"
      },
      'activeAccounts' : {
        'en':"Active Accounts",
        'fa':"حسابهای فعال",
        "ar":"فعال حسابونه"
      },
      'inactiveAccounts' : {
        'en':"Inactive Accounts",
        'fa':"حسابهای غیرفعال",
        "ar":"غیرفعال حسابونه"
      },
      'saleAmount': {
        'en': 'Sale Amount',
        'fa': 'مقدار فروش',
        'ar': 'د پلور مقدار'
      },
      'previousAccBalance': {
        'en': 'Previous Balance',
        'fa': 'مانده قبلی',
        'ar': 'اوسنی پاتی'
      },
      'thisCredit': {
        'en': 'Current Invoice',
        'fa': 'این اعتبار',
        'ar': 'دا کریډیټ'
      },
      'totalDebits' : {
        'en':"Total Debit",
        'fa':"مجموعه دبت",
        "ar":"مجموعه دبت"
      },
      'totalCredits' : {
        'en':"Total Credit",
        'fa':"مجموعه دبت",
        "ar":"مجموعه دبت"
      },
      'statementAccount' : {
        'en':"Statement of Account",
        'fa':"صورت حساب",
        "ar":"صورت حساب"
      },
      'address' : {
        'en':"Address",
        'fa':"آدرس",
        "ar":"پته"
      },
      'accountSummary': {
        'en': 'Account Summary',
        'fa': 'خلاصه صورت حساب',
        'ar': 'حساب لنډیز',
      },
      'signatory' : {
        'en':"Signatory",
        'fa':"دارنده حساب",
        "ar":"دارنده حساب"
      },
      'currentBalance' : {
        'en':"Current Balance",
        'fa':"مانده فعلی",
        "ar":"فعلی مانده"
      },
      'email' : {
        'en':"Email",
        'fa':"ایمیل آدرس",
        "ar":"ایمیل آدرس"
      },
      'availableBalance' : {
        'en':"Available Balance",
        'fa':"مانده قابل برداشت",
        "ar":"قابل برداشت مانده"
      },
      'incomeStatement' : {
        'en':"Profit & Loss",
        'fa':"سود و زیان",
        "ar":"سود و زیان"
      },
      'grossProfit' : {
        'en':"Gross Profit",
        'fa':"سود ناخالص",
        "ar":"ناخالصه ګټه"
      },
      'cogs' : {
        'en':"Cost of Goods Sold",
        'fa':"هزینه کالا فروخته شده",
        "ar":"د پلورل شویو توکو لګښت"
      },
      'totalExpense' : {
        'en':"Total Expenses",
        'fa':"مصارف",
        "ar":"مصرفونه"
      },
      'totalRevenue' : {
        'en':"Total Revenue",
        'fa':"عواید",
        "ar":"عواید"
      },
      'balanceSheet' : {
        'en':"Balance sheet",
        'fa':"بیلانس شیت",
        "ar":"بیلانس شیت"
      },
      'equityFormula' : {
        'en':"Equity = Asset - Liability",
        'fa':"سهام = دارایی - بدهی",
        "ar":"سهام = دارایی - بدهی"
      },
      'assetFormula' : {
        'en':"Asset = Liability + Equity",
        'fa':"دارایی = بدهی + سهام",
        "ar":"دارایی = بدهی + سهام"
      },
      'accounts' : {
        'en':"Accounts",
        'fa':"حساب ها",
        "ar":"حسابونه"
      },
      'equity' : {
        'en':"Equity",
        'fa':"سهام",
        "ar":"سهام"
      },
      'netProfit' : {
        'en':"Net Profit",
        'fa':"سود خالص",
        "ar":"خالص سود"
      },
      'drawings' : {
        'en':"Drawings",
        'fa':"برداشت ها",
        "ar":"برداشتونه"
      },
      'opb' : {
        'en':"Opening Balance",
        'fa':"بیلانس اولیه",
        "ar":"لومری بیلانس"
      },
      'retainedEarnings' : {
        'en':"Retained Earnings",
        'fa':"سود انباشته",
        "ar":"انباشته سود"
      },
      'capital' : {
        'en':"Capital",
        'fa':"دارایی",
        "ar":"دارایی"
      },
      'liability' : {
        'en':"Liability",
        'fa':"بدهی ها",
        "ar":"دیون"
      },
      'totalAsset' : {
        'en':"Total Asset",
        'fa':"سرمایه",
        "ar":"سرمایه"
      },
      'accountReceivable' : {
        'en':"Receivables",
        'fa':"پول دریافتنی",
        "ar":"دریافتی پیسی"
      },
      'cashVault' : {
        'en':"Cash Vault",
        'fa':"پول نقد",
        "ar":"نقدی پیسی"
      },
      'bank' : {
        'en':"Bank",
        'fa':"بانک",
        "ar":"بانک"
      },
      'saraf' : {
        'en':"Saraf",
        'fa':"صراف",
        "ar":"صراف"
      },
      'products' : {
        'en':"StockAvailability",
        'fa':"محصولات",
        "ar":"محصولات"
      },
      'stock' : {
        'en':"Stock",
        'fa':"انبار",
        "ar":"انبار"
      },
      'returnInvoice' : {
        'en':"Return Invoice",
        'fa':"بل برگشتی",
        "ar":"بل برگشتی"
      },
      'RTPU' : {
        'en':"OrderReport Return",
        'fa':"برگشت خرید",
        "ar":"برگشت خرید"
      },
      'RTSL' : {
        'en':"SaleReport Return",
        'fa':"برگشت فروش",
        "ar":"برگشت فروش"
      },
      'inventoryMovement' : {
        'en':"Product Card",
        'fa':"گردش کالا",
        "ar":"کالا گردش"
      },
      'qtyIn' : {
        'en':"IN",
        'fa':"ورود",
        "ar":"ورود"
      },
      'qtyOut' : {
        'en':"OUT",
        'fa':"خروج",
        "ar":"خروج"
      },
      'unitBasePrice' : {
        'en':"Price",
        'fa':"قیمت",
        "ar":"قیمت"
      },
      'deal' : {
        'en':"Deal",
        'fa':"معامله",
        "ar":"معامله"
      },
      'id' : {
        'en':"ID",
        'fa':"شناسه",
        "ar":"شناسه"
      },
      'noAccount' : {
        'en':"Settled",
        'fa':"تسویه",
        "ar":"تسویه"
      },
      'details' : {
        'en':"Details",
        'fa':"جزئیات",
        "ar":"جزئیات"
      },
      'productName' : {
        'en':"Product name",
        'fa':"نام کالا",
        "ar":"کالا نوم"
      },
      'inventoryTitle' : {
        'en':"Inventory Report",
        'fa':"گزارش کالا ها",
        "ar":"کالا گزارش"
      },
      'category' : {
        'en':"Category",
        'fa':"کتگوری",
        "ar":"کتگوری"
      },
      'inventory' : {
        'en':"QTY",
        'fa':"موجودی",
        "ar":"موجودی"
      },
      'unit' : {
        'en':"Unit",
        'fa':"واحد",
        "ar":"واحد"
      },
      'amountInWords' : {
        'en':"Amount in words",
        'fa':"مبلغ به حروف",
        "ar":"مبلغ کلمو کې"
      },
      'statementPeriod': {
        'en': 'Statement Period',
        'fa': 'مدت صورت حساب',
        'ar': 'صورت حساب مدت',
      },
      'statementDate': {
        'en': 'Statement Date',
        'fa': 'تاریخ صورت حساب',
        'ar': 'صورت حساب نیټه',
      },
      'total': {
        'en': 'Total',
        'fa': 'جمع کل',
        'ar': 'ټول قیمت',
      },
      'debitAccount':{
        'en':'Debit Account',
        'fa':'حساب دبت',
        'ar':'دبت حساب'
      },
      'creditAccount':{
        'en':'Credit Account',
        'fa':'حساب کریدت',
        'ar':'کریدت حساب'
      },
      'debitAmount':{
        'en':'Debit Amount',
        'fa':'مبلغ دبت',
        'ar':'مبلغ حساب'
      },
      'ACCT':{
        'en':'ACCT Transfer',
        'fa':'حساب به حساب',
        'ar':'حساب به حساب'
      },
      'creditAmount':{
        'en':'Credit Amount',
        'fa':'مبلغ کریدت',
        'ar':'کریدت مبلغ'
      },
      'OBAL':{
        'en':'OBAL',
        'fa':'بیلانس افتتاحیه',
        'ar':'افتتاحیه بیلانس'
      },
      'openingBalance': {
        'en': 'Opening Balance',
        'fa': 'مانده اولیه',
        'ar': 'د پرانیستې بیلانس',
      },
      'closingBalance': {
        'en': 'Closing Balance',
        'fa': 'بیلانس نهایی',
        'ar': 'تړلو بیلانس',
      },
      'totalCredit': {
        'en': 'Credits',
        'fa': 'بستانکار',
        'ar': 'بستانکار',
      },
      'totalDebit': {
        'en': 'Debits',
        'fa': 'بدهکار',
        'ar': 'بدهکار',
      },
      'page': {
        'en': 'Page',
        'fa': 'صفحه',
        'ar': 'پاڼه',
      },
      'of': {
        'en': 'of',
        'fa': 'از ',
        'ar': 'له',
      },
      'accountStatement': {
        'en': 'Account Statement',
        'fa': 'صورت حساب اشخاص',
        'ar': 'صورت حساب اشخاص',
      },
      'trnType': {
        'en': 'Transaction Code',
        'fa': 'کد معامله',
        'ar': 'معامله کد',
      },
      'checker': {
        'en': 'Checker',
        'fa': 'تایید کننده',
        'ar': 'تایید کونکی',
      },
      'maker': {
        'en': 'Maker',
        'fa': 'اجراء کننده',
        'ar': 'اجراء کونکی',
      },
      'CHDP': {
        'en': 'Cash Deposit',
        'fa': 'دریافت نقدی',
        'ar': 'نقدی دریافت',
      },
      'CHWL': {
        'en': 'Cash Withdraw',
        'fa': 'پرداخت نقدی',
        'ar': 'نقدی پرداخت',
      },
      'GLDR': {
        'en': 'General Ledger Debit',
        'fa': 'پرداخت دفتر کل',
        'ar': 'پرداخت دفتر کل',
      },
      'GLCR': {
        'en': 'General Ledger Credit',
        'fa': 'دریافت دفتر کل',
        'ar': 'دریافت دفتر کل',
      },
      'XPNS': {
        'en': 'Expense',
        'fa': 'مصارف',
        'ar': 'لګښت',
      },
      'INCM': {
        'en': 'Income (Profit)',
        'fa': 'عواید',
        'ar': 'عواید',
      },
      'EXCH': {
        'en': 'Cross Currency',
        'fa': 'ارز متقابل',
        'ar': 'متقابل ارز',
      },
      'debit': {
        'en': 'Debit',
        'fa': 'بدهکار',
        'ar': 'بدهکار',
      },
      'credit': {
        'en': 'Credit',
        'fa': 'بستانکار',
        'ar': 'بسټانکار',
      },
      'branch':{
        'en':'Branch',
        'fa':'شعبه',
        'ar':'څانګه',
      },
      'authorizedBy':{
        'en':'Authorized by: ',
        'fa':'تایید کننده',
        'ar':'تایید کونکی',
      },
      'producedBy':{
        'en':"Powered by Zaitoon Inc",
        'fa':"ساخته شده زیتون سافت",
        'ar':'زیتون سافت لخوا وړاندې شوی',
      },
      'createdBy':{
        'en':'Issued by: ',
        'fa':'تهیه شده توسط: ',
        'ar':'چمتو شوی لخوا: ',
      },
      'reference':{
        'en':'Reference',
        'fa':'شماره مرجع',
        'ar':'حوالې شمیره',
      },
      'amount':{
        'en':'Amount',
        'fa':'مبلغ',
        'ar':'مبلغ',
      },
      'accountName':{
        'en':'Account ',
        'fa':'نام حساب',
        'ar':'حساب نوم',
      },
      'debtor':{
        'en':'Debtor ',
        'fa':'بدهکار',
        'ar':'بدهکار',
      },
      'creditor':{
        'en':'Creditor ',
        'fa':'طلبکار',
        'ar':'طلبکار',
      },
      'accountNumber':{
        'en':'Account No',
        'fa':'شماره حساب',
        'ar':'حساب شمیره',
      },
      'currency': {
        'en':'Currency',
        'fa':'ارز حساب',
        'ar':'حساب ارز',
      },
      'narration':{
        'en':'Narration',
        'fa':'شرح',
        'ar':'شرح',
      },
      'withdrawal':{
        'en':'Withdrawal',
        'fa':'دریافت',
        'ar':'دریافت',
      },
      'deposit':{
        'en':'Deposit',
        'fa':'پرداخت',
        'ar':'پرداخت',
      },
      'balance':{
        'en':'Balance',
        'fa':'بیلانس',
        'ar':'بیلانس',
      },
      'date':{
        'en':'Date',
        'fa':'تاریخ',
        'ar':'نیته',
      },
      'accOwner':{
        'en':'Account holder',
        'fa':'دارنده حساب',
        'ar':'دارنده حساب',
      },
      'mobile':{
        'en':'Mobile',
        'fa':'تماس',
        'ar':'تماس',
      },
      'qty':{
        'en':'Qty',
        'fa':'مقدار',
        'ar':'مقدار',
      },
      'unitPrice':{
        'en':'Unit Price',
        'fa':'قیمت واحد',
        'ar':'واحد قیمت',
      },
      'totalInvoice':{
        'en':'Total',
        'fa':'جمع کل',
        'ar':'ټول قیمت',
      },
      'subTotal':{
        'en':'Total',
        'fa':'جمع جزء',
        'ar':'فرعي مجموعه',
      },
      'number':{
        'en':'No',
        'fa':'شماره',
        'ar':'شمېره',
      },
      'invoiceType':{
        'en':'Invoice',
        'fa':'نوع بل',
        'ar':'بل نوع',
      },
      'PUR':{
        'en':'Purchase',
        'fa':'خرید',
        'ar':'خرید',
      },
      'invDate':{
        'en':'Invoice Date',
        'fa':'تاریخ بل',
        'ar':'بل نیته',
      },
      'SEL':{
        'en':'Sale',
        'fa':'فروش',
        'ar':'فروش',
      },
      'invoiceNumber':{
        'en':'INV',
        'fa':'نمبر بل',
        'ar':'بل نمبر',
      },
      'items':{
        'en':'Items',
        'fa':'نام کالا',
        'ar':'توکي نوم',
      },
      'grandTotal':{
        'en':'Grand Total',
        'fa':'جمع کل نهایی',
        'ar':'ټولیز مجموعه',
      },
      'previousBalance':{
        'en':'Balance',
        'fa':'مانده حساب',
        'ar':'پاتې حساب',
      },
      'payment':{
        'en':'Payment',
        'fa':'مبلغ رسید',
        'ar':'رسید مبلغ',
      },
      'vehicleDetails': {
        'en': 'Vehicle Details',
        'fa': 'جزئیات وسیله نقلیه',
        'ar': 'د موټرو معلومات',
      },
      'vehicleID': {
        'en': 'Vehicle ID',
        'fa': 'شناسه وسیله نقلیه',
        'ar': 'د موټر آی ډی',
      },
      'model': {
        'en': 'Model',
        'fa': 'مدل',
        'ar': 'مودل',
      },
      'year': {
        'en': 'Year',
        'fa': 'سال',
        'ar': 'کال',
      },
      'vinNumber': {
        'en': 'VIN Number',
        'fa': 'شماره VIN',
        'ar': 'وی آی اېن نمبر',
      },
      'fuelType': {
        'en': 'Fuel Type',
        'fa': 'نوع سوخت',
        'ar': 'د سون توکي ډول',
      },
      'enginePower': {
        'en': 'Engine Power',
        'fa': 'قدرت موتور',
        'ar': 'د انجن قوت',
      },
      'bodyType': {
        'en': 'Body Type',
        'fa': 'نوع بدنه',
        'ar': 'د بدن ډول',
      },
      'balanced': {
        'en': 'Balanced',
        'fa': 'متعادل',
        'ar': 'متوازن',
      },
      'plateNumber': {
        'en': 'Plate Number',
        'fa': 'شماره پلاک',
        'ar': 'د پلیټ نمبر',
      },
      'registrationNumber': {
        'en': 'Registration Number',
        'fa': 'شماره ثبت',
        'ar': 'د ثبت نمبر',
      },
      'expiryDate': {
        'en': 'Expiry Date',
        'fa': 'تاریخ انقضا',
        'ar': 'د پای نیټه',
      },
      'odometer': {
        'en': 'Odometer',
        'fa': 'کیلومتر شمار',
        'ar': 'د ګزاریچې شمار',
      },
      'purchaseAmount': {
        'en': 'Orders Amount',
        'fa': 'مبلغ خرید',
        'ar': 'د پیرود مقدار',
      },
      'driver': {
        'en': 'Driver',
        'fa': 'راننده',
        'ar': 'چلوونکی',
      },
      'txnType': {
        'en': 'TXN Type',
        'fa': 'نوع معامله',
        'ar': 'معامله دول',
      },
      'units': {
        'en': 'Units',
        'fa': 'واحد',
        'ar': 'واحد',
      },
      'expense': {
        'en': 'Expense',
        'fa': 'مصرف',
        'ar': 'لگشت',
      },
      'entry': {
        'en': 'Entry',
        'fa': 'ورود',
        'ar': 'ورود',
      },
      'transactionDetails': {
        'en': 'Transaction Details',
        'fa': 'جزئیات تراکنش',
        'ar': 'د معاملې معلومات',
      },
      'transactionStatus': {
        'en': 'Transaction Status',
        'fa': 'وضعیت تراکنش',
        'ar': 'د معاملې حالت',
      },
      'inactive': {
        'en': 'Inactive',
        'fa': 'غیرفعال',
        'ar': 'غیر فعال',
      },
      'active': {
        'en': 'Active',
        'fa': 'فعال',
        'ar': 'فعال',
      },
      'pending': {
        'en': 'Pending',
        'fa': 'در انتظار',
        'ar': 'په تمه کې',
      },
      'approved': {
        'en': 'Approved',
        'fa': 'تایید شده',
        'ar': 'تصویب شوی',
      },
      'rejected': {
        'en': 'Rejected',
        'fa': 'رد شده',
        'ar': 'رد شوی',
      },
      'unknown': {
        'en': 'Unknown',
        'fa': 'ناشناخته',
        'ar': 'نامعلوم',
      },
      'allShipping': {
        'en': 'All Shipping Records',
        'fa': 'همه سوابق حمل و نقل',
        'ar': 'جميع سجلات الشحن',
      },
      'shippingSummary': {
        'en': 'Shipping Summary',
        'fa': 'خلاصه حمل و نقل',
        'ar': 'ملخص الشحن',
      },
      'totalShipments': {
        'en': 'Total Shipments',
        'fa': 'کل حمل و نقل',
        'ar': 'إجمالي الشحنات',
      },
      'completed': {
        'en': 'Completed',
        'fa': 'تکمیل شده',
        'ar': 'مكتمل',
      },
      'totalRent': {
        'en': 'Total Rent',
        'fa': 'کرایه کل',
        'ar': 'الإيجار الكلي',
      },
      'avgUnLoadSize': {
        'en': 'Avg Unload',
        'fa': 'میانگین بارگیری',
        'ar': 'میانگین بارگیری',
      },
      'avgLoadSize': {
        'en': 'Avg Load',
        'fa': 'میانگین تلخیه',
        'ar': 'میانگین تخلیه',
      },
      'vehicles': {
        'en': 'Vehicle',
        'fa': 'وسیله نقلیه',
        'ar': 'مركبة',
      },
      'customer': {
        'en': 'Customer',
        'fa': 'مشتری',
        'ar': 'عميل',
      },
      'shippingRent': {
        'en': 'Rent',
        'fa': 'کرایه',
        'ar': 'إيجار',
      },
      'loadingSize': {
        'en': 'LD Weight',
        'fa': 'اندازه بارگیری',
        'ar': 'حجم التحميل',
      },
      'unloadingSize': {
        'en': 'ULD Weight',
        'fa': 'اندازه تخلیه',
        'ar': 'حجم التفريغ',
      },
      'completedTitle': {
        'en': 'Completed',
        'fa': 'تکمیل',
        'ar': 'مكتمل',
      },
      'pendingTitle': {
        'en': 'Pending',
        'fa': 'در انتظار',
        'ar': 'قيد الانتظار',
      },
      'termsAndConditions': {
        'en': 'Terms & Conditions',
        'fa': 'شرایط و ضوابط',
        'ar': 'شرایط و ضوابط',
      },
      'customerSignature': {
        'en': 'Customer Signature',
        'fa': 'امضای مشتری',
        'ar': 'امضاء العميل',
      },
      'totalPayment': {
        'en': 'Total Payment',
        'fa': 'مجموع پرداخت',
        'ar': 'المبلغ الإجمالي',
      },
      'cashPayment': {
        'en': 'Cash Payment',
        'fa': 'پرداخت نقدی',
        'ar': 'دفع نقدي',
      },
      'accountPayment': {
        'en': 'Account Payment',
        'fa': 'پرداخت حساب',
        'ar': 'دفع الحساب',
      },
      'supplier': {
        'en': 'Supplier',
        'fa': 'تامین کننده',
        'ar': 'المورد',
      },
      'referenceNumber': {
        'en': 'Reference No',
        'fa': 'شماره مرجع',
        'ar': 'رقم المرجع',
      },
      'trialBalance': {
        'en': 'Trial Balance',
        'fa': 'بیلانس آزمایشی',
        'ar': 'آزمایشی بیلانس',
      },
      'outOfBalance':{
        'en': 'Out of balance',
        'fa': 'عدم تعادل',
        'ar': 'عدم تعادل',
      },
      'difference':{
        'en': 'Difference',
        'fa': 'تفاوت',
        'ar': 'تفاوت',
      },
      'orderDate': {
        'en': 'Order Date',
        'fa': 'تاریخ سفارش',
        'ar': 'تاريخ الطلب',
      },
      'quantity': {
        'en': 'Qty',
        'fa': 'تعداد',
        'ar': 'الكمية',
      },
      'actualBalance': {
        'en': 'Actual Balance',
        'fa': 'بیلانس اصلی',
        'ar': 'بیلانس اصلی',
      },
      'storage': {
        'en': 'Storage',
        'fa': 'انبار',
        'ar': 'المستودع',
      },
      'description': {
        'en': 'Description',
        'fa': 'توضیحات',
        'ar': 'الوصف',
      },
      'assets': {
        'en': 'ASSETS',
        'fa': 'دارایی ها',
        'ar': 'الأصول',
      },
      'liabilitiesEquity': {
        'en': 'LIABILITIES AND EQUITY',
        'fa': 'بدهی ها و حقوق صاحبان سهام',
        'ar': 'الالتزامات وحقوق الملكية',
      },
      'currentAssets': {
        'en': 'Current Assets',
        'fa': 'دارایی های جاری',
        'ar': 'الأصول المتداولة',
      },
      'fixedAssets': {
        'en': 'Fixed Assets',
        'fa': 'دارایی های ثابت',
        'ar': 'الأصول الثابتة',
      },
      'intangibleAssets': {
        'en': 'Intangible Assets',
        'fa': 'دارایی های نامشهود',
        'ar': 'الأصول غير الملموسة',
      },
      'currentLiabilities': {
        'en': 'Current Liabilities',
        'fa': 'بدهی های جاری',
        'ar': 'الالتزامات المتداولة',
      },
      'ownerEquity': {
        'en': "Owner's Equity",
        'fa': 'حقوق صاحبان سهام',
        'ar': 'حقوق الملكية',
      },
      'stakeholders': {
        'en': 'Stakeholders',
        'fa': 'ذینفعان',
        'ar': 'أصحاب المصلحة',
      },
      'totalAssets': {
        'en': 'TOTAL ASSETS',
        'fa': 'کل دارایی ها',
        'ar': 'إجمالي الأصول',
      },
      'totalLiabilitiesEquity': {
        'en': 'TOTAL LIABILITIES & EQUITY',
        'fa': 'کل بدهی ها و حقوق صاحبان سهام',
        'ar': 'إجمالي الالتزامات وحقوق الملكية',
      },
      'currentYear': {
        'en': 'Current Year',
        'fa': 'سال جاری',
        'ar': 'السنة الحالية',
      },
      'lastYear': {
        'en': 'Prior Year',
        'fa': 'سال گذشته',
        'ar': 'السنة السابقة',
      },
      'totalTitle': {
        'en': 'Total',
        'fa': 'مجموع',
        'ar': 'المجموع',
      },
      'shippingReport': {
        'en': 'Shipping Report',
        'fa': 'راپور ترانسپورت',
        'ar': 'راپور ترانسپورت'
      },
      'appliedFilters': {
        'en': 'Applied Filters',
        'fa': 'فیلترهای اعمال شده',
        'ar': 'فیلترهای اعمال شده'
      },
      'dateRange': {
        'en': 'Date Range',
        'fa': 'محدوده تاریخ',
        'ar': 'محدوده تاریخ'
      },
      'vehicle': {
        'en': 'Vehicle',
        'fa': 'وسله نقلیه',
        'ar': 'وسله نقلیه'
      },
      'shippingReportSummary': {
        'en': 'Shipping Report Summary',
        'fa': 'خلاصه راپور ترانسپورت',
        'ar': 'خلاصه راپور ترانسپورت'
      },
      'totalLoadSize': {
        'en': 'Total Load Size',
        'fa': 'مجموع حجم بارگیری',
        'ar': 'مجموع حجم بارگیری'
      },
      'totalUnLoadSize': {
        'en': 'Total Unload Size',
        'fa': 'مجموع حجم تخلیه',
        'ar': 'مجموع حجم تخلیه'
      },
      'avgDifference': {
        'en': 'Avg Difference',
        'fa': 'متوسط تفاوت',
        'ar': 'متوسط تفاوت'
      },
      'avgRentPerUnit': {
        'en': 'Avg Rent Per Unit',
        'fa': 'متوسط کرایه فی واحد',
        'ar': 'متوسط کرایه فی واحد'
      },
      'product': {
        'en': 'Product',
        'fa': 'محصول',
        'ar': 'محصول'
      },
      'from': {
        'en': 'From',
        'fa': 'از',
        'ar': 'از'
      },
      'to': {
        'en': 'To',
        'fa': 'به',
        'ar': 'به'
      },
      'loadSize': {
        'en': 'Load Size',
        'fa': 'حجم بارگیری',
        'ar': 'حجم بارگیری'
      },
      'unloadSize': {
        'en': 'Unload Size',
        'fa': 'حجم تخلیه',
        'ar': 'حجم تخلیه'
      },
      'rent': {
        'en': 'Rent',
        'fa': 'کرایه',
        'ar': 'کرایه'
      },
      'no': {
        'en': '#',
        'fa': 'شماره',
        'ar': 'شمیرہ'
      },
      'thisTransaction': {
        'en': 'Current Invoice',
        'fa': 'این معامله',
        'ar': 'دا راکړه ورکړه'
      },
      'newBalance': {
        'en': 'New Balance',
        'fa': 'موجودی جدید',
        'ar': 'نوی بیلانس'
      },
      'status': {
        'en': 'Status',
        'fa': 'وضعیت',
        'ar': 'حالت'
      },
      'settled': {
        'en': 'Settled',
        'fa': 'تسویه شده',
        'ar': 'تصفیه شوی'
      },
      "projectId": {
        "en": "Project ID",
        "ar": "د پروژې پېژند",
        "fa": "شناسه پروژه"
      },
      "projectName": {
        "en": "Project Name",
        "ar": "د پروژې نوم",
        "fa": "نام پروژه"
      },
      "customerName": {
        "en": "Customer Name",
        "ar": "د پیرودونکي نوم",
        "fa": "نام مشتری"
      },
      "location": {
        "en": "Location",
        "ar": "ځای",
        "fa": "موقعیت"
      },
      "projectDetails": {
        "en": "Project Details",
        "ar": "د پروژې تفصیلات",
        "fa": "جزئیات پروژه"
      },
      "deadline": {
        "en": "Deadline",
        "ar": "ټاکل شوې نېټه",
        "fa": "مهلت"
      },
      "paymentType": {
        "en": "Payment Type",
        "ar": "د تادیې ډول",
        "fa": "نوع پرداخت"
      },
      "projectStatus": {
        "en": "Project Status",
        "ar": "د پروژې حالت",
        "fa": "وضعیت پروژه"
      },
      "projectReport": {
        "en": "Project Report",
        "fa": "گزارش پروژه",
        "ar": "د پروژې راپور"
      },
      "financialSummary": {
        "en": "Financial Summary",
        "fa": "خلاصه مالی",
        "ar": "مالي لنډیز"
      },
      "totalServices": {
        "en": "Total Services",
        "fa": "کل خدمات",
        "ar": "ټول خدمات"
      },
      "totalServicesValue": {
        "en": "Total Services Value",
        "fa": "ارزش کل خدمات",
        "ar": "د خدماتو ټول ارزښت"
      },
      "totalTransactions": {
        "en": "Total Transactions",
        "fa": "کل تراکنش ‌ها",
        "ar": "ټولې راکړې ورکړې"
      },
      "currentPhase": {
        "en": "Current Phase",
        "fa": "مرحله فعلی",
        "ar": "اوسنی پړاو"
      },
      "projectInformation": {
        "en": "Project Information",
        "fa": "اطلاعات پروژه",
        "ar": "د پروژې معلومات"
      },
      "ownerInformation": {
        "en": "Client Information",
        "fa": "اطلاعات مالک",
        "ar": "د مالک معلومات"
      },
      "entryDate": {
        "en": "Entry Date",
        "fa": "تاریخ ثبت",
        "ar": "د ثبت نیته"
      },
      "clientTitle": {
        "en": "Client",
        "fa": "مشتری",
        "ar": "پیرودونکی"
      },
      "currencyTitle": {
        "en": "Currency",
        "fa": "واحد پول",
        "ar": "اسعار"
      },
      "serviceName": {
        "en": "Service Name",
        "fa": "نام خدمت",
        "ar": "د خدمت نوم"
      },
      "transactions": {
        "en": "Transactions",
        "fa": "معاملات",
        "ar": "راکړې ورکړې"
      },
      "incomeAndExpenses": {
        "en": "Income & Expenses",
        "fa": "درآمد و هزینه",
        "ar": "عواید او لګښتونه"
      },
      "inProgress": {
        "en": "In Progress",
        "fa": "در حال اجرا",
        "ar": "په پرمختګ کې"
      },
      "overview": {
        "en": "Overview",
        "fa": "بررسی کلی",
        "ar": "کتنه"
      },
      "services": {
        "en": "Services",
        "fa": "خدمات",
        "ar": "خدمتونه"
      },
      "noServicesTitle": {
        "en": "No Services",
        "fa": "بدون خدمات",
        "ar": "خدمتونه نشته"
      },
      "noServicesMessage": {
        "en": "No services found for this project",
        "fa": "خدماتی برای این پروژه یافت نشد",
        "ar": "د دې پروژې لپاره کوم خدمت ونه موندل شو"
      },
      "preparedBy": {
        "en": "Prepared By",
        "fa": "تهیه شده توسط",
        "ar": "چمتو شوی د"
      },
      "approvedBy": {
        "en": "Approved By",
        "fa": "تایید شده توسط",
        "ar": "تایید شوی د"
      },
      "activeServices": {
        "en": "Active Services",
        "fa": "خدمات فعال",
        "ar": "فعال خدمتونه"
      },
      'allBalances': {
        'en': 'All Balances',
        'fa': 'همه حساب‌ها',
        'ar': 'جميع الأرصدة',
      },
      'summaryByCurrency': {
        'en': 'Summary by Currency',
        'fa': 'خلاصه بر اساس ارز',
        'ar': 'ملخص حسب العملة',
      },
      'summary': {
        'en': 'Summary',
        'fa': 'خلاصه',
        'ar': 'ملخص',
      },
      'asOf': {
        'en': 'as of',
        'fa': 'تا تاریخ',
        'ar': 'اعتباراً من',
      },
      'account': {
        'en': 'Account',
        'fa': 'حساب',
        'ar': 'الحساب',
      },
      'name': {
        'en': 'Name',
        'fa': 'نام',
        'ar': 'الاسم',
      },
      'ccy': {
        'en': 'Ccy',
        'fa': 'ارز',
        'ar': 'العملة',
      },
      'stockReport': {
        'en': 'Stock Report',
        'fa': 'گزارش انبار',
        'ar': 'تقرير المخزون',
      },
      'totalItems': {
        'en': 'Total Items',
        'fa': 'تعداد کالاها',
        'ar': 'إجمالي العناصر',
      },
      'totalQuantity': {
        'en': 'Total Quantity',
        'fa': 'مجموع مقدار',
        'ar': 'الكمية الإجمالية',
      },
      'totalValue': {
        'en': 'Total Value',
        'fa': 'ارزش کل',
        'ar': 'القيمة الإجمالية',
      },
      'cashBalances': {
        'en': 'Cash Balances',
        'fa': 'موجودی نقدی',
        'ar': 'نقدی موجودی',
      },
      'allBranches': {
        'en': 'All Branches',
        'fa': 'تمام شعب',
        'ar': 'ټول څانګې',
      },
      'cashFlow': {
        'en': 'Cash Flow',
        'fa': 'جریان نقدی',
        'ar': 'نقدی جریان',
      },
      'phone': {
        'en': 'Phone',
        'fa': 'تلفن',
        'ar': 'تلیفون',
      },
      'time': {
        'en': 'Time',
        'fa': 'زمان',
        'ar': 'وخت',
      },
      'branchWiseDetails': {
        'en': 'Branch-wise Details',
        'fa': 'جزئیات هر شعبه',
        'ar': 'د څانګو تفصیلات',
      },
      'noRecords': {
        'en': 'No records found',
        'fa': 'رکوردی یافت نشد',
        'ar': 'هیڅ ریکارډ ونه موندل شو',
      },
      'branchTotal': {
        'en': 'Branch Total',
        'fa': 'مجموع شعبه',
        'ar': 'د څانګې مجموعه',
      },
      'opening': {
        'en': 'Opening',
        'fa': 'افتتاحیه',
        'ar': 'پرانیستل',
      },
      'closing': {
        'en': 'Closing',
        'fa': 'اختتامیه',
        'ar': 'تړل',
      },
    };

    // Default to English if language not found
    final languageMap = translation[text] ?? {'en': '', 'fa': '', 'ar': ''};
    return languageMap[tr] ?? languageMap['en']!;
  }
}