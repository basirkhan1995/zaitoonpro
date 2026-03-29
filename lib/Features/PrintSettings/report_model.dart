
import 'dart:typed_data';

class ReportModel {
  String? comName;
  String? compPhone;
  String? slogan;
  int? invoiceNumber;
  String? comEmail;
  Uint8List? comLogo;
  String? comAddress;
  String? baseCurrency;
  String? statementDate;
  String? startDate;
  String? endDate;
  String? statementPeriod;

  ReportModel({
    this.comName,
    this.compPhone,
    this.slogan,
    this.comEmail,
    this.comLogo,
    this.comAddress,
    this.invoiceNumber,
    this.baseCurrency,
    this.statementDate,
    this.startDate,
    this.statementPeriod,
    this.endDate,
  });

  ReportModel copyWith({
    String? comName,
    String? compPhone,
    String? slogan,
    int? invoiceNumber,
    String? comEmail,
    Uint8List? comLogo,
    String? comAddress,
    String? baseCurrency,
    String? statementDate,
    String? startDate,
    String? statementPeriod,
    String? endDate,
    }) =>
      ReportModel(
        comName: comName ?? this.comName,
        compPhone: compPhone ?? this.compPhone,
        comEmail: comEmail ?? this.comEmail,
        comLogo: comLogo ?? this.comLogo,
        slogan: slogan ?? this.slogan,
        comAddress: comAddress ?? this.comAddress,
        invoiceNumber: invoiceNumber ?? this.invoiceNumber,
        statementDate: statementDate ?? this.statementDate,
        startDate: startDate ?? this.startDate,
        statementPeriod: statementPeriod ?? this.statementPeriod,
        endDate: endDate ?? this.endDate,
        baseCurrency: baseCurrency ?? this.baseCurrency
      );
}
