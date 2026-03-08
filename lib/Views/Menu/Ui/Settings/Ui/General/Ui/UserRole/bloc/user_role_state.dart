part of 'user_role_bloc.dart';

sealed class UserRoleState extends Equatable {
  const UserRoleState();
}

final class UserRoleInitial extends UserRoleState {
  @override
  List<Object> get props => [];
}

final class UserRoleLoadingState extends UserRoleState {
  @override
  List<Object> get props => [];
}

final class UserRoleSuccessState extends UserRoleState {
  @override
  List<Object> get props => [];
}



final class UserRoleLoadedState extends UserRoleState {
  final List<UserRoleModel> roles;
  const UserRoleLoadedState(this.roles);
  @override
  List<Object> get props => [roles];
}

final class UserRoleErrorState extends UserRoleState {
  final String message;
  const UserRoleErrorState(this.message);
  @override
  List<Object> get props => [message];
}

