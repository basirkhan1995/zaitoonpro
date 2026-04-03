// To parse this JSON data, do
//
//     final productsModel = productsModelFromMap(jsonString);

import 'dart:convert';

List<ProductsModel> productsModelFromMap(String str) => List<ProductsModel>.from(json.decode(str).map((x) => ProductsModel.fromMap(x)));

String productsModelToMap(List<ProductsModel> data) => json.encode(List<dynamic>.from(data.map((x) => x.toMap())));

class ProductsModel {
  final int? proId;
  final String? proName;
  final String? proCode;
  final String? proUnit;
  final String? proBrand;
  final String? proMadeIn;
  final String? proModel;
  final String? proGrade;
  final int? proCategory;
  final String? proDetails;
  final int? proLsNqty;
  final String? proColor;
  final int? proStatus;
  final double? width;
  final double? length;
  final double? breadth;
  final double? weight;
  final double? salePricePercentage;

  ProductsModel({
    this.proId,
    this.proName,
    this.proCode,
    this.proUnit,
    this.proBrand,
    this.proMadeIn,
    this.proModel,
    this.proGrade,
    this.proCategory,
    this.proDetails,
    this.proLsNqty,
    this.proColor,
    this.proStatus,
    this.width,
    this.length,
    this.breadth,
    this.weight,
    this.salePricePercentage,
  });

  ProductsModel copyWith({
    int? proId,
    String? proName,
    String? proCode,
    String? proUnit,
    String? proBrand,
    String? proMadeIn,
    String? proModel,
    String? proGrade,
    int? proCategory,
    String? proDetails,
    int? proLsNqty,
    String? proColor,
    int? proStatus,
    double? width,
    double? length,
    double? breadth,
    double? weight,
    double? salePricePercentage,
  }) =>
      ProductsModel(
        proId: proId ?? this.proId,
        proName: proName ?? this.proName,
        proCode: proCode ?? this.proCode,
        proUnit: proUnit ?? this.proUnit,
        proBrand: proBrand ?? this.proBrand,
        proMadeIn: proMadeIn ?? this.proMadeIn,
        proModel: proModel ?? this.proModel,
        proGrade: proGrade ?? this.proGrade,
        proCategory: proCategory ?? this.proCategory,
        proDetails: proDetails ?? this.proDetails,
        proLsNqty: proLsNqty ?? this.proLsNqty,
        proColor: proColor ?? this.proColor,
        proStatus: proStatus ?? this.proStatus,
        width: width ?? this.width,
        length: length ?? this.length,
        breadth: breadth ?? this.breadth,
        weight: weight ?? this.weight,
        salePricePercentage: salePricePercentage ?? this.salePricePercentage,
      );

  factory ProductsModel.fromMap(Map<String, dynamic> json) => ProductsModel(
    proId: json["proID"],
    proName: json["proName"],
    proCode: json["proCode"],
    proUnit: json["proUnit"],
    proBrand: json["proBrand"],
    proMadeIn: json["proMadeIn"],
    proModel: json["proModel"],
    proGrade: json["proGrade"],
    proCategory: json["proCategory"],
    proDetails: json["proDetails"],
    proLsNqty: json["proLSNqty"],
    proColor: json["proColor"],
    proStatus: json["proStatus"],
    width: json["width"]?.toDouble(),
    length: json["length"]?.toDouble(),
    breadth: json["breadth"]?.toDouble(),
    weight: json["weight"]?.toDouble(),
    salePricePercentage: json["salePricePercentage"]?.toDouble(),
  );

  Map<String, dynamic> toMap() => {
    "proID": proId,
    "proName": proName,
    "proCode": proCode,
    "proUnit": proUnit,
    "proBrand": proBrand,
    "proMadeIn": proMadeIn,
    "proModel": proModel,
    "proGrade": proGrade,
    "proCategory": proCategory,
    "proDetails": proDetails,
    "proLSNQty": proLsNqty,
    "proColor": proColor,
    "proStatus": proStatus,
    "width": width,
    "length": length,
    "breadth": breadth,
    "weight": weight,
    "salePricePercentage": salePricePercentage,
  };
}
