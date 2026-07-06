import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zaitoonpro/Services/repositories.dart';

import '../project_stats_model.dart';


part 'project_stats_event.dart';
part 'project_stats_state.dart';

class ProjectStatsBloc extends Bloc<ProjectStatsEvent, ProjectStatsState> {
  final Repositories repository;
  ProjectStatsModel? _cachedStats;

  ProjectStatsBloc(this.repository) : super(ProjectStatsInitial()) {
    on<FetchProjectStatsEvent>(_onFetchProjectStats);
    on<RefreshProjectStatsEvent>(_onRefreshProjectStats);
  }

  Future<void> _onFetchProjectStats(
      FetchProjectStatsEvent event,
      Emitter<ProjectStatsState> emit,
      ) async {
    // If we have cached data, show it immediately (silent refresh)
    if (_cachedStats != null) {
      emit(ProjectStatsLoaded(_cachedStats!, isRefreshing: true));
    } else {
      // Only show loading if no cached data
      emit(ProjectStatsLoading());
    }

    try {
      final stats = await repository.getProjectStats();
      _cachedStats = stats; // Cache the result
      emit(ProjectStatsLoaded(stats, isRefreshing: false));
    } catch (e) {
      // On error, keep showing cached data if available
      if (_cachedStats != null) {
        emit(ProjectStatsLoaded(_cachedStats!));
      } else {
        emit(ProjectStatsError(e.toString()));
      }
    }
  }

  Future<void> _onRefreshProjectStats(
      RefreshProjectStatsEvent event,
      Emitter<ProjectStatsState> emit,
      ) async {
    // Show current cached data with refreshing indicator
    if (_cachedStats != null) {
      emit(ProjectStatsLoaded(_cachedStats!, isRefreshing: true));
    } else {
      emit(ProjectStatsLoading());
    }

    try {
      final stats = await repository.getProjectStats();
      _cachedStats = stats;
      emit(ProjectStatsLoaded(stats, isRefreshing: false));
    } catch (e) {
      // On error, keep showing cached data if available
      if (_cachedStats != null) {
        emit(ProjectStatsLoaded(_cachedStats!));
      } else {
        emit(ProjectStatsError(e.toString()));
      }
    }
  }
}