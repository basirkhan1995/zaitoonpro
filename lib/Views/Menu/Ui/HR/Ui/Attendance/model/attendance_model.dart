// attendance_model.dart
import 'dart:convert';

import 'package:zaitoonpro/Features/Date/shamsi_converter.dart';

AttendanceModel attendanceModelFromMap(String str) => AttendanceModel.fromMap(json.decode(str));
String attendanceModelToMap(AttendanceModel data) => json.encode(data.toMap());

class AttendanceModel {
  final String? usrName;
  final List<AttendanceRecord>? records;

  AttendanceModel({
    this.usrName,
    this.records,
  });

  AttendanceModel copyWith({
    String? usrName,
    List<AttendanceRecord>? records,
  }) =>
      AttendanceModel(
        usrName: usrName ?? this.usrName,
        records: records ?? this.records,
      );

  factory AttendanceModel.fromMap(Map<String, dynamic> json) => AttendanceModel(
    usrName: json["usrName"],
    records: json["records"] == null ? [] : List<AttendanceRecord>.from(json["records"]!.map((x) => AttendanceRecord.fromMap(x))),
  );

  Map<String, dynamic> toMap() {
    // For ADD operation
    if (records == null || records!.isEmpty) {
      return {
        "usrName": usrName,
        "emaDate": DateTime.now().toFormattedDate(),
        "emaCheckedIn": "08:00:00",
        "empCheckedOut": "16:00:00"
      };
    }

    // For UPDATE operation
    return {
      "usrName": usrName,
      "records": records == null ? [] : List<dynamic>.from(records!.map((x) => x.toMap())),
    };
  }
}

class AttendanceRecord {
  final String? usrName;
  final int? emaId;
  final int? emaEmployee; // Changed from empId to match API
  final String? fullName; // Changed from employeeName
  final String? emaCheckedIn;
  final String? emaCheckedOut;
  final String? emaStatus;
  final String? emaDate;
  final String? empPosition;

  AttendanceRecord({
    this.usrName,
    this.emaId,
    this.emaEmployee,
    this.fullName,
    this.emaCheckedIn,
    this.emaCheckedOut,
    this.emaStatus,
    this.emaDate,
    this.empPosition,
  });

  AttendanceRecord copyWith({
    String? usrName,
    int? emaId,
    int? emaEmployee,
    String? fullName,
    String? emaCheckedIn,
    String? emaCheckedOut,
    String? emaStatus,
    String? emaDate,
    String? empPosition,
  }) =>
      AttendanceRecord(
        usrName: usrName ?? this.usrName,
        emaId: emaId ?? this.emaId,
        emaEmployee: emaEmployee ?? this.emaEmployee,
        fullName: fullName ?? this.fullName,
        emaCheckedIn: emaCheckedIn ?? this.emaCheckedIn,
        emaCheckedOut: emaCheckedOut ?? this.emaCheckedOut,
        emaStatus: emaStatus ?? this.emaStatus,
        emaDate: emaDate ?? this.emaDate,
        empPosition: empPosition ?? this.empPosition,
      );

  factory AttendanceRecord.fromMap(Map<String, dynamic> json) => AttendanceRecord(
    usrName: json["usrName"],
    emaId: json["emaID"],
    emaEmployee: json["emaEmployee"],
    fullName: json["fullName"],
    emaCheckedIn: json["emaCheckedIn"],
    emaCheckedOut: json["emaCheckedOut"],
    emaStatus: json["emaStatus"],
    emaDate: json["emaDate"],
    empPosition: json["empPosition"],
  );

  Map<String, dynamic> toMap() => {
    "usrName": usrName,
    "emaID": emaId,
    "emaEmployee": emaEmployee,
    "fullName": fullName,
    "emaDate": emaDate,
    "emaCheckedIn": emaCheckedIn,
    "emaCheckedOut": emaCheckedOut,
    "emaStatus": emaStatus,
    "empPosition": empPosition,
  };

}

extension AttendanceCounter on List<AttendanceRecord> {
  int countByStatus(String status) {
    return where((e) => e.emaStatus?.toLowerCase() == status.toLowerCase(),
    ).length;
  }

  int get present => countByStatus('Present');
  int get late => countByStatus('Late');
  int get absent => countByStatus('Absent');
  int get leave => countByStatus('Leave');
}
