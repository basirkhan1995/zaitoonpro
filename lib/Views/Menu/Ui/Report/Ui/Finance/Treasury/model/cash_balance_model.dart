// To parse this JSON data, do
//
//     final cashBalancesModel = cashBalancesModelFromMap(jsonString);

import 'dart:convert';

List<CashBalancesModel> cashBalancesModelFromMap(String str) => List<CashBalancesModel>.from(json.decode(str).map((x) => CashBalancesModel.fromMap(x)));

String cashBalancesModelToMap(List<CashBalancesModel> data) => json.encode(List<dynamic>.from(data.map((x) => x.toMap())));

class CashBalancesModel {
  final int? brcId;
  final int? brcCompany;
  final String? brcName;
  final int? brcAddress;
  final String? brcPhone;
  final int? brcStatus;
  final DateTime? brcEntryDate;
  final String? address;
  final List<Record>? records;
  final List<Transaction>? transactions;

  CashBalancesModel({
    this.brcId,
    this.brcCompany,
    this.brcName,
    this.brcAddress,
    this.brcPhone,
    this.brcStatus,
    this.brcEntryDate,
    this.address,
    this.records,
    this.transactions,
  });

  CashBalancesModel copyWith({
    int? brcId,
    int? brcCompany,
    String? brcName,
    int? brcAddress,
    String? brcPhone,
    int? brcStatus,
    DateTime? brcEntryDate,
    String? address,
    List<Record>? records,
    List<Transaction>? transactions,
  }) =>
      CashBalancesModel(
        brcId: brcId ?? this.brcId,
        brcCompany: brcCompany ?? this.brcCompany,
        brcName: brcName ?? this.brcName,
        brcAddress: brcAddress ?? this.brcAddress,
        brcPhone: brcPhone ?? this.brcPhone,
        brcStatus: brcStatus ?? this.brcStatus,
        brcEntryDate: brcEntryDate ?? this.brcEntryDate,
        address: address ?? this.address,
        records: records ?? this.records,
        transactions: transactions ?? this.transactions,
      );

  factory CashBalancesModel.fromMap(Map<String, dynamic> json) => CashBalancesModel(
    brcId: json["brcID"],
    brcCompany: json["brcCompany"],
    brcName: json["brcName"],
    brcAddress: json["brcAddress"],
    brcPhone: json["brcPhone"],
    brcStatus: json["brcStatus"],
    brcEntryDate: json["brcEntryDate"] == null ? null : DateTime.parse(json["brcEntryDate"]),
    address: json["address"],
    records: json["records"] == null ? [] : List<Record>.from(json["records"]!.map((x) => Record.fromMap(x))),
    transactions: json["transactions"] == null ? [] : List<Transaction>.from(json["transactions"]!.map((x) => Transaction.fromMap(x))),
  );

  Map<String, dynamic> toMap() => {
    "brcID": brcId,
    "brcCompany": brcCompany,
    "brcName": brcName,
    "brcAddress": brcAddress,
    "brcPhone": brcPhone,
    "brcStatus": brcStatus,
    "brcEntryDate": brcEntryDate?.toIso8601String(),
    "address": address,
    "records": records == null ? [] : List<dynamic>.from(records!.map((x) => x.toMap())),
    "transactions": transactions == null ? [] : List<dynamic>.from(transactions!.map((x) => x.toMap())),
  };
}

class Record {
  final String? accName;
  final int? trdAccount;
  final String? ccyName;
  final String? trdCcy;
  final String? ccySymbol;
  final String? openingBalance;
  final String? openingSysEquivalent;
  final String? closingBalance;
  final String? closingSysEquivalent;

  Record({
    this.accName,
    this.trdAccount,
    this.ccyName,
    this.trdCcy,
    this.ccySymbol,
    this.openingBalance,
    this.openingSysEquivalent,
    this.closingBalance,
    this.closingSysEquivalent,
  });

