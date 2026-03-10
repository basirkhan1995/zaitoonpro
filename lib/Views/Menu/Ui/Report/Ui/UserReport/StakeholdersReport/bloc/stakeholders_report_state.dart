part of 'stakeholders_report_bloc.dart';

sealed class StakeholdersReportState extends Equatable {
  const StakeholdersReportState();
}

final class StakeholdersReportInitial extends StakeholdersReportState {
  @override
  List<Object> get props => [];
}


final class StakeholdersReportLoadingState extends StakeholdersReportState {
  @override
  List<Object> get props => [];
}

final class StakeholdersReportErrorState extends StakeholdersReportState {
  final String message;
  const StakeholdersReportErrorState(this.message);
  @override
  List<Object> get props => [message];
}


final class StakeholdersReportLoadedState extends StakeholdersReportState {
  final List<IndReportModel> ind;
  const StakeholdersReportLoadedState(this.ind);
  @override
  List<Object> get props => [ind];
}



