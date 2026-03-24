import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zaitoonpro/Services/repositories.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Report/Ui/Finance/TrialBalance/model/trial_balance_model.dart';

part 'trial_balance_event.dart';
part 'trial_balance_state.dart';

class TrialBalanceBloc extends Bloc<TrialBalanceEvent, TrialBalanceState> {
  final Repositories _repo;
  TrialBalanceBloc(this._repo) : super(TrialBalanceInitial()) {

    on<LoadTrialBalanceEvent>((event, emit) async{
      emit(TrialBalanceLoadingState());
      try{
        final balance = await _repo.getTrialBalance(date: event.date, branchCode: event.branchCode);
        emit(TrialBalanceLoadedState(balance));
      }catch(e){
        emit(TrialBalanceErrorState(e.toString()));
      }
    });
  }
}
