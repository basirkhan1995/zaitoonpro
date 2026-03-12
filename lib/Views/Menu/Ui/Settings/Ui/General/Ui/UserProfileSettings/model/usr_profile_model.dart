
import 'dart:convert';

UsrProfileModel usrProfileModelFromMap(String str) => UsrProfileModel.fromMap(json.decode(str));
String usrProfileModelToMap(UsrProfileModel data) => json.encode(data.toMap());

class UsrProfileModel {
  final int? perId;
  final String? perName;
  final String? perLastName;
  final String? perGender;
  final DateTime? perDoB;
  final String? perEnidNo;
  final int? perAddress;
  final String? perPhone;
  final String? perEmail;
  final String? perPhoto;
  final UsrAddress? address;
  final UserProfile? user;
  final List<UsrAccount>? accounts;
  final UsrEmployment? employment;

  UsrProfileModel({
    this.perId,
    this.perName,
    this.perLastName,
    this.perGender,
    this.perDoB,
    this.perEnidNo,
    this.perAddress,
    this.perPhone,
    this.perEmail,
    this.perPhoto,
    this.address,
    this.user,
    this.accounts,
    this.employment,
  });

  UsrProfileModel copyWith({
    int? perId,
    String? perName,
    String? perLastName,
    String? perGender,
    DateTime? perDoB,
    String? perEnidNo,
    int? perAddress,
    String? perPhone,
    String? perEmail,
    String? perPhoto,
    UsrAddress? address,
    UserProfile? user,
    List<UsrAccount>? accounts,
    UsrEmployment? employment,
  }) =>
      UsrProfileModel(
        perId: perId ?? this.perId,
        perName: perName ?? this.perName,
        perLastName: perLastName ?? this.perLastName,
        perGender: perGender ?? this.perGender,
        perDoB: perDoB ?? this.perDoB,
        perEnidNo: perEnidNo ?? this.perEnidNo,
        perAddress: perAddress ?? this.perAddress,
        perPhone: perPhone ?? this.perPhone,
        perEmail: perEmail ?? this.perEmail,
        perPhoto: perPhoto ?? this.perPhoto,
        address: address ?? this.address,
        user: user ?? this.user,
        accounts: accounts ?? this.accounts,
        employment: employment ?? this.employment,
      );

  factory UsrProfileModel.fromMap(Map<String, dynamic> json) => UsrProfileModel(
    perId: json["perID"],
    perName: json["perName"],
    perLastName: json["perLastName"],
    perGender: json["perGender"],
    perDoB: json["perDoB"] == null ? null : DateTime.parse(json["perDoB"]),
    perEnidNo: json["perENIDNo"],
    perAddress: json["perAddress"],
    perPhone: json["perPhone"],
    perEmail: json["perEmail"],
    perPhoto: json["perPhoto"],
    address: json["address"] == null ? null : UsrAddress.fromMap(json["address"]),
    user: json["user"] == null ? null : UserProfile.fromMap(json["user"]),
    accounts: json["accounts"] == null ? [] : List<UsrAccount>.from(json["accounts"]!.map((x) => UsrAccount.fromMap(x))),
    employment: json["employment"] is Map ? UsrEmployment.fromMap(json["employment"]) : null,
    );

  Map<String, dynamic> toMap() => {
    "perID": perId,
    "perName": perName,
    "perLastName": perLastName,
    "perGender": perGender,
    "perDoB": "${perDoB!.year.toString().padLeft(4, '0')}-${perDoB!.month.toString().padLeft(2, '0')}-${perDoB!.day.toString().padLeft(2, '0')}",
    "perENIDNo": perEnidNo,
    "perAddress": perAddress,
    "perPhone": perPhone,
    "perEmail": perEmail,
    "perPhoto": perPhoto,
    "address": address?.toMap(),
    "user": user?.toMap(),
    "accounts": accounts == null ? [] : List<dynamic>.from(accounts!.map((x) => x.toMap())),
    "employment": employment?.toMap(),
  };
}

class UsrAccount {
  final int? accNumber;
  final String? accName;
  final String? ccyName;
  final String? actCurrency;
  final String? accLimit;
  final String? balance;
  final String? accStatus;

