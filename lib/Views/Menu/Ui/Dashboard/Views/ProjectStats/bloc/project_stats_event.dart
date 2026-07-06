part of 'project_stats_bloc.dart';

sealed class ProjectStatsEvent extends Equatable {
  const ProjectStatsEvent();

  @override
  List<Object> get props => [];
}

final class FetchProjectStatsEvent extends ProjectStatsEvent {
  const FetchProjectStatsEvent();
}

final class RefreshProjectStatsEvent extends ProjectStatsEvent {
  const RefreshProjectStatsEvent();
}