import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zaitoonpro/Services/repositories.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Settings/Ui/General/Ui/UserProfileSettings/model/usr_profile_model.dart';

part 'user_profile_settings_event.dart';
part 'user_profile_settings_state.dart';

class UserProfileSettingsBloc extends Bloc<UserProfileSettingsEvent, UserProfileSettingsState> {
  final Repositories _repo;

  UserProfileSettingsBloc(this._repo) : super(UserProfileSettingsInitial()) {
    on<LoadProfileSettingsEvent>(_onLoadProfile);
    on<RefreshProfileEvent>(_onRefreshProfile);
  }

  Future<void> _onLoadProfile(LoadProfileSettingsEvent event, Emitter<UserProfileSettingsState> emit) async {
    emit(UserProfileSettingsLoadingState());
    try {
      final profile = await _repo.getProfile(usrName: event.usrName);
      emit(UserProfileSettingsLoadedState(profile));
    } catch (e) {
      emit(UserProfileSettingsErrorState(e.toString()));
    }
  }

  Future<void> _onRefreshProfile(RefreshProfileEvent event, Emitter<UserProfileSettingsState> emit) async {
    try {
      final profile = await _repo.getProfile(usrName: event.usrName);
      emit(UserProfileSettingsLoadedState(profile));
    } catch (e) {
      emit(UserProfileSettingsErrorState(e.toString()));
    }
  }
}