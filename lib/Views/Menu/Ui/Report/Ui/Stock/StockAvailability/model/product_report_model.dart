// To parse this JSON data, do
//
//     final productReportModel = productReportModelFromMap(jsonString);

import 'dart:convert';

List<ProductReportModel> productReportModelFromMap(String str) => List<ProductReportModel>.from(json.decode(str).map((x) => ProductReportModel.fromMap(x)));

String productReportModelToMap(List<ProductReportModel> data) => json.encode(List<dynamic>.from(data.map((x) => x.toMap())));

class ProductReportModel {
  final int? no;
  final int? proId;
  final String? proName;
  final String? proCode;
  final String? stgName;
  final String? proUnit;
  final int? proLsNqty;
  final String? recentPurPrice;
  final String? available;
  final int? batch;
  final String? availableItem;
  final String? averagePrice;
  final String? sellPrice;
  final String? totalValue;

  ProductReportModel({
    this.no,
    this.proId,
    this.proName,
    this.proCode,
    this.stgName,
    this.proUnit,
    this.proLsNqty,
    this.recentPurPrice,
    this.available,
    this.batch,
    this.availableItem,
    this.averagePrice,
    this.sellPrice,
    this.totalValue,
  });

  ProductReportModel copyWith({
    int? no,
    int? proId,
    String? proName,
    String? proCode,
    String? stgName,
    String? proUnit,
    int? proLsNqty,
    String? recentPurPrice,
    String? available,
    int? batch,
    String? availableItem,
    String? averagePrice,
    String? sellPrice,
    String? totalValue,
  }) =>
      ProductReportModel(
        no: no ?? this.no,
        proId: proId ?? this.proId,
        proName: proName ?? this.proName,
        proCode: proCode ?? this.proCode,
        stgName: stgName ?? this.stgName,
        proUnit: proUnit ?? this.proUnit,
        proLsNqty: proLsNqty ?? this.proLsNqty,
        recentPurPrice: recentPurPrice ?? this.recentPurPrice,
        available: available ?? this.available,
        batch: batch ?? this.batch,
        availableItem: availableItem ?? this.availableItem,
        averagePrice: averagePrice ?? this.averagePrice,
        sellPrice: sellPrice ?? this.sellPrice,
        totalValue: totalValue ?? this.totalValue,
      );

  factory ProductReportModel.fromMap(Map<String, dynamic> json) => ProductReportModel(
    no: json["No"],
    proId: json["proID"],
    proName: json["proName"],
    proCode: json["proCode"],
    stgName: json["stgName"],
    proUnit: json["proUnit"],
    proLsNqty: json["proLSNqty"],
    recentPurPrice: json["recent_PurPrice"],
    available: json["available"],
    batch: json["batch"],
    availableItem: json["available_Item"],
    averagePrice: json["average_price"],
    sellPrice: json["sell_price"],
    totalValue: json["total_value"],
  );

  Map<String, dynamic> toMap() => {
    "No": no,
    "proID": proId,
    "proName": proName,
    "proCode": proCode,
    "stgName": stgName,
    "proUnit": proUnit,
    "proLSNqty": proLsNqty,
    "recent_PurPrice": recentPurPrice,
    "available": available,
    "batch": batch,
    "available_Item": availableItem,
    "average_price": averagePrice,
    "sell_price": sellPrice,
    "total_value": totalValue,
  };
}
