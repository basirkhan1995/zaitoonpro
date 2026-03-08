part of 'user_role_bloc.dart';

sealed class UserRoleEvent extends Equatable {
  const UserRoleEvent();
}

class LoadUserRolesEvent extends UserRoleEvent{
  @override
  List<Object?> get props => [];
}

class AddUserRoleEvent extends UserRoleEvent {
  final String usrName;
  final String roleName;
  const AddUserRoleEvent({required this.usrName, required this.roleName});
  @override
  List<Object> get props => [usrName, roleName];
}

class UpdateUserRoleEvent extends UserRoleEvent {
 final UserRoleModel newRole;
  const UpdateUserRoleEvent({required this.newRole});
  @override
  List<Object> get props => [newRole];
}

class DeleteUserRolesEvent extends UserRoleEvent{
  final int roleId;
  const DeleteUserRolesEvent(this.roleId);
  @override
  List<Object?> get props => [roleId];
}
