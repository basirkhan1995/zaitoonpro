import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zaitoonpro/Services/repositories.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Report/Ui/Finance/Accounts/model/accounts_report_model.dart';

part 'accounts_report_event.dart';
part 'accounts_report_state.dart';

class AccountsReportBloc extends Bloc<AccountsReportEvent, AccountsReportState> {
  final Repositories _repo;
  AccountsReportBloc(this._repo) : super(AccountsReportInitial()) {

    on<LoadAccountsReportEvent>((event, emit)async {
      emit(AccountsReportLoadingState());
      try{
       final accounts = await _repo.getAccountsReport(search: event.search,currency: event.currency,limit: event.limit, status: event.status);
       emit(AccountsReportLoadedState(accounts ?? []));
      }catch(e){
        emit(AccountsReportErrorState(e.toString()));
      }
    });

    on<ResetAccountsReportEvent>((event, emit)async {
      emit(AccountsReportLoadingState());
      try{
        emit(AccountsReportInitial());
      }catch(e){
        emit(AccountsReportErrorState(e.toString()));
      }
    });


  }
}
