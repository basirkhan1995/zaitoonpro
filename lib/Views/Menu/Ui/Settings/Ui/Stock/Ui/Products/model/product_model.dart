// To parse this JSON data, do
//
//     final productsModel = productsModelFromMap(jsonString);

import 'dart:convert';

ProductsModel productsModelFromMap(String str) => ProductsModel.fromMap(json.decode(str));

String productsModelToMap(ProductsModel data) => json.encode(data.toMap());

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
  final int? pcId;
  final String? pcName;
  final String? pcDescription;
  final int? pcStatus;
  final List<Batch>? batches;

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
    this.pcId,
    this.pcName,
    this.pcDescription,
    this.pcStatus,
    this.batches,
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
    int? pcId,
    String? pcName,
    String? pcDescription,
    int? pcStatus,
    List<Batch>? batches,
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
        pcId: pcId ?? this.pcId,
        pcName: pcName ?? this.pcName,
        pcDescription: pcDescription ?? this.pcDescription,
        pcStatus: pcStatus ?? this.pcStatus,
        batches: batches ?? this.batches,
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
    proLsNqty: json["proLSNQty"],
    proColor: json["proColor"],
    proStatus: json["proStatus"],
    proWidth: json["proWidth"],
    proWeight: json["proWeight"],
    proBreadth: json["proBreadth"],
    proSpp: json["proSPP"],
    proLength: json["proLength"],
    pcId: json["pcID"],
    pcName: json["pcName"],
    pcDescription: json["pcDescription"],
    pcStatus: json["pcStatus"],
    batches: json["batches"] == null ? [] : List<Batch>.from(json["batches"]!.map((x) => Batch.fromMap(x))),
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
    "proWidth": proWidth,
    "proWeight": proWeight,
    "proBreadth": proBreadth,
    "proSPP": proSpp,
    "proLength": proLength,
    "pcID": pcId,
    "pcName": pcName,
    "pcDescription": pcDescription,
    "pcStatus": pcStatus,
    "batches": batches == null ? [] : List<dynamic>.from(batches!.map((x) => x.toMap())),
  };
}

class Batch {
  final int? storage;
  final int? batch;
  final String? availableQuantity;

  Batch({
    this.storage,
    this.batch,
    this.availableQuantity,
  });

  Batch copyWith({
    int? storage,
    int? batch,
    String? availableQuantity,
  }) =>
      Batch(
        storage: storage ?? this.storage,
        batch: batch ?? this.batch,
        availableQuantity: availableQuantity ?? this.availableQuantity,
      );

  factory Batch.fromMap(Map<String, dynamic> json) => Batch(
    storage: json["storage"],
    batch: json["batch"],
    availableQuantity: json["available_Quantity"],
  );

  Map<String, dynamic> toMap() => {
    "storage": storage,
    "batch": batch,
    "available_Quantity": availableQuantity,
  };
}
