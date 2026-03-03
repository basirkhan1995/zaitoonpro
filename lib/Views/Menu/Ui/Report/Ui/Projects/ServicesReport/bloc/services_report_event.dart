part of 'services_report_bloc.dart';

sealed class ServicesReportEvent extends Equatable {
  const ServicesReportEvent();
}

class LoadServicesReportEvent extends ServicesReportEvent{
  final String? fromDate;
  final String? toDate;
  final int? serviceId;
  final int? projectId;
  final String? currency;
  const LoadServicesReportEvent({this.fromDate,this.toDate, this.serviceId, this.projectId, this.currency});
  @override
  List<Object?> get props => [fromDate, toDate, serviceId, projectId, currency];
}

class ResetServicesReportEvent extends ServicesReportEvent{
  @override
  List<Object?> get props => [];
}