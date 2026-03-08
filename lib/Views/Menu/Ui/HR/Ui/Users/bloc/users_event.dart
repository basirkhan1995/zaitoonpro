part of 'users_bloc.dart';

sealed class UsersEvent extends Equatable {
  const UsersEvent();
}

class LoadUsersEvent extends UsersEvent{
  final int? usrOwner;
  const LoadUsersEvent({this.usrOwner});

  @override
  List<Object?> get props => [usrOwner];
}

class LoadUsersReportEvent extends UsersEvent{
  final int? branchId;
  final String? usrName;
  final int? role;
  final int? status;
  const LoadUsersReportEvent({this.branchId,this.usrName, this.role,this.status});

  @override
  List<Object?> get props => [branchId, usrName, role, status];
}

class ResetUsersEvent extends UsersEvent{
  @override
  List<Object?> get props => [];

}


class AddUserEvent extends UsersEvent{
  final UsersModel newUser;
  const AddUserEvent(this.newUser);
  @override
  List<Object?> get props => [newUser];
}

class UpdateUserEvent extends UsersEvent{
  final UsersModel newUser;
  const UpdateUserEvent(this.newUser);
  @override
  List<Object?> get props => [newUser];
}

class ResetUserEvent extends UsersEvent{
  @override
  List<Object?> get props => [];
}