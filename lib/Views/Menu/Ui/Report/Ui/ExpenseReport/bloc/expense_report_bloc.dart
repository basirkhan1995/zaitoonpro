import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zaitoonpro/Services/repositories.dart';

import '../exp_report_model.dart';

part 'expense_report_event.dart';
part 'expense_report_state.dart';

class ExpenseReportBloc extends Bloc<ExpenseReportEvent, ExpenseReportState> {
  final Repositories _repo;
  static const int defaultLimit = 1000;

  ExpenseReportBloc(this._repo) : super(ExpenseReportInitial()) {
    on<FetchExpenseReport>(_onFetchExpenseReport);
    on<FilterExpenseReport>(_onFilterExpenseReport);
    on<RefreshExpenseReport>(_onRefreshExpenseReport);
    on<ClearExpenseReportFilters>(_onClearExpenseReportFilters);
  }

  Future<void> _onFetchExpenseReport(
      FetchExpenseReport event,
      Emitter<ExpenseReportState> emit,
      ) async {
    emit(ExpenseReportLoading());
    try {
      final report = await _repo.getExpenseReport(
        dateFrom: event.dateFrom,
        dateTo: event.dateTo,
        currency: event.currency,
        accountNumber: event.accountNumber,
      );

      emit(ExpenseReportLoaded(
        expenseReport: report,
        dateFrom: event.dateFrom,
        dateTo: event.dateTo,
        currency: event.currency,
        accountNumber: event.accountNumber,
      ));
    } catch (e) {
      emit(ExpenseReportError(e.toString()));
    }
  }

  Future<void> _onFilterExpenseReport(
      FilterExpenseReport event,
      Emitter<ExpenseReportState> emit,
      ) async {
    // If currently loaded, show loading
    if (state is ExpenseReportLoaded) {
      emit(ExpenseReportLoading());
    }

    try {
      final report = await _repo.getExpenseReport(
        dateFrom: event.dateFrom,
        dateTo: event.dateTo,
        currency: event.currency,
        accountNumber: event.accountNumber,
      );

      emit(ExpenseReportLoaded(
        expenseReport: report,
        dateFrom: event.dateFrom,
        dateTo: event.dateTo,
        currency: event.currency,
        accountNumber: event.accountNumber,
      ));
    } catch (e) {
      emit(ExpenseReportError(e.toString()));
    }
  }

  Future<void> _onRefreshExpenseReport(
      RefreshExpenseReport event,
      Emitter<ExpenseReportState> emit,
      ) async {
    final currentState = state;
    if (currentState is ExpenseReportLoaded) {
      emit(ExpenseReportLoading());
      try {
        final report = await _repo.getExpenseReport(
          dateFrom: currentState.dateFrom,
          dateTo: currentState.dateTo,
          currency: currentState.currency,
          accountNumber: currentState.accountNumber,
        );

        emit(ExpenseReportLoaded(
          expenseReport: report,
          dateFrom: currentState.dateFrom,
          dateTo: currentState.dateTo,
          currency: currentState.currency,
          accountNumber: currentState.accountNumber,
        ));
      } catch (e) {
        emit(ExpenseReportError(e.toString()));
      }
    } else {
      // If not loaded, fetch default
      add(const FetchExpenseReport());
    }
  }

  void _onClearExpenseReportFilters(
      ClearExpenseReportFilters event,
      Emitter<ExpenseReportState> emit,
      ) {
    // Fetch with no filters (last 30 days default)
    add(const FetchExpenseReport());
  }
}