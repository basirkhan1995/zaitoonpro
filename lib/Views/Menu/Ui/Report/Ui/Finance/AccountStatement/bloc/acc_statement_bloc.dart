import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zaitoonpro/Services/repositories.dart';

import '../model/stmt_model.dart';

part 'acc_statement_event.dart';
part 'acc_statement_state.dart';

class AccStatementBloc extends Bloc<AccStatementEvent, AccStatementState> {
  final Repositories _repo;
  AccStatementBloc(this._repo) : super(AccStatementInitial()) {

    on<LoadAccountStatementEvent>((event, emit) async{
      emit(AccStatementLoadingState());
      try{
        final stmt = await _repo.getAccountStatement(
            account: event.accountNumber,
            fromDate: event.fromDate, toDate: event.toDate);
        emit(AccStatementLoadedState(accStatementDetails: stmt));
      }catch(e){
        emit(AccStatementErrorState(e.toString()));
      }
    });
    on<ResetAccStmtEvent>((event,emit){
      emit(AccStatementInitial());
    });
  }
}
