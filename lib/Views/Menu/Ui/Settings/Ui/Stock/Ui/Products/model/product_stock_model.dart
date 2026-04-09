// To parse this JSON data, do
//
//     final productsStockModel = productsStockModelFromMap(jsonString);

import 'dart:convert';

List<ProductsStockModel> productsStockModelFromMap(String str) => List<ProductsStockModel>.from(json.decode(str).map((x) => ProductsStockModel.fromMap(x)));

String productsStockModelToMap(List<ProductsStockModel> data) => json.encode(List<dynamic>.from(data.map((x) => x.toMap())));

class ProductsStockModel {
  final int? proId;
  final String? proName;
  final String? proCode;
  final String? proGrade;
  final String? proUnit;
  final String? proBrand;
  final int? proCategory;
  final String? proModel;
  final String? proMadeIn;
  final String? proColor;
  final String? proDetails;
  final int? stkStorage;
  final String? stgName;
  final int? stkQtyInBatch;
  final String? available;
  final String? recentPurPrice;
  final String? recentLandedPurPrice;
  final String? averagePrice;
  final String? sellPrice;

  ProductsStockModel({
    this.proId,
    this.proName,
    this.proCode,
    this.proGrade,
    this.proUnit,
    this.proBrand,
    this.proCategory,
    this.proModel,
    this.proMadeIn,
    this.proColor,
    this.proDetails,
    this.stkStorage,
    this.stgName,
    this.stkQtyInBatch,
    this.available,
    this.recentPurPrice,
    this.recentLandedPurPrice,
    this.averagePrice,
    this.sellPrice,
  });

  ProductsStockModel copyWith({
    int? proId,
    String? proName,
    String? proCode,
    String? proGrade,
    String? proUnit,
    String? proBrand,
    int? proCategory,
    String? proModel,
    String? proMadeIn,
    String? proColor,
    String? proDetails,
    int? stkStorage,
    String? stgName,
    int? stkQtyInBatch,
    String? available,
    String? recentPurPrice,
    String? recentLandedPurPrice,
    String? averagePrice,
    String? sellPrice,
  }) =>
      ProductsStockModel(
        proId: proId ?? this.proId,
        proName: proName ?? this.proName,
        proCode: proCode ?? this.proCode,
        proGrade: proGrade ?? this.proGrade,
        proUnit: proUnit ?? this.proUnit,
        proBrand: proBrand ?? this.proBrand,
        proCategory: proCategory ?? this.proCategory,
        proModel: proModel ?? this.proModel,
        proMadeIn: proMadeIn ?? this.proMadeIn,
        proColor: proColor ?? this.proColor,
        proDetails: proDetails ?? this.proDetails,
        stkStorage: stkStorage ?? this.stkStorage,
        stgName: stgName ?? this.stgName,
        stkQtyInBatch: stkQtyInBatch ?? this.stkQtyInBatch,
        available: available ?? this.available,
        recentPurPrice: recentPurPrice ?? this.recentPurPrice,
        recentLandedPurPrice: recentLandedPurPrice ?? this.recentLandedPurPrice,
        averagePrice: averagePrice ?? this.averagePrice,
        sellPrice: sellPrice ?? this.sellPrice,
      );

  factory ProductsStockModel.fromMap(Map<String, dynamic> json) => ProductsStockModel(
    proId: json["proID"],
    proName: json["proName"],
    proCode: json["proCode"],
    proGrade: json["proGrade"],
    proUnit: json["proUnit"],
    proBrand: json["proBrand"],
    proCategory: json["proCategory"],
    proModel: json["proModel"],
    proMadeIn: json["proMadeIn"],
    proColor: json["proColor"],
    proDetails: json["proDetails"],
    stkStorage: json["stkStorage"],
    stgName: json["stgName"],
    stkQtyInBatch: json["stkQtyInBatch"],
    available: json["available"],
    recentPurPrice: json["recent_PurPrice"],
    recentLandedPurPrice: json["recent_landedPurPrice"],
    averagePrice: json["average_price"],
    sellPrice: json["sell_price"],
  );

  Map<String, dynamic> toMap() => {
    "proID": proId,
    "proName": proName,
    "proCode": proCode,
    "proGrade": proGrade,
    "proUnit": proUnit,
    "proBrand": proBrand,
    "proCategory": proCategory,
    "proModel": proModel,
    "proMadeIn": proMadeIn,
    "proColor": proColor,
    "proDetails": proDetails,
    "stkStorage": stkStorage,
    "stgName": stgName,
    "stkQtyInBatch": stkQtyInBatch,
    "available": available,
    "recent_PurPrice": recentPurPrice,
    "recent_landedPurPrice": recentLandedPurPrice,
    "average_price": averagePrice,
    "sell_price": sellPrice,
  };
}
