// exp_report_model.dart
import 'dart:convert';

ExpenseReportModel expenseReportModelFromMap(String str) =>
    ExpenseReportModel.fromMap(json.decode(str));

String expenseReportModelToMap(ExpenseReportModel data) =>
    json.encode(data.toMap());

class ExpenseReportModel {
  final List<ExpenseRecord> data;
  final List<Summary> summary;

  const ExpenseReportModel({
    this.data = const [],
    this.summary = const [],
  });

  factory ExpenseReportModel.fromMap(Map<String, dynamic> json) {
    return ExpenseReportModel(
      data: json["data"] != null
          ? List<ExpenseRecord>.from(json["data"].map((x) => ExpenseRecord.fromMap(x)))
          : [],
      summary: json["summary"] != null
          ? List<Summary>.from(json["summary"].map((x) => Summary.fromMap(x)))
          : [],
    );
  }

  Map<String, dynamic> toMap() => {
    "data": data.map((x) => x.toMap()).toList(),
    "summary": summary.map((x) => x.toMap()).toList(),
  };
}

class ExpenseRecord {
  final DateTime? transactionDate;
  final String reference;
  final int accountNumber;
  final String accountName;
  final String expenseCategory;
  final String currency;
  final String expenseAmount;
  final String usdEquivalent;
  final String narration;
  final String branch;
  final String maker;
  final String status;

  const ExpenseRecord({
    this.transactionDate,
    this.reference = '',
    this.accountNumber = 0,
    this.accountName = '',
    this.expenseCategory = '',
    this.currency = '',
    this.expenseAmount = '0',
    this.usdEquivalent = '0',
    this.narration = '',
    this.branch = '',
    this.maker = '',
    this.status = '',
  });

  factory ExpenseRecord.fromMap(Map<String, dynamic> json) {
    return ExpenseRecord(
      transactionDate: json["transaction_date"] != null
          ? DateTime.tryParse(json["transaction_date"])
          : null,
      reference: json["reference"] ?? '',
      accountNumber: json["account_number"] ?? 0,
      accountName: json["account_name"] ?? '',
      expenseCategory: json["expense_category"] ?? '',
      currency: json["currency"] ?? '',
      expenseAmount: json["expense_amount"]?.toString() ?? '0',
      usdEquivalent: json["usd_equivalent"]?.toString() ?? '0',
      narration: json["narration"] ?? '',
      branch: json["branch"] ?? '',
      maker: json["maker"] ?? '',
      status: json["status"] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    "transaction_date": transactionDate?.toIso8601String(),
    "reference": reference,
    "account_number": accountNumber,
    "account_name": accountName,
    "expense_category": expenseCategory,
    "currency": currency,
    "expense_amount": expenseAmount,
    "usd_equivalent": usdEquivalent,
    "narration": narration,
    "branch": branch,
    "maker": maker,
    "status": status,
  };
}

class Summary {
  final String currency;
  final int transactionCount;
  final String totalAmount;
  final String totalUsd;
  final String minAmount;
  final String maxAmount;
  final String avgAmount;

  const Summary({
    this.currency = '',
    this.transactionCount = 0,
    this.totalAmount = '0',
    this.totalUsd = '0',
    this.minAmount = '0',
    this.maxAmount = '0',
    this.avgAmount = '0',
  });

  factory Summary.fromMap(Map<String, dynamic> json) {
    return Summary(
      currency: json["currency"] ?? '',
      transactionCount: json["transaction_count"] ?? 0,
      totalAmount: json["total_amount"]?.toString() ?? '0',
      totalUsd: json["total_usd"]?.toString() ?? '0',
      minAmount: json["min_amount"]?.toString() ?? '0',
      maxAmount: json["max_amount"]?.toString() ?? '0',
      avgAmount: json["avg_amount"]?.toString() ?? '0',
    );
  }

  Map<String, dynamic> toMap() => {
    "currency": currency,
    "transaction_count": transactionCount,
    "total_amount": totalAmount,
    "total_usd": totalUsd,
    "min_amount": minAmount,
    "max_amount": maxAmount,
    "avg_amount": avgAmount,
  };
}