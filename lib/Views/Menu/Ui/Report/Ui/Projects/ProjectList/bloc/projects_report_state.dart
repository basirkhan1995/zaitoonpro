part of 'projects_report_bloc.dart';

sealed class ProjectsReportState extends Equatable {
  const ProjectsReportState();
}

final class ProjectsReportInitial extends ProjectsReportState {
  @override
  List<Object> get props => [];
}

final class ProjectsReportLoadingState extends ProjectsReportState {
  @override
  List<Object> get props => [];
}

final class ProjectsReportErrorState extends ProjectsReportState {
  final String message;
  const ProjectsReportErrorState(this.message);
  @override
  List<Object> get props => [message];
}

final class ProjectsReportLoadedState extends ProjectsReportState {
  final List<ProjectsReportModel> prj;
  const ProjectsReportLoadedState(this.prj);
  @override
  List<Object> get props => [prj];
}
