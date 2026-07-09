part of 'projects_bloc.dart';

sealed class ProjectsState extends Equatable {
  const ProjectsState();
}

final class ProjectsInitial extends ProjectsState {
  @override
  List<Object> get props => [];
}

final class ProjectsLoadingState extends ProjectsState {
  @override
  List<Object> get props => [];
}

final class ProjectSuccessState extends ProjectsState {
  @override
  List<Object> get props => [];
}
final class ProjectDeletedState extends ProjectsState {
  @override
  List<Object> get props => [];
}

final class ProjectsErrorState extends ProjectsState {
  final String message;
  const ProjectsErrorState(this.message);
  @override
  List<Object> get props => [message];
}

final class ProjectsLoadedState extends ProjectsState {
  final List<ProjectsModel> pjr;
  const ProjectsLoadedState(this.pjr);
  @override
  List<Object> get props => [pjr];
}