  UsrAccount({
    this.accNumber,
    this.accName,
    this.ccyName,
    this.actCurrency,
    this.accLimit,
    this.balance,
    this.accStatus,
  });

  UsrAccount copyWith({
    int? accNumber,
    String? accName,
    String? ccyName,
    String? actCurrency,
    String? accLimit,
    String? balance,
    String? accStatus,
  }) =>
      UsrAccount(
        accNumber: accNumber ?? this.accNumber,
        accName: accName ?? this.accName,
        ccyName: ccyName ?? this.ccyName,
        actCurrency: actCurrency ?? this.actCurrency,
        accLimit: accLimit ?? this.accLimit,
        balance: balance ?? this.balance,
        accStatus: accStatus ?? this.accStatus,
      );

  factory UsrAccount.fromMap(Map<String, dynamic> json) => UsrAccount(
    accNumber: json["accNumber"],
    accName: json["accName"],
    ccyName: json["ccyName"],
    actCurrency: json["actCurrency"],
    accLimit: json["accLimit"],
    balance: json["balance"],
    accStatus: json["accStatus"],
  );

  Map<String, dynamic> toMap() => {
    "accNumber": accNumber,
    "accName": accName,
    "ccyName": ccyName,
    "actCurrency": actCurrency,
    "accLimit": accLimit,
    "balance": balance,
    "accStatus": accStatus,
  };
}
class UsrAddress {
  final int? addId;
  final String? addName;
  final String? addCity;
  final String? addProvince;
  final String? addCountry;
  final String? addZipCode;
  final int? addMailing;

  UsrAddress({
    this.addId,
    this.addName,
    this.addCity,
    this.addProvince,
    this.addCountry,
    this.addZipCode,
    this.addMailing,
  });

  UsrAddress copyWith({
    int? addId,
    String? addName,
    String? addCity,
    String? addProvince,
    String? addCountry,
    String? addZipCode,
    int? addMailing,
  }) =>
      UsrAddress(
        addId: addId ?? this.addId,
        addName: addName ?? this.addName,
        addCity: addCity ?? this.addCity,
        addProvince: addProvince ?? this.addProvince,
        addCountry: addCountry ?? this.addCountry,
        addZipCode: addZipCode ?? this.addZipCode,
        addMailing: addMailing ?? this.addMailing,
      );

  factory UsrAddress.fromMap(Map<String, dynamic> json) => UsrAddress(
    addId: json["addID"],
    addName: json["addName"],
    addCity: json["addCity"],
    addProvince: json["addProvince"],
    addCountry: json["addCountry"],
    addZipCode: json["addZipCode"],
    addMailing: json["addMailing"],
  );

  Map<String, dynamic> toMap() => {
    "addID": addId,
    "addName": addName,
    "addCity": addCity,
    "addProvince": addProvince,
    "addCountry": addCountry,
    "addZipCode": addZipCode,
    "addMailing": addMailing,
  };
}
class UsrEmployment {
  final int? empId;
  final DateTime? empHireDate;
  final String? empDepartment;
  final String? empPosition;
  final String? empSalCalcBase;
  final String? empPmntMethod;
  final String? empSalary;
  final String? empTaxInfo;
  final String? empStatus;
  final String? empFiredDate;

  UsrEmployment({
    this.empId,
    this.empHireDate,
    this.empDepartment,
    this.empPosition,
    this.empSalCalcBase,
    this.empPmntMethod,
    this.empSalary,
    this.empTaxInfo,
    this.empStatus,
    this.empFiredDate,
  });

  UsrEmployment copyWith({
    int? empId,
    DateTime? empHireDate,
    String? empDepartment,
    String? empPosition,
    String? empSalCalcBase,
    String? empPmntMethod,
    String? empSalary,
    String? empTaxInfo,
    String? empStatus,
    String? empFiredDate,
  }) =>
      UsrEmployment(
        empId: empId ?? this.empId,
        empHireDate: empHireDate ?? this.empHireDate,
        empDepartment: empDepartment ?? this.empDepartment,
        empPosition: empPosition ?? this.empPosition,
        empSalCalcBase: empSalCalcBase ?? this.empSalCalcBase,
        empPmntMethod: empPmntMethod ?? this.empPmntMethod,
        empSalary: empSalary ?? this.empSalary,
        empTaxInfo: empTaxInfo ?? this.empTaxInfo,
        empStatus: empStatus ?? this.empStatus,
        empFiredDate: empFiredDate ?? this.empFiredDate,
      );

