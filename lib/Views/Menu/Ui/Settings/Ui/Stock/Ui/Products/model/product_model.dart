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
  final String? proWidth;
  final String? proWeight;
  final String? proBreadth;
  final String? proSpp;
  final String? proLength;

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
    this.proWidth,
    this.proWeight,
    this.proBreadth,
    this.proSpp,
    this.proLength,
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
    String? proWidth,
    String? proWeight,
    String? proBreadth,
    String? proSpp,
    String? proLength,
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
        proWidth: proWidth ?? this.proWidth,
        proWeight: proWeight ?? this.proWeight,
        proBreadth: proBreadth ?? this.proBreadth,
        proSpp: proSpp ?? this.proSpp,
        proLength: proLength ?? this.proLength,
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
    proWidth: json["proWidth"],
    proWeight: json["proWeight"],
    proBreadth: json["proBreadth"],
    proSpp: json["proSPP"],
    proLength: json["proLength"],
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
    "proLSNqty": proLsNqty,
    "proColor": proColor,
    "proStatus": proStatus,
    "proWidth": proWidth,
    "proWeight": proWeight,
    "proBreadth": proBreadth,
    "proSPP": proSpp,
    "proLength": proLength,
  };
}
