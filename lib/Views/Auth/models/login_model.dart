// To parse this JSON data, do
//
//     final loginData = loginDataFromMap(jsonString);

import 'dart:convert';

LoginData loginDataFromMap(String str) => LoginData.fromMap(json.decode(str));

String loginDataToMap(LoginData data) => json.encode(data.toMap());

class LoginData {
  final String? usrName;
  final int? usrId;
  final String? usrFullName;
  final String? usrPhoto;
  final String? usrRole;
  final String? usrEmail;
  final String? perPhone;
  final DateTime? usrEntryDate;
  final int? usrBranch;
  final String? brcName;
  final List<UsrPermission>? permissions;
  final Company? company;

  LoginData({
    this.usrName,
    this.usrId,
    this.usrFullName,
    this.usrPhoto,
    this.usrRole,
    this.usrEmail,
    this.perPhone,
    this.usrEntryDate,
    this.usrBranch,
    this.brcName,
    this.permissions,
    this.company,
  });

  LoginData copyWith({
    String? usrName,
    int? usrId,
    String? usrFullName,
    String? usrPhoto,
    String? usrRole,
    String? usrEmail,
    String? perPhone,
    DateTime? usrEntryDate,
    int? usrBranch,
    String? brcName,
    List<UsrPermission>? permissions,
    Company? company,
  }) =>
      LoginData(
        usrName: usrName ?? this.usrName,
        usrId: usrId ?? this.usrId,
        usrFullName: usrFullName ?? this.usrFullName,
        usrPhoto: usrPhoto ?? this.usrPhoto,
        usrRole: usrRole ?? this.usrRole,
        usrEmail: usrEmail ?? this.usrEmail,
        perPhone: perPhone ?? this.perPhone,
        usrEntryDate: usrEntryDate ?? this.usrEntryDate,
        usrBranch: usrBranch ?? this.usrBranch,
        brcName: brcName ?? this.brcName,
        permissions: permissions ?? this.permissions,
        company: company ?? this.company,
      );

  factory LoginData.fromMap(Map<String, dynamic> json) => LoginData(
    usrName: json["usrName"],
    usrId: json["usrID"],
    usrFullName: json["usrFullName"],
    usrPhoto: json["perPhoto"],
    usrRole: json["usrRole"],
    usrEmail: json["usrEmail"],
    perPhone: json["perPhone"],
    usrEntryDate: json["usrEntryDate"] == null ? null : DateTime.parse(json["usrEntryDate"]),
    usrBranch: json["usrBranch"],
    brcName: json["brcName"],
    permissions: json["permissions"] == null ? [] : List<UsrPermission>.from(json["permissions"]!.map((x) => UsrPermission.fromMap(x))),
    company: json["company"] == null ? null : Company.fromMap(json["company"]),
  );

  Map<String, dynamic> toMap() => {
    "usrName": usrName,
    "usrID": usrId,
    "usrFullName": usrFullName,
    "perPhoto": usrPhoto,
    "usrRole": usrRole,
    "usrEmail": usrEmail,
    "perPhone": perPhone,
    "usrEntryDate": usrEntryDate?.toIso8601String(),
    "usrBranch": usrBranch,
    "brcName": brcName,
    "permissions": permissions == null ? [] : List<dynamic>.from(permissions!.map((x) => x.toMap())),
    "company": company?.toMap(),
  };
}

class Company {
  final int? comId;
  final String? comName;
  final dynamic comLicenseNo;
  final dynamic comSlogan;
  final dynamic comDetails;
  final String? comPhone;
  final String? comEmail;
  final String? comWebsite;
  final String? comLogo;
  final int? comOwner;
  final dynamic comFb;
  final dynamic comInsta;
  final dynamic comWhatsapp;
  final dynamic comVerify;
  final String? comLocalCcy;
  final String? comTimeZone;
  final String? comAddress;

  Company({
    this.comId,
    this.comName,
    this.comLicenseNo,
    this.comSlogan,
    this.comDetails,
    this.comPhone,
    this.comEmail,
    this.comWebsite,
    this.comLogo,
    this.comOwner,
    this.comFb,
    this.comInsta,
    this.comWhatsapp,
    this.comVerify,
    this.comLocalCcy,
    this.comTimeZone,
    this.comAddress,
  });

