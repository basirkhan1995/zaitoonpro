part of 'services_report_bloc.dart';

sealed class ServicesReportState extends Equatable {
  const ServicesReportState();
}

final class ServicesReportInitial extends ServicesReportState {
  @override
  List<Object> get props => [];
}

final class ServicesReportLoadingState extends ServicesReportState {
  @override
  List<Object> get props => [];
}

final class ServicesReportErrorState extends ServicesReportState {
  final String message;
  const ServicesReportErrorState(this.message);
  @override
  List<Object> get props => [message];
}

final class ServicesReportLoadedState extends ServicesReportState {
  final List<ServicesReportModel> services;
  const ServicesReportLoadedState(this.services);
  @override
  List<Object> get props => [services];
}

