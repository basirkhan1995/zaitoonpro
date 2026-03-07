part of 'permission_settings_bloc.dart';

sealed class PermissionSettingsEvent extends Equatable {
  const PermissionSettingsEvent();
}

class LoadPermissionsSettingsEvent extends PermissionSettingsEvent{
  @override
  List<Object?> get props => [];
}

