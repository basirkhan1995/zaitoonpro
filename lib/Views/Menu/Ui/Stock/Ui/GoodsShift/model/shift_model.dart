// To parse this JSON data, do
//
//     final goodShiftModel = goodShiftModelFromMap(jsonString);

import 'dart:convert';

List<GoodShiftModel> goodShiftModelFromMap(String str) => List<GoodShiftModel>.from(json.decode(str).map((x) => GoodShiftModel.fromMap(x)));

String goodShiftModelToMap(List<GoodShiftModel> data) => json.encode(List<dynamic>.from(data.map((x) => x.toMap())));



class GoodShiftModel {
  final int? ordId;
  final String? ordName;
  final dynamic ordPersonal;
  final dynamic ordPersonalName;
  final dynamic ordxRef;
  final String? ordTrnRef;
  final int? account;
  final String? amount;
  final String? trnStateText;
  final DateTime? ordEntryDate;
  List<ShiftRecord>? records;

  GoodShiftModel({
    this.ordId,
    this.ordName,
    this.ordPersonal,
    this.ordPersonalName,
    this.ordxRef,
    this.ordTrnRef,
    this.account,
    this.amount,
    this.trnStateText,
    this.ordEntryDate,
    this.records,
  });

  GoodShiftModel copyWith({
    int? ordId,
    String? ordName,
    dynamic ordPersonal,
    dynamic ordPersonalName,
    dynamic ordxRef,
    String? ordTrnRef,
    int? account,
    String? amount,
    String? trnStateText,
    DateTime? ordEntryDate,
    List<ShiftRecord>? records,
  }) =>
      GoodShiftModel(
        ordId: ordId ?? this.ordId,
        ordName: ordName ?? this.ordName,
        ordPersonal: ordPersonal ?? this.ordPersonal,
        ordPersonalName: ordPersonalName ?? this.ordPersonalName,
        ordxRef: ordxRef ?? this.ordxRef,
        ordTrnRef: ordTrnRef ?? this.ordTrnRef,
        account: account ?? this.account,
        amount: amount ?? this.amount,
        trnStateText: trnStateText ?? this.trnStateText,
        ordEntryDate: ordEntryDate ?? this.ordEntryDate,
        records: records ?? this.records,
      );

  factory GoodShiftModel.fromMap(Map<String, dynamic> json) => GoodShiftModel(
    ordId: json["ordID"],
    ordName: json["ordName"],
    ordPersonal: json["ordPersonal"],
    ordPersonalName: json["ordPersonalName"],
    ordxRef: json["ordxRef"],
    ordTrnRef: json["ordTrnRef"],
    account: json["account"],
    amount: json["amount"],
    trnStateText: json["trnStateText"],
    ordEntryDate: json["ordEntryDate"] == null ? null : DateTime.parse(json["ordEntryDate"]),
    records: json["records"] != null
        ? (json["records"] as List).map((x) => ShiftRecord.fromMap(x)).toList()
        : null,
  );

  Map<String, dynamic> toMap() => {
    "ordID": ordId,
    "ordName": ordName,
    "ordPersonal": ordPersonal,
    "ordPersonalName": ordPersonalName,
    "ordxRef": ordxRef,
    "ordTrnRef": ordTrnRef,
    "account": account,
    "amount": amount,
    "trnStateText": trnStateText,
    "ordEntryDate": ordEntryDate?.toIso8601String(),
    "records": records?.map((x) => x.toMap()).toList(),
  };

  double get totalAmount => double.tryParse(amount ?? "0") ?? 0;
  bool get hasExpense => account != null && amount != null && totalAmount > 0;
  int get outCount => records?.where((r) => r.stkEntryType == "OUT").length ?? 0;
  int get inCount => records?.where((r) => r.stkEntryType == "IN").length ?? 0;

  double get totalProductValue {
    if (records == null) return 0;
    double total = 0;
    for (final record in records!) {
      total += record.totalValue;
    }
    return total;
  }
}

