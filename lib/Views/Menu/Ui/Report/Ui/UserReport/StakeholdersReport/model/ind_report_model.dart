// To parse this JSON data, do
//
//     final indReportModel = indReportModelFromMap(jsonString);

import 'dart:convert';

List<IndReportModel> indReportModelFromMap(String str) => List<IndReportModel>.from(json.decode(str).map((x) => IndReportModel.fromMap(x)));

String indReportModelToMap(List<IndReportModel> data) => json.encode(List<dynamic>.from(data.map((x) => x.toMap())));

class IndReportModel {
  final int? perId;
  final String? perName;
  final String? perLastName;
  final String? perGender;
  final DateTime? perDoB;
  final String? perEnidNo;
  final String? perPhone;
  final String? perEmail;
  final String? address;

  IndReportModel({
    this.perId,
    this.perName,
    this.perLastName,
    this.perGender,
    this.perDoB,
    this.perEnidNo,
    this.perPhone,
    this.perEmail,
    this.address,
  });

  IndReportModel copyWith({
    int? perId,
    String? perName,
    String? perLastName,
    String? perGender,
    DateTime? perDoB,
    String? perEnidNo,
    String? perPhone,
    String? perEmail,
    String? address,
  }) =>
      IndReportModel(
        perId: perId ?? this.perId,
        perName: perName ?? this.perName,
        perLastName: perLastName ?? this.perLastName,
        perGender: perGender ?? this.perGender,
        perDoB: perDoB ?? this.perDoB,
        perEnidNo: perEnidNo ?? this.perEnidNo,
        perPhone: perPhone ?? this.perPhone,
        perEmail: perEmail ?? this.perEmail,
        address: address ?? this.address,
      );

  factory IndReportModel.fromMap(Map<String, dynamic> json) => IndReportModel(
    perId: json["perID"],
    perName: json["perName"],
    perLastName: json["perLastName"],
    perGender: json["perGender"],
    perDoB: json["perDoB"] == null ? null : DateTime.parse(json["perDoB"]),
    perEnidNo: json["perENIDNo"],
    perPhone: json["perPhone"],
    perEmail: json["perEmail"],
    address: json["address"],
  );

  Map<String, dynamic> toMap() => {
    "perID": perId,
    "perName": perName,
    "perLastName": perLastName,
    "perGender": perGender,
    "perDoB": "${perDoB!.year.toString().padLeft(4, '0')}-${perDoB!.month.toString().padLeft(2, '0')}-${perDoB!.day.toString().padLeft(2, '0')}",
    "perENIDNo": perEnidNo,
    "perPhone": perPhone,
    "perEmail": perEmail,
    "address": address,
  };
}
