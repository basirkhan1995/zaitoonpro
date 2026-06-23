// To parse this JSON data, do
//
//     final projectByIdModel = projectByIdModelFromMap(jsonString);

import 'dart:convert';

ProjectByIdModel projectByIdModelFromMap(String str) => ProjectByIdModel.fromMap(json.decode(str));

String projectByIdModelToMap(ProjectByIdModel data) => json.encode(data.toMap());

class ProjectByIdModel {
  final int? prjId;
  final String? prjName;
  final String? prjLocation;
  final String? prjDetails;
  final DateTime? prjDateLine;
  final DateTime? prjEntryDate;
  final int? prjOwner;
  final String? prjOwnerfullName;
  final int? prjOwnerAccount;
  final String? actCurrency;
  final int? prjStatus;
  final List<ProjectService>? projectServices;
  final List<ProjectPayment>? projectPayments;

  ProjectByIdModel({
    this.prjId,
    this.prjName,
    this.prjLocation,
    this.prjDetails,
    this.prjDateLine,
    this.prjEntryDate,
    this.prjOwner,
    this.prjOwnerfullName,
    this.prjOwnerAccount,
    this.actCurrency,
    this.prjStatus,
    this.projectServices,
    this.projectPayments,
  });

  ProjectByIdModel copyWith({
    int? prjId,
    String? prjName,
    String? prjLocation,
    String? prjDetails,
    DateTime? prjDateLine,
    DateTime? prjEntryDate,
    int? prjOwner,
    String? prjOwnerfullName,
    int? prjOwnerAccount,
    String? actCurrency,
    int? prjStatus,
    List<ProjectService>? projectServices,
    List<ProjectPayment>? projectPayments,
  }) =>
      ProjectByIdModel(
        prjId: prjId ?? this.prjId,
        prjName: prjName ?? this.prjName,
        prjLocation: prjLocation ?? this.prjLocation,
        prjDetails: prjDetails ?? this.prjDetails,
        prjDateLine: prjDateLine ?? this.prjDateLine,
        prjEntryDate: prjEntryDate ?? this.prjEntryDate,
        prjOwner: prjOwner ?? this.prjOwner,
        prjOwnerfullName: prjOwnerfullName ?? this.prjOwnerfullName,
        prjOwnerAccount: prjOwnerAccount ?? this.prjOwnerAccount,
        actCurrency: actCurrency ?? this.actCurrency,
        prjStatus: prjStatus ?? this.prjStatus,
        projectServices: projectServices ?? this.projectServices,
        projectPayments: projectPayments ?? this.projectPayments,
      );

  factory ProjectByIdModel.fromMap(Map<String, dynamic> json) => ProjectByIdModel(
    prjId: json["prjID"],
    prjName: json["prjName"],
    prjLocation: json["prjLocation"],
    prjDetails: json["prjDetails"],
    prjDateLine: json["prjDateLine"] == null ? null : DateTime.parse(json["prjDateLine"]),
    prjEntryDate: json["prjEntryDate"] == null ? null : DateTime.parse(json["prjEntryDate"]),
    prjOwner: json["prjOwner"],
    prjOwnerfullName: json["prjOwnerfullName"],
    prjOwnerAccount: json["prjOwnerAccount"],
    actCurrency: json["actCurrency"],
    prjStatus: json["prjStatus"],
    projectServices: json["projectServices"] == null ? [] : List<ProjectService>.from(json["projectServices"]!.map((x) => ProjectService.fromMap(x))),
    projectPayments: json["projectPayments"] == null ? [] : List<ProjectPayment>.from(json["projectPayments"]!.map((x) => ProjectPayment.fromMap(x))),
  );

  Map<String, dynamic> toMap() => {
    "prjID": prjId,
    "prjName": prjName,
    "prjLocation": prjLocation,
    "prjDetails": prjDetails,
    "prjDateLine": "${prjDateLine!.year.toString().padLeft(4, '0')}-${prjDateLine!.month.toString().padLeft(2, '0')}-${prjDateLine!.day.toString().padLeft(2, '0')}",
    "prjEntryDate": prjEntryDate?.toIso8601String(),
    "prjOwner": prjOwner,
    "prjOwnerfullName": prjOwnerfullName,
    "prjOwnerAccount": prjOwnerAccount,
    "actCurrency": actCurrency,
    "prjStatus": prjStatus,
    "projectServices": projectServices == null ? [] : List<dynamic>.from(projectServices!.map((x) => x.toMap())),
    "projectPayments": projectPayments == null ? [] : List<dynamic>.from(projectPayments!.map((x) => x.toMap())),
  };
}

