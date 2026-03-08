// To parse this JSON data, do
//
//     final usersModel = usersModelFromMap(jsonString);

import 'dart:convert';

List<UsersModel> usersModelFromMap(String str) => List<UsersModel>.from(json.decode(str).map((x) => UsersModel.fromMap(x)));

String usersModelToMap(List<UsersModel> data) => json.encode(List<dynamic>.from(data.map((x) => x.toMap())));

class UsersModel {
  final int? usrId;
  final int? rolID;
  final String? usrFullName;
  final String? usrName;
  final String? usrRole;
  final int? usrStatus;
  final int? usrBranch;
  final String? usrEmail;
  final String? usrToken;
  final DateTime? usrEntryDate;
  final int? usrOwner;
  final String? usrPass;
  final int? usrFcp;
  final String? loggedInUser;
  final bool? usrFev;
  final String? usrPhoto;

  UsersModel({
    this.usrId,
    this.rolID,
    this.usrFullName,
    this.usrName,
    this.usrRole,
    this.usrOwner,
    this.usrFcp,
    this.usrFev,
    this.usrPass,
    this.usrStatus,
    this.usrBranch,
    this.loggedInUser,
    this.usrEmail,
    this.usrToken,
    this.usrEntryDate,
    this.usrPhoto,
  });

  UsersModel copyWith({
    int? usrId,
    int? rolID,
    String? usrFullName,
    String? usrName,
    String? usrRole,
    int? usrStatus,
    int? usrBranch,
    String? usrEmail,
    String? usrToken,
    String? usrPhoto,
    DateTime? usrEntryDate,
  }) =>
      UsersModel(
        usrId: usrId ?? this.usrId,
        rolID: rolID ?? this.rolID,
        usrFullName: usrFullName ?? this.usrFullName,
        usrName: usrName ?? this.usrName,
        usrRole: usrRole ?? this.usrRole,
        usrStatus: usrStatus ?? this.usrStatus,
        usrBranch: usrBranch ?? this.usrBranch,
        usrEmail: usrEmail ?? this.usrEmail,
        usrToken: usrToken ?? this.usrToken,
        usrEntryDate: usrEntryDate ?? this.usrEntryDate,
        usrPhoto: usrPhoto ?? this.usrPhoto
      );

  factory UsersModel.fromMap(Map<String, dynamic> json) => UsersModel(
    usrId: json["usrID"],
    rolID: json["rolID"],
    usrFullName: json["usrFullName"],
    usrName: json["usrName"],
    usrRole: json["usrRole"],
    usrStatus: json["usrStatus"],
    usrBranch: json["usrBranch"],
    usrEmail: json["usrEmail"],
    usrToken: json["usrToken"],
    usrEntryDate: json["usrEntryDate"] == null ? null : DateTime.parse(json["usrEntryDate"]),
    usrPhoto: json["perPhoto"],
    usrFcp: json["usrFCP"]
  );

  Map<String, dynamic> toMap() => {
    "usrID": usrId,
    "rolID": rolID,
    "usrFullName": usrFullName,
    "usrName": usrName,
    "usrPass": usrPass,
    "usrOwner": usrOwner,
    "usrFCP": usrFcp,
    "usrFEV": usrFev,
    "usrRole": usrRole,
    "usrStatus": usrStatus,
    "usrBranch": usrBranch,
    "usrEmail": usrEmail,
    "usrToken": usrToken,
    "loggedInUser":loggedInUser,
    "usrEntryDate": usrEntryDate?.toIso8601String(),
  };
}
