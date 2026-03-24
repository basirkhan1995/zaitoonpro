import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zaitoonpro/Services/repositories.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Stakeholders/Ui/Accounts/model/acc_model.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Stakeholders/Ui/Accounts/model/stk_acc_model.dart';

part 'accounts_event.dart';
part 'accounts_state.dart';

class AccountsBloc extends Bloc<AccountsEvent, AccountsState> {
  final Repositories _repo;
  AccountsBloc(this._repo) : super(AccountsInitial()) {
    on<LoadAccountsFilterEvent>((event, emit) async{
      emit(AccountLoadingState());
      try{
        final acc = await _repo.getAccountFilter(ccy: event.ccy,include: event.include,exclude: event.exclude,input: event.input);
        emit(AccountLoadedState(acc));
      }catch(e){
        emit(AccountErrorState(e.toString()));
      }
    });

    on<LoadAccountsEvent>((event, emit) async{
      emit(AccountLoadingState());
      try{
       final acc = await _repo.getAccounts(ownerId: event.ownerId);
       emit(AccountLoadedState(acc));
      }catch(e){
        emit(AccountErrorState(e.toString()));
      }
    });

    on<LoadStkAccountsEvent>((event, emit) async{
      emit(AccountLoadingState());
      try{
        final acc = await _repo.getStakeholdersAccounts(search: event.search);
        emit(StkAccountLoadedState(acc));
      }catch(e){
        emit(AccountErrorState(e.toString()));
      }
    });
    on<AddAccountEvent>((event, emit) async{
      emit(AccountLoadingState());
      try{
        final response = await _repo.addAccount(newAccount: event.newAccount);
        if(response["msg"] == "success"){
          emit(AccountSuccessState());
          add(LoadAccountsEvent(ownerId: event.newAccount.actSignatory));
        }
      }catch(e){
        emit(AccountErrorState(e.toString()));
      }
    });
    on<UpdateAccountEvent>((event, emit) async{
      emit(AccountLoadingState());
      try{
        final response = await _repo.editAccount(newAccount: event.newAccount);
        if(response["msg"] == "success"){
          emit(AccountSuccessState());
          add(LoadAccountsEvent(ownerId: event.newAccount.actSignatory));
        }
      }catch(e){
        emit(AccountErrorState(e.toString()));
      }
    });
  }
}
