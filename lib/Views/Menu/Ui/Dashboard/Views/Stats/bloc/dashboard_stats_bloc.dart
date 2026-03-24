import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zaitoonpro/Services/repositories.dart';
import '../model/stats_model.dart';

part 'dashboard_stats_event.dart';
part 'dashboard_stats_state.dart';

class DashboardStatsBloc extends Bloc<DashboardStatsEvent, DashboardStatsState> {
  final Repositories repository;
  DashboardStatsModel? _cachedStats;

  DashboardStatsBloc(this.repository) : super(DashboardStatsInitial()) {
    on<FetchDashboardStatsEvent>(_onFetchDashboardStats);
  }

  Future<void> _onFetchDashboardStats(
      FetchDashboardStatsEvent event,
      Emitter<DashboardStatsState> emit,
      ) async {
    // If we have cached data, show it immediately (silent refresh)
    if (_cachedStats != null) {
      emit(DashboardStatsLoaded(_cachedStats!, isRefreshing: true));
    } else {
      // Only show loading if no cached data
      emit(DashboardStatsLoading());
    }

    try {
      final stats = await repository.getDashboardStats();
      _cachedStats = stats; // Cache the result
      emit(DashboardStatsLoaded(stats, isRefreshing: false));
    } catch (e) {
      // On error, keep showing cached data if available
      if (_cachedStats != null) {
        emit(DashboardStatsLoaded(_cachedStats!));
      } else {
        emit(DashboardStatsError(e.toString()));
      }
    }
  }
}