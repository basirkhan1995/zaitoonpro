import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zaitoon_petroleum/Services/repositories.dart';
import '../model/role_model.dart';

part 'user_role_event.dart';
part 'user_role_state.dart';

class UserRoleBloc extends Bloc<UserRoleEvent, UserRoleState> {
  final Repositories _repo;
  UserRoleBloc(this._repo) : super(UserRoleInitial()) {

    on<LoadUserRolesEvent>((event, emit) async{
      emit(UserRoleLoadingState());
      try{
        final role = await _repo.getUserRole();
        emit(UserRoleLoadedState(role));
      }catch(e){
        emit(UserRoleErrorState(e.toString()));
      }
    });
    on<AddUserRoleEvent>((event, emit) async{
      emit(UserRoleLoadingState());
      try{
       final role = await _repo.addNewRole(usrName: event.usrName, roleName: event.roleName);
       final msg = role["msg"];
       if(msg == "success"){
         emit(UserRoleSuccessState());
         add(LoadUserRolesEvent());
       }else{
         emit(UserRoleErrorState(msg));
       }
      }catch(e){
        emit(UserRoleErrorState(e.toString()));
      }
    });
    on<UpdateUserRoleEvent>((event, emit) async{
      emit(UserRoleLoadingState());
      try{
        final res = await _repo.editUserRole(newRole: event.newRole);
        final msg = res["msg"];
        if(msg == "success"){
          add(LoadUserRolesEvent());
          emit(UserRoleSuccessState());
        }else{
          emit(UserRoleErrorState(msg));
        }
      }catch(e){
        emit(UserRoleErrorState(e.toString()));
      }
    });
    on<DeleteUserRolesEvent>((event, emit) async{
      emit(UserRoleLoadingState());
      try{
        final res = await _repo.deleteUserRole(roleId: event.roleId);
        final msg = res["msg"];
        if(msg == "success"){
          add(LoadUserRolesEvent());
          emit(UserRoleSuccessState());
        }else{
          emit(UserRoleErrorState(msg));
        }
      }catch(e){
        emit(UserRoleErrorState(e.toString()));
      }
    });
  }
}
