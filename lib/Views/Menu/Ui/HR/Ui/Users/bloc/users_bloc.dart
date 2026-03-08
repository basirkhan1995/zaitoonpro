import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zaitoon_petroleum/Services/localization_services.dart';
import 'package:zaitoon_petroleum/Services/repositories.dart';
import 'package:zaitoon_petroleum/Views/Menu/Ui/HR/Ui/Users/model/usr_report_model.dart';
import '../model/user_model.dart';

part 'users_event.dart';
part 'users_state.dart';

class UsersBloc extends Bloc<UsersEvent, UsersState> {
  final Repositories _repo;
  UsersBloc(this._repo) : super(UsersInitial()) {
    
    on<LoadUsersEvent>((event, emit) async{
      emit(UsersLoadingState());
      try{
       final users = await _repo.getUsers(usrOwner: event.usrOwner);
       emit(UsersLoadedState(users));
      }catch(e){
        emit(UsersErrorState(e.toString()));
      }
    });

    on<LoadUsersReportEvent>((event, emit) async{
      emit(UsersLoadingState());
      try{
        final users = await _repo.getUsersReport(branch: event.branchId, usrName: event.usrName, role: event.role,status: event.status);
        emit(UsersReportLoadedState(users));
      }catch(e){
        emit(UsersErrorState(e.toString()));
      }
    });

    on<ResetUserEvent>((event, emit) async{
      try{
        emit(UsersInitial());
      }catch(e){
        emit(UsersErrorState(e.toString()));
      }
    });

    on<AddUserEvent>((event, emit) async {
      final locale = localizationService.loc;
      emit(UsersLoadingState());

      try {
        final response = await _repo.addUser(newUser: event.newUser);
        final String msg = response['msg'];

        switch (msg) {
          case "success":
            emit(UserSuccessState());
            add(LoadUsersEvent());
            break;

          case "email exists":
            emit(UsersErrorState(locale.emailExists));
            break;

          case "user exists":
            emit(UsersErrorState(locale.usernameExists));
            break;

          default:
            emit(UsersErrorState("Unexpected response: $msg"));
        }
      } catch (e) {
        emit(UsersErrorState(e.toString()));
      }
    });


    on<UpdateUserEvent>((event, emit) async{
      emit(UsersLoadingState());
      try{
        final response = await _repo.editUser(newUser: event.newUser);
        final String msg = response['msg'];
        if (msg == "success") {
          emit(UserSuccessState());
          add(LoadUsersEvent());
        }else if(msg == "not allowed"){
          emit(UsersErrorState("Password or role changes are not allowed. Contact your admin."));
        }else{
          emit(UsersErrorState(msg));
        }
      }catch(e){
        emit(UsersErrorState(e.toString()));
      }
    });

  }
}