class ShiftRecord {
  final int? stkID;
  final int? stkOrder;
  final int? stkProduct;
  final String? proName;
  final String? stkEntryType;
  final int? fromStorageId;
  final int? toStorageId;
  final String? fromStorageName;
  final String? toStorageName;
  final String? stkQuantity;
  final String? stkPurPrice;
  final String? stkSalePrice;
  final String? stkLandedPurPrice;
  final String? stkQtyInBatch;

  ShiftRecord({
    this.stkID,
    this.stkOrder,
    this.stkProduct,
    this.stkEntryType,
    this.proName,
    this.fromStorageName,
    this.toStorageName,
    this.fromStorageId,
    this.toStorageId,
    this.stkQuantity,
    this.stkPurPrice,
    this.stkSalePrice,
    this.stkLandedPurPrice,
    this.stkQtyInBatch,
  });

  ShiftRecord copyWith({
    int? stkID,
    int? stkOrder,
    int? stkProduct,
    String? stkEntryType,
    int? fromStorage,
    int? toStorage,
    String? stkQuantity,
    String? stkPurPrice,
    String? stkSalePrice,
    String? stkLandedPurPrice,
    String? stkQtyInBatch,
  }) => ShiftRecord(
    stkID: stkID ?? this.stkID,
    stkOrder: stkOrder ?? this.stkOrder,
    stkProduct: stkProduct ?? this.stkProduct,
    stkEntryType: stkEntryType ?? this.stkEntryType,
    fromStorageId: fromStorage ?? fromStorageId,
    toStorageId: toStorage ?? toStorageId,
    stkQuantity: stkQuantity ?? this.stkQuantity,
    stkPurPrice: stkPurPrice ?? this.stkPurPrice,
    stkSalePrice: stkSalePrice ?? this.stkSalePrice,
    stkLandedPurPrice: stkLandedPurPrice ?? this.stkLandedPurPrice,
    stkQtyInBatch: stkQtyInBatch ?? this.stkQtyInBatch,
  );

  factory ShiftRecord.fromMap(Map<String, dynamic> json) => ShiftRecord(
    stkID: json["stkID"],
    stkOrder: json["stkOrder"],
    stkProduct: json["stkProduct"],
    stkEntryType: json["stkEntryType"],
    fromStorageId: json["fromStorage"] ?? json["stkStorage"],
    toStorageId: json["toStorage"] ?? json["stkStorage"],
    fromStorageName: json["fromStorageName"] ?? json["stgName"],
    toStorageName: json["toStorageName"] ?? json["stgName"],
    proName: json["proName"],
    stkQuantity: json["stkQuantity"],
    stkPurPrice: json["stkPurPrice"],
    stkSalePrice: json["stkSalePrice"],
    stkLandedPurPrice: json["stkLandedPurPrice"],
    stkQtyInBatch: json["stkQtyInBatch"]?.toString(),
  );

  Map<String, dynamic> toMap() => {
    "stkID": stkID,
    "stkOrder": stkOrder,
    "stkProduct": stkProduct,
    "stkEntryType": stkEntryType,
    "fromStorage": fromStorageId,
    "toStorage": toStorageId,
    "stkQuantity": stkQuantity,
    "stkPurPrice": stkPurPrice,
    "stkLandedPurPrice": stkLandedPurPrice,
    "stkQtyInBatch": stkQtyInBatch,
  };

  double get quantity => double.tryParse(stkQuantity ?? "0") ?? 0;
  double get purchasePrice => double.tryParse(stkPurPrice ?? "0") ?? 0;
  double get salePrice => double.tryParse(stkSalePrice ?? "0") ?? 0;
  double get landedPurPrice => double.tryParse(stkLandedPurPrice ?? "0") ?? 0;
  int get qtyInBatch => int.tryParse(stkQtyInBatch ?? "0") ?? 0;
  double get totalValue => quantity * purchasePrice;
  bool get isOutEntry => stkEntryType == "OUT";
  bool get isInEntry => stkEntryType == "IN";
}