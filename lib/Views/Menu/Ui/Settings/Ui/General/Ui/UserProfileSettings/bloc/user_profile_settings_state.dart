part of 'user_profile_settings_bloc.dart';

sealed class UserProfileSettingsState extends Equatable {
  const UserProfileSettingsState();
}

final class UserProfileSettingsInitial extends UserProfileSettingsState {
  @override
  List<Object> get props => [];
}


final class UserProfileSettingsLoadingState extends UserProfileSettingsState {
  @override
  List<Object> get props => [];
}


final class UserProfileSettingsErrorState extends UserProfileSettingsState {
  final String message;
  const UserProfileSettingsErrorState(this.message);
  @override
  List<Object> get props => [message];
}

final class UserProfileSettingsSuccessState extends UserProfileSettingsState {
  @override
  List<Object> get props => [];
}


final class UserProfileSettingsLoadedState extends UserProfileSettingsState {
  final UsrProfileModel profile;
  const UserProfileSettingsLoadedState(this.profile);
  @override
  List<Object> get props => [profile];
}
