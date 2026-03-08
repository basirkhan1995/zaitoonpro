

import 'dart:convert';

List<UserRolePermissionSettingModel> userRolePermissionSettingModelFromMap(String str) => List<UserRolePermissionSettingModel>.from(json.decode(str).map((x) => UserRolePermissionSettingModel.fromMap(x)));

String userRolePermissionSettingModelToMap(List<UserRolePermissionSettingModel> data) => json.encode(List<dynamic>.from(data.map((x) => x.toMap())));

class UserRolePermissionSettingModel {
  final int? rolId;
  final String? rolName;
  final int? rolStatus;
  final List<UsrPermission>? permissions;

  UserRolePermissionSettingModel({
    this.rolId,
    this.rolName,
    this.rolStatus,
    this.permissions,
  });

  UserRolePermissionSettingModel copyWith({
    int? rolId,
    String? rolName,
    int? rolStatus,
    List<UsrPermission>? permissions,
  }) =>
      UserRolePermissionSettingModel(
        rolId: rolId ?? this.rolId,
        rolName: rolName ?? this.rolName,
        rolStatus: rolStatus ?? this.rolStatus,
        permissions: permissions ?? this.permissions,
      );

  factory UserRolePermissionSettingModel.fromMap(Map<String, dynamic> json) => UserRolePermissionSettingModel(
    rolId: json["rolID"],
    rolName: json["rolName"],
    rolStatus: json["rolStatus"],
    permissions: json["permissions"] == null ? [] : List<UsrPermission>.from(json["permissions"]!.map((x) => UsrPermission.fromMap(x))),
  );

  Map<String, dynamic> toMap() => {
    "rolID": rolId,
    "rolName": rolName,
    "rolStatus": rolStatus,
    "permissions": permissions == null ? [] : List<dynamic>.from(permissions!.map((x) => x.toMap())),
  };
}

class UsrPermission {
  final int? rpId;
  final String? rsgName;
  final int? rpStatus;

  UsrPermission({
    this.rpId,
    this.rsgName,
    this.rpStatus,
  });

  UsrPermission copyWith({
    int? rpId,
    String? rsgName,
    int? rpStatus,
  }) =>
      UsrPermission(
        rpId: rpId ?? this.rpId,
        rsgName: rsgName ?? this.rsgName,
        rpStatus: rpStatus ?? this.rpStatus,
      );

  factory UsrPermission.fromMap(Map<String, dynamic> json) => UsrPermission(
    rpId: json["rpID"],
    rsgName: json["rsgName"],
    rpStatus: json["rpStatus"],
  );

  Map<String, dynamic> toMap() => {
    "rpID": rpId,
    "rsgName": rsgName,
    "rpStatus": rpStatus,
  };
}


PermissionActionModel permissionActionModelFromMap(String str) => PermissionActionModel.fromMap(json.decode(str));

String permissionActionModelToMap(PermissionActionModel data) => json.encode(data.toMap());

class PermissionActionModel {
  final String? usrName;
  final List<PermissionActions>? permissions;

  PermissionActionModel({
    this.usrName,
    this.permissions,
  });

  PermissionActionModel copyWith({
    String? usrName,
    List<PermissionActions>? permissions,
  }) =>
      PermissionActionModel(
        usrName: usrName ?? this.usrName,
        permissions: permissions ?? this.permissions,
      );

  factory PermissionActionModel.fromMap(Map<String, dynamic> json) => PermissionActionModel(
    usrName: json["usrName"],
    permissions: json["permissions"] == null ? [] : List<PermissionActions>.from(json["permissions"]!.map((x) => PermissionActions.fromMap(x))),
  );

  Map<String, dynamic> toMap() => {
    "usrName": usrName,
    "permissions": permissions == null ? [] : List<dynamic>.from(permissions!.map((x) => x.toMap())),
  };
}

class PermissionActions {
  final int? rpId;
  final int? rpStatus;

  PermissionActions({
    this.rpId,
    this.rpStatus,
  });

  PermissionActions copyWith({
    int? rpId,
    int? rpStatus,
  }) =>
      PermissionActions(
        rpId: rpId ?? this.rpId,
        rpStatus: rpStatus ?? this.rpStatus,
      );

  factory PermissionActions.fromMap(Map<String, dynamic> json) => PermissionActions(
    rpId: json["rpID"],
    rpStatus: json["rpStatus"],
  );

  Map<String, dynamic> toMap() => {
    "rpID": rpId,
    "rpStatus": rpStatus,
  };
}