class ProjectPayment {
  final int? prjId;
  final String? prpType;
  final String? prpTrnRef;
  final String? trnStateText;
  final DateTime? trnEntryDate;
  final String? trdCcy;
  final String? payments;
  final String? expenses;
  final String? trdNarration;

  ProjectPayment({
    this.prjId,
    this.prpType,
    this.prpTrnRef,
    this.trnStateText,
    this.trnEntryDate,
    this.trdCcy,
    this.payments,
    this.expenses,
    this.trdNarration,
  });

  ProjectPayment copyWith({
    int? prjId,
    String? prpType,
    String? prpTrnRef,
    String? trnStateText,
    DateTime? trnEntryDate,
    String? trdCcy,
    String? payments,
    String? expenses,
    String? trdNarration,

  }) =>
      ProjectPayment(
        prjId: prjId ?? this.prjId,
        prpType: prpType ?? this.prpType,
        prpTrnRef: prpTrnRef ?? this.prpTrnRef,
        trnStateText: trnStateText ?? this.trnStateText,
        trnEntryDate: trnEntryDate ?? this.trnEntryDate,
        trdCcy: trdCcy ?? this.trdCcy,
        payments: payments ?? this.payments,
        expenses: expenses ?? this.expenses,
        trdNarration: trdNarration ?? this.trdNarration
      );

  factory ProjectPayment.fromMap(Map<String, dynamic> json) => ProjectPayment(
    prjId: json["prjID"],
    prpType: json["prpType"],
    prpTrnRef: json["prpTrnRef"],
    trnStateText: json["trnStateText"],
    trnEntryDate: json["trnEntryDate"] == null ? null : DateTime.parse(json["trnEntryDate"]),
    trdCcy: json["trdCcy"],
    payments: json["payments"],
    expenses: json["expenses"],
    trdNarration: json["trdNarration"]
  );

  Map<String, dynamic> toMap() => {
    "prjID": prjId,
    "prpType": prpType,
    "prpTrnRef": prpTrnRef,
    "trnStateText": trnStateText,
    "trnEntryDate": trnEntryDate?.toIso8601String(),
    "trdCcy": trdCcy,
    "payments": payments,
    "expenses": expenses,
    "trdNarration":trdNarration,
  };
}

class ProjectService {
  final int? pjdId;
  final int? srvId;
  final String? srvName;
  final String? pjdQuantity;
  final String? pjdPricePerQty;
  final String? total;
  final String? prpTrnRef;
  final int? paymentId;
  final String? pjdRemark;
  final int? pjdStatus;

  ProjectService({
    this.pjdId,
    this.srvId,
    this.srvName,
    this.pjdQuantity,
    this.pjdPricePerQty,
    this.total,
    this.prpTrnRef,
    this.paymentId,
    this.pjdRemark,
    this.pjdStatus,
  });

  ProjectService copyWith({
    int? pjdId,
    int? srvId,
    String? srvName,
    String? pjdQuantity,
    String? pjdPricePerQty,
    String? total,
    String? prpTrnRef,
    int? paymentId,
    String? pjdRemark,
    int? pjdStatus,
  }) =>
      ProjectService(
        pjdId: pjdId ?? this.pjdId,
        srvId: srvId ?? this.srvId,
        srvName: srvName ?? this.srvName,
        pjdQuantity: pjdQuantity ?? this.pjdQuantity,
        pjdPricePerQty: pjdPricePerQty ?? this.pjdPricePerQty,
        total: total ?? this.total,
        prpTrnRef: prpTrnRef ?? this.prpTrnRef,
        paymentId: paymentId ?? this.paymentId,
        pjdRemark: pjdRemark ?? this.pjdRemark,
        pjdStatus: pjdStatus ?? this.pjdStatus,
      );

  factory ProjectService.fromMap(Map<String, dynamic> json) => ProjectService(
    pjdId: json["pjdID"],
    srvId: json["srvID"],
    srvName: json["srvName"],
    pjdQuantity: json["pjdQuantity"],
    pjdPricePerQty: json["pjdPricePerQty"],
    total: json["total"],
    prpTrnRef: json["prpTrnRef"],
    paymentId: json["paymentID"],
    pjdRemark: json["pjdRemark"],
    pjdStatus: json["pjdStatus"],
  );

  Map<String, dynamic> toMap() => {
    "pjdID": pjdId,
    "srvID": srvId,
    "srvName": srvName,
    "pjdQuantity": pjdQuantity,
    "pjdPricePerQty": pjdPricePerQty,
    "total": total,
    "prpTrnRef": prpTrnRef,
    "paymentID": paymentId,
    "pjdRemark": pjdRemark,
    "pjdStatus": pjdStatus,
  };
}
