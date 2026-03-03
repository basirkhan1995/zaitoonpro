part of 'projects_report_bloc.dart';

sealed class ProjectsReportEvent extends Equatable {
  const ProjectsReportEvent();
}

class LoadProjectReportEvent extends ProjectsReportEvent{
  final String? fromDate;
  final String? toDate;
  final int? customerId;
  final int? status;
  final String? currency;

  const LoadProjectReportEvent({this.fromDate, this.toDate, this.customerId, this.status, this.currency});
  @override
  List<Object?> get props => [fromDate, toDate, customerId, status];
}

class ResetProjectReportEvent extends ProjectsReportEvent{
  @override
  List<Object?> get props => [];
}