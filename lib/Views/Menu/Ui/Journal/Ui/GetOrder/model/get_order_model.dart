import 'dart:convert';

OrderTxnModel orderTxnModelFromMap(String str) => OrderTxnModel.fromMap(json.decode(str));

String orderTxnModelToMap(OrderTxnModel data) => json.encode(data.toMap());

class OrderTxnModel {
  final String? trnReference;
  final String? trnType;
  final String? trntName;
  final int? trnStatus;
  final String? trnStateText;
  final String? maker;
  final DateTime? trnEntryDate;
  final String? totalBill;
  final String? ccySymbol;
  final String? ccy;
  final String? ccyName;
  final String? branch;
  final String? remark;
  final String? checker;
  final List<Record>? records;
  final List<Bill>? bill;

  OrderTxnModel({
    this.trnReference,
    this.trnType,
    this.trntName,
    this.trnStatus,
    this.trnStateText,
    this.maker,
    this.trnEntryDate,
    this.totalBill,
    this.ccySymbol,
    this.ccy,
    this.ccyName,
    this.branch,
    this.remark,
    this.checker,
    this.records,
    this.bill,
  });

  OrderTxnModel copyWith({
    String? trnReference,
    String? trnType,
    String? trntName,
    int? trnStatus,
    String? trnStateText,
    String? usrName,
    DateTime? trnEntryDate,
    String? totalBill,
    String? ccySymbol,
    String? ccy,
    String? ccyName,
    String? branch,
    String? remark,
    String? checker,
    List<Record>? records,
    List<Bill>? bill,
  }) =>
      OrderTxnModel(
        trnReference: trnReference ?? this.trnReference,
        trnType: trnType ?? this.trnType,
        trntName: trntName ?? this.trntName,
        trnStatus: trnStatus ?? this.trnStatus,
        trnStateText: trnStateText ?? this.trnStateText,
        maker: usrName ?? maker,
        trnEntryDate: trnEntryDate ?? this.trnEntryDate,
        totalBill: totalBill ?? this.totalBill,
        ccySymbol: ccySymbol ?? this.ccySymbol,
        ccy: ccy ?? this.ccy,
        ccyName: ccyName ?? this.ccyName,
        branch: branch ?? this.branch,
        remark: remark ?? this.remark,
        records: records ?? this.records,
        bill: bill ?? this.bill,
      );

  factory OrderTxnModel.fromMap(Map<String, dynamic> json) => OrderTxnModel(
    trnReference: json["trnReference"],
    trnType: json["trnType"],
    trntName: json["trntName"],
    trnStatus: json["trnStatus"],
    trnStateText: json["trnStateText"],
    maker: json["maker"],
    trnEntryDate: json["trnEntryDate"] == null ? null : DateTime.parse(json["trnEntryDate"]),
    totalBill: json["total_bill"],
    ccySymbol: json["ccy_symbol"],
    ccy: json["ccy"],
    checker: json["checker"],
    ccyName: json["ccy_name"],
    branch: json["branch"],
    remark: json["remark"],
    records: json["records"] == null ? [] : List<Record>.from(json["records"]!.map((x) => Record.fromMap(x))),
    bill: json["bill"] == null ? [] : List<Bill>.from(json["bill"]!.map((x) => Bill.fromMap(x))),
  );

  Map<String, dynamic> toMap() => {
    "trnReference": trnReference,
    "trnType": trnType,
    "trntName": trntName,
    "trnStatus": trnStatus,
    "trnStateText": trnStateText,
    "usrName": maker,
    "trnEntryDate": trnEntryDate?.toIso8601String(),
    "total_bill": totalBill,
    "ccy_symbol": ccySymbol,
    "ccy": ccy,
    "ccy_name": ccyName,
    "branch": branch,
    "remark": remark,
    "records": records == null ? [] : List<dynamic>.from(records!.map((x) => x.toMap())),
    "bill": bill == null ? [] : List<dynamic>.from(bill!.map((x) => x.toMap())),
  };
}

class Bill {
  final String? storageName;
  final String? productName;
  final String? quantity;
  final String? unitPrice;
  final String? totalPrice;

  Bill({
    this.storageName,
    this.productName,
    this.quantity,
    this.unitPrice,
    this.totalPrice,
  });

  Bill copyWith({
    String? storageName,
    String? productName,
    String? quantity,
    String? unitPrice,
    String? totalPrice,
  }) =>
      Bill(
        storageName: storageName ?? this.storageName,
        productName: productName ?? this.productName,
        quantity: quantity ?? this.quantity,
        unitPrice: unitPrice ?? this.unitPrice,
        totalPrice: totalPrice ?? this.totalPrice,
      );

  factory Bill.fromMap(Map<String, dynamic> json) => Bill(
    storageName: json["storage_name"],
    productName: json["product_name"],
    quantity: json["quantity"]?.toString(),
    unitPrice: json["unit_price"],
    totalPrice: json["total_price"],
  );

  Map<String, dynamic> toMap() => {
    "storage_name": storageName,
    "product_name": productName,
    "quantity": quantity,
    "unit_price": unitPrice,
    "total_price": totalPrice,
  };
}

class Record {
  final String? accountName;
  final int? accountNumber;
  final String? amount;
  final String? debitCredit;

  Record({
    this.accountName,
    this.accountNumber,
    this.amount,
    this.debitCredit,
  });

  Record copyWith({
    String? accountName,
    int? accountNumber,
    String? amount,
    String? debitCredit,
  }) =>
      Record(
        accountName: accountName ?? this.accountName,
        accountNumber: accountNumber ?? this.accountNumber,
        amount: amount ?? this.amount,
        debitCredit: debitCredit ?? this.debitCredit,
      );

  factory Record.fromMap(Map<String, dynamic> json) => Record(
    accountName: json["account_name"],
    accountNumber: json["account_number"],
    amount: json["amount"],
    debitCredit: json["debit_credit"],
  );

  Map<String, dynamic> toMap() => {
    "account_name": accountName,
    "account_number": accountNumber,
    "amount": amount,
    "debit_credit": debitCredit,
  };
}