  factory UsrEmployment.fromMap(Map<String, dynamic> json) => UsrEmployment(
    empId: json["empID"],
    empHireDate: json["empHireDate"] == null ? null : DateTime.parse(json["empHireDate"]),
    empDepartment: json["empDepartment"],
    empPosition: json["empPosition"],
    empSalCalcBase: json["empSalCalcBase"],
    empPmntMethod: json["empPmntMethod"],
    empSalary: json["empSalary"],
    empTaxInfo: json["empTaxInfo"],
    empStatus: json["empStatus"],
    empFiredDate: json["empFiredDate"],
  );

  Map<String, dynamic> toMap() => {
    "empID": empId,
    "empHireDate": "${empHireDate!.year.toString().padLeft(4, '0')}-${empHireDate!.month.toString().padLeft(2, '0')}-${empHireDate!.day.toString().padLeft(2, '0')}",
    "empDepartment": empDepartment,
    "empPosition": empPosition,
    "empSalCalcBase": empSalCalcBase,
    "empPmntMethod": empPmntMethod,
    "empSalary": empSalary,
    "empTaxInfo": empTaxInfo,
    "empStatus": empStatus,
    "empFiredDate": empFiredDate,
  };
}
class UserProfile {
  final int? usrId;
  final String? usrName;
  final String? usrEmail;
  final String? brcName;
  final int? brcId;
  final int? usrFcp;
  final String? usrVerify;
  final int? usrAlfCounter;
  final DateTime? usrEntryDate;
  final String? usrStatus;

  UserProfile({
    this.usrId,
    this.usrName,
    this.usrEmail,
    this.brcName,
    this.brcId,
    this.usrFcp,
    this.usrVerify,
    this.usrAlfCounter,
    this.usrEntryDate,
    this.usrStatus,
  });

  UserProfile copyWith({
    int? usrId,
    String? usrName,
    String? usrEmail,
    String? brcName,
    int? brcId,
    int? usrFcp,
    String? usrVerify,
    int? usrAlfCounter,
    DateTime? usrEntryDate,
    String? usrStatus,
  }) =>
      UserProfile(
        usrId: usrId ?? this.usrId,
        usrName: usrName ?? this.usrName,
        usrEmail: usrEmail ?? this.usrEmail,
        brcName: brcName ?? this.brcName,
        brcId: brcId ?? this.brcId,
        usrFcp: usrFcp ?? this.usrFcp,
        usrVerify: usrVerify ?? this.usrVerify,
        usrAlfCounter: usrAlfCounter ?? this.usrAlfCounter,
        usrEntryDate: usrEntryDate ?? this.usrEntryDate,
        usrStatus: usrStatus ?? this.usrStatus,
      );

  factory UserProfile.fromMap(Map<String, dynamic> json) => UserProfile(
    usrId: json["usrID"],
    usrName: json["usrName"],
    usrEmail: json["usrEmail"],
    brcName: json["brcName"],
    brcId: json["brcID"],
    usrFcp: json["usrFCP"],
    usrVerify: json["usrVerify"],
    usrAlfCounter: json["usrALFCounter"],
    usrEntryDate: json["usrEntryDate"] == null ? null : DateTime.parse(json["usrEntryDate"]),
    usrStatus: json["usrStatus"],
  );

  Map<String, dynamic> toMap() => {
    "usrID": usrId,
    "usrName": usrName,
    "usrEmail": usrEmail,
    "brcName": brcName,
    "brcID": brcId,
    "usrFCP": usrFcp,
    "usrVerify": usrVerify,
    "usrALFCounter": usrAlfCounter,
    "usrEntryDate": usrEntryDate?.toIso8601String(),
    "usrStatus": usrStatus,
  };
}
