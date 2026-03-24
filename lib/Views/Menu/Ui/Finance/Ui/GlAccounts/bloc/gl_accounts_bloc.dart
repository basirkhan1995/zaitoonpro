import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zaitoonpro/Services/localization_services.dart';
import 'package:zaitoonpro/Services/repositories.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Finance/Ui/GlAccounts/model/gl_model.dart';

part 'gl_accounts_event.dart';
part 'gl_accounts_state.dart';

class GlAccountsBloc extends Bloc<GlAccountsEvent, GlAccountsState> {
  final Repositories _repo;
  GlAccountsBloc(this._repo) : super(GlAccountsInitial()) {
    on<LoadGlAccountEvent>((event, emit) async{
      emit(GlAccountsLoadingState());
      try{
        final gl = await _repo.getGl(input: event.query);
        emit(GlAccountLoadedState(gl));
      }catch(e){
        emit(GlAccountsErrorState(e.toString()));
      }
    });
    on<AddGlEvent>((event, emit) async{
      final tr = localizationService.loc;
      emit(GlAccountsLoadingState());
      try{
        final response = await _repo.addGl(newAccount: event.newGl);
        final msg = response["msg"];
        switch(msg){
          case "success" :
            emit(GlSuccessState());
            add(LoadGlAccountEvent());
            return;
          case "exist" :
            emit(GlAccountsErrorState(tr.accountExist));
            return;
          case "failed" :
          emit(GlAccountsErrorState(tr.operationFailedMessage));
          return;
          default:
            emit(GlAccountsErrorState(msg));
            return;
        }

      }catch(e){
        emit(GlAccountsErrorState(e.toString()));
      }
    });
    on<UpdateGlEvent>((event, emit) async{
      final tr = localizationService.loc;
      emit(GlAccountsLoadingState());
      try{
        final response = await _repo.editGl(newAccount: event.newGl);
        final msg = response["msg"];
        switch(msg){
          case "success" :
            emit(GlSuccessState());
            add(LoadGlAccountEvent());
            return;
          case "exist" :
            emit(GlAccountsErrorState(tr.accountExist));
            return;
          case "failed" :
            emit(GlAccountsErrorState(tr.operationFailedMessage));
            return;
          default:
            emit(GlAccountsErrorState(msg));
            return;
        }

      }catch(e){
        emit(GlAccountsErrorState(e.toString()));
      }
    });
    on<DeleteGlEvent>((event, emit) async{
      final tr = localizationService.loc;
      emit(GlAccountsLoadingState());
      try{
        final response = await _repo.deleteGl(accNumber: event.accNumber);
        final msg = response["msg"];
        switch(msg){
          case "success" :
            emit(GlSuccessState());
            add(LoadGlAccountEvent());
            return;
          case "dependent" :
            emit(GlAccountsErrorState(tr.glDependentMsg));
            return;
          case "failed" :
            emit(GlAccountsErrorState(tr.operationFailedMessage));
            return;
          default:
            emit(GlAccountsErrorState(msg));
            return;
        }

      }catch(e){
        emit(GlAccountsErrorState(e.toString()));
      }
    });
  }
}
