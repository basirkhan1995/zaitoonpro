// To parse this JSON data, do
//
//     final productReportModel = productReportModelFromMap(jsonString);

import 'dart:convert';

ProductReportModel productReportModelFromMap(String str) => ProductReportModel.fromMap(json.decode(str));

String productReportModelToMap(ProductReportModel data) => json.encode(data.toMap());

class ProductReportModel {
  final int? no;
  final String? proName;
  final int? proId;
  final String? proCode;
  final String? stgName;
  final int? stkStorage;
  final String? availableQuantity;
  final String? totalItem;
  final String? pricePerUnit;
  final String? total;

  ProductReportModel({
    this.no,
    this.proName,
    this.proId,
    this.proCode,
    this.stgName,
    this.stkStorage,
    this.availableQuantity,
    this.totalItem,
    this.pricePerUnit,
    this.total,
  });

  ProductReportModel copyWith({
    int? no,
    String? proName,
    int? proId,
    String? proCode,
    String? stgName,
    int? stkStorage,
    String? availableQuantity,
    String? totalItem,
    String? pricePerUnit,
    String? total,
  }) =>
      ProductReportModel(
        no: no ?? this.no,
        proName: proName ?? this.proName,
        proId: proId ?? this.proId,
        proCode: proCode ?? this.proCode,
        stgName: stgName ?? this.stgName,
        stkStorage: stkStorage ?? this.stkStorage,
        availableQuantity: availableQuantity ?? this.availableQuantity,
        totalItem: totalItem ?? this.totalItem,
        pricePerUnit: pricePerUnit ?? this.pricePerUnit,
        total: total ?? this.total,
      );

  factory ProductReportModel.fromMap(Map<String, dynamic> json) => ProductReportModel(
    no: json["No"],
    proName: json["proName"],
    proId: json["proID"],
    proCode: json["proCode"],
    stgName: json["stgName"],
    stkStorage: json["stkStorage"],
    availableQuantity: json["available_quantity"],
    totalItem: json["total_item"],
    pricePerUnit: json["pricePerUnit"],
    total: json["total"],
  );

  Map<String, dynamic> toMap() => {
    "No": no,
    "proName": proName,
    "proID": proId,
    "proCode": proCode,
    "stgName": stgName,
    "stkStorage": stkStorage,
    "available_quantity": availableQuantity,
    "total_item": totalItem,
    "pricePerUnit": pricePerUnit,
    "total": total,
  };
}
