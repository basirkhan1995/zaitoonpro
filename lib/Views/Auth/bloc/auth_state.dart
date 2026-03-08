part of 'auth_bloc.dart';

sealed class AuthState extends Equatable {
  const AuthState();
}

final class AuthInitial extends AuthState {
  @override
  List<Object> get props => [];
}

final class ForceChangePasswordState extends AuthState {
  @override
  List<Object> get props => [];
}

final class EmailVerificationState extends AuthState {
  @override
  List<Object> get props => [];
}

final class AuthLoadingState extends AuthState {
  @override
  List<Object> get props => [];
}

final class UnAuthenticatedState extends AuthState {
  @override
  List<Object> get props => [];
}

final class NoSubscriptionState extends AuthState {
  @override
  List<Object> get props => [];
}

final class AuthErrorState extends AuthState {
  final String message;
  const AuthErrorState(this.message);
  @override
  List<Object> get props => [message];
}

final class AuthenticatedState extends AuthState {
  final LoginData loginData;
  const AuthenticatedState(this.loginData);
  @override
  List<Object> get props => [loginData];
}

