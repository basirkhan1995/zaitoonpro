
import 'dart:typed_data';

import 'package:zaitoonpro/Views/Menu/Ui/Settings/features/Visibility/bloc/settings_visible_bloc.dart';

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

  String? partyAddress;
  String? partyPhone;
  String? partyCity;
  String? partyProvince;
  SettingsVisibilityState? visible;

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
    this.partyAddress,
    this.partyPhone,
    this.partyCity,
    this.partyProvince,
    this.visible
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
    String? partyAddress,
    String? partyPhone,
    SettingsVisibilityState? visible
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
        baseCurrency: baseCurrency ?? this.baseCurrency,
        partyAddress: partyAddress ?? this.partyAddress,
        partyPhone:  partyPhone ?? this.partyPhone,
        visible: visible ?? this.visible
      );
}
