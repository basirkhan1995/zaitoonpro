part of 'project_stats_bloc.dart';

sealed class ProjectStatsState extends Equatable {
  const ProjectStatsState();

  @override
  List<Object> get props => [];
}

final class ProjectStatsInitial extends ProjectStatsState {}

final class ProjectStatsLoading extends ProjectStatsState {}

final class ProjectStatsLoaded extends ProjectStatsState {
  final ProjectStatsModel stats;
  final bool isRefreshing;

  const ProjectStatsLoaded(this.stats, {this.isRefreshing = false});

  @override
  List<Object> get props => [stats, isRefreshing];
}

final class ProjectStatsError extends ProjectStatsState {
  final String message;

  const ProjectStatsError(this.message);

  @override
  List<Object> get props => [message];
}