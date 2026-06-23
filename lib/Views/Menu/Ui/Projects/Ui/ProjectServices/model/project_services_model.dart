

import 'dart:convert';

List<ProjectServicesModel> projectDetailsModelFromMap(String str) =>
    List<ProjectServicesModel>.from(
        json.decode(str).map((x) => ProjectServicesModel.fromMap(x)));

String projectDetailsModelToMap(List<ProjectServicesModel> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toMap())));

class ProjectServicesModel {
  final int? pjdId;
  final int? prjId;
  final String? prjName;
  final int? srvId;
  final String? srvName;
  final double? pjdQuantity;
  final double? pjdPricePerQty;
  final double? total;
  final String? prpTrnRef;
  final int? paymentId;
  final String? pjdRemark;
  final int? pjdStatus;
  final String? usrName;

  ProjectServicesModel({
    this.pjdId,
    this.prjId,
    this.prjName,
    this.srvId,
    this.srvName,
    this.pjdQuantity,
    this.pjdPricePerQty,
    this.total,
    this.prpTrnRef,
    this.paymentId,
    this.pjdRemark,
    this.pjdStatus,
    this.usrName,
  });

  ProjectServicesModel copyWith({
    int? pjdId,
    int? prjId,
    String? prjName,
    int? srvId,
    String? srvName,
    double? pjdQuantity,
    double? pjdPricePerQty,
    double? total,
    String? prpTrnRef,
    int? paymentId,
    String? pjdRemark,
    int? pjdStatus,
    String? usrName,
  }) =>
      ProjectServicesModel(
        pjdId: pjdId ?? this.pjdId,
        prjId: prjId ?? this.prjId,
        prjName: prjName ?? this.prjName,
        srvId: srvId ?? this.srvId,
        srvName: srvName ?? this.srvName,
        pjdQuantity: pjdQuantity ?? this.pjdQuantity,
        pjdPricePerQty: pjdPricePerQty ?? this.pjdPricePerQty,
        total: total ?? this.total,
        prpTrnRef: prpTrnRef ?? this.prpTrnRef,
        paymentId: paymentId ?? this.paymentId,
        pjdRemark: pjdRemark ?? this.pjdRemark,
        pjdStatus: pjdStatus ?? this.pjdStatus,
        usrName: usrName ?? this.usrName,
      );

  factory ProjectServicesModel.fromMap(Map<String, dynamic> json) =>
      ProjectServicesModel(
        pjdId: json["pjdID"],
        prjId: json["prjID"],
        prjName: json["prjName"],
        srvId: json["srvID"],
        srvName: json["srvName"],
        pjdQuantity: json["pjdQuantity"] == null
            ? null
            : double.tryParse(json["pjdQuantity"].toString()),
        pjdPricePerQty: json["pjdPricePerQty"] == null
            ? null
            : double.tryParse(json["pjdPricePerQty"].toString()),
        total: json["total"] == null
            ? null
            : double.tryParse(json["total"].toString()),
        prpTrnRef: json["prpTrnRef"],
        paymentId: json["paymentID"],
        pjdRemark: json["pjdRemark"],
        pjdStatus: json["pjdStatus"],
        usrName: json["usrName"],
      );

  Map<String, dynamic> toMap() => {
    "pjdID": pjdId,
    "prjID": prjId,
    "prjName": prjName,
    "srvID": srvId,
    "srvName": srvName,
    "pjdQuantity": pjdQuantity,
    "pjdPricePerQty": pjdPricePerQty,
    "total": total,
    "prpTrnRef": prpTrnRef,
    "paymentID": paymentId,
    "pjdRemark": pjdRemark,
    "pjdStatus": pjdStatus,
    "usrName": usrName,
  };
}