import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zaitoonpro/Services/repositories.dart';

import '../model/gross_model.dart';

part 'daily_gross_event.dart';
part 'daily_gross_state.dart';

class DailyGrossBloc extends Bloc<DailyGrossEvent, DailyGrossState> {
  final Repositories repository;
  List<DailyGrossModel> _cachedData = [];

  DailyGrossBloc(this.repository) : super(DailyGrossInitial()) {
    on<FetchDailyGrossEvent>(_onFetchDailyGross);
  }

  Future<void> _onFetchDailyGross(
      FetchDailyGrossEvent event,
      Emitter<DailyGrossState> emit,
      ) async {
    // If we have cached data, show it immediately
    if (_cachedData.isNotEmpty) {
      emit(DailyGrossLoaded(_cachedData, isRefreshing: true));
    }

    try {
      final result = await repository.getDailyGross(
        from: event.from,
        to: event.to,
        startGroup: event.startGroup,
        stopGroup: event.stopGroup,
      );

      _cachedData = result; // Cache the result
      emit(DailyGrossLoaded(result));
    } catch (e) {
      // On error, keep showing cached data if available
      if (_cachedData.isNotEmpty) {
        emit(DailyGrossLoaded(_cachedData));
      } else {
        emit(DailyGrossError(e.toString()));
      }
    }
  }
}