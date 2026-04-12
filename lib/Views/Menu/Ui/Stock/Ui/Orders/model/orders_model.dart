// To parse this JSON data, do
//
//     final ordersModel = ordersModelFromMap(jsonString);

import 'dart:convert';

List<OrdersModel> ordersModelFromMap(String str) => List<OrdersModel>.from(json.decode(str).map((x) => OrdersModel.fromMap(x)));

String ordersModelToMap(List<OrdersModel> data) => json.encode(List<dynamic>.from(data.map((x) => x.toMap())));

class OrdersModel {
  final int? ordId;
  final String? ordName;
  final int? perId;
  final String? personal;
  final String? ordxRef;
  final String? ordTrnRef;
  final int? ordBranch;
  final String? brcName;
  final String? totalBill;
  final String? benifit;
  final String? ordStatus;
  final DateTime? ordEntryDate;

  OrdersModel({
    this.ordId,
    this.ordName,
    this.perId,
    this.personal,
    this.ordxRef,
    this.ordTrnRef,
    this.ordBranch,
    this.brcName,
    this.totalBill,
    this.benifit,
    this.ordStatus,
    this.ordEntryDate,
  });

  OrdersModel copyWith({
    int? ordId,
    String? ordName,
    int? perId,
    String? personal,
    String? ordxRef,
    String? ordTrnRef,
    int? ordBranch,
    String? brcName,
    String? totalBill,
    String? benifit,
    String? ordStatus,
    DateTime? ordEntryDate,
  }) =>
      OrdersModel(
        ordId: ordId ?? this.ordId,
        ordName: ordName ?? this.ordName,
        perId: perId ?? this.perId,
        personal: personal ?? this.personal,
        ordxRef: ordxRef ?? this.ordxRef,
        ordTrnRef: ordTrnRef ?? this.ordTrnRef,
        ordBranch: ordBranch ?? this.ordBranch,
        brcName: brcName ?? this.brcName,
        totalBill: totalBill ?? this.totalBill,
        benifit: benifit ?? this.benifit,
        ordStatus: ordStatus ?? this.ordStatus,
        ordEntryDate: ordEntryDate ?? this.ordEntryDate,
      );

  factory OrdersModel.fromMap(Map<String, dynamic> json) => OrdersModel(
    ordId: json["ordID"],
    ordName: json["ordName"],
    perId: json["perID"],
    personal: json["personal"],
    ordxRef: json["ordxRef"],
    ordTrnRef: json["ordTrnRef"],
    ordBranch: json["ordBranch"],
    brcName: json["brcName"],
    totalBill: json["totalBill"],
    benifit: json["benifit"],
    ordStatus: json["ordStatus"],
    ordEntryDate: json["ordEntryDate"] == null ? null : DateTime.parse(json["ordEntryDate"]),
  );

  Map<String, dynamic> toMap() => {
    "ordID": ordId,
    "ordName": ordName,
    "perID": perId,
    "personal": personal,
    "ordxRef": ordxRef,
    "ordTrnRef": ordTrnRef,
    "ordBranch": ordBranch,
    "brcName": brcName,
    "totalBill": totalBill,
    "benifit": benifit,
    "ordStatus": ordStatus,
    "ordEntryDate": ordEntryDate?.toIso8601String(),
  };
}