  Company copyWith({
    int? comId,
    String? comName,
    dynamic comLicenseNo,
    dynamic comSlogan,
    dynamic comDetails,
    String? comPhone,
    String? comEmail,
    String? comWebsite,
    String? comLogo,
    int? comOwner,
    dynamic comFb,
    dynamic comInsta,
    dynamic comWhatsapp,
    dynamic comVerify,
    String? comLocalCcy,
    String? comTimeZone,
    String? comAddress,
  }) => Company(
        comId: comId ?? this.comId,
        comName: comName ?? this.comName,
        comLicenseNo: comLicenseNo ?? this.comLicenseNo,
        comSlogan: comSlogan ?? this.comSlogan,
        comDetails: comDetails ?? this.comDetails,
        comPhone: comPhone ?? this.comPhone,
        comEmail: comEmail ?? this.comEmail,
        comWebsite: comWebsite ?? this.comWebsite,
        comLogo: comLogo ?? this.comLogo,
        comOwner: comOwner ?? this.comOwner,
        comFb: comFb ?? this.comFb,
        comInsta: comInsta ?? this.comInsta,
        comWhatsapp: comWhatsapp ?? this.comWhatsapp,
        comVerify: comVerify ?? this.comVerify,
        comLocalCcy: comLocalCcy ?? this.comLocalCcy,
        comTimeZone: comTimeZone ?? this.comTimeZone,
        comAddress: comAddress ?? this.comAddress,
      );

  factory Company.fromMap(Map<String, dynamic> json) => Company(
    comId: json["comID"],
    comName: json["comName"],
    comLicenseNo: json["comLicenseNo"],
    comSlogan: json["comSlogan"],
    comDetails: json["comDetails"],
    comPhone: json["comPhone"],
    comEmail: json["comEmail"],
    comWebsite: json["comWebsite"],
    comLogo: json["comLogo"],
    comOwner: json["comOwner"],
    comFb: json["comFB"],
    comInsta: json["comInsta"],
    comWhatsapp: json["comWhatsapp"],
    comVerify: json["comVerify"],
    comLocalCcy: json["comLocalCcy"],
    comTimeZone: json["comTimeZone"],
    comAddress: json["comAddress"],
  );

  Map<String, dynamic> toMap() => {
    "comID": comId,
    "comName": comName,
    "comLicenseNo": comLicenseNo,
    "comSlogan": comSlogan,
    "comDetails": comDetails,
    "comPhone": comPhone,
    "comEmail": comEmail,
    "comWebsite": comWebsite,
    "comLogo": comLogo,
    "comOwner": comOwner,
    "comFB": comFb,
    "comInsta": comInsta,
    "comWhatsapp": comWhatsapp,
    "comVerify": comVerify,
    "comLocalCcy": comLocalCcy,
    "comTimeZone": comTimeZone,
    "comAddress": comAddress,
  };
}

class UsrPermission {
  final int? uprRole;
  final int? uprStatus;
  final String? rsgName;

  UsrPermission({
    this.uprRole,
    this.uprStatus,
    this.rsgName,
  });

  UsrPermission copyWith({
    int? uprRole,
    int? uprStatus,
    String? rsgName,
  }) =>
      UsrPermission(
        uprRole: uprRole ?? this.uprRole,
        uprStatus: uprStatus ?? this.uprStatus,
        rsgName: rsgName ?? this.rsgName,
      );

  factory UsrPermission.fromMap(Map<String, dynamic> json) => UsrPermission(
    uprRole: json["uprRole"],
    uprStatus: json["uprStatus"],
    rsgName: json["rsgName"],
  );

  Map<String, dynamic> toMap() => {
    "uprRole": uprRole,
    "uprStatus": uprStatus,
    "rsgName": rsgName,
  };
}

extension LoginPermissionExt on LoginData {
  bool? hasPermission(int uprRole) {
    return permissions?.any((p) => p.uprRole == uprRole && p.uprStatus == 1);
  }
}


