import 'dart:convert';

ProjectInOutModel projectInOutModelFromMap(String str) => ProjectInOutModel.fromMap(json.decode(str));

String projectInOutModelToMap(ProjectInOutModel data) => json.encode(data.toMap());

class ProjectInOutModel {
  final String? prpType;
  final int? prjId;
  final String? trdCcy;
  final String? debitAccountNumber; // Account that gets DEBITED
  final String? creditAccountNumber; // Account that gets CREDITED
  final String? amount;
  final String? currency;
  final String? ppRemark;
  final String? totalProjectAmount;
  final List<Payment>? payments;
  final String? usrName;
  final String? reference;

  ProjectInOutModel({
    this.prpType,
    this.prjId,
    this.trdCcy,
    this.debitAccountNumber,
    this.creditAccountNumber,
    this.amount,
    this.currency,
    this.ppRemark,
    this.totalProjectAmount,
    this.payments,
    this.usrName,
    this.reference,
  });

  ProjectInOutModel copyWith({
    String? prpType,
    int? prjId,
    String? trdCcy,
    String? debitAccountNumber,
    String? creditAccountNumber,
    String? amount,
    String? currency,
    String? ppRemark,
    String? totalProjectAmount,
    List<Payment>? payments,
    String? usrName,
    String? reference,
  }) =>
      ProjectInOutModel(
        prpType: prpType ?? this.prpType,
        prjId: prjId ?? this.prjId,
        trdCcy: trdCcy ?? this.trdCcy,
        debitAccountNumber: debitAccountNumber ?? this.debitAccountNumber,
        creditAccountNumber: creditAccountNumber ?? this.creditAccountNumber,
        amount: amount ?? this.amount,
        currency: currency ?? this.currency,
        ppRemark: ppRemark ?? this.ppRemark,
        totalProjectAmount: totalProjectAmount ?? this.totalProjectAmount,
        payments: payments ?? this.payments,
        usrName: usrName ?? this.usrName,
        reference: reference ?? this.reference,
      );

  factory ProjectInOutModel.fromMap(Map<String, dynamic> json) => ProjectInOutModel(
    prpType: json["prpType"],
    prjId: json["prjID"],
    trdCcy: json["trdCcy"],
    debitAccountNumber: json["debitAccountNumber"], // ✅ Fixed: Match API response
    creditAccountNumber: json["creditAccountNumber"], // ✅ Fixed: Match API response
    amount: json["Amount"],
    currency: json["currency"],
    ppRemark: json["ppRemark"],
    totalProjectAmount: json["total_project_amount"],
    payments: json["payments"] == null ? [] : List<Payment>.from(json["payments"]!.map((x) => Payment.fromMap(x))),
    usrName: json["usrName"],
    reference: json["prpTrnRef"],
  );

  Map<String, dynamic> toMap() => {
    "prpType": prpType,
    "prjID": prjId,
    "trdCcy": trdCcy,
    "debitAccountNumber": debitAccountNumber, // ✅ Fixed: Match API
    "creditAccountNumber": creditAccountNumber, // ✅ Fixed: Match API
    "Amount": amount,
    "currency": currency,
    "ppRemark": ppRemark,
    "total_project_amount": totalProjectAmount,
    "payments": payments == null ? [] : List<dynamic>.from(payments!.map((x) => x.toMap())),
    "usrName": usrName,
    "prpTrnRef": reference,
  };
}

class Payment {
  final String? prpType;
  final String? prpTrnRef;
  final String? trnStateText;
  final DateTime? trnEntryDate;
  final String? trdCcy;
  final String? trdNarration;
  final int? debitAccount;
  final int? creditAccount;
  final String? creditAccName;
  final String? debitAccName;
  final String? payments;
  final String? expenses;

  Payment({
    this.prpType,
    this.prpTrnRef,
    this.trnStateText,
    this.trnEntryDate,
    this.trdCcy,
    this.trdNarration,
    this.debitAccount,
    this.creditAccount,
    this.creditAccName,
    this.debitAccName,
    this.payments,
    this.expenses,
  });

  Payment copyWith({
    String? prpType,
    String? prpTrnRef,
    String? trnStateText,
    DateTime? trnEntryDate,
    String? trdCcy,
    String? trdNarration,
    int? debitAccount,
    int? creditAccount,
    String? debitAccName,
    String? creditAccName,
    String? payments,
    String? expenses,
  }) =>
      Payment(
        prpType: prpType ?? this.prpType,
        prpTrnRef: prpTrnRef ?? this.prpTrnRef,
        trnStateText: trnStateText ?? this.trnStateText,
        trnEntryDate: trnEntryDate ?? this.trnEntryDate,
        trdCcy: trdCcy ?? this.trdCcy,
        trdNarration: trdNarration ?? this.trdNarration,
        debitAccount: debitAccount ?? this.debitAccount,
        creditAccount: creditAccount ?? this.creditAccount,
        creditAccName: creditAccName ?? this.creditAccName,
        debitAccName: debitAccName ?? this.debitAccName,
        payments: payments ?? this.payments,
        expenses: expenses ?? this.expenses,
      );

  factory Payment.fromMap(Map<String, dynamic> json) => Payment(
    prpType: json["prpType"],
    prpTrnRef: json["prpTrnRef"],
    trnStateText: json["trnStateText"],
    trnEntryDate: json["trnEntryDate"] == null ? null : DateTime.parse(json["trnEntryDate"]),
    trdCcy: json["trdCcy"],
    trdNarration: json["trdNarration"],
    debitAccount: json["debitAccount"],
    debitAccName: json["debitAccountName"],
    creditAccName: json["creditAccountName"],
    creditAccount: json["creditAccount"],
    payments: json["payments"],
    expenses: json["expenses"],
  );

  Map<String, dynamic> toMap() => {
    "prpType": prpType,
    "prpTrnRef": prpTrnRef,
    "trnStateText": trnStateText,
    "trnEntryDate": trnEntryDate?.toIso8601String(),
    "trdCcy": trdCcy,
    "trdNarration": trdNarration,
    "debitAccount": debitAccount,
    "creditAccount": creditAccount,
    "payments": payments,
    "expenses": expenses,
  };
}