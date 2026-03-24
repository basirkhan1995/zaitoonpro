import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zaitoonpro/Services/repositories.dart';

import '../../../Services/localization_services.dart';

part 'password_event.dart';
part 'password_state.dart';

class PasswordBloc extends Bloc<PasswordEvent, PasswordState> {
  final Repositories _repo;
  PasswordBloc(this._repo) : super(PasswordInitial()) {
    on<ForceChangePasswordEvent>((event, emit) async{
      emit(PasswordLoadingState());
     try{
      final result = await _repo.forceChangePassword(credential: event.credential, newPassword: event.newPassword);
      if(result['msg'] == "success"){
        emit(PasswordChangedSuccessState());
      }
     }catch(e){
       emit(PasswordErrorState(e.toString()));
     }
    });
    on<ChangePasswordEvent>((event, emit) async{
      final locale = localizationService.loc;
      emit(PasswordLoadingState());
      try{
        final response = await _repo.changePassword(credential: event.usrName,oldPassword: event.oldPassword, newPassword: event.newPassword);
        if (response.containsKey("msg") && response["msg"] != null) {
          final String result = response["msg"];

          switch (result) {
            case "incorrect":
              emit(PasswordErrorState(locale.oldPasswordIncorrect));
              return;

            case "success":
              emit(PasswordChangedSuccessState());
              return;

            default:
              emit(PasswordErrorState(result));
              return;
          }
        }
      }catch(e){
        emit(PasswordErrorState(e.toString()));
      }
    });
    on<ResetPasswordEvent>((event, emit)async{});
  }
}
