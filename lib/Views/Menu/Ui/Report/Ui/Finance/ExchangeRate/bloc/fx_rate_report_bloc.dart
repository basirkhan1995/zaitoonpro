import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zaitoonpro/Services/repositories.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Report/Ui/Finance/ExchangeRate/model/rate_report_model.dart';

part 'fx_rate_report_event.dart';
part 'fx_rate_report_state.dart';

class FxRateReportBloc extends Bloc<FxRateReportEvent, FxRateReportState> {
  final Repositories _repo;
  List<ExchangeRateReportModel> _cachedRates = [];

  FxRateReportBloc(this._repo) : super(FxRateReportInitial()) {
    on<LoadFxRateReportEvent>(_onLoadFxRateReport);
  }

  Future<void> _onLoadFxRateReport(
      LoadFxRateReportEvent event,
      Emitter<FxRateReportState> emit,
      ) async {
    // If we have cached data, show it immediately (silent refresh)
    if (_cachedRates.isNotEmpty) {
      emit(FxRateReportLoadedState(_cachedRates, isRefreshing: true));
    } else {
      // Only show loading if no cached data
      emit(FxRateReportLoadingState());
    }

    try {
      final rates = await _repo.exchangeRateReport(
          fromDate: event.fromDate,
          toDate: event.toDate,
          fromCcy: event.fromCcy,
          toCcy: event.toCcy
      );

      _cachedRates = rates; // Cache the result
      emit(FxRateReportLoadedState(rates));
    } catch (e) {
      // On error, keep showing cached data if available
      if (_cachedRates.isNotEmpty) {
        emit(FxRateReportLoadedState(_cachedRates));
      } else {
        emit(FxRateReportErrorState(e.toString()));
      }
    }
  }
}