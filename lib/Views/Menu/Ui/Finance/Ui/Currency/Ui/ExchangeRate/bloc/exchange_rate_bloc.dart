import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zaitoonpro/Services/repositories.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Finance/Ui/Currency/Ui/ExchangeRate/model/rate_model.dart';

part 'exchange_rate_event.dart';
part 'exchange_rate_state.dart';

class ExchangeRateBloc extends Bloc<ExchangeRateEvent, ExchangeRateState> {
  final Repositories _repo;

  ExchangeRateBloc(this._repo) : super(ExchangeRateInitial()) {

    on<LoadExchangeRateEvent>((event, emit) async {
      // Preserve existing data
      List<ExchangeRateModel>? currentRates;
      String? currentSingleRate;
      if (state is ExchangeRateLoadedState) {
        currentRates = (state as ExchangeRateLoadedState).rates;
        currentSingleRate = (state as ExchangeRateLoadedState).rate;
      }

      // Only show full loader if no previous data
      if (currentRates == null || currentRates.isEmpty) {
        emit(ExchangeRateLoadingState());
      }

      try {
        final rates = await _repo.getExchangeRate(ccyCode: event.ccyCode);
        emit(ExchangeRateLoadedState(rates: rates));
      } catch (e) {
        // On error, keep previous data if exists
        if (currentRates != null) {
          emit(ExchangeRateLoadedState(rates: currentRates, rate: currentSingleRate));
        } else {
          emit(ExchangeRateErrorState(e.toString()));
        }
      }
    });

    on<GetExchangeRateEvent>((event, emit) async {
      try {
        final rate = await _repo.getSingleRate(fromCcy: event.fromCcy, toCcy: event.toCcy);

        // Preserve existing rates
        List<ExchangeRateModel>? currentRates;
        if (state is ExchangeRateLoadedState) {
          currentRates = (state as ExchangeRateLoadedState).rates;
        }

        emit(ExchangeRateLoadedState(rates: currentRates ?? [], rate: rate));
      } catch (e) {
        emit(ExchangeRateErrorState(e.toString()));
      }
    });

    on<AddExchangeRateEvent>((event, emit) async {
      try {
        final rates = await _repo.addExchangeRate(newRate: event.newRate);
        if (rates["msg"] == "success") {
          emit(ExchangeRateSuccessState());
        }
      } catch (e) {
        emit(ExchangeRateErrorState(e.toString()));
      }
    });
  }
}
