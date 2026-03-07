import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zaitoon_petroleum/Services/repositories.dart';
import 'package:zaitoon_petroleum/Views/Menu/Ui/Settings/Ui/General/Ui/RolesAndPermissions/model/permission_settings_model.dart';

part 'permission_settings_event.dart';
part 'permission_settings_state.dart';

class PermissionSettingsBloc extends Bloc<PermissionSettingsEvent, PermissionSettingsState> {
  final Repositories _repo;
  PermissionSettingsBloc(this._repo) : super(PermissionSettingsInitial()) {

    on<PermissionSettingsEvent>((event, emit)async {
      emit(PermissionSettingsLoadingState());
      try{
       final per = await _repo.getPermissionSettings();
       emit(PermissionSettingsLoadedState(per));
      }catch(e){
       emit(PermissionSettingsErrorState(e.toString()));
      }
    });

  }
}
