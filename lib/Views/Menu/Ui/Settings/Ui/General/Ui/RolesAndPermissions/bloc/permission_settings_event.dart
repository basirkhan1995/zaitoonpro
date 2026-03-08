part of 'permission_settings_bloc.dart';

sealed class PermissionSettingsEvent extends Equatable {
  const PermissionSettingsEvent();
}

class LoadPermissionsSettingsEvent extends PermissionSettingsEvent{
  @override
  List<Object?> get props => [];
}

class AddNewRoleEvent extends PermissionSettingsEvent{
  final String usrName;
  final String roleName;
  const AddNewRoleEvent(this.roleName, this.usrName);
  @override
  List<Object?> get props => [usrName, roleName];
}

class UpdateNewRoleEvent extends PermissionSettingsEvent{
  final int roleId;
  final String usrName;
  final String roleName;
  final int? rpStatus;
  const UpdateNewRoleEvent(this.roleId, this.roleName, this.usrName, this.rpStatus);
  @override
  List<Object?> get props => [roleId, usrName, roleName, rpStatus];
}

class UpdatePermissionsSettingsEvent extends PermissionSettingsEvent{
  final int rpId;
  final int rpStatus;
  const UpdatePermissionsSettingsEvent(this.rpId, this.rpStatus);
  @override
  List<Object?> get props => [rpId, rpStatus];
}

class DeletePermissionsSettingsEvent extends PermissionSettingsEvent{
  @override
  List<Object?> get props => [];
}