  Record copyWith({
    String? accName,
    int? trdAccount,
    String? ccyName,
    String? trdCcy,
    String? ccySymbol,
    String? openingBalance,
    String? openingSysEquivalent,
    String? closingBalance,
    String? closingSysEquivalent,
  }) =>
      Record(
        accName: accName ?? this.accName,
        trdAccount: trdAccount ?? this.trdAccount,
        ccyName: ccyName ?? this.ccyName,
        trdCcy: trdCcy ?? this.trdCcy,
        ccySymbol: ccySymbol ?? this.ccySymbol,
        openingBalance: openingBalance ?? this.openingBalance,
        openingSysEquivalent: openingSysEquivalent ?? this.openingSysEquivalent,
        closingBalance: closingBalance ?? this.closingBalance,
        closingSysEquivalent: closingSysEquivalent ?? this.closingSysEquivalent,
      );

  factory Record.fromMap(Map<String, dynamic> json) => Record(
    accName: json["accName"],
    trdAccount: json["trdAccount"],
    ccyName: json["ccyName"],
    trdCcy: json["trdCcy"],
    ccySymbol: json["ccySymbol"],
    openingBalance: json["opening_balance"],
    openingSysEquivalent: json["opening_sys_equivalent"],
    closingBalance: json["closing_balance"],
    closingSysEquivalent: json["closing_sys_equivalent"],
  );

  Map<String, dynamic> toMap() => {
    "accName": accName,
    "trdAccount": trdAccount,
    "ccyName": ccyName,
    "trdCcy": trdCcy,
    "ccySymbol": ccySymbol,
    "opening_balance": openingBalance,
    "opening_sys_equivalent": openingSysEquivalent,
    "closing_balance": closingBalance,
    "closing_sys_equivalent": closingSysEquivalent,
  };
}

class Transaction {
  final DateTime? date;
  final String? narration;
  final String? debit;
  final String? credit;
  final String? currency;
  final String? reference;
  final String? creditAccountName;
  final int? creditAccountNumber;
  final String? transactionType;
  final String? status;
  final String? runningBalance;

  Transaction({
    this.date,
    this.narration,
    this.debit,
    this.credit,
    this.currency,
    this.reference,
    this.creditAccountName,
    this.creditAccountNumber,
    this.transactionType,
    this.status,
    this.runningBalance,
  });

  Transaction copyWith({
    DateTime? date,
    String? narration,
    String? debit,
    String? credit,
    String? currency,
    String? reference,
    String? creditAccountName,
    int? creditAccountNumber,
    String? transactionType,
    String? status,
    String? runningBalance,
  }) =>
      Transaction(
        date: date ?? this.date,
        narration: narration ?? this.narration,
        debit: debit ?? this.debit,
        credit: credit ?? this.credit,
        currency: currency ?? this.currency,
        reference: reference ?? this.reference,
        creditAccountName: creditAccountName ?? this.creditAccountName,
        creditAccountNumber: creditAccountNumber ?? this.creditAccountNumber,
        transactionType: transactionType ?? this.transactionType,
        status: status ?? this.status,
        runningBalance: runningBalance ?? this.runningBalance,
      );

  factory Transaction.fromMap(Map<String, dynamic> json) => Transaction(
    date: json["date"] == null ? null : DateTime.parse(json["date"]),
    narration: json["narration"],
    debit: json["debit"],
    credit: json["credit"],
    currency: json["currency"],
    reference: json["reference"],
    creditAccountName: json["credit_account_name"],
    creditAccountNumber: json["credit_account_number"],
    transactionType: json["transaction_type"],
    status: json["status"],
    runningBalance: json["running_balance"],
  );

  Map<String, dynamic> toMap() => {
    "date": date == null ? null : "${date!.year.toString().padLeft(4, '0')}-${date!.month.toString().padLeft(2, '0')}-${date!.day.toString().padLeft(2, '0')}",
    "narration": narration,
    "debit": debit,
    "credit": credit,
    "currency": currency,
    "reference": reference,
    "credit_account_name": creditAccountName,
    "credit_account_number": creditAccountNumber,
    "transaction_type": transactionType,
    "status": status,
    "running_balance": runningBalance,
  };
}
