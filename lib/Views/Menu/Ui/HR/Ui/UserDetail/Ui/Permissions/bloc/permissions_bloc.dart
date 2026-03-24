import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zaitoonpro/Services/repositories.dart';

import '../per_model.dart';
part 'permissions_event.dart';
part 'permissions_state.dart';

class PermissionsBloc extends Bloc<PermissionsEvent, PermissionsState> {
  final Repositories _repo;
  PermissionsBloc(this._repo) : super(PermissionsInitial()) {

    on<LoadPermissionsEvent>((event, emit) async{
      emit(PermissionsLoadingState());
      try{
      final permissions = await _repo.getPermissions(usrName: event.usrName);
      emit(PermissionsLoadedState(permissions));
      }catch(e){
       emit(PermissionsErrorState(e.toString()));
      }
    });

    on<UpdatePermissionsEvent>((event, emit) async {
      emit(PermissionsLoadingState());
      try {
        final response = await _repo.updatePermissions(
          usrId: event.usrId,
          usrName: event.usrName,
          permissions: event.permissions,
        );

        if (response["msg"] == "success") {
          // Show success message
          // You might want to add a Success state here
          add(LoadPermissionsEvent(event.usrName));
        } else {
          emit(PermissionsErrorState(response["msg"] ?? "Update failed"));
        }
      } catch (e) {
        emit(PermissionsErrorState(e.toString()));
      }
    });

  }
}
