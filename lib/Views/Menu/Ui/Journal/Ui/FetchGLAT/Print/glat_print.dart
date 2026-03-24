import 'package:pdf/pdf.dart' as pw;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:zaitoonpro/Features/Date/shamsi_converter.dart';
import 'package:zaitoonpro/Features/Other/extensions.dart';
import 'package:zaitoonpro/Features/PrintSettings/print_services.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Journal/Ui/FetchGLAT/model/glat_model.dart';
import '../../../../../../../Features/PrintSettings/report_model.dart';
import 'package:flutter/services.dart';

 class GlatPrintSettings extends PrintServices{

   Future<pw.Document> generateStatement({
     required String language,
     required ReportModel report,
     required GlatModel data,
     required pw.PageOrientation orientation,
     required pw.PdfPageFormat pageFormat,
   }) async {
     final document = pw.Document();
     final prebuiltHeader = await header(report: report);

     final ByteData imageData = await rootBundle.load('assets/images/zaitoonLogo.png');
     final Uint8List imageBytes = imageData.buffer.asUint8List();
     final pw.MemoryImage logoImage = pw.MemoryImage(imageBytes);

     document.addPage(
       pw.MultiPage(
         maxPages: 1000,
         margin: pw.EdgeInsets.symmetric(horizontal: 25, vertical: 10),
         pageFormat: pageFormat,
         textDirection: documentLanguage(language: language),
         orientation: orientation,
         build: (context) => [
           horizontalDivider(),
           pw.SizedBox(height: 5),
           buildResponseData(data: data, language: language),
           signatory(language: language, data: data)
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

   //Real Time document show
   Future<pw.Document> printPreview({
     required String language,
     required ReportModel company,
     required pw.PageOrientation orientation,
     required GlatModel data,
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

   //To Print
   Future<void> printDocument({
     required GlatModel data,
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
           await Future.delayed(Duration(milliseconds: 100));
         }
       }
     } catch (e) {
       throw e.toString();
     }
   }

   Future<void> createDocument({
     required GlatModel data,
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
           pageFormat: pageFormat
       );

       // Save the document
       await saveDocument(
         suggestedName: "Glat.pdf",
         pdf: document,
       );
     } catch (e) {
       throw e.toString();
     }
   }

   //Signature
   pw.Padding signatory({required String language, required GlatModel data}) {
     return pw.Padding(
       padding: pw.EdgeInsets.symmetric(horizontal: 15, vertical: 10),
       child: pw.Row(
         mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
         crossAxisAlignment: pw.CrossAxisAlignment.start,
         children: [
           pw.Column(
             mainAxisAlignment: pw.MainAxisAlignment.start,
             crossAxisAlignment: pw.CrossAxisAlignment.center,
             children: [
               horizontalDivider(width: 120),
               pw.Row(
                 mainAxisAlignment: pw.MainAxisAlignment.start,
                 children: [
                   zText(text: tr(text: 'createdBy', tr: language), fontSize: 7),
                   zText(text: " ${data.transaction?.maker} ", fontSize: 7),
                 ],
               ),
             ],
           ),
           pw.Column(
             mainAxisAlignment: pw.MainAxisAlignment.start,
             crossAxisAlignment: pw.CrossAxisAlignment.center,
             children: [
               horizontalDivider(width: 120),
               pw.Row(
                 mainAxisAlignment: pw.MainAxisAlignment.start,
                 children: [
                   zText(text: tr(text: 'authorizedBy', tr: language), fontSize: 7),
                   zText(text: data.transaction?.checker??"", fontSize: 7),
                 ],
               ),

             ],
           ),
         ],
       ),
     );
   }

   pw.Widget buildResponseData({required GlatModel data, required String language}) {
     return pw.Container(
       decoration: pw.BoxDecoration(
        // border: pw.Border.all(color: pw.PdfColors.black, width: 0.5),
         borderRadius: pw.BorderRadius.circular(5),
       ),
       child: pw.Padding(
         padding: pw.EdgeInsets.all(15),
         child: pw.Column(
           crossAxisAlignment: pw.CrossAxisAlignment.start,
           children: [
             pw.Row(
               children: [
                 zText(
                   text: tr(text: 'vehicleDetails', tr: language),
                   fontSize: 16,
                   fontWeight: pw.FontWeight.bold,
                 ),
               ]
             ),
             pw.SizedBox(height: 15),

             pw.Row(
               crossAxisAlignment: pw.CrossAxisAlignment.start,
               children: [
                 pw.Expanded(
                   child: pw.Column(
                     crossAxisAlignment: pw.CrossAxisAlignment.start,
                     children: [
                       _buildDetailRow(
                         label: tr(text: 'vehicleID', tr: language),
                         value: data.vclId?.toString() ?? 'N/A',
                       ),
                       _buildDetailRow(
                         label: tr(text: 'model', tr: language),
                         value: data.vclModel ?? 'N/A',
                       ),
                       _buildDetailRow(
                         label: tr(text: 'year', tr: language),
                         value: data.vclYear ?? 'N/A',
                       ),
                       _buildDetailRow(
                         label: tr(text: 'vinNumber', tr: language),
                         value: data.vclVinNo ?? 'N/A',
                       ),
                       _buildDetailRow(
                         label: tr(text: 'fuelType', tr: language),
                         value: data.vclFuelType ?? 'N/A',
                       ),
                       _buildDetailRow(
                         label: tr(text: 'enginePower', tr: language),
                         value: data.vclEnginPower ?? 'N/A',
                       ),
                       _buildDetailRow(
                         label: tr(text: 'bodyType', tr: language),
                         value: data.vclBodyType ?? 'N/A',
                       ),
                     ],
                   ),
                 ),

                 pw.SizedBox(width: 5),

                 pw.Expanded(
                   child: pw.Column(
                     crossAxisAlignment: pw.CrossAxisAlignment.start,
                     children: [
                       _buildDetailRow(
                         label: tr(text: 'plateNumber', tr: language),
                         value: data.vclPlateNo ?? 'N/A',
                       ),
                       _buildDetailRow(
                         label: tr(text: 'registrationNumber', tr: language),
                         value: data.vclRegNo ?? 'N/A',
                       ),
                       _buildDetailRow(
                         label: tr(text: 'expiryDate', tr: language),
                         value: data.vclExpireDate.toFormattedDate(),
                       ),
                       _buildDetailRow(
                         label: tr(text: 'odometer', tr: language),
                         value: data.vclOdoMeter?.toString() ?? 'N/A',
                       ),
                       _buildDetailRow(
                         label: tr(text: 'purchaseAmount', tr: language),
                         value: '${data.vclPurchaseAmount?.toAmount()} ${data.transaction?.purchaseCurrency}',
                       ),
                       _buildDetailRow(
                         label: tr(text: 'driver', tr: language),
                         value: data.driver ?? 'N/A',
                       ),
                       _buildDetailRow(
                         label: tr(text: 'status', tr: language),
                         value: _getStatusText(data.vclStatus ?? 0, language),
                       ),
                     ],
                   ),
                 ),
               ],
             ),

             pw.SizedBox(height: 20),

             pw.Container(
               decoration: pw.BoxDecoration(
                 border: pw.Border.all(color: pw.PdfColors.grey, width: 0.5),
                 borderRadius: pw.BorderRadius.circular(3),
               ),
               padding: pw.EdgeInsets.all(10),
               child: pw.Column(
                 crossAxisAlignment: pw.CrossAxisAlignment.start,
                 children: [
                   pw.Text(
                     tr(text: 'transactionDetails', tr: language),
                     style: pw.TextStyle(
                       fontSize: 14,
                       fontWeight: pw.FontWeight.bold,
                       color: pw.PdfColors.blue800,
                     ),
                   ),
                   pw.SizedBox(height: 10),

                   if (data.transaction != null)
                     pw.Row(
                       crossAxisAlignment: pw.CrossAxisAlignment.start,
                       children: [
                         pw.Expanded(
                           child: pw.Column(
                             crossAxisAlignment: pw.CrossAxisAlignment.start,
                             children: [
                               _buildDetailRow(
                                 label: tr(text: 'reference', tr: language),
                                 value: data.transaction!.trnReference ?? 'N/A',
                               ),
                               _buildDetailRow(
                                 label: tr(text: 'amount', tr: language),
                                 value: '${data.transaction!.purchaseAmount?.toAmount()} ${data.transaction!.purchaseCurrency ?? ''}',
                               ),
                               _buildDetailRow(
                                 label: tr(text: 'debitAccount', tr: language),
                                 value: data.transaction!.debitAccount?.toString() ?? 'N/A',
                               ),
                             ],
                           ),
                         ),

                         pw.SizedBox(width: 20),

                         pw.Expanded(
                           child: pw.Column(
                             crossAxisAlignment: pw.CrossAxisAlignment.start,
                             children: [
                               _buildDetailRow(
                                 label: tr(text: 'creditAccount', tr: language),
                                 value: data.transaction!.creditAccount?.toString() ?? 'N/A',
                               ),

                               _buildDetailRow(
                                 label: tr(text: 'transactionStatus', tr: language),
                                 value: _getTransactionStatusText(data.transaction!.trnStatus ?? 0, language),
                               ),

                               _buildDetailRow(
                                 label: tr(text: 'narration', tr: language),
                                 value: data.transaction!.narration ?? 'N/A',
                               ),
                             ],
                           ),
                         ),
                       ],
                     ),
                 ],
               ),
             ),
           ],
         ),
       ),
     );
   }

   pw.Widget _buildDetailRow({required String label, required String value}) {
     return pw.Padding(
       padding: pw.EdgeInsets.symmetric(vertical: 4),
       child: pw.Row(
         crossAxisAlignment: pw.CrossAxisAlignment.start,
         children: [
           pw.Expanded(
             flex: 2,
             child:zText(
               text: '$label:',
               fontSize: 8,
               fontWeight: pw.FontWeight.bold,
             ),
           ),
           pw.Expanded(
             flex: 3,
             child: zText(
               text: value,
               fontSize: 8,
             ),
           ),
         ],
       ),
     );
   }

   String _getStatusText(int status, String language) {
     switch (status) {
       case 0:
         return tr(text: 'inactive', tr: language);
       case 1:
         return tr(text: 'active', tr: language);
       default:
         return tr(text: 'unknown', tr: language);
     }
   }

   String _getTransactionStatusText(int status, String language) {
     switch (status) {
       case 0:
         return tr(text: 'pending', tr: language);
       case 1:
         return tr(text: 'approved', tr: language);
       case 2:
         return tr(text: 'rejected', tr: language);
       default:
         return tr(text: 'unknown', tr: language);
     }
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
             // Company info (left side)
             pw.Expanded(
               flex: 3,
               child: pw.Column(
                 crossAxisAlignment: pw.CrossAxisAlignment.start,
                 mainAxisAlignment: pw.MainAxisAlignment.center,
                 children: [
                   zText(text: report.comName ?? "", fontSize: 20,tightBounds: true),
                   pw.SizedBox(height: 3),
                   zText(text: report.statementDate ?? "", fontSize: 10),
                 ],
               ),
             ),
             // Logo (right side)
             if (image != null)
               pw.Container(
                 width: 40,
                 height: 40,
                 child: pw.Image(image, fit: pw.BoxFit.contain),
               ),
           ],
         ),
         pw.SizedBox(height: 5)
       ],
     );
   }
   @override
  pw.Widget footer({required ReportModel report, required pw.Context context, required String language, required pw.MemoryImage logoImage}) {
     return pw.Column(
       children: [
         pw.Row(
           mainAxisAlignment: pw.MainAxisAlignment.start,
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
             zText(text: report.comAddress ?? "", fontSize: 9),
           ],
         ),
         pw.SizedBox(height: 3),
         pw.Row(
           mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
           crossAxisAlignment: pw.CrossAxisAlignment.end,
           children: [
             pw.Row(
               children: [
                 zText(text: report.compPhone ?? "", fontSize: 9),
                 verticalDivider(height: 10, width: 1),
                 zText(text: report.comEmail ?? "", fontSize: 9),
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
 }