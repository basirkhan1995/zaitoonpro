part of 'permission_settings_bloc.dart';

sealed class PermissionSettingsState extends Equatable {
  const PermissionSettingsState();
}

final class PermissionSettingsInitial extends PermissionSettingsState {
  @override
  List<Object> get props => [];
}

final class PermissionSettingsLoadingState extends PermissionSettingsState {
  @override
  List<Object> get props => [];
}

final class PermissionSettingsErrorState extends PermissionSettingsState {
  final String message;
  const PermissionSettingsErrorState(this.message);
  @override
  List<Object> get props => [message];
}

final class PermissionSettingsLoadedState extends PermissionSettingsState {
  final List<UserRolePermissionSettingModel> permissions;
  const PermissionSettingsLoadedState(this.permissions);
  @override
  List<Object> get props => [permissions];
}