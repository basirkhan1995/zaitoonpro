// To parse this JSON data, do
//
//     final transactionReportModel = transactionReportModelFromMap(jsonString);

import 'dart:convert';

List<TransactionReportModel> transactionReportModelFromMap(String str) => List<TransactionReportModel>.from(json.decode(str).map((x) => TransactionReportModel.fromMap(x)));

String transactionReportModelToMap(List<TransactionReportModel> data) => json.encode(List<dynamic>.from(data.map((x) => x.toMap())));

class TransactionReportModel {
  final int? no;
  final String? reference;
  final String? narration;
  final String? type;
  final int? status;
  final String? statusText;
  final String? maker;
  final String? checker;
  final String? currency;
  final String? actualAmount;
  final String? sysEquavalint;
  final DateTime? timing;

  TransactionReportModel({
    this.no,
    this.reference,
    this.type,
    this.status,
    this.statusText,
    this.maker,
    this.checker,
    this.currency,
    this.actualAmount,
    this.sysEquavalint,
    this.narration,
    this.timing,
  });

  TransactionReportModel copyWith({
    int? no,
    String? reference,
    String? type,
    int? status,
    String? statusText,
    String? maker,
    String? checker,
    String? currency,
    String? actualAmount,
    String? sysEquavalint,
    String? narration,
    DateTime? timing,
  }) =>
      TransactionReportModel(
        no: no ?? this.no,
        reference: reference ?? this.reference,
        type: type ?? this.type,
        status: status ?? this.status,
        statusText: statusText ?? this.statusText,
        maker: maker ?? this.maker,
        checker: checker ?? this.checker,
        currency: currency ?? this.currency,
        actualAmount: actualAmount ?? this.actualAmount,
        sysEquavalint: sysEquavalint ?? this.sysEquavalint,
        timing: timing ?? this.timing,
        narration: narration ?? this.narration
      );

  factory TransactionReportModel.fromMap(Map<String, dynamic> json) => TransactionReportModel(
    no: json["No"],
    reference: json["reference"],
    type: json["trnType"],
    status: json["trnStatus"],
    statusText: json["statusText"],
    maker: json["maker"],
    checker: json["checker"] ?? "",
    currency: json["currency"],
    actualAmount: json["actual_amount"],
    sysEquavalint: json["sys_equivalent"],
    narration: json["narration"],
    timing: json["timing"] == null ? null : DateTime.parse(json["timing"]),
  );

  Map<String, dynamic> toMap() => {
    "No": no,
    "reference": reference,
    "trnType": type,
    "trnStatus": status,
    "statusText": statusText,
    "maker": maker,
    "checker": checker,
    "currency": currency,
    "actual_amount": actualAmount,
    "sys_equivalent": sysEquavalint,
    "timing": timing?.toIso8601String(),
    "narration": narration,
  };
}
