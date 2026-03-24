import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zaitoonpro/Services/repositories.dart';
import 'package:zaitoonpro/Views/Menu/Ui/HR/Ui/UserDetail/Ui/Log/model/user_log_model.dart';

part 'user_log_event.dart';
part 'user_log_state.dart';

class UserLogBloc extends Bloc<UserLogEvent, UserLogState> {
  final Repositories _repo;
  UserLogBloc(this._repo) : super(UserLogInitial()) {

    on<LoadUserLogEvent>((event, emit) async{
      emit(UserLogLoadingState());
      try{
        final log = await _repo.getUserLog(usrName: event.usrName, fromDate: event.fromDate, toDate: event.toDate);
         emit(UserLogLoadedState(log));
      }catch(e){
        emit(UserLogErrorState(e.toString()));
      }
    });
    on<ResetUserLogEvent>((event, emit) async{
      try{
        emit(UserLogInitial());
      }catch(e){
        emit(UserLogErrorState(e.toString()));
      }
    });
  }
}
