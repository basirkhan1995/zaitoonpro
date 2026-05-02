// To parse this JSON data, do
//
//     final stockRecordModel = stockRecordModelFromMap(jsonString);

import 'dart:convert';

List<StockRecordModel> stockRecordModelFromMap(String str) => List<StockRecordModel>.from(json.decode(str).map((x) => StockRecordModel.fromMap(x)));

String stockRecordModelToMap(List<StockRecordModel> data) => json.encode(List<dynamic>.from(data.map((x) => x.toMap())));

class StockRecordModel {
  final int? no;
  final int? orderId;
  final int? perId;
  final String? fullname;
  final int? productId;
  final String? productName;
  final int? storageId;
  final String? storageName;
  final String? entryType;
  final DateTime? entryDate;
  final String? quantity;
  final int? batch;
  final String? price;
  final String? runningQuantity;

  StockRecordModel({
    this.no,
    this.orderId,
    this.perId,
    this.fullname,
    this.productId,
    this.productName,
    this.storageId,
    this.storageName,
    this.entryType,
    this.entryDate,
    this.quantity,
    this.batch,
    this.price,
    this.runningQuantity,
  });

  StockRecordModel copyWith({
    int? no,
    int? orderId,
    int? perId,
    String? fullname,
    int? productId,
    String? productName,
    int? storageId,
    String? storageName,
    String? entryType,
    DateTime? entryDate,
    String? quantity,
    String? price,
    String? runningQuantity,
    int? batch,
  }) =>
      StockRecordModel(
        no: no ?? this.no,
        orderId: orderId ?? this.orderId,
        perId: perId ?? this.perId,
        fullname: fullname ?? this.fullname,
        productId: productId ?? this.productId,
        productName: productName ?? this.productName,
        storageId: storageId ?? this.storageId,
        storageName: storageName ?? this.storageName,
        entryType: entryType ?? this.entryType,
        entryDate: entryDate ?? this.entryDate,
        quantity: quantity ?? this.quantity,
        price: price ?? this.price,
        runningQuantity: runningQuantity ?? this.runningQuantity,
        batch: batch ?? this.batch,
      );

  factory StockRecordModel.fromMap(Map<String, dynamic> json) => StockRecordModel(
    no: json["No"],
    orderId: json["orderID"],
    perId: json["perID"],
    fullname: json["fullname"],
    productId: json["productID"],
    productName: json["productName"],
    storageId: json["storageID"],
    storageName: json["storageName"],
    entryType: json["entryType"],
    entryDate: json["entryDate"] == null ? null : DateTime.parse(json["entryDate"]),
    quantity: json["quantity"]?.toString(),
    price: json["price"],
    runningQuantity: json["runningQuantity"],
    batch: json["batch"]
  );

  Map<String, dynamic> toMap() => {
    "No": no,
    "orderID": orderId,
    "perID": perId,
    "fullname": fullname,
    "productID": productId,
    "productName": productName,
    "storageID": storageId,
    "storageName": storageName,
    "entryType": entryType,
    "entryDate": "${entryDate!.year.toString().padLeft(4, '0')}-${entryDate!.month.toString().padLeft(2, '0')}-${entryDate!.day.toString().padLeft(2, '0')}",
    "quantity": quantity,
    "price": price,
    "runningQuantity": runningQuantity,
  };
}
