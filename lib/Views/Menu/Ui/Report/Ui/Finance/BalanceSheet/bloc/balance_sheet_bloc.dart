import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zaitoonpro/Services/repositories.dart';
import '../model/bs_model.dart';

part 'balance_sheet_event.dart';
part 'balance_sheet_state.dart';

class BalanceSheetBloc extends Bloc<BalanceSheetEvent, BalanceSheetState> {
  final Repositories _repo;

  BalanceSheetBloc(this._repo) : super(BalanceSheetInitial()) {
    on<LoadBalanceSheet>((event, emit) async {
      emit(BalanceSheetLoading());
      try {
        final data = await _repo.balanceSheet(branchCode: event.branchCode);
        emit(BalanceSheetLoaded(data));
      } catch (e) {
        emit(BalanceSheetError(e.toString()));
      }
    });
  }
}
