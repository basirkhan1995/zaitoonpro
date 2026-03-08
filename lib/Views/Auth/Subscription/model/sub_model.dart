

import 'dart:convert';

List<SubscriptionModel> subscriptionModelFromMap(String str) => List<SubscriptionModel>.from(json.decode(str).map((x) => SubscriptionModel.fromMap(x)));

String subscriptionModelToMap(List<SubscriptionModel> data) => json.encode(List<dynamic>.from(data.map((x) => x.toMap())));

class SubscriptionModel {
  final int? subId;
  final String? subKey;
  final DateTime? subExpireDate;
  final DateTime? subEntryDate;

  SubscriptionModel({
    this.subId,
    this.subKey,
    this.subExpireDate,
    this.subEntryDate,
  });

  SubscriptionModel copyWith({
    int? subId,
    String? subKey,
    DateTime? subExpireDate,
    DateTime? subEntryDate,
  }) =>
      SubscriptionModel(
        subId: subId ?? this.subId,
        subKey: subKey ?? this.subKey,
        subExpireDate: subExpireDate ?? this.subExpireDate,
        subEntryDate: subEntryDate ?? this.subEntryDate,
      );

  factory SubscriptionModel.fromMap(Map<String, dynamic> json) => SubscriptionModel(
    subId: json["subID"],
    subKey: json["subKey"],
    subExpireDate: json["subExpireDate"] == null ? null : DateTime.parse(json["subExpireDate"]),
    subEntryDate: json["subEntryDate"] == null ? null : DateTime.parse(json["subEntryDate"]),
  );

  Map<String, dynamic> toMap() => {
    "subID": subId,
    "subKey": subKey,
    "subExpireDate": "${subExpireDate!.year.toString().padLeft(4, '0')}-${subExpireDate!.month.toString().padLeft(2, '0')}-${subExpireDate!.day.toString().padLeft(2, '0')}",
    "subEntryDate": subEntryDate?.toIso8601String(),
  };
}
