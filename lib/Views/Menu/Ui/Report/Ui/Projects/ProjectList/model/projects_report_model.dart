
import 'dart:convert';

List<ProjectsReportModel> projectsReportModelFromMap(String str) => List<ProjectsReportModel>.from(json.decode(str).map((x) => ProjectsReportModel.fromMap(x)));

String projectsReportModelToMap(List<ProjectsReportModel> data) => json.encode(List<dynamic>.from(data.map((x) => x.toMap())));

class ProjectsReportModel {
  final int? prjId;
  final String? prjName;
  final String? prjLocation;
  final String? customerName;
  final int? prjOwnerAccount;
  final DateTime? prjDateLine;
  final DateTime? prjEntryDate;
  final String? totalAmount;
  final String? totalPayments;
  final String? actCurrency;
  final String? ccySymbol;
  final String? prjStatus;

  ProjectsReportModel({
    this.prjId,
    this.prjName,
    this.prjLocation,
    this.customerName,
    this.prjOwnerAccount,
    this.prjDateLine,
    this.prjEntryDate,
    this.totalAmount,
    this.totalPayments,
    this.actCurrency,
    this.ccySymbol,
    this.prjStatus,
  });

  ProjectsReportModel copyWith({
    int? prjId,
    String? prjName,
    String? prjLocation,
    String? customerName,
    int? prjOwnerAccount,
    DateTime? prjDateLine,
    DateTime? prjEntryDate,
    String? totalAmount,
    String? totalPayments,
    String? actCurrency,
    String? ccySymbol,
    String? prjStatus,
  }) =>
      ProjectsReportModel(
        prjId: prjId ?? this.prjId,
        prjName: prjName ?? this.prjName,
        prjLocation: prjLocation ?? this.prjLocation,
        customerName: customerName ?? this.customerName,
        prjOwnerAccount: prjOwnerAccount ?? this.prjOwnerAccount,
        prjDateLine: prjDateLine ?? this.prjDateLine,
        prjEntryDate: prjEntryDate ?? this.prjEntryDate,
        totalAmount: totalAmount ?? this.totalAmount,
        totalPayments: totalPayments ?? this.totalPayments,
        actCurrency: actCurrency ?? this.actCurrency,
        ccySymbol: ccySymbol ?? this.ccySymbol,
        prjStatus: prjStatus ?? this.prjStatus,
      );

  factory ProjectsReportModel.fromMap(Map<String, dynamic> json) => ProjectsReportModel(
    prjId: json["prjID"],
    prjName: json["prjName"],
    prjLocation: json["prjLocation"],
    customerName: json["customerName"],
    prjOwnerAccount: json["prjOwnerAccount"],
    prjDateLine: json["prjDateLine"] == null ? null : DateTime.parse(json["prjDateLine"]),
    prjEntryDate: json["prjEntryDate"] == null ? null : DateTime.parse(json["prjEntryDate"]),
    totalAmount: json["totalAmount"],
    totalPayments: json["totalPayments"],
    actCurrency: json["actCurrency"],
    ccySymbol: json["ccySymbol"],
    prjStatus: json["prjStatus"],
  );

  Map<String, dynamic> toMap() => {
    "prjID": prjId,
    "prjName": prjName,
    "prjLocation": prjLocation,
    "customerName": customerName,
    "prjOwnerAccount": prjOwnerAccount,
    "prjDateLine": "${prjDateLine!.year.toString().padLeft(4, '0')}-${prjDateLine!.month.toString().padLeft(2, '0')}-${prjDateLine!.day.toString().padLeft(2, '0')}",
    "prjEntryDate": "${prjEntryDate!.year.toString().padLeft(4, '0')}-${prjEntryDate!.month.toString().padLeft(2, '0')}-${prjEntryDate!.day.toString().padLeft(2, '0')}",
    "totalAmount": totalAmount,
    "totalPayments": totalPayments,
    "actCurrency": actCurrency,
    "ccySymbol": ccySymbol,
    "prjStatus": prjStatus,
  };
}
