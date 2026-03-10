part of 'stakeholders_report_bloc.dart';

sealed class StakeholdersReportEvent extends Equatable {
  const StakeholdersReportEvent();
}

class LoadStakeholdersReportEvent extends StakeholdersReportEvent{
  final String? search;
  final String? dob;
  final String? phone;
  final String? gender;
  const LoadStakeholdersReportEvent({this.search, this.dob, this.phone, this.gender});
  @override
  List<Object?> get props => [search, dob, phone, gender];
}

class ResetStakeholdersReportEvent extends StakeholdersReportEvent {
  @override
  List<Object?> get props => [];
}