// cash_balances_bloc.dart
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zaitoonpro/Services/repositories.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Report/Ui/Finance/Treasury/model/cash_balance_model.dart';

part 'cash_balances_event.dart';
part 'cash_balances_state.dart';

class CashBalancesBloc extends Bloc<CashBalancesEvent, CashBalancesState> {
  final Repositories _repo;
  CashBalancesBloc(this._repo) : super(CashBalancesInitial()) {
    on<LoadCashBalanceBranchWiseEvent>((event, emit) async {
      emit(CashBalancesLoadingState());
      try {
        final cash = await _repo.cashBalances(branchId: event.branchId);
        emit(CashBalancesLoadedState(cash));
      } catch (e) {
        emit(CashBalancesErrorState(e.toString()));
      }
    });

    on<LoadAllCashBalancesEvent>((event, emit) async {
      emit(CashBalancesLoadingState());
      try {
        final cashList = await _repo.allCashBalances();
        emit(AllCashBalancesLoadedState(cashList));
      } catch (e) {
        emit(CashBalancesErrorState(e.toString()));
      }
    });
  }
}